import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_dao.dart';
import 'package:home_pocket/data/daos/group_member_dao.dart';
import 'package:home_pocket/data/repositories/group_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';

void main() {
  late AppDatabase database;
  late GroupRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase.forTesting();
    repository = GroupRepositoryImpl(
      groupDao: GroupDao(database),
      memberDao: GroupMemberDao(database),
    );
    await database
        .into(database.groups)
        .insert(
          GroupsCompanion.insert(
            groupId: 'group-1',
            status: 'active',
            role: 'owner',
            groupName: const Value('Current'),
            groupKey: const Value('epoch-key'),
            keyEpoch: const Value(2),
            createdAt: 1,
            controlRevision: const Value(5),
            controlSnapshotDigest: const Value('digest-5'),
          ),
        );
  });

  tearDown(() => database.close());

  const member = GroupMember(
    deviceId: 'owner',
    publicKey: 'pk',
    deviceName: 'Phone',
    role: 'owner',
    status: 'active',
    displayName: 'Owner',
    avatarEmoji: '🏠',
  );

  test('older revision is ignored without rolling back state', () async {
    final applied = await repository.applyRevisionedAuthoritativeSnapshot(
      groupId: 'group-1',
      groupName: 'Stale',
      role: 'owner',
      keyEpoch: 1,
      members: const [member],
      revision: 4,
      updatedAt: DateTime.utc(2026),
      snapshotDigest: 'digest-4',
    );

    expect(applied, isFalse);
    final group = await repository.getActiveGroup();
    expect(group?.groupName, 'Current');
    expect(group?.keyEpoch, 2);
    expect(group?.controlRevision, 5);
  });

  test('same revision with different content is a hard conflict', () async {
    await expectLater(
      repository.applyRevisionedAuthoritativeSnapshot(
        groupId: 'group-1',
        groupName: 'Conflicting',
        role: 'owner',
        keyEpoch: 2,
        members: const [member],
        revision: 5,
        updatedAt: DateTime.utc(2026),
        snapshotDigest: 'different-digest',
      ),
      throwsA(isA<ControlSnapshotConflictException>()),
    );
  });

  test(
    'new revision applies lifecycle atomically and deduplicates event',
    () async {
      final joinedAt = DateTime.utc(2026, 7, 1);
      final confirmedAt = DateTime.utc(2026, 7, 2);
      final applied = await repository.applyRevisionedAuthoritativeSnapshot(
        groupId: 'group-1',
        groupName: 'Newest',
        role: 'owner',
        keyEpoch: 3,
        members: [
          member.copyWith(joinedAt: joinedAt, confirmedAt: confirmedAt),
        ],
        revision: 6,
        updatedAt: DateTime.utc(2026, 7, 3),
        snapshotDigest: 'digest-6',
        eventId: 'event-6',
        eventRevision: 6,
        eventType: 'member_confirmed',
        eventOccurredAt: confirmedAt,
      );

      expect(applied, isTrue);
      final group = await repository.getActiveGroup();
      expect(group?.groupName, 'Newest');
      expect(group?.controlRevision, 6);
      expect(group?.groupKey, isNull, reason: 'epoch advance retires old key');
      expect(
        group?.members.single.joinedAt?.millisecondsSinceEpoch,
        joinedAt.millisecondsSinceEpoch,
      );
      expect(
        group?.members.single.confirmedAt?.millisecondsSinceEpoch,
        confirmedAt.millisecondsSinceEpoch,
      );
      expect(await repository.hasProcessedControlEvent('event-6'), isTrue);

      final duplicate = await repository.applyRevisionedAuthoritativeSnapshot(
        groupId: 'group-1',
        groupName: 'Newest',
        role: 'owner',
        keyEpoch: 3,
        members: [
          member.copyWith(joinedAt: joinedAt, confirmedAt: confirmedAt),
        ],
        revision: 6,
        updatedAt: DateTime.utc(2026, 7, 3),
        snapshotDigest: 'digest-6',
        eventId: 'event-6',
        eventRevision: 6,
        eventType: 'member_confirmed',
        eventOccurredAt: confirmedAt,
      );
      expect(duplicate, isFalse);
      final count = await database
          .customSelect(
            "SELECT COUNT(*) AS total FROM control_events WHERE event_id = 'event-6'",
          )
          .getSingle();
      expect(count.read<int>('total'), 1);
    },
  );

  test('snapshot atomically settles every covered control event', () async {
    final applied = await repository.applyRevisionedAuthoritativeSnapshot(
      groupId: 'group-1',
      groupName: 'Newest',
      role: 'owner',
      keyEpoch: 2,
      members: const [member],
      revision: 8,
      updatedAt: DateTime.utc(2026, 8, 2),
      snapshotDigest: 'digest-8',
      controlEvents: [
        ControlEventMetadata(
          eventId: 'event-6',
          groupId: 'group-1',
          revision: 6,
          eventType: 'group_renamed',
          occurredAt: DateTime.utc(2026, 8, 2, 1),
        ),
        ControlEventMetadata(
          eventId: 'event-7',
          groupId: 'group-1',
          revision: 7,
          eventType: 'member_removed',
          occurredAt: DateTime.utc(2026, 8, 2, 2),
        ),
        ControlEventMetadata(
          eventId: 'event-8',
          groupId: 'group-1',
          revision: 8,
          eventType: 'key_rotated',
          occurredAt: DateTime.utc(2026, 8, 2, 3),
        ),
      ],
    );

    expect(applied, isTrue);
    expect((await repository.getActiveGroup())?.controlRevision, 8);
    final rows = await database.customSelect(
      '''SELECT event_id, revision FROM control_events
         WHERE group_id = 'group-1' ORDER BY revision''',
    ).get();
    expect(rows.map((row) => row.read<String>('event_id')), [
      'event-6',
      'event-7',
      'event-8',
    ]);
  });
}

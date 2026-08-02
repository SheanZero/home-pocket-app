import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_dao.dart';
import 'package:home_pocket/data/daos/group_member_dao.dart';
import 'package:home_pocket/data/repositories/group_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';

void main() {
  late AppDatabase database;
  late GroupRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting();
    repository = GroupRepositoryImpl(
      groupDao: GroupDao(database),
      memberDao: GroupMemberDao(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('savePendingGroup persists a pending owner group', () async {
    final expiresAt = DateTime(2026, 3, 2);

    await repository.savePendingGroup(
      groupId: 'group-1',
      groupName: 'My Family',
      inviteCode: 'ABC123',
      inviteExpiresAt: expiresAt,
      groupKey: 'group-key-base64',
    );

    final pending = await repository.getPendingGroup();

    expect(pending, isNotNull);
    expect(pending!.groupId, 'group-1');
    expect(pending.status, GroupStatus.pending);
    expect(pending.role, 'owner');
    expect(pending.inviteCode, 'ABC123');
    expect(pending.inviteExpiresAt, expiresAt);
    expect(pending.groupKey, 'group-key-base64');
    expect(pending.members, isEmpty);
  });

  test('saveConfirmingGroup persists members for a joiner', () async {
    final members = [
      const GroupMember(
        deviceId: 'owner-device',
        publicKey: 'owner-public-key',
        deviceName: 'Owner phone',
        role: 'owner',
        status: 'active',
        displayName: 'Owner',
        avatarEmoji: '🏠',
      ),
      const GroupMember(
        deviceId: 'joiner-device',
        publicKey: 'joiner-public-key',
        deviceName: 'Joiner phone',
        role: 'member',
        status: 'pending',
        displayName: 'Joiner',
        avatarEmoji: '🏠',
      ),
    ];

    await repository.saveConfirmingGroup(
      groupId: 'group-2',
      groupName: 'Family Group',
      members: members,
    );

    final pending = await repository.getPendingGroup();

    expect(pending, isNotNull);
    expect(pending!.groupId, 'group-2');
    expect(pending.status, GroupStatus.confirming);
    expect(pending.role, 'member');
    expect(pending.members, hasLength(2));
    expect(
      pending.members.map((member) => member.deviceId),
      containsAll(<String>['owner-device', 'joiner-device']),
    );
  });

  test(
    'getCurrentGroup finds pending, confirming, and active states',
    () async {
      await repository.savePendingGroup(
        groupId: 'pending-group',
        groupName: 'Pending',
        inviteCode: 'ABC123',
        inviteExpiresAt: DateTime(2026, 3, 2),
        groupKey: 'key',
      );
      expect((await repository.getCurrentGroup())?.groupId, 'pending-group');

      await repository.deactivateGroup('pending-group');
      await repository.saveConfirmingGroup(
        groupId: 'confirming-group',
        groupName: 'Confirming',
        members: const [],
      );
      expect((await repository.getCurrentGroup())?.groupId, 'confirming-group');

      await repository.storeGroupKey('confirming-group', 'key');
      await repository.confirmLocalGroup('confirming-group');
      expect((await repository.getCurrentGroup())?.groupId, 'confirming-group');
    },
  );

  test(
    'getCurrentGroup fails closed when corrupt history has two live groups',
    () async {
      await database
          .into(database.groups)
          .insert(
            GroupsCompanion.insert(
              groupId: 'active-a',
              status: 'active',
              role: 'owner',
              createdAt: 1,
            ),
          );
      await database
          .into(database.groups)
          .insert(
            GroupsCompanion.insert(
              groupId: 'pending-b',
              status: 'confirming',
              role: 'member',
              createdAt: 2,
            ),
          );

      await expectLater(
        repository.getCurrentGroup(),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'restoreActiveGroup persists a keyed active snapshot recovered from server',
    () async {
      final members = [
        const GroupMember(
          deviceId: 'owner-device',
          publicKey: 'owner-public-key',
          deviceName: 'Owner phone',
          role: 'owner',
          status: 'active',
          displayName: 'Owner',
          avatarEmoji: '🏠',
        ),
        const GroupMember(
          deviceId: 'member-device',
          publicKey: 'member-public-key',
          deviceName: 'Member phone',
          role: 'member',
          status: 'active',
          displayName: 'Member',
          avatarEmoji: '🏠',
        ),
      ];

      await repository.restoreActiveGroup(
        groupId: 'group-3',
        role: 'member',
        inviteCode: 'ZXCVBN',
        inviteExpiresAt: DateTime(2026, 3, 5),
        groupKey: 'group-key-base64',
        members: members,
      );

      final active = await repository.getActiveGroup();

      expect(active, isNotNull);
      expect(active!.groupId, 'group-3');
      expect(active.status, GroupStatus.active);
      expect(active.role, 'member');
      expect(active.inviteCode, 'ZXCVBN');
      expect(active.inviteExpiresAt, DateTime(2026, 3, 5));
      expect(active.groupKey, 'group-key-base64');
      expect(active.members, unorderedEquals(members));
      expect(active.confirmedAt, isNotNull);
    },
  );

  test('confirmLocalGroup rejects activation without a group key', () async {
    await repository.saveConfirmingGroup(
      groupId: 'group-without-key',
      groupName: 'Family Group',
      members: const [],
    );

    await expectLater(
      repository.confirmLocalGroup('group-without-key'),
      throwsA(isA<StateError>()),
    );
    expect(await repository.getActiveGroup(), isNull);
  });

  test(
    'markGroupConfirming removes a legacy group from active lookup',
    () async {
      await repository.restoreActiveGroup(
        groupId: 'legacy-active-group',
        role: 'member',
        groupKey: 'group-key-base64',
        members: const [],
      );

      await repository.markGroupConfirming('legacy-active-group');

      expect(await repository.getActiveGroup(), isNull);
      final pending = await repository.getPendingGroup();
      expect(pending?.status, GroupStatus.confirming);
    },
  );

  test('deactivateGroup atomically removes members and group key', () async {
    const groupId = 'group-to-deactivate';
    const member = GroupMember(
      deviceId: 'member-device',
      publicKey: 'member-public-key',
      deviceName: 'Member phone',
      role: 'member',
      status: 'active',
      displayName: 'Member',
      avatarEmoji: '🏠',
    );
    await repository.restoreActiveGroup(
      groupId: groupId,
      role: 'member',
      groupKey: 'secret-group-key',
      members: const [member],
    );

    await repository.deactivateGroup(groupId);

    expect(await repository.getActiveGroup(), isNull);
    final inactive = await repository.getGroupById(groupId);
    expect(inactive?.status, GroupStatus.inactive);
    expect(inactive?.groupKey, isNull);
    expect(inactive?.members, isEmpty);
  });

  test('updateActiveGroupName cannot mutate a non-active group', () async {
    await repository.saveConfirmingGroup(
      groupId: 'confirming-group',
      groupName: 'Original',
      members: const [],
    );

    expect(
      await repository.updateActiveGroupName('confirming-group', 'Injected'),
      isFalse,
    );
    expect(
      (await repository.getGroupById('confirming-group'))?.groupName,
      'Original',
    );

    await repository.storeGroupKey('confirming-group', 'group-key');
    await repository.confirmLocalGroup('confirming-group');
    expect(
      await repository.updateActiveGroupName('confirming-group', 'Current'),
      isTrue,
    );
    expect((await repository.getActiveGroup())?.groupName, 'Current');
  });

  test('member identity refresh preserves the verified local avatar', () async {
    await repository.restoreActiveGroup(
      groupId: 'profile-group',
      role: 'owner',
      groupKey: 'group-key',
      members: const [
        GroupMember(
          deviceId: 'member-device',
          publicKey: 'member-public-key',
          deviceName: 'Member phone',
          role: 'member',
          status: 'active',
          displayName: 'Before',
          avatarEmoji: '🏠',
          avatarImagePath: '/documents/avatars/member.jpg',
          avatarImageHash: 'verified-hash',
        ),
      ],
    );

    await repository.updateMemberIdentity(
      groupId: 'profile-group',
      deviceId: 'member-device',
      displayName: 'After',
      avatarEmoji: '🌟',
    );

    final member = (await repository.getActiveGroup())!.members.single;
    expect(member.displayName, 'After');
    expect(member.avatarEmoji, '🌟');
    expect(member.avatarImagePath, '/documents/avatars/member.jpg');
    expect(member.avatarImageHash, 'verified-hash');
  });

  test('deactivating one group clears only its inbound ledger', () async {
    await repository.restoreActiveGroup(
      groupId: 'group-a',
      role: 'owner',
      groupKey: 'group-key',
      members: const [],
    );
    await database.customStatement('''
      INSERT INTO inbound_sync_operations (
        group_id, operation_id, message_id, state, created_at, updated_at
      ) VALUES
        ('group-a', 'same-id', 'message-a', 'applied', 1, 1),
        ('group-b', 'same-id', 'message-b', 'applied', 1, 1)
    ''');

    await repository.deactivateGroup('group-a');

    final rows = await database
        .customSelect(
          'SELECT group_id FROM inbound_sync_operations '
          "WHERE operation_id = 'same-id'",
        )
        .get();
    expect(rows.map((row) => row.read<String>('group_id')), ['group-b']);
  });
}

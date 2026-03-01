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
      bookId: 'book-1',
      inviteCode: 'ABC123',
      inviteExpiresAt: expiresAt,
      groupKey: 'group-key-base64',
    );

    final pending = await repository.getPendingGroup();

    expect(pending, isNotNull);
    expect(pending!.groupId, 'group-1');
    expect(pending.bookId, 'book-1');
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
      ),
      const GroupMember(
        deviceId: 'joiner-device',
        publicKey: 'joiner-public-key',
        deviceName: 'Joiner phone',
        role: 'member',
        status: 'pending',
      ),
    ];

    await repository.saveConfirmingGroup(
      groupId: 'group-2',
      bookId: 'book-2',
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
}

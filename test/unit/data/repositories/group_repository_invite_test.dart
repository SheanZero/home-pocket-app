import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_dao.dart';
import 'package:home_pocket/data/daos/group_member_dao.dart';
import 'package:home_pocket/data/repositories/group_repository_impl.dart';

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

  tearDown(() => database.close());

  test(
    'updateInviteCode persists the refreshed code and expiry together',
    () async {
      await repository.savePendingGroup(
        groupId: 'group-1',
        groupName: 'Pocket Family',
        inviteCode: '111222',
        inviteExpiresAt: DateTime(2026, 8, 1),
        groupKey: 'group-key',
      );
      final refreshedExpiry = DateTime(2026, 8, 2, 12, 30);

      await repository.updateInviteCode('group-1', '333444', refreshedExpiry);

      final refreshed = await repository.getGroupById('group-1');
      expect(refreshed?.inviteCode, '333444');
      expect(refreshed?.inviteExpiresAt, refreshedExpiry);
    },
  );
}

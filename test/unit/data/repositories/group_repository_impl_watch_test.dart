import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_dao.dart';
import 'package:home_pocket/data/daos/group_member_dao.dart';
import 'package:home_pocket/data/repositories/group_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';

void main() {
  late AppDatabase db;
  late GroupRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = GroupRepositoryImpl(
      groupDao: GroupDao(db),
      memberDao: GroupMemberDao(db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('GroupRepositoryImpl.watchActiveGroup', () {
    test(
      'emits null then active group info when local group is confirmed',
      () async {
        Future<void>.delayed(const Duration(milliseconds: 50), () async {
          await repo.savePendingGroup(
            groupId: 'group-1',
            groupName: 'Test Family',
            inviteCode: 'ABC123',
            inviteExpiresAt: DateTime.now().add(const Duration(hours: 1)),
            groupKey: 'group-key',
          );
          await repo.confirmLocalGroup('group-1');
        });

        await expectLater(
          repo.watchActiveGroup(),
          emitsInOrder([
            // Initial: no active group in DB
            isNull,
            // After savePendingGroup: still null (status is 'pending', not 'active')
            isNull,
            // After confirmLocalGroup: status becomes 'active', group emitted
            isA<GroupInfo>()
                .having((g) => g.groupId, 'groupId', 'group-1')
                .having((g) => g.status, 'status', GroupStatus.active),
          ]),
        );
      },
    );
  });
}

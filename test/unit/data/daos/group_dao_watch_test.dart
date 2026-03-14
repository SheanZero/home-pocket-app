import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_dao.dart';

void main() {
  late AppDatabase db;
  late GroupDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = GroupDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('GroupDao.watchActiveGroup', () {
    test('emits null when no active group exists', () async {
      expect(dao.watchActiveGroup(), emits(isNull));
    });

    test('emits active group after insert', () async {
      Future<void>.delayed(const Duration(milliseconds: 50), () async {
        await dao.insert(
          GroupsCompanion.insert(
            groupId: 'group-1',
            status: 'active',
            role: 'owner',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      });

      await expectLater(
        dao.watchActiveGroup(),
        emitsInOrder([
          isNull,
          isA<GroupData>().having(
            (group) => group.groupId,
            'groupId',
            'group-1',
          ),
        ]),
      );
    });

    test('emits null after active group becomes inactive', () async {
      await dao.insert(
        GroupsCompanion.insert(
          groupId: 'group-2',
          status: 'active',
          role: 'owner',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      Future<void>.delayed(const Duration(milliseconds: 50), () async {
        await dao.updateStatus('group-2', 'inactive');
      });

      await expectLater(
        dao.watchActiveGroup(),
        emitsInOrder([
          isA<GroupData>().having(
            (group) => group.groupId,
            'groupId',
            'group-2',
          ),
          isNull,
        ]),
      );
    });
  });
}

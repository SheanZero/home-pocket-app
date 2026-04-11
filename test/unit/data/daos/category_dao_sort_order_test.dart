import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';

void main() {
  late AppDatabase db;
  late CategoryDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = CategoryDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryDao.updateSortOrder', () {
    test('updates only sortOrder and updatedAt; leaves other fields intact', () async {
      final now = DateTime(2026, 4, 11, 9, 0);
      await dao.insertCategory(
        id: 'cat_food',
        name: 'category_food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        isSystem: true,
        sortOrder: 1,
        createdAt: now,
      );

      await dao.updateSortOrder('cat_food', 42);

      final row = await dao.findById('cat_food');
      expect(row, isNotNull);
      expect(row!.sortOrder, 42);
      expect(row.name, 'category_food'); // untouched
      expect(row.icon, 'restaurant'); // untouched
      expect(row.color, '#FF5722'); // untouched
      expect(row.isSystem, true); // untouched
      expect(row.updatedAt, isNotNull); // stamped
    });

    test('no-op when id does not exist (does not throw)', () async {
      await dao.updateSortOrder('cat_missing', 99);
      final row = await dao.findById('cat_missing');
      expect(row, isNull);
    });
  });
}

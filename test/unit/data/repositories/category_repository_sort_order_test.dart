import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';

void main() {
  late AppDatabase db;
  late CategoryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = CategoryRepositoryImpl(dao: CategoryDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed() async {
    final now = DateTime(2026, 4, 11);
    await repo.insertBatch([
      Category(id: 'l1_a', name: 'A', icon: 'a', color: '#000',
          level: 1, isSystem: true, sortOrder: 10, createdAt: now),
      Category(id: 'l1_b', name: 'B', icon: 'b', color: '#000',
          level: 1, isSystem: true, sortOrder: 20, createdAt: now),
      Category(id: 'l1_c', name: 'C', icon: 'c', color: '#000',
          level: 1, isSystem: true, sortOrder: 30, createdAt: now),
      Category(id: 'l2_a1', name: 'A1', icon: 'a', color: '#000',
          parentId: 'l1_a', level: 2, sortOrder: 1, createdAt: now),
      Category(id: 'l2_a2', name: 'A2', icon: 'a', color: '#000',
          parentId: 'l1_a', level: 2, sortOrder: 2, createdAt: now),
    ]);
  }

  group('CategoryRepository.updateSortOrders', () {
    test('atomically rewrites sortOrder for the given ids', () async {
      await seed();

      // Reverse L1 order and swap L2 A1/A2
      await repo.updateSortOrders({
        'l1_c': 0,
        'l1_b': 1,
        'l1_a': 2,
        'l2_a2': 0,
        'l2_a1': 1,
      });

      final all = await repo.findActive();
      final l1 = all.where((c) => c.level == 1).toList();
      expect(l1.map((c) => c.id), ['l1_c', 'l1_b', 'l1_a']);

      final l2 = all.where((c) => c.parentId == 'l1_a').toList();
      expect(l2.map((c) => c.id), ['l2_a2', 'l2_a1']);
    });

    test('does not touch ids absent from the map', () async {
      await seed();
      await repo.updateSortOrders({'l1_a': 99});

      final b = await repo.findById('l1_b');
      expect(b!.sortOrder, 20); // unchanged
    });

    test('empty map is a no-op', () async {
      await seed();
      await repo.updateSortOrders({});
      final a = await repo.findById('l1_a');
      expect(a!.sortOrder, 10);
    });
  });
}

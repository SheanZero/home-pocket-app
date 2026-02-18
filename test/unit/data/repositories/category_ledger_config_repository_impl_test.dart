import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_ledger_config_dao.dart';
import 'package:home_pocket/data/repositories/category_ledger_config_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  late AppDatabase db;
  late CategoryLedgerConfigDao dao;
  late CategoryLedgerConfigRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = CategoryLedgerConfigDao(db);
    repo = CategoryLedgerConfigRepositoryImpl(dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryLedgerConfigRepositoryImpl', () {
    test('upsert and findById', () async {
      final config = CategoryLedgerConfig(
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        updatedAt: DateTime(2026, 2, 18),
      );

      await repo.upsert(config);
      final result = await repo.findById('cat_food');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food');
      expect(result.ledgerType, LedgerType.survival);
    });

    test('findAll returns all configs', () async {
      final now = DateTime(2026, 2, 18);
      await repo.upsert(CategoryLedgerConfig(
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          updatedAt: now));
      await repo.upsert(CategoryLedgerConfig(
          categoryId: 'cat_fun',
          ledgerType: LedgerType.soul,
          updatedAt: now));

      final all = await repo.findAll();
      expect(all.length, 2);
    });

    test('delete removes config', () async {
      await repo.upsert(CategoryLedgerConfig(
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        updatedAt: DateTime(2026, 2, 18),
      ));

      await repo.delete('cat_food');
      final result = await repo.findById('cat_food');
      expect(result, isNull);
    });

    test('upsertBatch inserts multiple configs', () async {
      final now = DateTime(2026, 2, 18);
      await repo.upsertBatch([
        CategoryLedgerConfig(
            categoryId: 'cat_food',
            ledgerType: LedgerType.survival,
            updatedAt: now),
        CategoryLedgerConfig(
            categoryId: 'cat_fun',
            ledgerType: LedgerType.soul,
            updatedAt: now),
      ]);

      final all = await repo.findAll();
      expect(all.length, 2);
    });

    test('deleteAll removes all configs', () async {
      final now = DateTime(2026, 2, 18);
      await repo.upsert(CategoryLedgerConfig(
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          updatedAt: now));
      await repo.upsert(CategoryLedgerConfig(
          categoryId: 'cat_fun',
          ledgerType: LedgerType.soul,
          updatedAt: now));

      await repo.deleteAll();
      final all = await repo.findAll();
      expect(all, isEmpty);
    });
  });
}

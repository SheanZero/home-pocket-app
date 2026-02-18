import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_ledger_config_dao.dart';

void main() {
  late AppDatabase db;
  late CategoryLedgerConfigDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = CategoryLedgerConfigDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryLedgerConfigDao', () {
    test('upsert and findById', () async {
      final now = DateTime(2026, 2, 18);
      await dao.upsert(
        categoryId: 'cat_food',
        ledgerType: 'survival',
        updatedAt: now,
      );

      final config = await dao.findById('cat_food');
      expect(config, isNotNull);
      expect(config!.ledgerType, 'survival');
    });

    test('upsert overwrites existing entry', () async {
      final t1 = DateTime(2026, 2, 18, 10);
      final t2 = DateTime(2026, 2, 18, 11);

      await dao.upsert(
        categoryId: 'cat_food',
        ledgerType: 'survival',
        updatedAt: t1,
      );
      await dao.upsert(
        categoryId: 'cat_food',
        ledgerType: 'soul',
        updatedAt: t2,
      );

      final config = await dao.findById('cat_food');
      expect(config!.ledgerType, 'soul');
    });

    test('findAll returns all configs', () async {
      final now = DateTime(2026, 2, 18);
      await dao.upsert(
        categoryId: 'cat_food',
        ledgerType: 'survival',
        updatedAt: now,
      );
      await dao.upsert(
        categoryId: 'cat_entertainment',
        ledgerType: 'soul',
        updatedAt: now,
      );

      final all = await dao.findAll();
      expect(all.length, 2);
    });

    test('delete removes config', () async {
      final now = DateTime(2026, 2, 18);
      await dao.upsert(
        categoryId: 'cat_food',
        ledgerType: 'survival',
        updatedAt: now,
      );

      await dao.delete('cat_food');
      final config = await dao.findById('cat_food');
      expect(config, isNull);
    });

    test('deleteAll removes all configs', () async {
      final now = DateTime(2026, 2, 18);
      await dao.upsert(
        categoryId: 'cat_food',
        ledgerType: 'survival',
        updatedAt: now,
      );
      await dao.upsert(
        categoryId: 'cat_fun',
        ledgerType: 'soul',
        updatedAt: now,
      );

      await dao.deleteAll();
      final all = await dao.findAll();
      expect(all, isEmpty);
    });

    test('upsertBatch inserts multiple configs', () async {
      final now = DateTime(2026, 2, 18);
      await dao.upsertBatch([
        LedgerConfigInsertData(
          categoryId: 'cat_food',
          ledgerType: 'survival',
          updatedAt: now,
        ),
        LedgerConfigInsertData(
          categoryId: 'cat_fun',
          ledgerType: 'soul',
          updatedAt: now,
        ),
      ]);

      final all = await dao.findAll();
      expect(all.length, 2);
    });
  });
}

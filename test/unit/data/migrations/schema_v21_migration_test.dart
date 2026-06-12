import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
// HashChainService import will be added in Plan 40-06 when the STORE-04 test goes GREEN.

void main() {
  test('AppDatabase schemaVersion is 21', () {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    // RED: schemaVersion is currently 20 — this test fails until Wave 1 lands.
    expect(db.schemaVersion, equals(21));
  });

  test('exchange_rates table exists after fresh install', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    // RED: exchange_rates table does not exist until Wave 1 migration lands.
    final rows = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          "WHERE type = 'table' AND name = 'exchange_rates'",
        )
        .get();
    expect(rows, isNotEmpty);
  });

  test('exchange_rates index idx_exchange_rates_currency_date exists', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    // RED: index does not exist until Wave 1 migration lands.
    final rows = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          "WHERE type = 'index' AND tbl_name = 'exchange_rates'",
        )
        .get();
    final indexNames = rows.map((r) => r.read<String>('name')).toSet();
    expect(indexNames, contains('idx_exchange_rates_currency_date'));
  });

  group('v20→v21 upgrade columns', () {
    test('transactions table has original_currency column after v20→v21 upgrade',
        () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      // RED: column does not exist until Wave 1 migration lands.
      final cols = await db
          .customSelect('PRAGMA table_info(transactions)')
          .get();
      final colNames = cols.map((r) => r.read<String>('name')).toSet();
      expect(colNames, contains('original_currency'));
    });

    test('transactions table has original_amount column after v20→v21 upgrade',
        () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      // RED: column does not exist until Wave 1 migration lands.
      final cols = await db
          .customSelect('PRAGMA table_info(transactions)')
          .get();
      final colNames = cols.map((r) => r.read<String>('name')).toSet();
      expect(colNames, contains('original_amount'));
    });

    test('transactions table has applied_rate column after v20→v21 upgrade',
        () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      // RED: column does not exist until Wave 1 migration lands.
      final cols = await db
          .customSelect('PRAGMA table_info(transactions)')
          .get();
      final colNames = cols.map((r) => r.read<String>('name')).toSet();
      expect(colNames, contains('applied_rate'));
    });
  });

  test('original_currency, original_amount, applied_rate columns are nullable (accept NULL)',
      () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    // RED: columns do not exist until Wave 1 migration lands.
    // Once they exist, this test verifies they accept NULL values.
    final now = DateTime.utc(2026, 6, 12).millisecondsSinceEpoch;
    // Insert a transaction row with NULL for the three new columns.
    // This will fail until schemaVersion 21 is in place.
    await db.customStatement(
      '''INSERT INTO transactions
         (id, book_id, device_id, amount, type, category_id, ledger_type,
          timestamp, created_at, current_hash, entry_source,
          original_currency, original_amount, applied_rate)
         VALUES (
           'tx_null_currency', 'book_1', 'device_1', 500, 'expense',
           'cat_food', 'daily', ?, ?, '', 'manual',
           NULL, NULL, NULL
         )''',
      [now, now],
    );
    final rows = await db
        .customSelect(
          'SELECT original_currency, original_amount, applied_rate '
          "FROM transactions WHERE id = 'tx_null_currency'",
        )
        .get();
    expect(rows, isNotEmpty);
    expect(rows.first.read<String?>('original_currency'), isNull);
    expect(rows.first.read<int?>('original_amount'), isNull);
    expect(rows.first.read<String?>('applied_rate'), isNull);
  });

  test(
    'STORE-04: HashChainService.verifyChain passes on dataset with '
    'null and non-null currency fields',
    () {
      // STUB — implement in Wave 2 (Plan 40-06) after schema migration lands.
      // This test requires a pre-seeded in-memory DB with the v21 schema
      // and HashChainService wired up; all infrastructure is absent in Wave 0.
      fail(
        'not implemented — implement in Wave 2 (Plan 40-06) after schema '
        'migration lands',
      );
    },
  );
}

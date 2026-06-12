import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('AppDatabase schemaVersion is at least 20 (shopping_items era)', () {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    // v20 introduced shopping_items; later phases may bump further (v21: exchange_rates).
    expect(db.schemaVersion, greaterThanOrEqualTo(20));
  });

  test('real Drift schema creates all shopping_items indices', () async {
    // Guards CR-01: the customIndices getter is not consumed by Drift, so the
    // indices are emitted by hand in app_database.dart. A fresh forTesting() DB
    // runs onCreate, which must create them.
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final rows = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          "WHERE type = 'index' AND tbl_name = 'shopping_items'",
        )
        .get();
    final indexNames = rows.map((r) => r.read<String>('name')).toSet();
    expect(
      indexNames,
      containsAll([
        'idx_shopping_list_type',
        'idx_shopping_list_deleted',
        'idx_shopping_completed',
        'idx_shopping_sort_order',
        'idx_shopping_added_by_book',
      ]),
    );
  });

  group('shopping_items v20 physical schema', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _createV20ShoppingItemsTable(rawDb);
    });

    tearDown(() => rawDb.dispose());

    test('shopping_items table has correct column names', () {
      final cols = rawDb
          .select('PRAGMA table_info(shopping_items)')
          .map((r) => r['name'] as String)
          .toSet();

      expect(
        cols,
        containsAll([
          'id',
          'device_id',
          'list_type',
          'name',
          'ledger_type',
          'category_id',
          'tags',
          'note',
          'quantity',
          'estimated_price',
          'completed_at',
          'is_completed',
          'sort_order',
          'is_synced',
          'is_deleted',
          'added_by_book_id',
          'created_at',
          'updated_at',
        ]),
      );
    });

    test("list_type CHECK rejects 'shared'", () {
      expect(
        () => _insertRow(rawDb, listType: 'shared'),
        throwsA(isA<SqliteException>()),
      );
    });

    test("list_type accepts 'public' and 'private'", () {
      expect(() => _insertRow(rawDb, id: 'item_pub', listType: 'public'), returnsNormally);
      expect(() => _insertRow(rawDb, id: 'item_prv', listType: 'private'), returnsNormally);
    });

    test('completed_at column accepts NULL', () {
      _insertRow(rawDb, id: 'item_null_ca');
      final rows = rawDb.select(
        "SELECT completed_at FROM shopping_items WHERE id = 'item_null_ca'",
      );
      expect(rows.first['completed_at'], isNull);
    });

    test('is_deleted soft-delete: row persists with isDeleted=true', () {
      _insertRow(rawDb, id: 'item_deleted');
      rawDb.execute(
        "UPDATE shopping_items SET is_deleted = 1 WHERE id = 'item_deleted'",
      );
      final rows = rawDb.select(
        "SELECT is_deleted FROM shopping_items WHERE id = 'item_deleted'",
      );
      expect(rows.first['is_deleted'], equals(1));
    });
  });
}

void _createV20ShoppingItemsTable(Database db) {
  db.execute('''
    CREATE TABLE shopping_items (
      id TEXT NOT NULL,
      device_id TEXT NOT NULL,
      list_type TEXT NOT NULL DEFAULT 'private',
      name TEXT NOT NULL,
      ledger_type TEXT,
      category_id TEXT,
      tags TEXT,
      note TEXT,
      quantity INTEGER NOT NULL DEFAULT 1,
      estimated_price INTEGER,
      completed_at INTEGER,
      is_completed INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      added_by_book_id TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER,
      PRIMARY KEY (id),
      CHECK(list_type IN ('public', 'private')),
      CHECK(quantity >= 1),
      CHECK(ledger_type IN ('daily', 'joy') OR ledger_type IS NULL),
      CHECK(estimated_price IS NULL OR estimated_price >= 0)
    )
  ''');
}

void _insertRow(
  Database db, {
  String id = 'item_test',
  String listType = 'private',
}) {
  final now = DateTime(2026, 6, 7, 12).millisecondsSinceEpoch;
  db.execute(
    '''INSERT INTO shopping_items
       (id, device_id, list_type, name, created_at)
       VALUES (?, 'device_test', ?, 'Test Item', ?)''',
    [id, listType, now],
  );
}

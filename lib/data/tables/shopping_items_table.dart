import 'package:drift/drift.dart';

/// Shopping list items table — persistent list entries with soft-delete and sync support.
@DataClassName('ShoppingItemRow')
class ShoppingItems extends Table {
  // Identity
  TextColumn get id => text()();
  TextColumn get deviceId => text()();

  // Visibility (D1): 'public' syncs via family_sync; 'private' is local-only
  TextColumn get listType =>
      text().withDefault(const Constant('private'))();

  // Required content
  TextColumn get name => text().withLength(min: 1, max: 200)();

  // Optional accounting (D3 — no FK, per CONTEXT D-03 "pure list")
  // 'daily' | 'joy' | null
  TextColumn get ledgerType => text().nullable()();
  TextColumn get categoryId => text().nullable()();

  // D-01: JSON-encoded List<String>. Encode/decode at repository boundary.
  TextColumn get tags => text().nullable()();

  // note encrypted at repository boundary (ITEM-05); nullable in schema, repo handles empty string as null
  TextColumn get note => text().nullable()();

  // D-02: whole-count; UI defaults blank to 1
  IntColumn get quantity =>
      integer().withDefault(const Constant(1))();

  // ITEM-05: integer yen, rendered via NumberFormatter
  IntColumn get estimatedPrice => integer().nullable()();

  // D-03: sticky-complete merge reference timestamp (SYNC-05). Merge algorithm in Phase 37.
  DateTimeColumn get completedAt => dateTime().nullable()();

  // State flags
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  // nullable TEXT, no FK — shadow book may not be local yet
  TextColumn get addedByBookId => text().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK(list_type IN ('public', 'private'))",
    'CHECK(quantity >= 1)',
    "CHECK(ledger_type IN ('daily', 'joy') OR ledger_type IS NULL)",
    'CHECK(estimated_price IS NULL OR estimated_price >= 0)',
  ];

  // No @override on customIndices — CLAUDE.md pitfall #11
  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_shopping_list_type', columns: {#listType}),
    TableIndex(
      name: 'idx_shopping_list_deleted',
      columns: {#listType, #isDeleted},
    ),
    TableIndex(name: 'idx_shopping_completed', columns: {#isCompleted}),
    TableIndex(name: 'idx_shopping_sort_order', columns: {#sortOrder}),
    TableIndex(
      name: 'idx_shopping_added_by_book',
      columns: {#addedByBookId},
    ),
  ];
}

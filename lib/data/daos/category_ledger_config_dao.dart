import 'package:drift/drift.dart';

import '../app_database.dart';

/// Parameter object for batch ledger config insertion.
class LedgerConfigInsertData {
  final String categoryId;
  final String ledgerType;
  final DateTime updatedAt;

  const LedgerConfigInsertData({
    required this.categoryId,
    required this.ledgerType,
    required this.updatedAt,
  });
}

/// Data access object for the CategoryLedgerConfigs table.
class CategoryLedgerConfigDao {
  CategoryLedgerConfigDao(this._db);

  final AppDatabase _db;

  /// Insert or update a ledger config for a category.
  Future<void> upsert({
    required String categoryId,
    required String ledgerType,
    required DateTime updatedAt,
  }) async {
    await _db.into(_db.categoryLedgerConfigs).insertOnConflictUpdate(
      CategoryLedgerConfigsCompanion.insert(
        categoryId: categoryId,
        ledgerType: ledgerType,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Find a ledger config by category ID.
  Future<CategoryLedgerConfigRow?> findById(String categoryId) async {
    return (_db.select(_db.categoryLedgerConfigs)
          ..where((t) => t.categoryId.equals(categoryId)))
        .getSingleOrNull();
  }

  /// Return all ledger configs.
  Future<List<CategoryLedgerConfigRow>> findAll() async {
    return _db.select(_db.categoryLedgerConfigs).get();
  }

  /// Delete a ledger config by category ID.
  Future<void> delete(String categoryId) async {
    await (_db.delete(_db.categoryLedgerConfigs)
          ..where((t) => t.categoryId.equals(categoryId)))
        .go();
  }

  /// Delete all ledger configs (hard delete, for backup restore).
  Future<void> deleteAll() async {
    await _db.delete(_db.categoryLedgerConfigs).go();
  }

  /// Batch insert or update multiple ledger configs.
  Future<void> upsertBatch(List<LedgerConfigInsertData> configs) async {
    await _db.batch((batch) {
      for (final c in configs) {
        batch.insert(
          _db.categoryLedgerConfigs,
          CategoryLedgerConfigsCompanion.insert(
            categoryId: c.categoryId,
            ledgerType: c.ledgerType,
            updatedAt: c.updatedAt,
          ),
          onConflict: DoUpdate(
            (old) => CategoryLedgerConfigsCompanion(
              ledgerType: Value(c.ledgerType),
              updatedAt: Value(c.updatedAt),
            ),
          ),
        );
      }
    });
  }
}

import '../models/category_ledger_config.dart';

/// Repository for personal category ledger type configurations.
abstract class CategoryLedgerConfigRepository {
  Future<void> upsert(CategoryLedgerConfig config);
  Future<CategoryLedgerConfig?> findById(String categoryId);
  Future<List<CategoryLedgerConfig>> findAll();
  Future<void> delete(String categoryId);
  Future<void> deleteAll();
  Future<void> upsertBatch(List<CategoryLedgerConfig> configs);
}

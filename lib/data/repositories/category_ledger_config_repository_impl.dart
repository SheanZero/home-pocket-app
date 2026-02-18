import '../../features/accounting/domain/models/category_ledger_config.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/category_ledger_config_repository.dart';
import '../app_database.dart';
import '../daos/category_ledger_config_dao.dart';

/// Concrete implementation of [CategoryLedgerConfigRepository].
class CategoryLedgerConfigRepositoryImpl
    implements CategoryLedgerConfigRepository {
  CategoryLedgerConfigRepositoryImpl({required CategoryLedgerConfigDao dao})
      : _dao = dao;

  final CategoryLedgerConfigDao _dao;

  @override
  Future<void> upsert(CategoryLedgerConfig config) async {
    await _dao.upsert(
      categoryId: config.categoryId,
      ledgerType: config.ledgerType.name,
      updatedAt: config.updatedAt,
    );
  }

  @override
  Future<CategoryLedgerConfig?> findById(String categoryId) async {
    final row = await _dao.findById(categoryId);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<List<CategoryLedgerConfig>> findAll() async {
    final rows = await _dao.findAll();
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> delete(String categoryId) async {
    await _dao.delete(categoryId);
  }

  @override
  Future<void> deleteAll() async {
    await _dao.deleteAll();
  }

  @override
  Future<void> upsertBatch(List<CategoryLedgerConfig> configs) async {
    await _dao.upsertBatch(
      configs
          .map((c) => LedgerConfigInsertData(
                categoryId: c.categoryId,
                ledgerType: c.ledgerType.name,
                updatedAt: c.updatedAt,
              ))
          .toList(),
    );
  }

  CategoryLedgerConfig _toModel(CategoryLedgerConfigRow row) {
    return CategoryLedgerConfig(
      categoryId: row.categoryId,
      ledgerType: LedgerType.values.byName(row.ledgerType),
      updatedAt: row.updatedAt,
    );
  }
}

import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/category_ledger_config_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../accounting/category_service.dart';

/// Resolves the effective ledger type for a category.
///
/// @deprecated Use [CategoryService.resolveLedgerType] instead.
/// This class delegates to [CategoryService] internally.
@Deprecated('Use CategoryService instead')
class ResolveLedgerTypeService {
  ResolveLedgerTypeService({
    required CategoryRepository categoryRepository,
    required CategoryLedgerConfigRepository ledgerConfigRepository,
  }) : _delegate = CategoryService(
          categoryRepository: categoryRepository,
          ledgerConfigRepository: ledgerConfigRepository,
        );

  final CategoryService _delegate;

  /// Returns the effective [LedgerType] for [categoryId], or null if
  /// the category doesn't exist or has no config.
  Future<LedgerType?> resolve(String categoryId) async {
    return _delegate.resolveLedgerType(categoryId);
  }

  /// Returns the resolved L1 category ID for statistics aggregation.
  Future<String?> resolveL1(String categoryId) async {
    return _delegate.resolveL1(categoryId);
  }
}

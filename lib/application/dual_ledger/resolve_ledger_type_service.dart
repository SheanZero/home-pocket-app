import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/category_ledger_config_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';

/// Resolves the effective ledger type for a category.
///
/// Resolution rules (PRD FR-004):
/// - L1: returns its own `CategoryLedgerConfig.ledgerType`
/// - L2 with override: returns the L2's own config
/// - L2 without override: inherits from parent L1's config
class ResolveLedgerTypeService {
  ResolveLedgerTypeService({
    required CategoryRepository categoryRepository,
    required CategoryLedgerConfigRepository ledgerConfigRepository,
  })  : _categoryRepo = categoryRepository,
        _configRepo = ledgerConfigRepository;

  final CategoryRepository _categoryRepo;
  final CategoryLedgerConfigRepository _configRepo;

  /// Returns the effective [LedgerType] for [categoryId], or null if
  /// the category doesn't exist or has no config.
  Future<LedgerType?> resolve(String categoryId) async {
    final category = await _categoryRepo.findById(categoryId);
    if (category == null) return null;

    // Check for direct config (works for both L1 and L2 with override)
    final directConfig = await _configRepo.findById(categoryId);
    if (directConfig != null) return directConfig.ledgerType;

    // L2 without override -> inherit from parent L1
    if (category.level == 2 && category.parentId != null) {
      final parentConfig = await _configRepo.findById(category.parentId!);
      return parentConfig?.ledgerType;
    }

    return null;
  }

  /// Returns the resolved L1 category ID for statistics aggregation.
  ///
  /// - L1 -> returns its own ID
  /// - L2 -> returns its parentId (the L1)
  Future<String?> resolveL1(String categoryId) async {
    final category = await _categoryRepo.findById(categoryId);
    if (category == null) return null;

    if (category.level == 1) return category.id;
    return category.parentId;
  }
}

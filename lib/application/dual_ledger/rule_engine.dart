import '../../features/accounting/domain/models/transaction.dart';

/// Layer 1: Category-based rule engine for ledger classification.
///
/// Maps category IDs to [LedgerType] with 100% confidence.
/// Highest priority in the 3-layer classification engine.
class RuleEngine {
  final Map<String, LedgerType> _categoryRules = {};

  RuleEngine() {
    _initializeDefaultRules();
  }

  void _initializeDefaultRules() {
    // Survival (必要支出)
    _categoryRules['cat_food'] = LedgerType.survival;
    _categoryRules['cat_food_breakfast'] = LedgerType.survival;
    _categoryRules['cat_food_lunch'] = LedgerType.survival;
    _categoryRules['cat_food_dinner'] = LedgerType.survival;
    _categoryRules['cat_food_snack'] = LedgerType.survival;
    _categoryRules['cat_transport'] = LedgerType.survival;
    _categoryRules['cat_transport_public'] = LedgerType.survival;
    _categoryRules['cat_transport_taxi'] = LedgerType.survival;
    _categoryRules['cat_housing'] = LedgerType.survival;
    _categoryRules['cat_medical'] = LedgerType.survival;
    _categoryRules['cat_daily'] = LedgerType.survival;
    _categoryRules['cat_other_expense'] = LedgerType.survival;

    // Soul (享受型支出)
    _categoryRules['cat_entertainment'] = LedgerType.soul;
    _categoryRules['cat_shopping'] = LedgerType.soul;
    _categoryRules['cat_education'] = LedgerType.soul;
    _categoryRules['cat_social'] = LedgerType.soul;
  }

  /// Classify a category ID. Returns null if no rule matches.
  LedgerType? classify(String categoryId) {
    return _categoryRules[categoryId];
  }

  /// Add or override a classification rule.
  void addRule(String categoryId, LedgerType ledgerType) {
    _categoryRules[categoryId] = ledgerType;
  }

  /// Remove a classification rule.
  void removeRule(String categoryId) {
    _categoryRules.remove(categoryId);
  }
}

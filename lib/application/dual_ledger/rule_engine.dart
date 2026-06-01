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
    _categoryRules['cat_food'] = LedgerType.daily;
    _categoryRules['cat_food_dining_out'] = LedgerType.daily;
    _categoryRules['cat_food_snack'] = LedgerType.daily;
    _categoryRules['cat_transport'] = LedgerType.daily;
    _categoryRules['cat_transport_public'] = LedgerType.daily;
    _categoryRules['cat_transport_taxi'] = LedgerType.daily;
    _categoryRules['cat_housing'] = LedgerType.daily;
    _categoryRules['cat_medical'] = LedgerType.daily;
    _categoryRules['cat_daily'] = LedgerType.daily;
    _categoryRules['cat_other_expense'] = LedgerType.daily;

    // Soul (享受型支出)
    _categoryRules['cat_entertainment'] = LedgerType.joy;
    _categoryRules['cat_shopping'] = LedgerType.joy;
    _categoryRules['cat_education'] = LedgerType.joy;
    _categoryRules['cat_social'] = LedgerType.joy;
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

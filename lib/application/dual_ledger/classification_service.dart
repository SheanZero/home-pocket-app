import '../../features/accounting/domain/models/transaction.dart';
import 'classification_result.dart';
import 'rule_engine.dart';

/// 3-layer classification engine for dual ledger.
///
/// Priority: Rule Engine → (Merchant DB → ML Classifier) → Default survival.
/// Layers 2 and 3 are stubbed for MVP.
class ClassificationService {
  ClassificationService({required RuleEngine ruleEngine})
    : _ruleEngine = ruleEngine;

  final RuleEngine _ruleEngine;

  /// Classify a transaction into survival or soul ledger.
  Future<ClassificationResult> classify({
    required String categoryId,
    String? merchant,
    String? note,
  }) async {
    // Layer 1: Rule Engine (highest priority, confidence 1.0)
    final ruleResult = _ruleEngine.classify(categoryId);
    if (ruleResult != null) {
      return ClassificationResult(
        ledgerType: ruleResult,
        confidence: 1.0,
        method: ClassificationMethod.rule,
        reason: 'Category rule: $categoryId',
      );
    }

    // Layer 2: Merchant Database (stub for MVP)
    // TODO: Implement MerchantDatabase lookup when lib/infrastructure/ml/ is built

    // Layer 3: ML Classifier (stub for MVP)
    // TODO: Implement TFLiteClassifier when model is available

    // Default fallback: survival
    return ClassificationResult(
      ledgerType: LedgerType.survival,
      confidence: 0.5,
      method: ClassificationMethod.rule,
      reason: 'Default fallback',
    );
  }
}

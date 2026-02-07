import '../../features/accounting/domain/models/transaction.dart';

/// Method used to classify the transaction.
enum ClassificationMethod {
  rule, // Rule engine (Layer 1)
  merchant, // Merchant database (Layer 2)
  ml, // ML classifier (Layer 3)
}

/// Result of the 3-layer classification engine.
class ClassificationResult {
  final LedgerType ledgerType;
  final double confidence;
  final ClassificationMethod method;
  final String reason;

  const ClassificationResult({
    required this.ledgerType,
    required this.confidence,
    required this.method,
    required this.reason,
  });
}

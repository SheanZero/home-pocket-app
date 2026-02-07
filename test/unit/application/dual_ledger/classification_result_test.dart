import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/dual_ledger/classification_result.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  group('ClassificationResult', () {
    test('creates with all required fields', () {
      final result = ClassificationResult(
        ledgerType: LedgerType.soul,
        confidence: 0.95,
        method: ClassificationMethod.rule,
        reason: 'Entertainment category',
      );

      expect(result.ledgerType, LedgerType.soul);
      expect(result.confidence, 0.95);
      expect(result.method, ClassificationMethod.rule);
      expect(result.reason, 'Entertainment category');
    });

    test('ClassificationMethod has all expected values', () {
      expect(ClassificationMethod.values, hasLength(3));
      expect(ClassificationMethod.values, contains(ClassificationMethod.rule));
      expect(
        ClassificationMethod.values,
        contains(ClassificationMethod.merchant),
      );
      expect(ClassificationMethod.values, contains(ClassificationMethod.ml));
    });
  });
}

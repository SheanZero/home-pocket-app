import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/dual_ledger/classification_result.dart';
import 'package:home_pocket/application/dual_ledger/classification_service.dart';
import 'package:home_pocket/application/dual_ledger/rule_engine.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  late RuleEngine ruleEngine;
  late ClassificationService service;

  setUp(() {
    ruleEngine = RuleEngine();
    service = ClassificationService(ruleEngine: ruleEngine);
  });

  group('ClassificationService', () {
    test('uses rule engine when category has a rule (survival)', () async {
      final result = await service.classify(
        categoryId: 'cat_food',
      );

      expect(result.ledgerType, LedgerType.survival);
      expect(result.method, ClassificationMethod.rule);
      expect(result.confidence, 1.0);
    });

    test('uses rule engine when category has a rule (soul)', () async {
      final result = await service.classify(
        categoryId: 'cat_entertainment',
      );

      expect(result.ledgerType, LedgerType.soul);
      expect(result.method, ClassificationMethod.rule);
      expect(result.confidence, 1.0);
    });

    test('falls back to default survival for unknown category', () async {
      final result = await service.classify(
        categoryId: 'cat_unknown_xyz',
      );

      expect(result.ledgerType, LedgerType.survival);
      expect(result.confidence, lessThan(1.0));
    });

    test('classifies all default expense categories without error', () async {
      final expenseCategoryIds = [
        'cat_food', 'cat_food_breakfast', 'cat_food_lunch',
        'cat_food_dinner', 'cat_food_snack',
        'cat_transport', 'cat_transport_public', 'cat_transport_taxi',
        'cat_shopping', 'cat_entertainment', 'cat_housing',
        'cat_medical', 'cat_education', 'cat_daily',
        'cat_social', 'cat_other_expense',
      ];

      for (final id in expenseCategoryIds) {
        final result = await service.classify(categoryId: id);
        expect(result.ledgerType, isNotNull, reason: 'Failed for $id');
        expect(result.confidence, greaterThan(0), reason: 'Failed for $id');
      }
    });

    test('income categories fall back to survival', () async {
      final result = await service.classify(categoryId: 'cat_salary');
      expect(result.ledgerType, LedgerType.survival);
    });
  });
}

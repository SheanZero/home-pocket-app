import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/dual_ledger/rule_engine.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  late RuleEngine engine;

  setUp(() {
    engine = RuleEngine();
  });

  group('RuleEngine', () {
    group('default survival rules', () {
      test('classifies food categories as survival', () {
        expect(engine.classify('cat_food'), LedgerType.survival);
        expect(engine.classify('cat_food_breakfast'), LedgerType.survival);
        expect(engine.classify('cat_food_lunch'), LedgerType.survival);
        expect(engine.classify('cat_food_dinner'), LedgerType.survival);
        expect(engine.classify('cat_food_snack'), LedgerType.survival);
      });

      test('classifies transport as survival', () {
        expect(engine.classify('cat_transport'), LedgerType.survival);
        expect(engine.classify('cat_transport_public'), LedgerType.survival);
        expect(engine.classify('cat_transport_taxi'), LedgerType.survival);
      });

      test('classifies housing and medical as survival', () {
        expect(engine.classify('cat_housing'), LedgerType.survival);
        expect(engine.classify('cat_medical'), LedgerType.survival);
      });

      test('classifies daily necessities as survival', () {
        expect(engine.classify('cat_daily'), LedgerType.survival);
      });

      test('classifies other_expense as survival', () {
        expect(engine.classify('cat_other_expense'), LedgerType.survival);
      });
    });

    group('default soul rules', () {
      test('classifies entertainment as soul', () {
        expect(engine.classify('cat_entertainment'), LedgerType.soul);
      });

      test('classifies shopping as soul', () {
        expect(engine.classify('cat_shopping'), LedgerType.soul);
      });

      test('classifies education as soul', () {
        expect(engine.classify('cat_education'), LedgerType.soul);
      });

      test('classifies social as soul', () {
        expect(engine.classify('cat_social'), LedgerType.soul);
      });
    });

    test('returns null for unknown category', () {
      expect(engine.classify('cat_unknown_xyz'), isNull);
    });

    test('addRule overrides existing rule', () {
      expect(engine.classify('cat_food'), LedgerType.survival);
      engine.addRule('cat_food', LedgerType.soul);
      expect(engine.classify('cat_food'), LedgerType.soul);
    });

    test('removeRule makes classify return null', () {
      expect(engine.classify('cat_food'), LedgerType.survival);
      engine.removeRule('cat_food');
      expect(engine.classify('cat_food'), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/dual_ledger/rule_engine.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  late RuleEngine engine;

  setUp(() {
    engine = RuleEngine();
  });

  group('RuleEngine', () {
    group('default daily rules', () {
      test('classifies food categories as daily', () {
        expect(engine.classify('cat_food'), LedgerType.daily);
        expect(engine.classify('cat_food_dining_out'), LedgerType.daily);
        expect(engine.classify('cat_food_snack'), LedgerType.daily);
      });

      test('classifies transport as daily', () {
        expect(engine.classify('cat_transport'), LedgerType.daily);
        expect(engine.classify('cat_transport_public'), LedgerType.daily);
        expect(engine.classify('cat_transport_taxi'), LedgerType.daily);
      });

      test('classifies housing and medical as daily', () {
        expect(engine.classify('cat_housing'), LedgerType.daily);
        expect(engine.classify('cat_medical'), LedgerType.daily);
      });

      test('classifies daily necessities as daily', () {
        expect(engine.classify('cat_daily'), LedgerType.daily);
      });

      test('classifies other_expense as daily', () {
        expect(engine.classify('cat_other_expense'), LedgerType.daily);
      });
    });

    group('default joy rules', () {
      test('classifies entertainment as joy', () {
        expect(engine.classify('cat_entertainment'), LedgerType.joy);
      });

      test('classifies shopping as joy', () {
        expect(engine.classify('cat_shopping'), LedgerType.joy);
      });

      test('classifies education as joy', () {
        expect(engine.classify('cat_education'), LedgerType.joy);
      });

      test('classifies social as joy', () {
        expect(engine.classify('cat_social'), LedgerType.joy);
      });
    });

    test('returns null for unknown category', () {
      expect(engine.classify('cat_unknown_xyz'), isNull);
    });

    test('addRule overrides existing rule', () {
      expect(engine.classify('cat_food'), LedgerType.daily);
      engine.addRule('cat_food', LedgerType.joy);
      expect(engine.classify('cat_food'), LedgerType.joy);
    });

    test('removeRule makes classify return null', () {
      expect(engine.classify('cat_food'), LedgerType.daily);
      engine.removeRule('cat_food');
      expect(engine.classify('cat_food'), isNull);
    });
  });
}

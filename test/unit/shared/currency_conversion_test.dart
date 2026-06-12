// currency_conversion_test.dart — convertToJpy behavior tests.
//
// STORE-02 specification: convertToJpy(originalMinorUnits, appliedRate, subunitToUnit)
// returns an int (JPY rounded to nearest yen via Dart's .round(), which is
// half-AWAY-FROM-ZERO — NOT banker's rounding; 750.5 rounds to 751, not 750).

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/utils/currency_conversion.dart';

void main() {
  group('convertToJpy', () {
    test('USD 50.00 at 149.30 → 7465', () {
      // 5000 minor units (cents) / 100 subunit × 149.30 = 7465.0 JPY
      expect(
        convertToJpy(
          originalMinorUnits: 5000,
          appliedRate: '149.30',
          subunitToUnit: 100,
        ),
        equals(7465),
      );
    });

    test('USD 1 cent (1 minor unit) at 149.30 → 1', () {
      // 1 cent / 100 × 149.30 = 1.493 → rounds to 1
      expect(
        convertToJpy(
          originalMinorUnits: 1,
          appliedRate: '149.30',
          subunitToUnit: 100,
        ),
        equals(1),
      );
    });

    test('EUR 1000 minor units (10.00) at 160.50 → 1605', () {
      // 1000 / 100 × 160.50 = 1605.0 JPY
      expect(
        convertToJpy(
          originalMinorUnits: 1000,
          appliedRate: '160.50',
          subunitToUnit: 100,
        ),
        equals(1605),
      );
    });

    test('edge case 0 minor units → 0', () {
      expect(
        convertToJpy(
          originalMinorUnits: 0,
          appliedRate: '149.30',
          subunitToUnit: 100,
        ),
        equals(0),
      );
    });

    test("rate string '148.5000' same result as '148.5'", () {
      final result1 = convertToJpy(
        originalMinorUnits: 1000,
        appliedRate: '148.5000',
        subunitToUnit: 100,
      );
      final result2 = convertToJpy(
        originalMinorUnits: 1000,
        appliedRate: '148.5',
        subunitToUnit: 100,
      );
      expect(result1, equals(result2));
    });

    test('JPY 100 (subunitToUnit=1) at 1.0 → 100', () {
      // JPY has no subunit — 1 minor unit = 1 JPY
      expect(
        convertToJpy(
          originalMinorUnits: 100,
          appliedRate: '1.0',
          subunitToUnit: 1,
        ),
        equals(100),
      );
    });

    test('half-yen 750.5 rounds AWAY from zero to 751 (pins .round() semantics)',
        () {
      // 1501 × 0.5 = 750.5 exactly (0.5 is exact in binary). Dart's .round()
      // is half-away-from-zero → 751. Banker's rounding would give 750 (round
      // half to even) — this test pins which semantics convertToJpy has
      // (WR-08: the old header comment claimed banker's rounding, wrongly).
      expect(
        convertToJpy(
          originalMinorUnits: 1501,
          appliedRate: '0.5',
          subunitToUnit: 1,
        ),
        equals(751),
      );
    });

    test('half-yen 749.5 rounds up to 750', () {
      expect(
        convertToJpy(
          originalMinorUnits: 1499,
          appliedRate: '0.5',
          subunitToUnit: 1,
        ),
        equals(750),
      );
    });

    test("float-precision stressor: rate '0.1' × 1,000,000 → exactly 100000",
        () {
      // 0.1 is not exactly representable in binary; 1000000 × 0.1 =
      // 100000.00000000001 as doubles — .round() must still land on 100000.
      expect(
        convertToJpy(
          originalMinorUnits: 1000000,
          appliedRate: '0.1',
          subunitToUnit: 1,
        ),
        equals(100000),
      );
    });

    test('USD 50 at 148.30 → 7415 (STORE-02 specification example)', () {
      // 5000 cents / 100 × 148.30 = 7415.0 JPY
      expect(
        convertToJpy(
          originalMinorUnits: 5000,
          appliedRate: '148.30',
          subunitToUnit: 100,
        ),
        equals(7415),
      );
    });

    test('large amount USD 100000 cents (1000.00) at 149.99 → 149990', () {
      // 100000 / 100 × 149.99 = 149990.0 JPY
      expect(
        convertToJpy(
          originalMinorUnits: 100000,
          appliedRate: '149.99',
          subunitToUnit: 100,
        ),
        equals(149990),
      );
    });

    test('KRW 1000 (subunitToUnit=1) at 0.110 → 110', () {
      // KRW has no sub-unit (display convention 0 decimals): 1000 × 0.110 = 110.0
      expect(
        convertToJpy(
          originalMinorUnits: 1000,
          appliedRate: '0.110',
          subunitToUnit: 1,
        ),
        equals(110),
      );
    });

    group('invalid input fails fast (WR-01)', () {
      for (final badRate in ['abc', '', '0', '-1', 'NaN', 'Infinity']) {
        test("appliedRate '$badRate' throws FormatException", () {
          expect(
            () => convertToJpy(
              originalMinorUnits: 5000,
              appliedRate: badRate,
              subunitToUnit: 100,
            ),
            throwsFormatException,
          );
        });
      }

      test('subunitToUnit 0 throws ArgumentError (not Infinity crash)', () {
        expect(
          () => convertToJpy(
            originalMinorUnits: 5000,
            appliedRate: '149.30',
            subunitToUnit: 0,
          ),
          throwsArgumentError,
        );
      });

      test('negative subunitToUnit throws ArgumentError', () {
        expect(
          () => convertToJpy(
            originalMinorUnits: 5000,
            appliedRate: '149.30',
            subunitToUnit: -100,
          ),
          throwsArgumentError,
        );
      });

      test('negative originalMinorUnits throws ArgumentError', () {
        expect(
          () => convertToJpy(
            originalMinorUnits: -5000,
            appliedRate: '149.30',
            subunitToUnit: 100,
          ),
          throwsArgumentError,
        );
      });
    });
  });

  group('validateAppliedRate (ADR-020 D-05)', () {
    test('accepts plain decimal literals', () {
      for (final ok in ['149.30', '0.001', '1', '157.3421']) {
        expect(validateAppliedRate(ok), isNull, reason: ok);
      }
    });

    test('rejects scientific notation, signs, whitespace, and non-numbers',
        () {
      for (final bad in ['1.493e2', '+149.30', '-1.5', ' 149.30 ', 'abc',
          '', 'NaN', 'Infinity', '.5', '5.']) {
        expect(validateAppliedRate(bad), isNotNull, reason: bad);
      }
    });

    test('rejects zero', () {
      expect(validateAppliedRate('0'), isNotNull);
      expect(validateAppliedRate('0.000'), isNotNull);
    });
  });

  group('subunitToUnitFor', () {
    test('JPY and KRW have no sub-unit', () {
      expect(subunitToUnitFor('JPY'), equals(1));
      expect(subunitToUnitFor('KRW'), equals(1));
    });

    test('2-decimal currencies use 100', () {
      for (final code in ['USD', 'EUR', 'CNY', 'GBP']) {
        expect(subunitToUnitFor(code), equals(100), reason: code);
      }
    });
  });
}

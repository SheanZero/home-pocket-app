// currency_conversion_test.dart — Wave 0 RED state stubs.
//
// These tests fail at compile time because lib/shared/utils/currency_conversion.dart
// does not exist yet — it is created in Wave 1 (Plan 40-03). The compile error
// IS the correct RED state for Wave 0.
//
// STORE-02 specification: convertToJpy(originalMinorUnits, appliedRate, subunitToUnit)
// returns an int (JPY rounded to nearest yen using banker's rounding).

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

    test('preview and persist give same int for USD 4999 at 151.23', () {
      // Both calls must return the same integer — no floating-point divergence.
      final result1 = convertToJpy(
        originalMinorUnits: 4999,
        appliedRate: '151.23',
        subunitToUnit: 100,
      );
      final result2 = convertToJpy(
        originalMinorUnits: 4999,
        appliedRate: '151.23',
        subunitToUnit: 100,
      );
      expect(result1, equals(result2));
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
  });
}

/// Phase 42 GAP-CLOSURE (WR-01) — unit coverage for `foreignPushIsStale`, the
/// bail predicate guarding `_pushForeignTriple` against a mid-fetch input change.
///
/// The original guard checked only currency + minor-units; a DATE change mid
/// rate-fetch would persist an OLD-date rate against the NEW-date timestamp —
/// undetectable once saved because the currency triple is excluded from the
/// hash chain (ADR-021). WR-01 adds the date dimension; this pins all three.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/screens/manual_one_step_screen.dart';

void main() {
  final d1 = DateTime(2026, 5, 1);
  final d2 = DateTime(2026, 5, 2);

  test('not stale when currency, amount and date all match', () {
    expect(
      foreignPushIsStale(
        capturedCurrency: 'USD',
        currentCurrency: 'USD',
        capturedMinorUnits: 5000,
        currentMinorUnits: 5000,
        capturedDate: d1,
        currentDate: d1,
      ),
      isFalse,
    );
  });

  test('stale when currency changed mid-fetch', () {
    expect(
      foreignPushIsStale(
        capturedCurrency: 'USD',
        currentCurrency: 'EUR',
        capturedMinorUnits: 5000,
        currentMinorUnits: 5000,
        capturedDate: d1,
        currentDate: d1,
      ),
      isTrue,
    );
  });

  test('stale when amount changed mid-fetch', () {
    expect(
      foreignPushIsStale(
        capturedCurrency: 'USD',
        currentCurrency: 'USD',
        capturedMinorUnits: 5000,
        currentMinorUnits: 9900,
        capturedDate: d1,
        currentDate: d1,
      ),
      isTrue,
    );
  });

  test('WR-01: stale when DATE changed mid-fetch (the regressed dimension)', () {
    expect(
      foreignPushIsStale(
        capturedCurrency: 'USD',
        currentCurrency: 'USD',
        capturedMinorUnits: 5000,
        currentMinorUnits: 5000,
        capturedDate: d1,
        currentDate: d2,
      ),
      isTrue,
      reason: 'an OLD-date rate must never be pushed against a NEW-date '
          'timestamp (ADR-021 — triple excluded from hash chain)',
    );
  });
}

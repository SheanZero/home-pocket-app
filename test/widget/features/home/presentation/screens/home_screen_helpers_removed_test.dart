import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI regression guard — the 3 deleted home_screen.dart helpers must stay
/// deleted.
///
/// Phase 10 D-01 deletes `_computeHappinessROI`, `_computeSatisfaction`, and
/// `_buildLedgerRows` from `home_screen.dart` because:
///   - `_computeHappinessROI` was a misleading "budget-share" framing
///     (anti-pattern per FEATURES.md research line 81-82).
///   - `_computeSatisfaction` was an intraday-only metric superseded by
///     `HappinessReport.avgSatisfaction` (Phase 9 D-15).
///   - `_buildLedgerRows` is no longer needed (`HomeHeroCard` consumes
///     `MonthlyReport.soulTotal/survivalTotal` directly).
///
/// This test asserts none of those identifiers reappear in the source. If a
/// future refactor reintroduces them, this test fails — and the planner must
/// re-justify the resurrection rather than letting it slip in unnoticed.
///
/// **Why source-grep, not symbol-lookup:** the helpers are private (underscore
/// prefix), so they are not exported in any way reflectable. The cheapest
/// regression guard is a substring scan against the file content.
///
/// **Lifecycle:** During Wave 0 (Plan 10-03) this test is skipped because the
/// 3 helpers still exist. Plan 10-08 deletes the helpers and unskips this
/// test (removes the `skip:` argument). After Plan 10-08 lands, the test
/// runs on every `flutter test` invocation as a CI guard.
void main() {
  test('home_screen.dart does not reintroduce deleted helpers', () {
    final file = File(
      'lib/features/home/presentation/screens/home_screen.dart',
    );
    expect(
      file.existsSync(),
      isTrue,
      reason: 'home_screen.dart must exist at the expected path',
    );

    final source = file.readAsStringSync();

    expect(
      source,
      isNot(contains('_computeHappinessROI')),
      reason:
          '_computeHappinessROI was deleted in Phase 10 D-01 — see CONTEXT.md',
    );
    expect(
      source,
      isNot(contains('_computeSatisfaction')),
      reason:
          '_computeSatisfaction was deleted in Phase 10 D-01 — see CONTEXT.md',
    );
    expect(
      source,
      isNot(contains('_buildLedgerRows')),
      reason: '_buildLedgerRows was deleted in Phase 10 D-01 — see CONTEXT.md',
    );
  });
}

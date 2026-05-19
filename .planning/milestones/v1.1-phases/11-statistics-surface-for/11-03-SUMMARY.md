---
phase: 11-statistics-surface-for
plan: 03
subsystem: analytics
tags: [usecase, riverpod, freezed, l10n, analytics, statsui]

requires:
  - phase: 11-statistics-surface-for
    provides: Plan 11-02 daily soul row and largest expense repository contracts
provides:
  - DailyJoyPerYenPoint Freezed model and generated output
  - Daily Joy/¥ PTVF fold use case with currency-aware base
  - Largest monthly expense use case
  - Anchor-based expense trend use case and provider key
  - Daily Joy/¥ and largest monthly expense async providers
  - Trilingual analytics ARB namespace for Variant δ widgets
affects: [11-statistics-surface-for, analytics, statsui, l10n]

tech-stack:
  added: []
  patterns: [Freezed value model, Riverpod generated providers, typed Flutter l10n placeholders]

key-files:
  created:
    - lib/application/analytics/get_daily_joy_per_yen_use_case.dart
    - lib/application/analytics/get_largest_monthly_expense_use_case.dart
    - lib/features/analytics/domain/models/daily_joy_per_yen_point.dart
    - lib/features/analytics/domain/models/daily_joy_per_yen_point.freezed.dart
    - test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart
    - test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart
  modified:
    - lib/application/analytics/get_expense_trend_use_case.dart
    - lib/features/analytics/presentation/providers/repository_providers.dart
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/features/analytics/presentation/providers/state_happiness.dart
    - lib/features/analytics/presentation/screens/analytics_screen.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations.dart

key-decisions:
  - "Daily Joy/¥ folds use the same α=0.88 PTVF density formula and ptvfBaseFor(currencyCode) base as monthly happiness reports."
  - "Expense trend now trails the selected month via an explicit anchor instead of DateTime.now()."
  - "Analytics ARB strings were added to ja/zh/en in one commit with the hard-locked bar-5 histogram annotation."

patterns-established:
  - "Use cases compute month windows with DateTime(year, month, 1) through DateTime(year, month + 1, 0, 23, 59, 59)."
  - "Consumer-facing analytics provider families include every dimension needed for selected-month invalidation."

requirements-completed: [STATSUI-01, STATSUI-02, STATSUI-03, STATSUI-06, STATSUI-07]

duration: 9min
completed: 2026-05-03
---

# Phase 11 Plan 03: Analytics Use Cases, Providers, and ARB Summary

**Analytics now exposes selected-month Daily Joy/¥, largest monthly expense, anchored 6-month trends, and the trilingual Variant δ copy contract through generated providers and l10n outputs.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-05-03T14:47:47Z
- **Completed:** 2026-05-03T14:56:38Z
- **Tasks:** 2
- **Files modified:** 21

## Accomplishments

- Added `DailyJoyPerYenPoint` with generated Freezed output.
- Added `GetDailyJoyPerYenUseCase` and `GetLargestMonthlyExpenseUseCase`.
- Re-keyed `GetExpenseTrendUseCase` and `expenseTrendProvider` on an explicit selected-month anchor.
- Added `dailyJoyPerYenProvider` and `largestMonthlyExpenseProvider` to `state_happiness.dart`.
- Added 39 analytics ARB keys to each locale and regenerated Flutter l10n outputs.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: failing use case tests** - `c02d4b3` (test)
2. **Task 1 GREEN: use cases, model, providers, anchor trend** - `8d3e88d` (feat)
3. **Task 2: trilingual ARB keys and async providers** - `c27ba9e` (feat)

**Plan metadata:** committed separately with this SUMMARY/state update.

## Files Created/Modified

- `lib/features/analytics/domain/models/daily_joy_per_yen_point.dart` - Freezed output model for per-day Joy/¥ points.
- `lib/features/analytics/domain/models/daily_joy_per_yen_point.freezed.dart` - Generated Freezed implementation.
- `lib/application/analytics/get_daily_joy_per_yen_use_case.dart` - Groups daily soul rows and folds PTVF density per day.
- `lib/application/analytics/get_largest_monthly_expense_use_case.dart` - Month-window wrapper for the total-ledger largest expense query.
- `lib/application/analytics/get_expense_trend_use_case.dart` - Uses `anchor` instead of `DateTime.now()` for the trailing window.
- `lib/features/analytics/presentation/providers/repository_providers.dart` - Adds the two use case providers.
- `lib/features/analytics/presentation/providers/state_analytics.dart` - Re-keys `expenseTrendProvider` on `(bookId, anchor)`.
- `lib/features/analytics/presentation/providers/state_happiness.dart` - Adds Daily Joy/¥ and largest expense async providers.
- `lib/features/analytics/presentation/screens/analytics_screen.dart` - Existing caller passes selected month as trend anchor.
- `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_en.arb` - Adds 39 analytics keys per locale.
- `lib/generated/app_localizations*.dart` - Regenerated typed localization outputs.
- `test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart` - Covers empty rows, day grouping, currency base, sample size, and month boundaries.
- `test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart` - Covers null, passthrough, and month boundaries.
- `test/unit/application/analytics/get_expense_trend_use_case_test.dart` - Pins selected-month anchor behavior.

## Decisions Made

- Followed the existing `MetricResult<T>` positional `Value(data, sampleSize)` constructor instead of the plan sketch's named fields.
- Kept `analyticsScreen.dart` changes limited to existing provider call sites so Plan 11-07 can still own the screen rewrite.
- Used typed ARB placeholder metadata for all placeholder-bearing analytics keys.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `flutter test` and `flutter analyze` printed existing pub advisory decode warnings: `FormatException: advisoriesUpdated must be a String`. The actual test and analyzer exits were green.
- `flutter gen-l10n` printed its standard `l10n.yaml exists` informational message and exited 0.
- `build_runner` printed the existing analyzer language-version warning during generation; the final plan-level codegen rerun wrote 0 outputs.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. This plan added provider/use-case surfaces and ARB strings only; no new endpoint, auth, file access, schema, or trust-boundary persistence surface was introduced.

## Verification

- RED: `flutter test test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart` failed because the new use case/model files did not exist.
- GREEN targeted: `flutter test test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart test/unit/application/analytics/get_expense_trend_use_case_test.dart` passed with 15 tests.
- Plan-level: `flutter test test/unit/application/analytics/` passed with 53 tests.
- `flutter gen-l10n` exited 0.
- `flutter pub run build_runner build --delete-conflicting-outputs` exited 0 and final rerun wrote 0 outputs.
- `flutter analyze lib/application/ lib/features/analytics/ lib/l10n/` reported `No issues found!`.
- ARB parity smoke: 15-key sample returned `15 / 15 / 15`; hard-locked `analyticsHistogramBarFiveAnnotation` strings each returned count `1`.

## Next Phase Readiness

Plans 11-04/11-05/11-06 can consume generated providers and ARB keys without reaching into DAOs or raw use cases. Plan 11-07 can keep the selected-month anchor by passing the selected month to `expenseTrendProvider`.

## Self-Check: PASSED

- Found `.planning/phases/11-statistics-surface-for/11-03-SUMMARY.md`.
- Found task commits `c02d4b3`, `8d3e88d`, and `c27ba9e`.
- Plan-level analytics tests, l10n/codegen, analyzer, and ARB parity checks passed.

---
*Phase: 11-statistics-surface-for*
*Completed: 2026-05-03*

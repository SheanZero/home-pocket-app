---
phase: 46-cards
plan: 01
subsystem: analytics
tags: [flutter, riverpod, freezed, drift, analytics, trend, line-chart, dual-ledger]

# Dependency graph
requires:
  - phase: 44-data-use-case-additions-reuse-first
    provides: "findByBookIds reuse-first fetch primitive; per-ledger zero-default split pattern; category_l1_rollup helper; CategoryDrillDown transient-model precedent"
  - phase: 45-presentation-shell-rebuild
    provides: "analyticsCardRegistry spec-list mechanism; AnalyticsCardContext; refreshTargets single-source pattern; auto-dispose family + D-12 month-anchor key conventions"
provides:
  - "GetWithinMonthCumulativeUseCase — within-month per-day-cumulative per-ledger expense trend over findByBookIds (2-month window, no DAO, no migration)"
  - "WithinMonthCumulativeTrend freezed transient model (per-ledger current+previous month cumulative points; NO previousMonthJoy — joy cross-period unrepresentable)"
  - "withinMonthCumulativeTrendProvider — auto-dispose @riverpod family, month-anchored key, manualOnly-aware"
  - "getWithinMonthCumulativeUseCaseProvider wiring"
  - "Full removal of the 6-month MonthlyTrend/BarChart trend stack (use-case, model, providers, card, bar-chart widget, registry spec, dead tests)"
affects: [46-04, 46-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Within-month per-day running-cumulative transform scoped per calendar month (no cross-month carry), per-ledger split with sparse spend-day points"
    - "Type-level cross-period guard: omitting previousMonthJoy makes a joy cross-period series unrepresentable (D-E1 / ADR-012)"

key-files:
  created:
    - lib/application/analytics/get_within_month_cumulative_use_case.dart
    - lib/features/analytics/domain/models/within_month_cumulative_trend.dart
    - lib/features/analytics/domain/models/within_month_cumulative_trend.freezed.dart
    - test/unit/application/analytics/get_within_month_cumulative_use_case_test.dart
  modified:
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/features/analytics/presentation/providers/repository_providers.dart
    - lib/features/analytics/presentation/analytics_card_registry.dart

key-decisions:
  - "Within-month cumulative trend data path built as a pure Dart transform over findByBookIds (2-month window); no new DAO, no migration, schema stays v21 (RESEARCH Flag 1 verdict)"
  - "Joy side modelled current-month-only via a model with NO previousMonthJoy field — a previous-month joy series is unrepresentable by construction (D-E1, Pitfall 2)"
  - "entrySourceFilter threaded through and applied Dart-side (findByBookIds has no entry-source SQL param) to support the manualOnly joy variant"
  - "DEVIATION: the 6-month TotalSixMonth registry spec + its 'Time' section header were removed in THIS plan (not deferred to 46-07) because total_six_month_card.dart and monthly_spend_trend_bar_chart.dart hard-import the deleted data symbols — a data-only deletion cannot compile, and the must_have requires zero dangling references"

patterns-established:
  - "Per-ledger per-day cumulative: group expense by day-of-month within each calendar month, running sum, optional ledger filter; sparse points (only spend days), no-spend day inherits prior cumulative"
  - "Provider re-anchors raw DateTime to DateTime(year, month) before the family key (D-12) so the use case derives the 2-month window from month precision"

requirements-completed: [OVW-02]

# Metrics
duration: ~40min
completed: 2026-06-17
---

# Phase 46 Plan 01: Within-Month Cumulative Trend Data Path Summary

**Within-month per-day-cumulative per-ledger expense trend (current + previous month spend lines, current-month-only joy line) over the existing findByBookIds primitive, plus full removal of the obsolete 6-month MonthlyTrend/BarChart stack.**

## Performance

- **Duration:** ~40 min
- **Completed:** 2026-06-17
- **Tasks:** 2 (Task 1 TDD: RED + GREEN; Task 2: provider add + coherent stack deletion)
- **Files:** 4 created, 7 modified, 9 deleted

## Accomplishments
- `GetWithinMonthCumulativeUseCase` + `WithinMonthCumulativeTrend` model: per-day running-cumulative per-ledger (total/daily/joy) expense for the current month, plus a previous-month reference line on the spend side (total/daily). Joy carries ONLY the current month — the model has no `previousMonthJoy` field, so a joy cross-period line is unrepresentable (D-E1, ADR-012).
- Reuse-first: a single 2-month-window `findByBookIds` call + pure Dart transform — no new DAO, no migration, schema stays v21.
- `withinMonthCumulativeTrendProvider`: auto-dispose `@riverpod` family, month-anchored key (D-12), manualOnly-aware entrySource derivation; `getWithinMonthCumulativeUseCase` wired from `transactionRepository`.
- Deleted the entire 6-month trend stack with zero dangling references: `get_expense_trend_use_case.dart`, `expense_trend.dart` (+gen), `expenseTrendProvider`, `getExpenseTrendUseCase`, `total_six_month_card.dart`, `monthly_spend_trend_bar_chart.dart`, plus their tests; updated the registry + 4 consuming tests.
- Full suite green (2914/2914), `flutter analyze` 0 issues project-wide.

## Task Commits

1. **Task 1 (TDD RED): failing test for within-month cumulative use case** - `871c1c15` (test)
2. **Task 1 (TDD GREEN): use case + freezed model** - `ec03a510` (feat)
3. **Task 2: within-month trend provider + delete 6-month trend stack** - `dd7a5baf` (feat)
4. **Task 2 (doc-accuracy fix): analytics_data_card docstring** - `c1dec020` (docs)

## Files Created/Modified

**Created:**
- `lib/application/analytics/get_within_month_cumulative_use_case.dart` - 2-month-window expense fetch + per-day per-ledger running cumulative; expense-only + optional entrySource filter; book set never widened; no tx logging
- `lib/features/analytics/domain/models/within_month_cumulative_trend.dart` - `CumulativePoint` (day, cumulativeAmount) + `WithinMonthCumulativeTrend` (current total/daily/joy + previous total/daily; no previousMonthJoy)
- `test/unit/application/analytics/get_within_month_cumulative_use_case_test.dart` - 7 tests: monotonic cumulative, total==daily+joy carry-forward, joy current-month-only, expense-only, empty-safe, book-set-faithful, entrySource threading

**Modified:**
- `lib/features/analytics/presentation/providers/state_analytics.dart` - added `withinMonthCumulativeTrend` family; removed `expenseTrend` provider + import
- `lib/features/analytics/presentation/providers/repository_providers.dart` - added `getWithinMonthCumulativeUseCase`; removed `getExpenseTrendUseCase`
- `lib/features/analytics/presentation/analytics_card_registry.dart` - removed TotalSixMonth spec + import (registry 10 → 9 specs)
- `test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart` - swapped expenseTrend → withinMonthCumulative construction test (overrides transactionRepositoryProvider)
- `test/widget/features/analytics/presentation/analytics_card_registry_test.dart` - dropped ExpenseTrendProvider whitelist entry + TotalSixMonth key assertion; spec count 10→9, visibility 8→7
- `test/widget/.../screens/analytics_screen_test.dart`, `analytics_no_delta_ui_test.dart`, `analytics_refresh_group_mode_test.dart` - removed trend overrides/fixtures; screen test section-header count 3→2, trend-render assertions retargeted to the donut

**Deleted:**
- `lib/application/analytics/get_expense_trend_use_case.dart`, `lib/features/analytics/domain/models/expense_trend.dart` (+`.freezed.dart`,`.g.dart`)
- `lib/features/analytics/presentation/widgets/cards/total_six_month_card.dart`, `lib/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart`
- `test/unit/application/analytics/get_expense_trend_use_case_test.dart`, `test/unit/features/analytics/domain/models/expense_trend_test.dart`, `test/widget/.../widgets/monthly_spend_trend_bar_chart_test.dart`

## Decisions Made
- Built the trend as a use-case-internal 2-month-window transform over `findByBookIds` (vs a new repo thin method) — both reuse-first; chose the use-case-internal form per the use-case-internal analog (drill-down) and to keep zero new repo surface.
- Applied `entrySourceFilter` in Dart (not SQL) because `findByBookIds` has no entry-source param; mirrors the expense-only Dart gate from the drill use case.
- Did NOT add the missing `(book_id, timestamp)` index (RESEARCH Pitfall 1 / Open Q1) — adding it would break the "no migration / v21 unchanged" lock; deferred (accept full scan at current row volumes).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] 6-month trend presentation consumers force a wider deletion than the plan scoped**
- **Found during:** Task 2 (delete the 6-month stack)
- **Issue:** The plan's Task 2 deletes the trend DATA layer (`expenseTrendProvider`, `GetExpenseTrendUseCase`, `ExpenseTrendData`, `MonthlyTrend`) but its prose NOTE reserves the PRESENTATION consumers (`total_six_month_card.dart`, `monthly_spend_trend_bar_chart.dart`, the registry spec, the registry test's `ExpenseTrendProvider` whitelist, and 3 screen tests) for wave-3 plan 46-07, asserting "Registry still compiles because 46-07 owns the registry-side trend swap." That assertion is false: those files hard-import the deleted symbols (`TotalSixMonthCard` watches `expenseTrendProvider`; `MonthlySpendTrendBarChart` imports `expense_trend.dart`). A data-only deletion does not compile. Meanwhile the plan's own `must_haves.truths` requires the stack "fully removed with zero dangling references."
- **Fix:** Applied the plan's own Pitfall 4 principle ("delete the stack and its consumers together so the build stays coherent"). Deleted `total_six_month_card.dart` + `monthly_spend_trend_bar_chart.dart` + their test; removed the `TotalSixMonthCard` registry spec (and with it the `analyticsGroupHeaderTime` section header); updated the registry test (count 10→9, visibility 8→7, dropped the whitelist entry + the TotalSixMonth key assertion) and the 3 screen tests (removed trend overrides/fixtures; screen test section-header count 3→2). Left the registry RE-ORDER and the NEW round-5 B within-month card to 46-07, and left the (now-unused) `analyticsCardTitleTotalSixMonth` / `analyticsGroupHeaderTime` ARB keys for 46-07 to remove with the registry re-order.
- **Files modified:** analytics_card_registry.dart, analytics_card_registry_test.dart, analytics_screen_test.dart, analytics_no_delta_ui_test.dart, analytics_refresh_group_mode_test.dart (+ the deletions above)
- **Verification:** `flutter analyze` 0 issues project-wide; full suite 2914/2914 green; grep confirms zero live `expenseTrend`/`MonthlyTrend`/`TotalSixMonth` references in source (only doc comments remain)
- **Committed in:** `dd7a5baf`

**2. [Rule 1 - Doc accuracy] Stale docstring in kept file referenced deleted card**
- **Found during:** post-Task-2 verification
- **Issue:** `analytics_data_card.dart` docstring listed `TotalSixMonthCard` as a consumer after that card was deleted.
- **Fix:** Updated the docstring to drop `TotalSixMonthCard` and note its removal (46-01, D-E2).
- **Files modified:** lib/features/analytics/presentation/widgets/cards/analytics_data_card.dart
- **Verification:** analyze clean; comment-only change
- **Committed in:** `c1dec020`

---

**Total deviations:** 2 (1 blocking-issue scope-widening, 1 doc-accuracy)
**Impact on plan:** Deviation 1 expands the deletion boundary between 46-01 and 46-07 — it pulls the trend-card REMOVAL (and its Time section header) forward into 46-01 because compilation + the zero-dangling-reference must_have demand it. The registry RE-ORDER and the NEW within-month trend card remain for 46-07 as planned. A blocker was recorded in STATE.md documenting the sequencing conflict for 46-07's author. No functional scope creep beyond what the must_have requires.

## Issues Encountered
- Test 2 initially failed on a wrong test-side expectation (`total == daily + joy` and the joy "no reset" assertion used point-exact lookups against sparse series). Fixed the test helper to use carry-forward cumulative (`_cumOnOrBefore`); the implementation was correct (verified via a throwaway debug test). Not a production bug.

## TDD Gate Compliance
RED (`871c1c15` test) precedes GREEN (`ec03a510` feat); no REFACTOR commit needed. Gate sequence satisfied.

## Threat Flags
None — no new network/auth/file/schema surface. T-46-01-01 (book-set never widened) is covered by Test 6; T-46-01-02 (no tx logging) holds (aggregate ints only).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The Wave-2 trend card (46-04) can now `ref.watch(withinMonthCumulativeTrendProvider(...))` for its LineChart series (本月 total/daily/joy + 上月 total/daily reference).
- **For 46-07:** the registry RE-ORDER + the NEW round-5 B within-month trend card spec + section-header removal (D-F2) remain. Also remove the now-orphaned ARB keys `analyticsCardTitleTotalSixMonth` / `analyticsCardCaptionTotalSixMonth` / `analyticsGroupHeaderTime` (left in place here to avoid touching l10n outside this plan's scope). The registry test currently asserts 9 specs / 7-solo / 9-group; 46-07 will re-baseline these when it adds the round-5 B cards.

## Self-Check: PASSED

- Created files verified on disk: get_within_month_cumulative_use_case.dart, within_month_cumulative_trend.dart, 46-01-SUMMARY.md
- Commits verified in git log: 871c1c15, ec03a510, dd7a5baf, c1dec020
- Full suite 2914/2914 green; flutter analyze 0 issues project-wide

---
*Phase: 46-cards*
*Completed: 2026-06-17*

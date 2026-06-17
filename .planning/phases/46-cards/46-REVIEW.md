---
phase: 46-cards
reviewed: 2026-06-17T00:00:00Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - lib/application/analytics/get_joy_category_amounts_use_case.dart
  - lib/application/analytics/get_per_day_joy_counts_use_case.dart
  - lib/application/analytics/get_within_month_cumulative_use_case.dart
  - lib/features/analytics/domain/models/joy_category_amount.dart
  - lib/features/analytics/domain/models/per_day_joy_count.dart
  - lib/features/analytics/domain/models/within_month_cumulative_trend.dart
  - lib/features/analytics/presentation/analytics_card_registry.dart
  - lib/features/analytics/presentation/providers/repository_providers.dart
  - lib/features/analytics/presentation/providers/state_analytics.dart
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/features/analytics/presentation/screens/category_drill_down_screen.dart
  - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
  - lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart
  - lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart
  - lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
  - lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart
  - lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart
  - lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart
  - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
  - lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart
  - lib/features/list/presentation/widgets/list_transaction_tile.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - test/widget/features/analytics/presentation/analytics_card_registry_test.dart
  - test/widget/features/analytics/presentation/screens/analytics_screen_test.dart
  - test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart
findings:
  critical: 0
  warning: 4
  info: 5
  total: 9
status: issues_found
---

# Phase 46: Code Review Report

**Reviewed:** 2026-06-17
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

Reviewed the round-5 B analytics flat 5-card lineup: three new pure-Dart use cases over `findByBookIds`, three domain models, the card registry/shell, five card widgets, three chart widgets, the read-only drill screen, and the read-only tile path.

The phase-defining invariants hold and verify cleanly:

- **GATE-04 PASS** — neither `joy_spend_stacked_bar.dart` nor `joy_calendar_heatmap.dart` imports `fl_chart` (custom `Row`/`Flexible` and custom `GridView` respectively; the only "fl_chart" tokens are docstring prose).
- **D-E1 PASS** — the joy cross-period guard is structural, not a runtime flag: `WithinMonthCumulativeTrend` has no `previousMonthJoy` field, the joy tab passes `previousMonth = null`, and `_hasReference` can never be true on the joy side. The 上月 legend row is gated behind `previous != null && previous.isNotEmpty`.
- **Expense-filter (Phase 44 CR-01) PASS** — all three new joy/trend use cases AND the `joyDayTransactions` provider filter `tx.type == TransactionType.expense` after `findByBookIds(ledgerType: joy)`, so income/transfer joy rows never leak into amounts/counts.
- **ARB trilingual parity PASS** — all 21 Phase-46 keys exist in en/ja/zh.
- **D-11 single-source rollup PASS** — joy amounts route through the locked `l1RollupFromTransactions`; the donut and joy-spend windows are both already whole-day normalized by `TimeWindow.range`, so the "strict subset" invariant is not broken by the asymmetric `DateBoundaries.dayRange` normalization.
- **Anti-toxicity / immutability / layer separation** — no ranking/streak/goal-pressure copy in the new cards; domain models are immutable value classes; use cases live in `application/`, models in `domain/`, no `home/*` import in the registry.

No blockers. The findings below are quality/correctness-at-the-edges issues: hardcoded `JPY` formatting that ignores the book currency the context already computes, a donut center-total vs. legend-total inconsistency under >10 L1 categories, an O(n·k) re-rollup loop, and several minor robustness/dead-code items.

## Warnings

### WR-01: Amounts hardcode `'JPY'` while the real book currency is computed but never threaded into the cards

**File:** `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart:183,206`; `lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart:135,160`; `lib/features/analytics/presentation/screens/category_drill_down_screen.dart:161,257,282`; `lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart:257`

**Issue:** `buildAnalyticsCardContext` resolves `currencyCode = bookByIdProvider.value?.currency ?? 'JPY'` (registry:114–119) — the book's *actual* currency. But the donut center count-up, the donut legend rows, the joy-spend segments/header, the drill subtotal/avg-per-day, and the calendar day tiles all format with the literal string `'JPY'` instead of that resolved code. `CategoryDonutCard` and `JoySpendCard` don't even accept a `currencyCode` parameter, so the resolved value is dead plumbing for them. For any non-JPY book these cards render the wrong symbol and wrong decimal precision (e.g. USD `$1,234.50` would show as `¥1,235`). This contradicts the project's own NumberFormatter convention (`Always pass locale from currentLocaleProvider`, and currency per book). It is partly a pre-existing analytics convention, but Phase 46 rebuilt these cards and re-introduced the literal rather than wiring the context value.

**Fix:** Thread `ctx.currencyCode` into `CategoryDonutCard`/`JoySpendCard`/`JoyCalendarCard` (they are constructed in the registry where `ctx` is in scope) and replace the `'JPY'` literals with the passed currency. For the drill screen, read the book currency via `bookByIdProvider` (the screen already has `bookId`) rather than hardcoding. If JPY-only is a deliberate v1 constraint, drop the `currencyCode` field from `AnalyticsCardContext` so the dead plumbing doesn't imply unsupported multi-currency.

### WR-02: Donut center total (`totalExpenses`) and legend percentages (`donutTotal`) diverge when there are >10 L1 categories

**File:** `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart:139,179,209`

**Issue:** The center count-up animates to `total` = `monthly.totalExpenses` (the authoritative all-category expense total), but `rollupCategoryBreakdownsToL1(..., topN: 10)` truncates to the top 10 L1 buckets and the legend `percent` divides by `donutTotal` = sum of those ≤10 rows. When more than 10 distinct L1 categories have spend, `donutTotal < total`: the center shows ¥X, the visible slices sum to less than ¥X, and the legend percentages sum to 100% of the *truncated* set (overstating each row's share of the real total). The donut wedges (drawn from `entry.value.amount`) also won't visually fill to the center total. The user sees a total that doesn't reconcile with the slices below it.

**Fix:** Either base the center total on the rendered set (`final donutTotal = rows.fold(...); ... end: donutTotal`), or add an explicit "其他/Other" rollup bucket capturing `total - donutTotal` so slices + legend reconcile to the displayed center number. Computing the percentage off the true `total` (not `donutTotal`) would also make the percentages honest about the long tail.

### WR-03: `GetJoyCategoryAmountsUseCase` re-scans the full transaction list once per distinct L1 (O(n·k))

**File:** `lib/application/analytics/get_joy_category_amounts_use_case.dart:79-93`

**Issue:** The use case first builds the set of distinct L1 ids, then calls `l1RollupFromTransactions(expenseTxns, categoryMap, l1Id)` *inside a loop over every L1 id*. Each call re-iterates the entire `expenseTxns` list (see `l1RollupFromTransactions` — it filters all transactions by `l1AncestorOf == l1CategoryId`). For k distinct L1 categories over n transactions this is O(n·k) and recomputes `l1AncestorOf(tx.categoryId, ...)` k times per transaction. The docstring claims "There is NO second rollup loop here," but this is effectively k rollup passes. (Performance is out of v1 scope, but this is flagged as a maintainability/contract-accuracy defect: the comment misrepresents the algorithm, and a future reader will trust "single pass" that isn't there.)

**Fix:** Single-pass accumulate, mirroring `rollupCategoryBreakdownsToL1`:
```dart
final acc = <String, int>{};
for (final tx in expenseTxns) {
  final l1 = l1AncestorOf(tx.categoryId, categoryMap) ?? tx.categoryId;
  acc[l1] = (acc[l1] ?? 0) + tx.amount;
}
final buckets = [
  for (final e in acc.entries)
    if (e.value > 0) JoyCategoryAmount(categoryId: e.key, amount: e.value),
]..sort((a, b) => b.amount.compareTo(a.amount));
```
This still routes through the same `l1AncestorOf` rule (D-11 satisfied) and removes the per-L1 rescan. Update the docstring to match.

### WR-04: `joyDayTransactionsProvider` is absent from `joyCalendarRefreshTargets`, so pull-to-refresh leaves an expanded day's list stale

**File:** `lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart:99-107`; `lib/features/analytics/presentation/providers/state_analytics.dart:257-288`

**Issue:** `joyCalendarRefreshTargets` returns only `perDayJoyCountsProvider`. When a user has expanded a calendar day (the inline `_InlineDayPanel` watching `joyDayTransactionsProvider`) and then pull-to-refreshes, the per-day *count* heatmap is invalidated and recomputed, but the *expanded day's transaction list* is not — it keeps showing pre-refresh rows (e.g. a row the user just deleted on another tab still appears). The count cell could update while the list below it disagrees. This is a state-consistency gap, not just a perf nicety.

**Fix:** This is genuinely awkward because `joyDayTransactionsProvider` is keyed on the *currently selected* day, which lives in `_JoyCalendarBodyState` local state, not in `AnalyticsCardContext`. Options: (a) have `_InlineDayPanel` invalidate its own `joyDayTransactionsProvider` on a refresh signal, or (b) since auto-dispose providers re-fetch when re-subscribed, accept the gap but document it explicitly. At minimum, add a code comment recording that the expanded-day list is intentionally excluded from the refresh union and why (it is currently silent).

## Info

### IN-01: `JoySpendStackedBar` segment `Flexible(flex: amount)` truncates to int and breaks on zero/huge amounts

**File:** `lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart:86-100`

**Issue:** `flex` is the raw `amount` (minor units). `Flexible.flex` must be a non-negative int; the upstream use case already drops `amount <= 0` buckets so zero is avoided in practice, but the coupling is implicit. More notably, for very large totals the flex values are large ints — fine for the framework, but a single dominant segment can crush sub-1px siblings into invisible/untappable slivers (the legend remains tappable, so not a blocker). Consider normalizing flex to a bounded range (e.g. per-mille) to keep tiny segments hit-testable.

**Fix:** Map `amount` to a normalized weight (`(amount / total * 1000).round().clamp(1, ...)`) so every non-zero segment keeps a minimum tappable width.

### IN-02: Duplicated `_resolveL1IconForCategory` + 17-entry icon map across three files

**File:** `lib/features/analytics/presentation/screens/category_drill_down_screen.dart:209-235`; `lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart:299-324` (and per the docstrings, `list_screen.dart`)

**Issue:** The static L1-icon map and `_resolveL1IconForCategory` are copy-pasted verbatim in at least three places (the docstrings explicitly say "Mirrors `list_screen.dart`'s static icon map"). Any new L1 category requires editing every copy; drift is likely. Violates the project's DRY/coding-style guidance.

**Fix:** Extract a single `shared/utils` (or `accounting` domain) helper `l1IconForCategoryId(String)` and have all call sites use it.

### IN-03: `_noop` no-op callbacks wired into required `onTap`/`onDeleted` in read-only tiles

**File:** `lib/features/analytics/presentation/screens/category_drill_down_screen.dart:206`; `lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart:296`

**Issue:** Read-only tiles satisfy `ListTransactionTile`'s required `onTap`/`onDeleted` with `static void _noop() {}`. This works because `readOnly: true` suppresses the gesture wiring, but the required-callback contract is being satisfied with dead callbacks — a code smell that relies on the tile internally honoring `readOnly`. If a future edit forgets to check `readOnly` before invoking `onTap`, a silent no-op tap results.

**Fix:** Make `onTap`/`onDeleted` nullable (`VoidCallback?`) in `ListTransactionTile` so read-only callers pass `null` and the contract is explicit, or add an assert that `readOnly` callers don't pass live callbacks.

### IN-04: Line chart degenerate axis when the only spend day is day 1

**File:** `lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart:64-65,106-117`

**Issue:** `minX = 1` and `maxX = _maxDay()`. If the month's only spend (and no reference series) falls on day 1, `maxDay == 1`, giving `minX == maxX == 1` — a zero-width x-domain. fl_chart tolerates this but renders a single point/flat segment with no horizontal extent; the "line" is invisible. Edge case, cosmetic.

**Fix:** Clamp the domain, e.g. `maxX: maxDay <= minX ? minX + 1 : maxDay.toDouble()`, or fall back to days-in-month for the x-axis extent.

### IN-05: `_DonutHero._colorFor` / `_segmentColor` recomputed per row instead of precomputed once

**File:** `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart:157,199,225-229`; `lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart:141,173-179`

**Issue:** Each legend row and each pie section calls `_colorFor(index, rows.length, palette)` independently, recomputing the same `Color.lerp` twice per index (once for the slice, once for the legend row). Minor; readability/consistency nit — the slice color and legend swatch are guaranteed equal only because the same pure function is called with the same args. Precomputing a `List<Color>` once would make the slice↔legend color pairing self-evidently consistent.

**Fix:** Compute `final colors = [for (var i=0;i<rows.length;i++) _colorFor(i, rows.length, palette)];` once and index into it for both the sections and the legend rows.

---

_Reviewed: 2026-06-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

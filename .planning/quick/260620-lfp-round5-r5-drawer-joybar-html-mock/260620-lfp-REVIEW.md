---
phase: quick-260620-lfp-round5-r5-drawer-joybar-html-mock
reviewed: 2026-06-20T00:00:00Z
depth: quick
files_reviewed: 13
files_reviewed_list:
  - lib/core/theme/joy_warm_palette.dart
  - lib/features/analytics/presentation/widgets/analytics_section_header.dart
  - lib/features/analytics/presentation/widgets/joy_spend_drawer.dart
  - lib/features/analytics/presentation/widgets/joy_spend_drawer_body.dart
  - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
  - lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart
  - lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
  - lib/features/analytics/presentation/analytics_card_registry.dart
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart
  - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
  - lib/features/analytics/presentation/widgets/cards/analytics_data_card.dart
  - lib/l10n/app_ja.arb,app_zh.arb,app_en.arb
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase quick-260620-lfp: Code Review Report

**Reviewed:** 2026-06-20
**Depth:** quick
**Files Reviewed:** 13
**Status:** issues_found (no blockers; 2 minor warnings + 2 info)

## Summary

This is a clean presentation-only refactor. I verified every defect class the brief
flagged as high-risk, and all of them are correctly handled:

- **Refresh-union fold (Pitfall-3): CORRECT.** `categoryDonutRefreshTargets` now returns
  `[monthlyReportProvider, joyCategoryAmountsProvider]` keyed on the same `ctx`. The shell
  `_refresh` derives the union via `expand(refreshTargets).toSet()`, so pull-to-refresh
  still invalidates the nested drawer's `joyCategoryAmountsProvider`. The drawer
  (`JoySpendDrawer`) watches that provider with the identical `bookId/startDate/endDate/
  joyMetricVariant` tuple the card receives, so the invalidation key matches the watch key.
- **Weighted-median (Pitfall-7): CORRECT.** `_weightedMedian` returns the first score whose
  cumulative count reaches `total/2`; that bucket necessarily has `count > 0`, so the
  `bucket.score == medianScore` outline can never land on a phantom (count==0) bar. Empty
  data → `null` → no pill, no outline (`bucket.score == null` is a safe int/int? compare).
  The `bucket.score == 5` hardcode is a SEPARATE concern (the STATSUI-02 hard-locked
  「中位数·含未評分」annotation), intentionally decoupled from the data-derived pill.
- **Expense-only + amount-descending: CORRECT.** `get_joy_category_amounts_use_case.dart`
  filters `TransactionType.expense` (avoids the analytics-transaction-type-reuse-trap) and
  sorts `b.amount.compareTo(a.amount)`. Donut percentages divide by the TRUE total
  (incl. the neutral "Other" residual), reconciling to the center.
- **D3 trend FROZEN: CONFIRMED via git.** `within_month_cumulative_line_chart.dart` has zero
  diff vs HEAD. The only edit to `within_month_trend_card.dart` (commit ca78e669) is the
  added `showHeader: false` line + a comment — `_TrendBody`/`_PillTabs`/chart untouched.
- **Palette discipline: CLEAN.** The only raw hex is in `lib/core/theme/joy_warm_palette.dart`
  (sanctioned carve-out, outside the `color_literal_scan` dirs). Drawer/legend/median chrome
  all resolve via `context.palette` + `Color.lerp`.
- **i18n parity: CLEAN.** 18 new `analytics*` keys present and identical across ja/zh/en;
  no hardcoded CJK in the new widgets (titles/tags passed pre-localized).
- **Provider hygiene: CLEAN.** No duplicate refresh-target defs, no `UnimplementedError`,
  registry imports zero `home/*` providers, `JoySpendCard` retained as a thin wrapper with
  its single-target `joySpendRefreshTargets` intact. `flutter analyze` on the changed tree:
  `No issues found`.

Two minor warnings and two info items below — none block shipping.

## Warnings

### WR-01: Joy drawer renders an awkward "¥0 / 0 类" header in the empty-joy state

**File:** `lib/features/analytics/presentation/widgets/joy_spend_drawer.dart:56-128`
**Issue:** `JoySpendDrawer.build` computes `total = amounts.fold(...)` and `amounts.length`
unconditionally in the `data:` branch, then renders the connector chip + drawer title
`analyticsJoyDrawerTitle(¥0)` + count badge `analyticsJoyDrawerCount(0)` even when
`amounts` is empty. The inner `JoySpendDrawerBody` does correctly switch to the neutral
empty copy, but the *outer* drawer still shows "悦己 ¥0 花在哪几类开心事 · 0 类" — a
month with no joy spend gets a slightly self-contradictory header (title promises a
breakdown, body says there is none). The standalone `JoySpendCard` wrapper avoids this
because its `AnalyticsDataCard` title is static, not amount-interpolated.
**Fix:** In the `data:` branch, short-circuit to the body-only empty path when
`amounts.isEmpty`, skipping the connector/title/count chrome:
```dart
data: (amounts) {
  if (amounts.isEmpty) {
    return const Padding(
      padding: EdgeInsets.only(top: 12),
      child: JoySpendDrawerBody(amounts: []),
    );
  }
  final total = amounts.fold<int>(0, (s, a) => s + a.amount);
  // ...existing connector + drawer...
}
```

### WR-02: Donut error state hides the joy drawer even when joy data is healthy

**File:** `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart:65-97`
**Issue:** The nested `JoySpendDrawer` is rendered *inside* `monthlyAsync.when(data: ...)`.
If `monthlyReportProvider` errors (but `joyCategoryAmountsProvider` succeeds), the whole
card collapses to `AnalyticsCardErrorState`, so the joy breakdown the user could still see
is suppressed. Pre-refactor, `JoySpendCard` was an independent top-level sibling card with
its own `.when`, so a donut failure never took the joybar down with it. This is a behavioral
regression in failure isolation introduced by the nesting (functionally fine on the happy
path, which is why goldens pass).
**Fix:** Render the donut hero and the joy drawer as siblings that each own their `.when`,
e.g. keep `JoySpendDrawer` (which already has its own `amountsAsync.when`) OUTSIDE the
`monthlyAsync.when` data branch — show the donut error state only for the donut region and
let the drawer resolve independently. If the coupling is an accepted product call (single
card = single error surface), document it; otherwise decouple.

## Info

### IN-01: `_ctx()` is duplicated across three card files with identical bodies

**File:** `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart:102-110`
(also `joy_spend_card.dart:69-77`, `within_month_trend_card.dart:88-96`)
**Issue:** Each card rebuilds a minimal `AnalyticsCardContext` with the same
`trendAnchor: DateTime(endDate.year, endDate.month)` / `isGroupMode: false` /
`locale: const Locale('ja')` boilerplate purely to feed its `*RefreshTargets` for the
error-retry path. Three copies will drift if the context shape changes.
**Fix:** Extract a shared `AnalyticsCardContext.forCard({bookId, startDate, endDate,
joyMetricVariant})` factory (or a free helper) and call it from all three cards. Low
priority — purely a maintainability nit, not a behavior change.

### IN-02: Histogram annotation comment claims median, code hardcodes score 5

**File:** `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart:99-118`
**Issue:** The inline comment on the `borderSide` says "outline the data-derived median
bucket," and two lines later the `label` comment says "Only the median bucket (score 5)
carries the … annotation" — but the `label` is gated on `bucket.score == 5` (a fixed
constant), while the outline is gated on `bucket.score == medianScore` (data-derived).
These are deliberately different features (the score-5 annotation is the STATSUI-02
hard-locked default-cluster note; the outline is the dynamic median), but the comment
wording conflates them and will mislead the next reader into thinking the「中位数」label
follows the median.
**Fix:** Reword the `label` comment to "the FIXED score-5 default-cluster annotation
(STATSUI-02, NOT the dynamic median — see medianScore outline above)". No code change.

---

_Reviewed: 2026-06-20_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: quick_

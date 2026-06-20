---
quick_task: 260620-kll
title: 支出趋势图表修正 round 2（整月X轴/去起点标注/数据锚定端点标注上下对置/进位至今天）
status: complete
subsystem: analytics-presentation
tags: [fl_chart, analytics, trend-chart, goldens, carry-forward, adr-019, adr-012]
requirements: [QUICK-260620-kll]
key-files:
  modified:
    - lib/application/analytics/get_within_month_cumulative_use_case.dart
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart
    - test/unit/application/analytics/get_within_month_cumulative_use_case_test.dart
    - test/widget/features/analytics/presentation/widgets/within_month_cumulative_line_chart_test.dart
    - test/golden/within_month_trend_card_golden_test.dart
    - test/golden/analytics_screen_scroll_smoke_golden_test.dart
    - test/golden/goldens/within_month_trend_card_light_ja.png
    - test/golden/goldens/within_month_trend_card_light_zh.png
    - test/golden/goldens/within_month_trend_card_light_en.png
    - test/golden/goldens/within_month_trend_card_dark_ja.png
    - test/golden/goldens/within_month_trend_card_dark_zh.png
    - test/golden/goldens/within_month_trend_card_dark_en.png
    - test/golden/goldens/analytics_screen_scroll_smoke_light_ja.png
commits:
  - fc5e6caf: "feat: carry-forward + now-injection in within-month cumulative use case"
  - a38938ee: "feat: whole-month X extent + data-anchored above/below endpoint labels in trend chart"
  - 3ff74f9f: "test: re-baseline trend-card + analytics-smoke goldens for whole-month axis + endpoint labels"
metrics:
  tasks: 3
  files: 14
  tests_total: 3071
  analyze_issues: 0
  completed: 2026-06-20
---

# Quick Task 260620-kll: 支出趋势图表修正 round 2 Summary

Round-2 correction of the statistics-page 「支出趋势」 within-month cumulative
line chart, implementing the 5 LOCKED corrections from CONTEXT. Round 1 (jx2)
stopped the X-axis and both lines at the last spend day and labelled both
start AND end with fixed-corner offsets. This round moves carry-forward + the
"today" injection into the USE CASE (so the chart is clockless / golden-stable),
makes the chart span the WHOLE month, removes the start label, and data-anchors
a SINGLE endpoint label per line placed above/below by 本月-vs-上月 comparison
with the 上月 label at the opposite position.

## What changed

### Task 1 — use-case carry-forward + now injection (commit fc5e6caf)

`GetWithinMonthCumulativeUseCase.execute(...)` gains a required `DateTime now`
param — the use case is the ONLY place that knows "today" (D-5), so the chart
stays clockless and goldens deterministic. `_cumulative(...)` now carry-forwards
each month's sparse series across the whole displayed span:

- PREPEND `(day: 1, cumulativeAmount: 0)` when the first spend day > 1 (left
  edge). If spend exists ON day 1, no duplicate is added (the day-1 cumulative
  is the left edge — Test 12).
- APPEND `(day: comparisonDay, cumulativeAmount: finalRunning)` when the last
  spend predates the comparison day (right-edge carry-forward).
- Comparison day: current month → `now.day` when `now` falls inside the
  displayed month (live), else month-end (a past, complete month, clamped to
  the month length); previous month → ALWAYS its last day.
- A month with NO spend returns `const []` (no synthesized flat line) so the
  empty placeholder still renders.

`state_analytics.dart withinMonthCumulativeTrend` passes `now: DateTime.now()`
(the only production caller injecting the real clock). The expense-only gate,
entrySourceFilter, and the single 2-month `findByBookIds` fetch are unchanged
(T-46-01-01). No model change → no build_runner. Use-case tests extended from
7 → 13 (all pass an explicit `now`; +6 carry-forward extent assertions).

### Task 2 — chart whole-month extent + data-anchored endpoint labels (commit a38938ee)

`WithinMonthCumulativeLineChart`:

- **Whole-month X (D-1):** `maxX = daysInMonth(anchor)` (derived from anchor),
  `minX = 1`; the bottom day-marker guard is `> daysInMonth` so 7/14/21/28日
  span the full month.
- **No start label (D-2):** removed the first `_EndpointAnnotation` + the
  first-spot dot; only the last spot keeps an endpoint dot.
- **Data-anchored labels (D-3/D-4):** the `LineChart` is wrapped in a
  `LayoutBuilder`; spot→pixel via plot-area math (`leftReserved 44`,
  `bottomReserved 22`, `topPad 12`). The 本月 label anchors at the line's last
  point; the 上月 label (spend side only) anchors at the previous-month point
  with the latest `day <= comparisonDay` (LOOKED UP — 上月 now spans the whole
  month so `.last` is month-end, not the comparison day). `labelAbove =
  currentEnd >= prevAtComparison` (本月 above when ≥); the 上月 label is placed
  at the negation (opposite). Labels are clamped to the card bounds.
- **Clockless:** comparisonDay = `currentMonth.last.day` (the use case already
  made that = today). Zero wall-clock read; `context.palette.*` only (no hex).
- Static `labelAbove(...)` helper + a visible-for-testing
  `WithinMonthEndpointAnnotation` (`isCurrent`/`above`) so the comparison /
  opposite logic is unit-asserted without pixel math. Joy single-line
  single-label invariant intact (D-E1). Chart tests 9 → 13 (+4).

### Task 3 — golden fixtures + full gate (commit 3ff74f9f)

Both golden tests override the provider with FIXED series, so the fixtures were
rewritten to encode the round-2 use-case OUTPUT shape (May-2026 anchor = a
COMPLETE past month): current series day 1 (cumulative 0) → day 31 (month-end);
previous (April, 30 days) series day 1 (0) → day 30; 本月 (98000) > 上月-at-day-30
(90000) at the comparison day so the ABOVE branch renders both labels without
collision. Re-baselined the 8 affected macOS masters via scoped
`--update-goldens`; visually sanity-checked the ja light master (whole-month X
axis, green 本月 day1→day31, gray dashed 上月 full April, no start label, two
endpoint labels 本月-above / 上月-below without overlap). The empty master was
not regenerated (empty fixture/placeholder path unchanged).

## Verification

- `flutter analyze` — **0 issues** (full project).
- `flutter test` — **3071/3071 passed** (was 3061; +6 use-case + +4 chart tests),
  including the hardcoded-CJK-UI architecture scan and the anti-toxicity sweeps.
- `grep 'DateTime.now()' within_month_cumulative_line_chart.dart` — **0** (clockless).
- `grep -E '#[0-9A-Fa-f]{6}' within_month_cumulative_line_chart.dart` — **0** (palette-only).
- No new ARB keys; `within_month_cumulative_trend.dart` model unchanged (no
  previousMonthJoy).
- `git status` shows exactly the 8 PNG masters + the 2 golden test files +
  the lib/test source files changed.

## Deviations from Plan

**None affecting scope.** Two planning-discretion notes:
1. The clockless-guard doc-comment in the chart originally contained the literal
   token `DateTime.now()` (in prose, "reads NO DateTime.now()"), which would
   trip the plan's `grep 'DateTime.now()'` verification. Reworded to "reads NO
   wall clock" so the grep returns zero — the chart genuinely reads no clock.
2. Endpoint dots: kept the LAST-spot dot only (start dot removed per D-2), as
   permitted by CONTEXT's Claude-discretion note.

## Known Stubs

None.

## Self-Check: PASSED

- use case + provider + chart: present, analyze-clean, clockless, palette-only.
- 8 golden masters: modified + committed (3ff74f9f).
- Commits fc5e6caf + a38938ee + 3ff74f9f: present in git log.

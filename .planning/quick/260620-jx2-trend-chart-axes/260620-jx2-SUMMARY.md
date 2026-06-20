---
quick_task: 260620-jx2
title: 支出趋势图表增加坐标轴/网格/上月对比线/起止点标注
status: complete
subsystem: analytics-presentation
tags: [fl_chart, analytics, trend-chart, goldens, i18n, adr-019]
requirements: [QUICK-260620-jx2]
key-files:
  modified:
    - lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart
    - lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
    - lib/infrastructure/i18n/formatters/date_formatter.dart
    - test/widget/features/analytics/presentation/widgets/within_month_cumulative_line_chart_test.dart
    - test/golden/goldens/within_month_trend_card_light_ja.png
    - test/golden/goldens/within_month_trend_card_light_zh.png
    - test/golden/goldens/within_month_trend_card_light_en.png
    - test/golden/goldens/within_month_trend_card_dark_ja.png
    - test/golden/goldens/within_month_trend_card_dark_zh.png
    - test/golden/goldens/within_month_trend_card_dark_en.png
    - test/golden/goldens/within_month_trend_card_empty_light_ja.png
    - test/golden/goldens/analytics_screen_scroll_smoke_light_ja.png
commits:
  - ec4d43e2: "feat: add axes, grid, gray 上月 line, endpoint annotations to within-month trend chart"
  - c005e531: "test: re-baseline trend-card + analytics-smoke goldens for chart axes/grid/annotations"
metrics:
  tasks: 2
  files: 12
  tests_total: 3061
  analyze_issues: 0
  completed: 2026-06-20
---

# Quick Task 260620-jx2: 支出趋势图表坐标轴/网格/上月对比/起止标注 Summary

Reversed the deliberate "bare line" look of the within-month 支出趋势 cumulative
line chart and adopted the richer reference presentation — left amount axis +
horizontal gridlines (from 0), bottom localized day markers, a clearly-visible
muted-gray dashed 上月 reference line (spend side only), and 本月 start/current
endpoint annotations — across all three tabs (总支出/日常/悦己), with the
ADR-012/D-E1 joy single-line guarantee fully intact (structural, not runtime).

## What changed

### Task 1 — chart widget (commit ec4d43e2)

`WithinMonthCumulativeLineChart` was turned from a grid/axes/annotation-off bare
line into the full reference presentation:

- **Y-axis + horizontal gridlines (Feature 1):** `FlGridData(show: true,
  drawVerticalLine: false, horizontalInterval: <nice step>)` with a "nice" round
  step (1/2/5 × 10ⁿ) computed from `_maxY()` to yield ~4 lines from 0. Axis
  ceiling rounded up to a whole number of steps so the top tick is never clipped.
  Left `SideTitles` formatted via `NumberFormatter.formatCompact` (ja/zh `1万`,
  en `10K`) in `palette.textSecondary`. `minY` stays **0** — no negative tick.
- **X-axis day markers (Feature 2):** bottom `SideTitles` `interval: 7`, labels
  via the new `DateFormatter.formatDayOfMonthAxis` (ja/zh `7日`, en `7`). Edge
  labels past `maxX` skipped to avoid clutter.
- **上月 gray reference (Feature 3):** the dashed 上月 series now uses an explicit
  neutral `palette.textTertiary` (was a faint `Color.lerp(seriesColor, card,
  0.55)`) with `barWidth` bumped 1.5 → 2 so it reads as a clearly-visible muted
  gray. Still dashed, still spend-side-only (gated by `_hasReference`).
- **Endpoint annotations (Feature 4):** the 本月 line shows dots only at the
  first + last spots (`FlDotData.checkToShowDot`), plus a `Stack` overlay with
  two `_EndpointAnnotation` labels (date via `DateFormatter.formatShortMonthDay`,
  amount via `NumberFormatter.formatCurrency(..,'JPY',..)` in
  `AppTextStyles.amountSmall` tabular figures, series-colored).
- New required `anchor` `DateTime` param (current-month anchor) so the chart can
  build `DateTime(anchor.year, anchor.month, point.day)` for annotation dates
  (`CumulativePoint.day` carries no month). Chart height bumped 220 → 244 for
  axis/annotation room. Locale read via `Localizations.localeOf(context)` (no
  `WidgetRef` added).

`within_month_trend_card.dart` threads `ctx.trendAnchor` to `_TrendBody` and on
to the chart, and the 上月 legend swatch was switched to `palette.textTertiary`
so legend == line. The joy branch still passes `previous = null` (D-E1 untouched).

Chart unit tests extended from 5 → 9 (grid horizontal-only, left/bottom titles
on + top/right off, minY 0, endpoint dots only at first/last). All call-sites
updated to pass `anchor`.

### Task 2 — goldens + full gate (commit c005e531)

Re-baselined the 8 affected macOS masters (7 trend-card + the analytics scroll
smoke that renders this card) via scoped `--update-goldens`. Visually verified
the ja/en value masters (axes, gridlines, green 本月 line with endpoint dots,
gray dashed 上月, day markers, annotations — no clipping) and the empty-state
master (stable placeholder, no LineChart, no throw).

## Verification

- `flutter analyze` — **0 issues** (full project).
- `flutter test` — **3061/3061 passed** (was 3057; +4 new chart unit tests).
  Includes the hardcoded-CJK-UI architecture scan and the anti-toxicity sweeps.

## Deviations from Plan

**None affecting scope.** One planning-discretion note: the `日` X-axis affix was
routed through a new `DateFormatter.formatDayOfMonthAxis` helper (the formatter
file is on the hardcoded-CJK-scan whitelist) rather than a bare `Text('日')`
literal in the chart — exactly the idiom the plan recommended to keep the scan
green. No new ARB keys were added (all labels reuse `DateFormatter` /
`NumberFormatter`). No data-model change; ADR-012/D-E1 joy single-line guarantee
preserved structurally.

## Known Stubs

None.

## Self-Check: PASSED

- lib chart + card + date_formatter: present, analyze-clean.
- 8 golden masters: modified and committed (c005e531).
- Commits ec4d43e2 + c005e531: present in git log.

---
phase: quick-260620-kll
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/application/analytics/get_within_month_cumulative_use_case.dart
  - lib/features/analytics/presentation/providers/state_analytics.dart
  - lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart
  - lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
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
  - test/golden/goldens/within_month_trend_card_empty_light_ja.png
  - test/golden/goldens/analytics_screen_scroll_smoke_light_ja.png
autonomous: true
requirements: [QUICK-260620-kll]
must_haves:
  truths:
    - "X-axis spans the WHOLE displayed month (minX=1 .. maxX=daysInMonth(anchor)); day markers run across the full month (D-1)"
    - "本月 line is carry-forwarded from day 1 (cumulative 0 until first spend) to the comparison day = today when viewing the live current month, or to the month's last day for a past-month view (D-5)"
    - "上月 reference line spans the ENTIRE previous month (day 1 .. last day of prev month), carry-forwarded (D-5)"
    - "No start-point label is rendered; only the 本月 endpoint is annotated (D-2)"
    - "本月 endpoint label (date + amount) sits NEAR the actual endpoint (data-anchored, not a fixed corner), ABOVE the point when 本月 ≥ 上月 at the comparison day, BELOW when 本月 < 上月 (D-3)"
    - "上月 endpoint label (date + amount near its comparison-day point) uses the SAME above/below rule but the OPPOSITE position from the 本月 label so the two never collide (D-4)"
    - "悦己 (joy) tab stays a single line with NO 上月 line and NO 上月 label (ADR-012/D-E1); model gains no previousMonthJoy field"
    - "The chart reads NO clock (no DateTime.now()); 'today'/extension is injected by the use case via a now param so goldens stay deterministic"
    - "flutter analyze == 0 issues; full flutter test passes"
  artifacts:
    - path: "lib/application/analytics/get_within_month_cumulative_use_case.dart"
      provides: "carry-forward series shaping + now-injected current-month extension to today/month-end"
      contains: "now"
    - path: "lib/features/analytics/presentation/providers/state_analytics.dart"
      provides: "provider passes DateTime.now() into the use case"
      contains: "DateTime.now()"
    - path: "lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart"
      provides: "whole-month X extent, start label removed, data-anchored above/below endpoint labels with 上月 opposite, via LayoutBuilder plot-area math"
      contains: "LayoutBuilder"
    - path: "test/golden/within_month_trend_card_golden_test.dart"
      provides: "fixtures updated to the new look (day1 prepend + extended endpoint + full prev-month)"
      contains: "previousMonth"
    - path: "test/unit/application/analytics/get_within_month_cumulative_use_case_test.dart"
      provides: "use-case tests pass an explicit now and assert carry-forward extents"
      contains: "now:"
  key_links:
    - from: "state_analytics.dart withinMonthCumulativeTrend"
      to: "GetWithinMonthCumulativeUseCase.execute"
      via: "now: DateTime.now()"
      pattern: "now:\\s*DateTime\\.now\\(\\)"
    - from: "within_month_cumulative_line_chart.dart"
      to: "plot-area pixel math"
      via: "LayoutBuilder + leftReserved 44 / bottomReserved 22"
      pattern: "LayoutBuilder"
---

<objective>
Round-2 correction of the statistics-page 「支出趋势」 within-month cumulative line
chart (analytics card #1), per the 5 LOCKED corrections in
`260620-kll-CONTEXT.md`. Round 1 (jx2) added axes/grid/上月 line/start+end
annotations but: the X-axis stopped at the last spend day, the line stopped early,
both start AND end were labelled with fixed-corner offsets, and there was no
carry-forward to "today".

This plan:
1. Moves carry-forward + "today" injection into the USE CASE (pure, testable) so
   the chart renders deterministically from its inputs (golden stability — the
   chart must NEVER read `DateTime.now()`).
2. Reworks the chart to a whole-month X extent, removes the start label, and
   data-anchors the 本月 + 上月 endpoint labels with the above/below + opposite rule.
3. Updates the use-case test, chart widget test, and BOTH golden fixtures, then
   re-baselines the affected goldens on macOS and runs the full gate.

Purpose: make the live chart match the user's reviewed intent (whole month axis,
本月 line to today carrying forward, full 上月 reference, single anchored endpoint
label per line placed above/below by comparison).
Output: corrected use case + provider + chart + card, updated tests + fixtures,
re-baselined goldens, green full suite + analyze 0.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/quick/260620-kll-trend-chart-fix/260620-kll-CONTEXT.md
@.planning/quick/260620-jx2-trend-chart-axes/260620-jx2-SUMMARY.md
@.planning/STATE.md
@CLAUDE.md

# Source under correction
@lib/application/analytics/get_within_month_cumulative_use_case.dart
@lib/features/analytics/presentation/providers/state_analytics.dart
@lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart
@lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
@lib/features/analytics/domain/models/within_month_cumulative_trend.dart
@lib/features/analytics/domain/models/time_window.dart
@lib/infrastructure/i18n/formatters/date_formatter.dart

# Tests + fixtures to update
@test/unit/application/analytics/get_within_month_cumulative_use_case_test.dart
@test/widget/features/analytics/presentation/widgets/within_month_cumulative_line_chart_test.dart
@test/golden/within_month_trend_card_golden_test.dart
@test/golden/analytics_screen_scroll_smoke_golden_test.dart
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Use-case carry-forward + now injection (data layer is the only place that knows "today")</name>
  <files>lib/application/analytics/get_within_month_cumulative_use_case.dart, lib/features/analytics/presentation/providers/state_analytics.dart, test/unit/application/analytics/get_within_month_cumulative_use_case_test.dart</files>
  <behavior>
    Update `get_within_month_cumulative_use_case_test.dart` FIRST (RED), then make the use case pass (GREEN). New/updated test cases (all pass an EXPLICIT `now`, never DateTime.now()):
    - Current-month series is PREPENDED with a day-1 point: when the displayed month is the current month and there is spend, `currentMonthTotal.first.day == 1` with cumulative 0 (carry-forward left edge per D-5; reuse the existing day-1-spend-equals-same value note from CONTEXT discretion).
    - Current-month series is EXTENDED to the comparison day: when `now` falls inside the displayed month (live current month), the last current-month point has `day == now.day` carrying forward the running cumulative even on a no-spend `now` day (D-5). Assert `currentMonthTotal.last.day == now.day` and its cumulative == the running total at/just-before `now.day`.
    - Past-month view: when `now` is AFTER the displayed month (the month is complete), the current-month series extends to the month's LAST day (`DateTime(year, month+1, 0).day`), not to `now.day` (D-5 generalization). Assert `.last.day == daysInMonth(anchor)`.
    - 上月 series spans the WHOLE previous month: `previousMonthTotal.first.day == 1` (cumulative 0 until first prev-month spend) and `previousMonthTotal.last.day == daysInMonth(previousMonth)` (D-5). Same for `previousMonthDaily`.
    - total == daily + joy at every CURRENT-month point still holds after carry-forward (existing Test 2 invariant — keep it green; carry-forward must apply consistently across total/daily/joy).
    - Joy current-month series ALSO gets day-1 prepend + extension to the comparison day (so the joy single line spans the chart) — but there is still NO previousMonthJoy (existing Test 3 cross-period guard stays green; the model is unchanged).
    - Empty window: all series stay empty, no throw (existing Test 5 — when perDay is empty for a month, do NOT synthesize a flat 0-line; emit `const []` so the empty placeholder still shows; assert unchanged).
    - Security Test 6 window assertion unchanged (still 2-month fetch May 1 .. June 30).
  </behavior>
  <action>
    Add a required `DateTime now` param to `GetWithinMonthCumulativeUseCase.execute(...)` (D-5: the use case is the ONLY place that knows "today"; the chart stays clockless). Implement carry-forward in `_cumulative(...)` (or a thin wrapper): after building the sparse per-day running points for a month, (a) PREPEND a `CumulativePoint(day: 1, cumulativeAmount: 0)` when the first spend day > 1 (left-edge carry-forward, D-5; if spend exists on day 1 the prepend is the day-1 cumulative — same value, per CONTEXT discretion); (b) APPEND a carry-forward endpoint at the month's comparison day carrying the final running cumulative when the last spend day < comparison day. The comparison day per month: for the CURRENT-month series, `comparisonDay = (now is within the displayed month) ? now.day : daysInMonth(anchor)`; for the PREVIOUS-month series, `comparisonDay = daysInMonth(previousMonth)` (always the full prev month, D-5). Compute `daysInMonth(y, m) = DateTime(y, m + 1, 0).day`. Determine "now is within the displayed month" by comparing `now.year/now.month` to the anchor's year/month. CRITICAL: when a month has NO spend at all, emit `const []` (do NOT synthesize a flat 0→0 line) so the empty-state placeholder still renders. Apply the SAME carry-forward to total/daily/joy current and total/daily previous (joy previous remains absent — D-E1). Keep the expense-only gate, entrySourceFilter, and the single 2-month `findByBookIds` fetch byte-unchanged (T-46-01-01). Update doc-comments to describe the carry-forward + now contract; remove any stale "starts at first spend day / ends at last spend day" wording. Then in `state_analytics.dart` `withinMonthCumulativeTrend`, pass `now: DateTime.now()` into `useCase.execute(...)` (the provider is the ONLY production caller injecting the real clock; keep the existing month-anchor defensive normalization). Run build_runner only if a generated file changed (no model change here, so likely not needed).
  </action>
  <verify>
    <automated>flutter test test/unit/application/analytics/get_within_month_cumulative_use_case_test.dart && flutter analyze lib/application/analytics/get_within_month_cumulative_use_case.dart lib/features/analytics/presentation/providers/state_analytics.dart</automated>
  </verify>
  <done>Use-case test green with explicit-now carry-forward assertions (day-1 prepend, current-month extension to now.day live / to month-end for past month, 上月 full-month span, total==daily+joy preserved, empty stays empty); provider passes DateTime.now(); analyze 0 on touched files; the chart widget reads no clock.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Chart whole-month X extent, remove start label, data-anchored above/below endpoint labels (本月 + 上月 opposite)</name>
  <files>lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart, lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart, test/widget/features/analytics/presentation/widgets/within_month_cumulative_line_chart_test.dart</files>
  <behavior>
    Update the chart widget test FIRST (RED) then make it pass (GREEN). New/updated assertions on `WithinMonthCumulativeLineChart`:
    - maxX spans the whole month: with an `anchor` of May 2026 (31 days) and current series ending before day 31, `_chart(tester).data.maxX == 31` (whole-month extent derived from `anchor`, D-1). minX stays 1.
    - Only ONE endpoint label per drawn line: a 本月-only chart renders exactly ONE `_EndpointAnnotation` (no start label — D-2). Update Test 9-style dot assertion so the FIRST spot no longer needs a labelled dot (start label gone); keep an endpoint dot on the last spot (Claude discretion to keep dots).
    - Spend mode (current + non-empty previous) renders TWO endpoint labels (本月 + 上月, D-4). Joy mode (previous null/empty) renders exactly ONE (本月 only; no 上月 label — D-E1).
    - Above/below decision is data-driven (D-3/D-4): assert via a small pure helper (e.g. a static/visible-for-test method `labelAbove({required currentEndAmount, required prevAtComparisonAmount})`) that returns true when current ≥ prev (本月 above) and false when current < prev; and that the 上月 placement is the boolean negation (opposite, D-4). Test both orderings.
    - Existing Tests 1–8 stay green (2 vs 1 series, dashed 上月, palette color, empty placeholder, empty-previous=single, grid horizontal-only, left+bottom titles on, minY 0) — only the start-label/dot expectation changes.
  </behavior>
  <action>
    Whole-month X extent (D-1): replace `_maxDay()` usage for `maxX` with `daysInMonth = DateTime(anchor.year, anchor.month + 1, 0).day`; set `maxX = daysInMonth.toDouble()`, keep `minX = 1`. Bottom day markers already use `interval: 7`; change the `getTitlesWidget` guard from `> maxDay` to `> daysInMonth` so 7/14/21/28日 span the full month. Keep `_maxY()` scanning both series for the Y ceiling.
    Remove the start label (D-2): delete the first `Positioned`/`_EndpointAnnotation` (the `firstPoint` annotation) and the `firstSpot`-based dot in `checkToShowDot` (keep only the last-spot dot, or all-off per discretion — keep last dot).
    Data-anchored endpoint labels (D-3/D-4): wrap the `LineChart` in a `LayoutBuilder` inside the `Stack` so the builder yields plot dimensions. Per CONTEXT key_facts compute the spot→pixel mapping with `leftReserved = 44`, `bottomReserved = 22`, and a small `topPad` (reuse the headroom already implied by `axisMaxY`; pick a const topPad and document it): `plotW = constraints.maxWidth - leftReserved`, `plotH = constraints.maxHeight - bottomReserved - topPad`, `px(day) = leftReserved + (day - minX)/(maxX - minX) * plotW`, `py(amount) = topPad + (1 - (amount - minY)/(axisMaxY - minY)) * plotH`. Anchor the 本月 label at the LAST current-month point (the comparison-day endpoint the use case produced); anchor the 上月 label (when `_hasReference`) at the previous-month point with `day <= comparisonDay` LOOKED UP (do NOT use `previousMonth!.last` — 上月 now spans the whole month so its last point is month-end, not the comparison day; find the latest prev point with `day <= comparisonDay`, where `comparisonDay = currentMonth.last.day` since the use case made that = today). Compute `labelAbove = currentEndAmount >= prevAtComparisonAmount` (D-3: 本月 ≥ 上月 ⇒ above; otherwise below). Place the 本月 label via `Positioned` nudged UP by a const offset (e.g. ~28px) when `labelAbove`, DOWN when not; place the 上月 label at the OPPOSITE (`!labelAbove`, D-4). Clamp both `Positioned` left/top so labels never overflow the card (clamp to [0, maxWidth - labelWidthEstimate] / [0, maxHeight - labelHeightEstimate]); when there is no reference (joy), only the 本月 label is placed and `labelAbove` defaults to true (above). Expose the comparison decision as a small visible-for-testing pure helper so Task-2 tests can assert the above/below + opposite logic without pixel math. The `_EndpointAnnotation` keeps using `DateFormatter.formatShortMonthDay` + `NumberFormatter.formatCurrency(.., 'JPY', ..)` + `AppTextStyles.amountSmall` (tabular) + `context.palette.*`; for the 上月 label pass the 上月 series color (muted `palette.textTertiary`, matching the line) and build its date from `DateTime(anchor.year, anchor.month - 1, prevPoint.day)` (previous month, e.g. 5月20日 when viewing June). NO new ARB keys, NO hardcoded hex, NO DateTime.now() in the widget.
    In `within_month_trend_card.dart`: no API change is required (it already threads `anchor`/series); verify the joy branch still passes `previous = null` (D-E1) and the legend still gates on non-empty previous. Update the legend comment only if wording references the removed start label.
  </action>
  <verify>
    <automated>flutter test test/widget/features/analytics/presentation/widgets/within_month_cumulative_line_chart_test.dart && flutter analyze lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart</automated>
  </verify>
  <done>Chart maxX == daysInMonth(anchor) with minX 1; no start label/dot; one 本月 endpoint label data-anchored above/below by comparison; 上月 label (spend side only) opposite; joy stays single-line single-label; above/below helper unit-tested both orderings; widget Tests 1–8 still green; analyze 0; zero DateTime.now() and zero hardcoded hex in the widget (grep clean).</done>
</task>

<task type="auto">
  <name>Task 3: Update both golden fixtures to the new look, re-baseline on macOS, run full gate</name>
  <files>test/golden/within_month_trend_card_golden_test.dart, test/golden/analytics_screen_scroll_smoke_golden_test.dart, test/golden/goldens/within_month_trend_card_light_ja.png, test/golden/goldens/within_month_trend_card_light_zh.png, test/golden/goldens/within_month_trend_card_light_en.png, test/golden/goldens/within_month_trend_card_dark_ja.png, test/golden/goldens/within_month_trend_card_dark_zh.png, test/golden/goldens/within_month_trend_card_dark_en.png, test/golden/goldens/within_month_trend_card_empty_light_ja.png, test/golden/goldens/analytics_screen_scroll_smoke_light_ja.png</files>
  <action>
    Both golden tests OVERRIDE `withinMonthCumulativeTrendProvider` with a fixed `WithinMonthCumulativeTrend` (they never run the use case), so they fully control the rendered shape — update the fixtures to encode the use-case OUTPUT shape so the masters show the new look (whole-month X axis, 本月 line day1→endpoint, 上月 line full month, NO start label, end labels above/below with 上月 opposite). Both fixtures use a May-2026 anchor (a COMPLETE past month) → the current-month series must extend to day 31 (month-end) and the 上月 series to day 30 (April). Rewrite `_fixtureRich()` in `within_month_trend_card_golden_test.dart` and `_trend()` in `analytics_screen_scroll_smoke_golden_test.dart` so: every current series STARTS at `_p(1, 0)` (or day-1 cumulative) and ENDS at day 31; every previous series STARTS at `_p(1, 0)` and ENDS at day 30; pick interior points (e.g. days ~10/20) such that at the comparison day (31) 本月 > 上月 in one tab to exercise the ABOVE branch and ensure both labels are visible without collision. Keep the empty fixture all-`[]` (placeholder path unchanged). Keep total == daily + joy at each current point so the data stays self-consistent. Verify the value tests render without overflow/clipping (the new whole-month axis + two labels must fit the 360-wide card). Then re-baseline ONLY the 8 affected masters on macOS via scoped `--update-goldens` (the 7 `within_month_trend_card_*` + `analytics_screen_scroll_smoke_light_ja`); confirm `git status` shows exactly those 8 PNGs changed (clean diff attribution; macOS-only per the golden CI platform gate). Finally run the FULL gate: `flutter analyze` (== 0) and the complete `flutter test` suite (NOT a scoped subset — the per-wave gate must catch architecture sweeps like the hardcoded-CJK-UI scan and anti-toxicity).
  </action>
  <verify>
    <automated>flutter test test/golden/within_month_trend_card_golden_test.dart test/golden/analytics_screen_scroll_smoke_golden_test.dart && flutter analyze && flutter test</automated>
  </verify>
  <done>Both fixtures rewritten to the new look (day1→day31 current, day1→day30 previous, one tab with 本月>上月 at the comparison day); 8 macOS PNG masters re-baselined and committed; `git status` shows only those 8 PNGs + the 2 test files changed; `flutter analyze` == 0; FULL `flutter test` passes (≥3061 tests, no regressions).</done>
</task>

</tasks>

<verification>
- `flutter analyze` == 0 issues (whole project).
- Full `flutter test` passes (≥3061 tests; +0 or more from new chart/use-case assertions; no regressions), including the hardcoded-CJK-UI architecture scan and anti-toxicity sweeps.
- `grep -n 'DateTime.now()' lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart` returns ZERO (chart is clockless — golden determinism).
- `grep -nE '#[0-9A-Fa-f]{6}' lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart` returns ZERO (palette-only).
- No new ARB keys added (all labels reuse DateFormatter/NumberFormatter); `within_month_cumulative_trend.dart` model unchanged (no previousMonthJoy).
- The 8 affected golden masters re-baselined on macOS; `git status` shows only those PNGs + the touched test/lib files.
</verification>

<success_criteria>
All 5 LOCKED corrections implemented and verifiable:
1. X-axis spans the whole month (maxX = daysInMonth(anchor)). ✓ chart test
2. No start-point label. ✓ chart test (one endpoint label per line)
3. 本月 endpoint label data-anchored, ABOVE when 本月 ≥ 上月 / BELOW when 本月 < 上月. ✓ above/below helper test
4. 上月 endpoint label same rule, OPPOSITE position. ✓ helper test (negation)
5. 本月 line → today (now.day live / month-end past) carry-forward from day 1; 上月 line full previous month; comparison point = today. ✓ use-case test
+ Joy single-line invariant intact (no 上月 line/label, no model change) — ADR-012/D-E1.
+ Chart is clockless; carry-forward + now injection live in the use case (golden determinism).
+ Full suite + analyze 0; 8 goldens re-baselined on macOS.
</success_criteria>

<output>
Create `.planning/quick/260620-kll-trend-chart-fix/260620-kll-SUMMARY.md` when done.
Also generate a worklog under `docs/worklog/` per .claude/rules/worklog.md.
Executor commits code atomically; the orchestrator handles the docs commit. No ROADMAP edit (quick task).
</output>

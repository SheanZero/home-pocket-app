# Quick Task 260620-jx2: 支出趋势图表增加坐标轴/网格/上月对比线/起止点标注 - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

> The orchestrator gathered this from two reference screenshots the user supplied
> (subagents cannot see images — this text IS the visual spec). The user
> confirmed scope and the joy-tab constraint via an explicit clarifying question.

<domain>
## Task Boundary

Redesign the **statistics-page (图表 tab) 「支出趋势」 within-month cumulative line
chart** so it adopts the richer presentation of an external reference app
(screenshot the user marked with a red box). Today the chart is a bare colored
diagonal line with NO axes, grid, labels, or visible comparison.

Files in scope (the only two that should change for the chart itself):
- `lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart`
  — the fl_chart `LineChart` widget. Currently explicitly sets
  `gridData: FlGridData(show: false)`, `titlesData: FlTitlesData(show: false)`,
  `borderData: FlBorderData(show: false)`. This is where axes/grid/annotations
  get turned on.
- `lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart`
  — the card wrapper (`_TrendBody`, `_PillTabs`, legend). Tab → series + color
  resolution lives here. Legend may need to stay/extend.

NOT in scope: the home-screen hero card, the donut/category card, the analytics
data model, or the joy-tab cross-period rule (kept as-is).
</domain>

<decisions>
## Implementation Decisions (LOCKED — do not revisit)

### Feature scope — user selected ALL FOUR
The reference chart adds these over the current bare line. All four are in scope:

1. **Y-axis value labels + horizontal gridlines.** Left-side amount ticks (the
   reference shows e.g. `10,000` / `20,000`) with faint horizontal gridlines
   across the plot. Our 支出趋势 is cumulative SPEND, always ≥ 0, so the axis
   starts at 0 — do NOT replicate the reference's negative `-10,000` tick (that
   reference app charts net balance 収支 which can go negative; ours cannot).
   Pick a small number of "nice" round ticks (e.g. 3–4 horizontal lines).
   Format amounts with the project currency formatter, not raw numbers.

2. **X-axis date markers.** Bottom axis day labels like `7日 / 14日 / 21日 / 28日`
   (locale-aware — `日` suffix only for ja/zh; en uses plain day number or the
   project DateFormatter convention). Show a sparse set (every ~7 days), not
   every day, to avoid clutter.

3. **「上个月」 last-month comparison line (gray), made clearly visible + legend.**
   The dashed previous-month series already exists in code (drawn only on the
   spend side: 总支出/日常) but is faint. Make it read clearly as a muted gray
   reference line. Keep/ensure the existing legend row ("本月" solid + "上月"
   dashed) is present on the spend side.

4. **Start / current point amount annotations.** Label the first point and the
   latest (current) point of the 本月 line with date + amount (reference shows
   `5月1日 4,700円` at the start and `6月1日 0円` at the current point). Implement
   with fl_chart dot+label or a small overlay. Keep it readable, not cluttered —
   annotate the 本月 line's endpoints only (not the 上月 line, not every point).

### 悦己 (joy) tab — keep single line (LOCKED)
The new axes/grid/X-ticks/Y-ticks apply to ALL THREE tabs (总支出/日常/悦己), BUT
the 悦己 tab MUST still draw only the 本月 single line with NO 上月 comparison —
this is the existing ADR-012 structural guarantee (joy has no previous-month
field by construction). Do NOT add a previous-month series to joy. The start/
current point annotation still applies to the joy 本月 line.

### Claude's Discretion
- Exact tick count, gridline color/opacity (use `context.palette` muted tokens —
  e.g. `borderDefault` / `backgroundDivider` / `textSecondary`; NEVER hardcode
  hex — ADR-019 palette rule).
- Annotation label placement/anchoring and whether to use fl_chart's built-in
  `showingTooltipIndicators` / `extraLinesData` / `FlDotData` + a Stack overlay,
  whichever renders cleanly without overflow at height ~220.
- Whether to bump chart height slightly to make room for axis labels.
</decisions>

<specifics>
## Specific Ideas / Reference description

Reference chart (Image #2, red box) — an EXTERNAL app, described for the planner:
- A card with a line chart. Left edge: y-axis amount ticks with horizontal
  gridlines. Bottom: x-axis date ticks (7日/14日/21日…).
- Two lines: a muted GRAY flat line = 上个月 (last month), and a colored line =
  本月 (this month).
- The 本月 line's start point and current point carry small text labels with the
  date and cumulative amount.
- (Reference also has a "⚙ 上个月" toggle chip + 月度变动/结算 sibling tabs — these
  are the reference app's own chrome and are OUT OF SCOPE; our equivalent tabs
  are the existing 总支出/日常/悦己 pills.)

Current chart (Image #1): same data, but `FlGridData/FlTitlesData/FlBorderData`
all `show:false`, no annotations — just the line. The bare-line look was a
deliberate earlier choice ("the line is the signal"); this task reverses it
toward the richer reference.
</specifics>

<canonical_refs>
## Canonical References
- `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md` — palette tokens; use
  `context.palette.*`, never hardcoded hex.
- ADR-012 (referenced in the widget docstrings) — joy tab has NO cross-period
  reference line. This task preserves that rule.
- Project CLAUDE.md — Amount Display (`AppTextStyles.amount*` +
  `FontFeature.tabularFigures()`), i18n (all UI text via `S.of(context)`,
  dates via `DateFormatter`, currency via the formatter — no `¥`/`円` literals),
  and the golden-test workflow (goldens are macOS-baselined; we ARE on macOS).
</canonical_refs>

<constraints>
## Hard constraints for the plan
- `flutter analyze` MUST stay at 0 issues.
- This change alters rendering → golden tests for the trend card/chart WILL
  fail and MUST be re-baselined (`flutter test --update-goldens` for the
  affected goldens) — we are on macOS so this is valid. Then full `flutter test`
  must pass.
- Any NEW user-facing strings (e.g. axis-related, if any) need all 3 ARB files
  (ja/zh/en) + `flutter gen-l10n`. Prefer reusing existing keys / the
  DateFormatter + currency formatter so no new ARB keys are needed if possible.
- Immutability, small focused widgets, no hardcoded hex, no hardcoded strings.
</constraints>

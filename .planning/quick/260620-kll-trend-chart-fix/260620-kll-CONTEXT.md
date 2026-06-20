# Quick Task 260620-kll: 支出趋势图表修正 (round 2) - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

> This is a CORRECTION round on quick task 260620-jx2 (which added axes/grid/上月
> line/endpoint annotations to the statistics-page 「支出趋势」 within-month
> cumulative chart). The user reviewed jx2 on-device and gave 5 specific
> corrections. Subagents cannot see the screenshots — this text is authoritative.
> The orchestrator has already verified the data-layer facts below against the code.

<domain>
## Task Boundary

Fix the statistics-page (图表 tab) 「支出趋势」 within-month cumulative line chart
(card #1 of the analytics registry) per the user's 5 corrections. Same feature as
jx2; this refines axis extent, line extent, and endpoint annotations, and adds a
carry-forward in the data layer so the lines reach "today" / span the whole month.

Files likely in scope:
- `lib/application/analytics/get_within_month_cumulative_use_case.dart` — the
  cumulative shaping. MUST gain a carry-forward extension + a `now`/today input
  (see Decisions). + its unit test.
- `lib/features/analytics/presentation/providers/state_analytics.dart` — the
  `withinMonthCumulativeTrend` provider that calls the use case; pass real `now`.
- `lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart`
  — axis extent (whole month), remove start label, data-anchored endpoint labels
  with above/below + opposite logic.
- `lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart`
  — passes anchor/series through (already passes `anchor`); legend unchanged.
- Tests: chart widget test, use-case test, and the 8 golden masters from jx2
  (`within_month_trend_card_*` + `analytics_screen_scroll_smoke_light_ja`).

NOT in scope: the donut/other analytics cards, the joy cross-period rule (joy
stays single-line, no 上月, ADR-012/D-E1 — unchanged).
</domain>

<decisions>
## The 5 corrections (LOCKED — verbatim intent from the user)

### 1. X-axis must show the WHOLE (current) month — not stop at the last expense day
Today `maxX = _maxDay()` (the last day that has data). Change so the X-axis spans
the full displayed month: `maxX = daysInMonth(anchor)` (e.g. June → 30). Bottom
day markers (7日/14日/21日/28日…) span the whole month. minX stays 1.
The chart can derive days-in-month from `anchor`: `DateTime(anchor.year,
anchor.month + 1, 0).day`.

### 2. Start point: NO label
Remove the start-point (first-point) date+amount annotation entirely. Only the
END point of the 本月 line is annotated now. (Round 1 showed both start and end.)

### 3. End point: date + amount near the endpoint, placed ABOVE or BELOW by comparison
The 本月 endpoint annotation (date + cumulative amount) must sit NEAR the actual
endpoint of the line (data-anchored, not a fixed corner offset like round 1).
Vertical placement depends on this-month-vs-last-month at the comparison day:
- if **本月 current amount > 上月 amount** (this month higher) → label ABOVE the point
- if **本月 current amount < 上月 amount** (this month lower) → label BELOW the point

### 4. 上月 (last-month) reference line ALSO gets a date + amount label — same logic, OPPOSITE position
The 上月 line gets its own date+amount label near ITS comparison point, using the
SAME above/below rule but placed EXACTLY OPPOSITE to the 本月 label (so the two
labels never collide):
- if 本月 label is ABOVE its point → 上月 label is BELOW its point
- if 本月 label is BELOW its point → 上月 label is ABOVE its point
(上月 label applies to the spend side only — joy has no 上月 line, so no 上月 label.)

### 5. "Today is the 20th" → line extents + comparison point
- The **本月 line is drawn to TODAY's day** (the 20th in the live example), i.e. the
  current series extends to today (day 20), carrying forward the running cumulative
  even on no-spend days. Generalize: extend to `now.day` when the displayed month
  IS the real current month; for a PAST month view, extend to that month's last day
  (the month is complete). The line should also start at **day 1** (left edge) so it
  spans the chart — cumulative = 0 until the first spend day (carry-forward both
  ends).
- The **上月 reference line is drawn across the ENTIRE previous month** (day 1 →
  last day of prev month), carrying forward.
- The **comparison / reference point is day 20** (= the 本月 endpoint's day, i.e.
  "today"). The above/below decision in #3/#4 compares 本月 cumulative at the
  endpoint day vs 上月 cumulative at the SAME day-of-month (lookup the last 上月
  point with `day <= comparisonDay`). The 本月 label anchors at (today, currentEnd);
  the 上月 label anchors at (today, prevAtToday) with date = previous-month/today
  (e.g. 5月20日) + that day's cumulative amount.

### Claude's Discretion
- Exact label offset (px above/below), small-screen overflow handling, whether to
  keep an endpoint dot on each annotated point.
- Whether to draw a thin vertical guide at the comparison day (optional, only if
  it reads cleanly — not required).
- Whether the day-1 prepend value is 0 or the day-1 cumulative (same thing if no
  day-1 spend).
- Y-tick formatting / gridline styling — keep round-1 behavior unless it conflicts.
</decisions>

<key_facts>
## Verified data-layer facts (orchestrator already checked the code)

- **`TimeWindow.month.range.end` = month-end 23:59:59, NOT today.** So `endDate`
  and `anchor` reaching the card do NOT encode "today". "Today" must be injected.
- **`GetWithinMonthCumulativeUseCase._cumulative()` emits one point PER SPEND DAY
  only** — days with no spend are omitted; the series ends at the last spend day,
  starts at the first spend day. There is NO day-1 point and NO today/month-end
  point unless spend happened then. THIS is why round-1 lines stop early.
- **Carry-forward belongs in the use case** (pure, testable), NOT in the chart
  widget. The chart MUST stay deterministic from its inputs or the golden tests
  become time-dependent (they render the card; if the widget read `DateTime.now()`
  internally goldens would flake). So: the use case gains a `now` (DateTime) param,
  produces series already extended (本月 → today/month-end, 上月 → prev month-end,
  both prepended to day 1), and the chart renders whatever series it is given.
  The provider `withinMonthCumulativeTrend` passes `DateTime.now()`; use-case tests
  pass an explicit `now`; golden/widget tests build fixed series directly (so they
  control the shape — update those fixtures to include day-1 + a today/month-end
  endpoint + a full 上月 month so the masters show the new look).
- **comparisonDay for the chart = `currentMonth.last.day`** (the use case makes
  that = today). The chart needs NO clock — it derives everything from its inputs.
- **上月 value at comparison day** = last `previousMonth` point with `day <=
  comparisonDay` (since 上月 now spans the whole month, its `.last` is month-end,
  not day 20 — must LOOK UP day-20's value, not use `.last`).
- **Data-anchored label positioning:** fl_chart has no public spot→pixel API here;
  compute it. Wrap the `LineChart` in a `LayoutBuilder`; plot area =
  `(width - leftReserved(44), height - bottomReserved(22) - topPad)`. For a point
  `(day, amount)`: `px = leftReserved + (day - minX)/(maxX - minX) * plotW`,
  `py = topPad + (1 - (amount - minY)/(maxY - minY)) * plotH`. Place the label via
  `Positioned`, nudged up/down by the above/below rule, clamped so it doesn't
  overflow the card. This is deterministic → goldens stable.
- **fl_chart 1.2.0** API as used today (FlGridData / FlTitlesData / SideTitles /
  SideTitleWidget / FlDotData / FlDotCirclePainter) — keep using these.
- **Locale** via `Localizations.localeOf(context)` (no WidgetRef in the chart).
  Currency `'JPY'` (analytics is JPY-only). Dates `DateFormatter.formatShortMonthDay`,
  amounts `NumberFormatter.formatCurrency` + `AppTextStyles.amountSmall` (tabular).
- **Joy invariant (ADR-012 / D-E1):** joy tab still passes `previous = null` → no
  上月 line, no 上月 label. Do NOT add a previousMonthJoy field. Keep structural.
</key_facts>

<canonical_refs>
## Canonical References
- jx2 SUMMARY: `.planning/quick/260620-jx2-trend-chart-axes/260620-jx2-SUMMARY.md`
  (what round 1 shipped — this round corrects its annotation/extent behavior).
- ADR-019 palette (no hardcoded hex), ADR-012/D-E1 (joy zero cross-period).
- CLAUDE.md: amounts via `AppTextStyles.amount*`; i18n via S/DateFormatter/
  NumberFormatter; golden workflow (macOS-baselined — we ARE on macOS).
</canonical_refs>

<constraints>
## Hard constraints
- `flutter analyze` == 0 issues; full `flutter test` passes (3061+ tests).
- Re-baseline the affected goldens on macOS (`--update-goldens` for the trend-card
  + analytics-smoke golden tests), AFTER updating their fixture data so the masters
  reflect: whole-month X axis, 本月 line day1→today, 上月 line full month, NO start
  label, end labels above/below with 上月 opposite.
- Use the use-case `now` injection — do NOT read `DateTime.now()` inside the chart
  widget (golden determinism). Use-case test MUST pass an explicit `now`.
- `context.palette.*` only (no hex); zero new ARB keys (reuse formatters); reuse
  `DateFormatter.formatDayOfMonthAxis` / `formatShortMonthDay` from round 1.
- Immutability, small widgets, analyzer-clean. Quick task: no ROADMAP edit.
- Worklog under `docs/worklog/` per .claude/rules/worklog.md.
</constraints>

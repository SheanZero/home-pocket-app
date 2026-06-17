---
phase: 46-cards
plan: 04
subsystem: ui
tags: [flutter, fl_chart, riverpod, analytics, line-chart, adr-012]

# Dependency graph
requires:
  - phase: 46-01
    provides: withinMonthCumulativeTrendProvider + WithinMonthCumulativeTrend model (per-day-cumulative, joy current-month-only by construction)
provides:
  - WithinMonthCumulativeLineChart widget (fl_chart 1.2.0 LineChart; 1 or 2 series, palette-colored, empty-safe)
  - WithinMonthTrendCard ConsumerWidget with 总支出/日常/悦己 pill tabs (joy = single line, zero cross-period D-E1)
  - withinMonthTrendRefreshTargets(ctx) single-source refresh-target function (trendAnchor-keyed, categoryDonut shape)
affects: [46-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "fl_chart 1.2.0 LineChart wiring (first LineChart in lib/): SizedBox(height:) + LineChartData(lineBarsData:[...]) + hidden grid/axes/touch"
    - "Structural cross-period guard: joy tab passes previousMonth=null so a 上月 line is unrepresentable, not runtime-gated (D-E1, Pitfall 2)"
    - "Pill-tab local state via inner StatefulWidget — tab switch changes rendered series only, never re-watches the provider (D-12)"

key-files:
  created:
    - lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart
    - lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
    - test/widget/features/analytics/presentation/widgets/within_month_cumulative_line_chart_test.dart
    - test/widget/features/analytics/presentation/widgets/cards/within_month_trend_card_test.dart
  modified:
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/generated/app_localizations*.dart

key-decisions:
  - "Joy cross-period guard is STRUCTURAL: the joy tab sets previousMonth=null and the model has no previousMonthJoy field, so the dashed 上月 series is impossible — not merely hidden (D-E1, Pitfall 2)"
  - "Pill tabs implemented as an inner _TrendBody StatefulWidget (no StateProvider) — local-only state, no provider re-watch on tab switch (D-12 rebuild-storm guard)"
  - "Added 4 new l10n keys (title/caption/this-month/last-month) across all 3 ARBs rather than reuse mismatched donut/six-month keys; tab labels reuse existing analyticsKpiTotalLabel/daily/joy"
  - "Card NOT registered — 46-07 owns the registry edit; withinMonthTrendRefreshTargets is exported ready for the registry union"

patterns-established:
  - "LineChart series-color passed in by the card (seriesColor) rather than resolved in the chart widget — keeps the chart palette-agnostic and tab-driven; 上月 reference = Color.lerp(seriesColor, palette.card, 0.55)"

requirements-completed: [OVW-02, REDES-03]

# Metrics
duration: 18min
completed: 2026-06-17
---

# Phase 46 Plan 04: Within-Month Spend-Trend Card Summary

**Within-month per-day-cumulative spend LineChart (round-5 B card #1) with 总支出/日常/悦己 pill tabs — spend tabs draw 本月 solid + 上月 dashed dual lines, the 悦己 tab draws a structurally-single 本月 line with zero cross-period (D-E1, ADR-012 Pitfall 2).**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-06-17T10:00:00Z
- **Completed:** 2026-06-17T10:18:00Z
- **Tasks:** 2 (both TDD)
- **Files modified:** 8 (2 lib widgets, 2 tests, 3 ARBs + generated l10n)

## Accomplishments

- `WithinMonthCumulativeLineChart` — the first `LineChart` in `lib/`. Builds 1 series (joy) or 2 series (spend: 本月 solid `isStrokeCapRound` + 上月 `dashArray [4,4]`), palette-colored via the passed `seriesColor`, hidden grid/axes/touch, empty-safe placeholder.
- `WithinMonthTrendCard` — single-provider `ConsumerWidget` mirroring the donut card contract: watches `withinMonthCumulativeTrendProvider` (trendAnchor-keyed, D-12), loading → `SizedBox(height: 280)`, error → `AnalyticsCardErrorState` retrying `targets.single`.
- Pill tabs (总支出 / 日常 / 悦己) as local `_TrendBody` state; the 悦己 tab passes `previousMonth = null` so the joy chart can never carry a 上月 line.
- `withinMonthTrendRefreshTargets(ctx)` exported as the single source for the (future 46-07) registry union and the card's error-retry.
- 4 new l10n keys added across en/ja/zh + regenerated; tab labels reuse existing keys.

## Task Commits

Each task committed atomically (TDD RED folded into the GREEN commit per file):

1. **Task 1: WithinMonthCumulativeLineChart widget** — `5890f20b` (feat)
2. **Task 2: WithinMonthTrendCard + pill tabs + refreshTargets** — `b2e34217` (feat)

**Plan metadata:** (this commit) docs(46-04)

_Note: l10n ARB + gen-l10n changes are bundled into the Task 1 commit (the chart widget is the first consumer of the new trend keys)._

## Files Created/Modified

- `lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart` — fl_chart 1.2.0 LineChart; 1/2 series; structural single-vs-dual guard.
- `lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart` — card + pill tabs + `withinMonthTrendRefreshTargets`.
- `test/.../within_month_cumulative_line_chart_test.dart` — 5 tests (dual/single series, dashed/solid, palette color, empty-safe, empty-prev guard).
- `test/.../cards/within_month_trend_card_test.dart` — 6 tests (data render, tab switching, joy single-line guard, loading 280, error retry).
- `lib/l10n/app_{en,ja,zh}.arb` + `lib/generated/app_localizations*.dart` — 4 new keys.

## Decisions Made

See `key-decisions` frontmatter. Core: the joy single-line property is enforced by construction (null `previousMonth` + no `previousMonthJoy` model field), not by a runtime flag, satisfying ADR-012 Pitfall 2 at the type level.

## New l10n keys (for Phase 47 ARB-parity / anti-toxicity sweep)

Added now (all 3 ARBs, en/ja/zh, with `@description`):

| Key | en | ja | zh |
|-----|-----|-----|-----|
| `analyticsCardTitleWithinMonthTrend` | Spending trend | 支出の推移 | 支出趋势 |
| `analyticsCardCaptionWithinMonthTrend` | Cumulative spend by day this month | 今月の日ごとの累計支出 | 本月按天累计支出 |
| `analyticsTrendSeriesThisMonth` | This month | 今月 | 本月 |
| `analyticsTrendSeriesLastMonth` | Last month | 先月 | 上月 |

Note for Phase 47: `analyticsTrendSeriesLastMonth` (上月/先月/Last month) is a SPEND-side-only string — it is rendered only behind the `previous != null && previous.isNotEmpty` legend gate and is never reachable from the 悦己 tab. The anti-toxicity sweep should treat the cross-period vocabulary as the ADR-012 §4 recorded spend-side exception, not a joy-side violation.

## Deviations from Plan

None — plan executed exactly as written. Both tasks followed the prescribed TDD flow (RED widget tests → GREEN implementation) and the donut-card single-source contract.

## Issues Encountered

- Test-harness only: an early loading-state override used `Future.delayed`, leaving a pending timer that tripped `!timersPending`. Switched to a never-completing `Completer.future` for the loading test and a synchronous throw for the error test. No production-code change.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `WithinMonthTrendCard` + `withinMonthTrendRefreshTargets` are built and exported but **NOT registered** — 46-07 owns the registry re-order/insert and will add this card at the top of the round-5 B flat 5-card list, wiring `withinMonthTrendRefreshTargets` into the `_refresh` union.
- The STATE.md 46-07 sequencing blocker (6-month trend presentation consumers) is unaffected by this plan — this plan added only new files, deleted nothing.
- Full `flutter test` suite: **2949/2949 green** (Wave-2 integration gate); `flutter analyze` 0 issues.

## Self-Check: PASSED

- All 4 created files exist on disk.
- Both task commits (`5890f20b`, `b2e34217`) present in git history.

---
*Phase: 46-cards*
*Completed: 2026-06-17*

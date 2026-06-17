---
phase: 46-cards
plan: 05
subsystem: ui
tags: [flutter, riverpod, analytics, custom-widget, gridview, stacked-bar, adr-012, joy-ledger]

# Dependency graph
requires:
  - phase: 46-02
    provides: joyCategoryAmountsProvider (per-L1 joy AMOUNT) + perDayJoyCountsProvider (per-day joy COUNT); JoyCategoryAmount + PerDayJoyCount domain models; their use cases over findByBookIds(joy)
  - phase: 45-presentation-shell-rebuild
    provides: AnalyticsCardContext + AnalyticsCardSpec single-source registry; <card>RefreshTargets(ctx) contract; AnalyticsDataCard shell
  - phase: 46-06
    provides: ListTransactionTile readOnly flag (D-B3 reuse); category_donut_card single-source ConsumerWidget skeleton
provides:
  - "JoySpendStackedBar — custom horizontal Row+Flexible(flex:amount) segmented bar (R-1, GATE-04, zero fl_chart) + single-column legend + tap-highlight"
  - "JoySpendCard — ConsumerWidget watching joyCategoryAmountsProvider; 悦己 header total TweenAnimationBuilder count-up (D-D2 anchor #2); empty-safe; joySpendRefreshTargets"
  - "JoyCalendarHeatmap — custom 7-column GridView month grid (R-2, GATE-04, zero fl_chart); cell depth = continuous f(per-day joy COUNT) ambient (NOT streak)"
  - "JoyCalendarCard — ConsumerWidget watching perDayJoyCountsProvider; tap-day INLINE AnimatedSize expansion (D-C1) reading joyDayTransactionsProvider; joyCalendarRefreshTargets"
  - "joyDayTransactionsProvider — day-scoped findByBookIds(joy) read for the calendar inline expansion (count model stays count-only)"
affects: [46-07, 47-validation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Custom non-fl_chart ambient chart widgets (Row+Flexible stacked bar; GridView color-depth heatmap) — GATE-04 mandate honored"
    - "Pure-UI segment/cell contract: the card pre-resolves localized label + formatted ¥ + color; the widget never fetches/localizes/formats (mirrors donut legend-row contract)"
    - "Inline (in-place AnimatedSize) day expansion as a calm one-shot grow — D-C1/D-D1, no sheet/route, no loop/glow/pulse"
    - "Day-scoped on-demand read provider for inline detail, keeping the aggregate count model count-only (T-46-05-01 narrow-window read)"

key-files:
  created:
    - lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart
    - lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart
    - lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart
    - lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart
    - test/widget/features/analytics/presentation/widgets/cards/joy_spend_card_test.dart
    - test/widget/features/analytics/presentation/widgets/cards/joy_calendar_card_test.dart
  modified:
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb

key-decisions:
  - "Calendar inline-expand data path = new joyDayTransactionsProvider (day-scoped findByBookIds(joy) over the tapped day's whole-day window) rather than widening the count model — keeps perDayJoyCounts count-only (D-C1) and passes only the active book + tapped day to findByBookIds (T-46-05-01)"
  - "Joy-spend bar segment hues lerp WITHIN the joy family (palette.joy → palette.joyLight), avoiding the daily-green/shared-blue cross-ledger gradient the donut uses — every segment reads as 悦己 spend (README data-correction)"
  - "Read-only inline day list reuses ListTransactionTile(readOnly:true) with the drill-screen's pre-formatting contract (D-B3) — no new tile variant"
  - "Heatmap GridView uses childAspectRatio 1.3 (wider-than-tall cells) to keep the 6-row month grid compact inside the analytics scroll"

patterns-established:
  - "Custom ambient f(value)→color widget pair (Color.lerp in joy family) for both the bar segments and the calendar cells — ADR-016 §5 continuous, explicitly NOT a streak"
  - "Tap-highlight as pure local StatefulWidget state (selectedIndex / selectedDay) — no navigation, no provider invalidation (D-C2/D-C1)"

requirements-completed: [JOY-01, JOY-02, REDES-03]

# Metrics
duration: ~30min
completed: 2026-06-17
---

# Phase 46 Plan 05: 悦己花在哪 stacked bar + 小确幸日历 heatmap Summary

**Two CUSTOM non-fl_chart joy cards (R-1 Row+Flexible stacked bar with count-up header + R-2 GridView calendar heatmap with inline day expansion) — ambient celebrate-past surfaces consuming the 46-02 joy providers, GATE-04 clean.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-06-17T~09:50Z
- **Completed:** 2026-06-17T10:20Z
- **Tasks:** 2 (both TDD)
- **Files modified:** 10 (4 widgets/cards created, 2 tests created, 1 provider + 3 ARB modified)

## Accomplishments
- **悦己花在哪 (R-1):** custom `Row` of `Flexible(flex: amount)` segments largest→smallest (zero fl_chart) + single-column legend; tap a segment/legend-row → local segment + legend highlight (no drill, D-C2); 悦己 header total count-up via `TweenAnimationBuilder` ~480ms (D-D2 anchor #2); empty-safe.
- **小确幸日历 (R-2):** custom 7-column `GridView` month grid (zero fl_chart) with correct weekday offset + month day count; cell depth = continuous `f(per-day joy COUNT)` via `Color.lerp` (ADR-016 §5 ambient, explicitly NOT a streak); tap-day → INLINE `AnimatedSize` expansion in place (D-C1, no sheet/route) showing the day's read-only joy list; 0-joy day → neutral inline copy.
- Both cards mirror the donut/ trend single-source `ConsumerWidget` + `*RefreshTargets` contract; both auto-dispose; zero `home/*`.
- Full suite **2963/2963 green** (incl. anti_toxicity, hardcoded_cjk_ui_scan, import_guard, registry, home_screen_isolation); `flutter analyze` 0 issues.

## Task Commits

Each task was committed atomically (TDD RED folded into the single GREEN commit per task — failing test authored first, then implementation):

1. **Task 1: 悦己花在哪 stacked-bar widget + joy_spend_card** - `8f1665c0` (feat)
2. **Task 2: 小确幸日历 heatmap widget + joy_calendar_card** - `15fb684d` (feat)

**Plan metadata:** committed separately at plan close (docs).

## Files Created/Modified
- `lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart` - Custom Row+Flexible stacked bar (R-1) + legend + tap-highlight (`JoySpendStackedBar` + `JoySpendStackedBarState` + `JoySpendSegment`)
- `lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart` - `JoySpendCard` ConsumerWidget + count-up header + `joySpendRefreshTargets`
- `lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart` - Custom GridView month heatmap (R-2), f(count)→color ambient (`JoyCalendarHeatmap`)
- `lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart` - `JoyCalendarCard` ConsumerWidget + inline AnimatedSize day expansion + `joyCalendarRefreshTargets`
- `lib/features/analytics/presentation/providers/state_analytics.dart` - Added `joyDayTransactions` provider (day-scoped joy read for the inline panel)
- `lib/l10n/app_{en,ja,zh}.arb` - 7 new l10n keys (see New l10n Keys below)
- `test/.../cards/joy_spend_card_test.dart` + `joy_calendar_card_test.dart` - 14 widget tests total (7 each)

## New l10n Keys (for Phase 47 ARB parity / anti-toxicity sweep)

All added to **all three** ARB files (en/ja/zh) and `flutter gen-l10n` run. All copy is anti-toxicity clean (no ranking/streak/goal/red-deficit framing — celebrate-past descriptive):

| Key | en | Purpose |
|-----|----|----|
| `analyticsCardTitleJoySpend` | "Joy · Where it went" | 悦己花在哪 card title |
| `analyticsCardCaptionJoySpend` | "How your joy spending breaks down" | bar caption |
| `analyticsJoySpendHeaderLabel` | "Joy spend" | count-up header label |
| `analyticsJoySpendEmpty` | "No joy spending in this window yet" | empty-state (neutral) |
| `analyticsCardTitleJoyCalendar` | "Little joys · Calendar" | 小确幸日历 card title |
| `analyticsCardCaptionJoyCalendar` | "The texture of your joyful days" | heatmap caption |
| `analyticsJoyCalendarDayEmpty` | "No little joys recorded this day" | inline 0-joy day copy |

Phase 47 note: these 7 keys should join the `anti_toxicity_*_test` forbidden-substring sweep across all three locales/states.

## Decisions Made
- **Calendar inline-expand data path:** chose a NEW `joyDayTransactionsProvider` (day-scoped `findByBookIds(ledgerType: joy)` over the tapped day's whole-day window, D-12 normalized) over widening the count model — keeps `perDayJoyCounts` count-only (D-C1) and passes only the active book + the single tapped day to `findByBookIds` (T-46-05-01 mitigation). Auto-dispose, zero `home/*`.
- **Joy-spend segment colors:** lerp WITHIN the joy family (`palette.joy → palette.joyLight`) rather than the donut's daily-green→joy cross-ledger ramp — every segment reads as 悦己 spend (README sakura-anchored data-correction).
- **Read-only inline tile:** reuse `ListTransactionTile(readOnly: true)` with the drill-screen's pure-UI pre-formatting contract (D-B3) — no new tile variant.

## Deviations from Plan

None requiring auto-fix rules. Two test-harness adjustments made during TDD GREEN (not production deviations):
- Joy-spend Test 2 taps the full-width legend row (which routes to the same `_onSegmentTap`) instead of the narrow ~14px flex-1200 segment, which is too thin to hit-test reliably. Behavior identical; the segment's own tap is still wired and exercised by the wider segments.
- Joy-calendar test wraps the card in a `SingleChildScrollView` (matching production — the card lives inside the analytics scroll) so the 6-row month grid + inline panel does not overflow the bare 800px test surface. Heatmap `childAspectRatio` set to 1.3 to keep the grid compact.

**Total deviations:** 0 deviation-rule fixes. **Impact:** none — plan executed as written; both surfaces custom (GATE-04), both consume the 46-02 providers, copy anti-toxicity clean.

## Issues Encountered
- Initial `flutter pub run build_runner build` regenerated `repository_providers.g.dart` (a stale doc-comment from the 46-02 deviation that reworded the source `getDailyTotals` reference). Committed the regenerated `.g.dart` with Task 1 to keep generated files in sync (CLAUDE.md pitfall 3/13). No functional change.

## Cards NOT Registered (46-07 owns the registry)
Per the plan, the four new symbols are built but NOT added to `analyticsCardRegistry`. `joySpendRefreshTargets` and `joyCalendarRefreshTargets` are exported in the donut-card shape, ready for 46-07 to wire into the round-5 B flat 5-card order (within_month_trend → category_donut → **joy_spend → joy_calendar** → satisfaction_histogram → [family_insight group-only]).

## Threat Flags
None. The only new surface is `joyDayTransactionsProvider`, which is in the plan's `<threat_model>` (T-46-05-01/02): it passes only the active book + the tapped day to `findByBookIds`, renders the book's own joy rows only, and never logs tx contents.

## Next Phase Readiness
- Round-5 B cards #3 (悦己花在哪) and #4 (小确幸日历) are built, tested, and GATE-04-clean — Wave 3 complete.
- 46-07 can now re-order the registry to the round-5 B flat 5-card lineup and add these two specs.
- Phase 47: add the 7 new l10n keys to the anti-toxicity sweep; author macOS goldens for both new cards from scratch.

## Self-Check: PASSED
- `joy_spend_stacked_bar.dart`, `joy_spend_card.dart`, `joy_calendar_heatmap.dart`, `joy_calendar_card.dart` — all exist on disk.
- Commits `8f1665c0` + `15fb684d` exist in `git log`.
- Full `flutter test` suite 2963/2963; `flutter analyze` 0 issues; zero fl_chart import in all 4 new files.

---
*Phase: 46-cards*
*Completed: 2026-06-17*

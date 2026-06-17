---
phase: 46-cards
plan: 06
subsystem: analytics
tags: [flutter, riverpod, fl_chart, analytics, donut, histogram, drill-down, read-only, anti-gamification]

# Dependency graph
requires:
  - phase: 44-data-use-case-additions-reuse-first
    provides: "categoryDrillDownProvider + GetCategoryDrillDownUseCase (read-only, expense-only, auto-dispose); category_l1_rollup helper (rollupCategoryBreakdownsToL1, D-11 single source)"
  - phase: 45-presentation-shell-rebuild
    provides: "AnalyticsCardContext + categoryDonutRefreshTargets single-source pattern; CategoryDonutCard verbatim-moved host; selectedTimeWindowProvider keepAlive session window (D-C1)"
provides:
  - "CategoryDrillDownScreen — pushed READ-ONLY drill route (subtotal/count/日均 neutral header + read-only ListTransactionTile list)"
  - "ListTransactionTile.readOnly flag — suppresses the swipe-to-delete wrapper + tap-to-edit; shared _buildRow body keeps the List tab byte-identical"
  - "CategoryDonutCard hero rebuild — 10 L1-rollup tappable legend rows → drill push (D-B1) + TweenAnimationBuilder count-up center total (D-D2)"
  - "Native histogram BarChartRodData.label (Stack/Align/DecoratedBox 5-annotation hack deleted, REDES-02)"
  - "analyticsCategoriesMapProvider — {id->Category} map for the donut L1 rollup (reuses categoryRepository.findAll, auto-dispose)"
  - "ja/zh/en ARB keys: analyticsDonutCenterLabel, analyticsDrillSubtotalLabel/CountLabel/AvgPerDayLabel/Empty/LoadError"
affects: [46-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "fl_chart 1.2.0 native per-rod label (BarChartRodLabel) replacing a hand-built Stack/Align overlay annotation"
    - "Read-only tile reuse via a readOnly flag on the shared tile (no new tile variant) — no Dismissible, no-op tap"
    - "Legend-ROW (not pie slice) as the drill affordance (D-B1) — InkWell row → Navigator.push(MaterialPageRoute)"
    - "Single-anchor count-up: only the donut center total animates (TweenAnimationBuilder<int>, ~480ms easeOutCubic); other numbers static (D-D2)"

key-files:
  created:
    - lib/features/analytics/presentation/screens/category_drill_down_screen.dart
    - test/widget/features/analytics/presentation/screens/category_drill_down_screen_test.dart
    - test/widget/features/analytics/presentation/widgets/cards/category_donut_card_test.dart
  modified:
    - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
    - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/features/analytics/presentation/providers/state_analytics.g.dart
    - lib/features/list/presentation/widgets/list_transaction_tile.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
    - lib/generated/app_localizations_en.dart
    - test/widget/features/analytics/presentation/screens/analytics_screen_test.dart
    - test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart

key-decisions:
  - "Histogram native label: only the score-5 rod carries a visible BarChartRodLabel(show:true, text: l10n.analyticsHistogramBarFiveAnnotation, offset Offset(0,-4)); all other rods BarChartRodLabel(show:false). The l10n key + the score-5 placement are preserved; the widget ValueKey could not survive (a canvas-painted label carries no widget key), so the test now asserts the rod label text instead of a keyed widget."
  - "Read-only drill list = ListTransactionTile + new readOnly flag (planner discretion: reuse over a new tile variant). The tile previously always wrapped itself in a Dismissible; readOnly:true renders the shared _buildRow directly (no Dismissible, no GestureDetector, no chevron). List tab path unchanged (readOnly defaults to false)."
  - "Drill list sort = provider's time-descending order (D-B2 permits amount-desc or time-desc; the mock shows a chronological list, kept time-desc). showDate:true so each read-only row shows its date."
  - "Donut categoryMap source = new analyticsCategoriesMapProvider over categoryRepository.findAll() (the same repo the drill use case reads). While it loads, the card falls back to an empty map so the donut + count-up still render; rows resolve once it settles."
  - "Drill screen reads selectedTimeWindowProvider directly for the window range (D-C1 keepAlive session) — only bookId + l1CategoryId are threaded through the route."

patterns-established:
  - "readOnly tile flag: a shared tile gains a descriptive read-only mode by gating its Dismissible/tap wrappers behind one bool; row body extracted to a private _buildRow(showChevron:) shared by both modes"
  - "Donut hero: PieChart (cornerRadius:4) with an empty-title sections list + a Stack-centered Column overlay carrying the count-up total; the legend below is the interactive surface (rows), not the chart"

requirements-completed: [REDES-02, DRILL-01, OVW-02]

# Metrics
duration: ~50min
completed: 2026-06-17
---

# Phase 46 Plan 06: Donut Hero + Histogram Native Label + Read-Only Drill Summary

**Rebuilt round-5 B cards #2 (donut) and #5 (histogram) and added the read-only category drill route: the histogram drops its Stack/Align/DecoratedBox "5" hack for fl_chart 1.2.0's native `BarChartRodData.label`; the donut renders 10 single-source L1-rollup legend rows where each ROW (not the slice) pushes the new read-only `CategoryDrillDownScreen`, with a `TweenAnimationBuilder` count-up center total; the drill screen is a pushed, read-only transaction list (no swipe-delete, no tap-edit) under a neutral subtotal/count/日均 header.**

## What Was Built

### Task 1 — Histogram native label (REDES-02), commit `897235cd`
- Deleted the `Stack` + `Align` + `DecoratedBox` "5" annotation overlay (the old `satisfaction_distribution_histogram.dart:35-138` region). The `BarChart` now renders directly inside the `SizedBox`.
- The 中央値・含未評価 annotation moved onto the **native `BarChartRodData.label`** of the score-5 rod (`BarChartRodLabel(show: true, text: l10n.analyticsHistogramBarFiveAnnotation, style: …joy/w700, offset: Offset(0, -4))`); every other rod gets `const BarChartRodLabel(show: false)`.
- `_normalize`, `_colorForScore`, `_semanticLabel` kept byte-identical (regression guards green).
- Verified `BarChartRodData.label` / `BarChartRodLabel` shape against the installed `fl_chart-1.2.0` source (Assumption A3 resolved).

### Task 2 — Read-only `CategoryDrillDownScreen` (DRILL-01 UI, D-B1/B2/B3), commit `abf355a1`
- New `ConsumerWidget(bookId, l1CategoryId)` that reads the window from `selectedTimeWindowProvider` (keepAlive session, D-C1) and watches `categoryDrillDownProvider(bookId, startDate, endDate, l1CategoryId)`.
- Header = subtotal (`amountMedium`) + count + 日均 (`avgPerDay`, hidden when null) — three neutral descriptive cells (D-B2, ADR-012-safe; no targets/ranking/cross-period copy).
- Body = `ListView.separated` of **read-only** `ListTransactionTile` rows. Added a `readOnly` flag to the shared tile that skips the `Dismissible` swipe wrapper + tap-to-edit; drill passes no-op callbacks. Tile row body extracted into a shared `_buildRow(showChevron:)` so the List tab is byte-identical.
- Loading/error/empty states all safe. Pre-formatting (tag/colors/category/amount/foreign annotation/L1 icon/satisfaction) replicated from `list_screen.dart`.
- New ja/zh/en ARB header/empty/error keys + `gen-l10n`.

### Task 3 — Donut hero rebuild (D-B1/D-D2/D-11), commit `e000b623`
- `CategoryDonutCard` keeps its `monthlyReportProvider` watch + `categoryDonutRefreshTargets` single source unchanged; adds an `analyticsCategoriesMapProvider` watch for the `{id->Category}` map.
- Legend = **10 L1-rollup rows** via `rollupCategoryBreakdownsToL1(breakdowns, categoryMap, topN: 10)` (D-11 single source), amount-descending; each row keyed `donut_legend_row_<l1Id>`, fully tappable (`InkWell`) → `Navigator.push(MaterialPageRoute → CategoryDrillDownScreen(bookId, l1CategoryId))` (D-B1 — the row, never a slice).
- Donut center 本月支出 total wrapped in `TweenAnimationBuilder<int>` count-up (0→total, ~480ms `easeOutCubic`, D-D2 anchor #1); other numbers static. `PieChartSectionData.cornerRadius: 4` (REDES-02 polish).
- New auto-dispose `analyticsCategoriesMapProvider` reuses `categoryRepository.findAll()` (no new DAO, zero `home/*`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `analytics_screen_test.dart` asserted the deleted donut child widget**
- **Found during:** Task 3
- **Issue:** The screen test asserted `find.byType(CategorySpendDonutChart)` (lines 168, 185). The rebuilt `CategoryDonutCard` renders the new `_DonutHero` and no longer instantiates `CategorySpendDonutChart`, so those assertions would fail.
- **Fix:** Updated both assertions to `find.byType(CategoryDonutCard)` and swapped the stale import. The donut card is still registered and renders; the assertion target moved up one level.
- **Files modified:** `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart`
- **Commit:** `e000b623`

**2. [Rule 1 - Bug] Histogram annotation `ValueKey` could not survive on a canvas-painted label**
- **Found during:** Task 1
- **Issue:** The plan's truth said the `ValueKey('analytics_histogram_bar_5_annotation')` should "still be findable (now on the native label)". A native `BarChartRodLabel` is painted on the chart canvas and carries no Flutter widget key, so a keyed-widget finder is impossible.
- **Fix:** Preserved the **l10n string + the score-5 placement** (the load-bearing semantics) on the native rod label; the rewritten test asserts `barGroups[4].barRods.single.label.text == '中央値・含未評価'` and that only the score-5 rod has `label.show == true`, plus that no `Stack` ancestors the `BarChart` and the old keyed widget is gone.
- **Files modified:** `satisfaction_distribution_histogram.dart`, `satisfaction_distribution_histogram_test.dart`
- **Commit:** `897235cd`

### Cleanup commit `62c3fbd3` (chore)
- Reworded drill-screen doc comments so the literal word `Dismissible` appears nowhere in `category_drill_down_screen.dart` — keeps the read-only verification grep (`! grep -q "Dismissible"`) unambiguous (the only remaining match was in a doc comment).
- Removed an unused `_subject(override:)` test param + stale `flutter_riverpod` import.

## Threat Model Adherence
- **T-46-06-01/03 (book-set scope):** drill screen passes only `bookId` into `categoryDrillDownProvider`; the Phase-44 use case never widens the book set. No tx contents logged.
- **T-46-06-02 (tampering / read-only):** no write path — `readOnly` tile has no `Dismissible` and a no-op tap; verified by test "no Dismissible in the subtree" + "tapping a tile pushes nothing".
- **T-46-06-04 (ADR-012 integrity):** header is subtotal + count + 日均 only; test asserts no 目標/達成/ranking/vs/上月/先月/target strings. Full-suite `anti_toxicity_*` green.

## Verification
- Plan trio green: `satisfaction_distribution_histogram_test.dart` (7), `category_donut_card_test.dart` (4), `category_drill_down_screen_test.dart` (6).
- `grep -q "Stack(" satisfaction_distribution_histogram.dart` → false (hack removed).
- `grep -q "Dismissible" category_drill_down_screen.dart` → false (read-only).
- Donut card contains `rollupCategoryBreakdownsToL1` + `Navigator`.
- `flutter analyze` (whole project) — **0 issues**.
- **FULL `flutter test` — 2928/2928 passed** (per-wave gate: anti_toxicity, ADR-017 grep-ban, hardcoded_cjk_ui_scan, import_guard, registry all green).

## Known Stubs
None — all three surfaces are wired to live providers (`categoryDrillDownProvider`, `monthlyReportProvider`, `analyticsCategoriesMapProvider`, `satisfactionDistributionProvider`).

## Notes for 46-07
- The donut card and drill screen are NOT yet registered/re-ordered into `analyticsCardRegistry` here (46-07 owns the registry re-order). The donut→drill `Navigator.push` is wired directly inside the card (no router config needed — the app uses imperative `Navigator`, not GoRouter; CLAUDE.md is stale on this).
- The existing 46-07 sequencing blocker in STATE.md is preserved (this plan only appended its plan-progress update).

## Self-Check: PASSED
- All 6 declared artifacts exist on disk.
- All 4 commits (`897235cd`, `abf355a1`, `e000b623`, `62c3fbd3`) present in git log.
- Drill screen is 329 lines (min_lines 80 satisfied).

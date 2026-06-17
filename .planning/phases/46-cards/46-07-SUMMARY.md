---
phase: 46-cards
plan: 07
subsystem: ui
tags: [flutter, riverpod, analytics, registry, integration, adr-012, round-5-b]

# Dependency graph
requires:
  - phase: 46-01
    provides: withinMonthCumulativeTrendProvider + within-month trend data; removed total_six_month_card / monthly_spend_trend_bar_chart / Time section header (registry was 9 specs)
  - phase: 46-04
    provides: WithinMonthTrendCard + withinMonthTrendRefreshTargets (built, not registered)
  - phase: 46-05
    provides: JoySpendCard+joySpendRefreshTargets / JoyCalendarCard+joyCalendarRefreshTargets (built, not registered)
  - phase: 46-06
    provides: CategoryDonutCard hero rebuild + categoryDonutRefreshTargets; SatisfactionHistogramCard native rod label; CategoryDrillDownScreen
provides:
  - "analyticsCardRegistry = round-5 B flat 5-card lineup (within_month_trend → category_donut → joy_spend → joy_calendar → satisfaction_histogram) + family_insight group-only conditional (D-F2)"
  - "Thin analytics_screen shell with NO section-header interleave (flat Column of cards + inter-card spacers)"
  - "Dead Variant-δ cards/section-header deleted with zero dangling references (best_joy_card, kpi_hero_card, largest_expense_card, analytics_screen_section_header)"
affects: [47-validation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Registry/test/build move in lockstep (Pitfall 4) — registry re-order + dead-card deletion + 3 test updates in the same plan; full-suite gate catches dangling refs"
    - "De-register (NOT delete): daily_vs_joy_card + per_category_breakdown_card widget files retained (keep own tests) but dropped from the round-5 B lineup + their refreshTargets fns removed from the registry"

key-files:
  created: []
  modified:
    - lib/features/analytics/presentation/analytics_card_registry.dart
    - lib/features/analytics/presentation/screens/analytics_screen.dart
    - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
    - test/widget/features/analytics/presentation/analytics_card_registry_test.dart
    - test/widget/features/analytics/presentation/screens/analytics_screen_test.dart
    - test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart
  deleted:
    - lib/features/analytics/presentation/widgets/cards/best_joy_card.dart
    - lib/features/analytics/presentation/widgets/cards/kpi_hero_card.dart
    - lib/features/analytics/presentation/widgets/cards/largest_expense_card.dart
    - lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart

key-decisions:
  - "The 46-01 STATE.md sequencing blocker was ALREADY RESOLVED: 46-01 deleted total_six_month_card + monthly_spend_trend_bar_chart + the Time section header (registry was 9 specs). 46-07 verified their absence (no re-delete) and completed the remaining 4 deletions."
  - "Section-header ARB keys (analyticsGroupHeaderTime/Distribution/Stories) are now orphaned (zero source consumers) — DEFERRED to Phase 47's ARB sweep per plan (ARB removal needs gen-l10n + force-add of gitignored generated files; low value, high churn). Noted below."
  - "bestJoyMomentProvider / largestMonthlyExpenseProvider providers are RETAINED — bestJoyMomentProvider is consumed by HomeHero (home_screen.dart, main_shell_screen.dart, invalidate_transaction_dependents.dart), so it is NOT a dead-card-unique symbol. Only the 3 card widget files + section header were on the D-A3 hard-delete list."
  - "Sibling tests analytics_no_delta_ui_test + analytics_refresh_group_mode_test needed NO edits — they only override retained providers and assert no-delta / group-refresh intent generically; the new cards self-isolate their (unoverridden) errors so the screen still renders."

patterns-established:
  - "Registry-derived _refresh union stays ⊆ analytics, zero home/* by construction; round-5 B group mode adds EXACTLY FamilyHappinessProvider (the only group-only spec is family_insight)"

requirements-completed: [REDES-02, OVW-02, JOY-01, JOY-02, GUARD-02]

# Metrics
duration: ~35min
completed: 2026-06-17
---

# Phase 46 Plan 07: Round-5 B Registry Integration Summary

**The live analytics screen IS now the round-5 B flat 5-card lineup (within_month_trend → category_donut → joy_spend → joy_calendar → satisfaction_histogram) + the group-only family_insight conditional card — wired through `analyticsCardRegistry`, with the Variant-δ section headers and dead cards deleted (zero dangling references) and the registry/screen/anti-toxicity tests updated in lockstep (Pitfall 4). Full suite 2971/2971 green.**

## What Was Built

### Task 1 — Registry re-order + dead-card deletion + thin shell, commit `cc0b8534`
- `analyticsCardRegistry` replaced with the round-5 B flat lineup: `WithinMonthTrendCard` (withinMonthTrendRefreshTargets) → `CategoryDonutCard` (categoryDonutRefreshTargets) → `JoySpendCard` (joySpendRefreshTargets) → `JoyCalendarCard` (joyCalendarRefreshTargets) → `SatisfactionHistogramCard` (satisfactionHistogramRefreshTargets) → `FamilyInsightDataCard` `isVisible:(ctx)=>ctx.isGroupMode` (D-F1, kept verbatim incl. the null shadowBooks placeholder).
- Removed the `KpiHero`, `DailyVsJoy`, both `PerCategoryBreakdown`, `LargestExpense`, `BestJoy` specs. Removed the `sectionHeaderKey` field from `AnalyticsCardSpec` and every usage (zero `sectionHeaderKey` in the file).
- `analytics_screen.dart`: removed the section-header interleave branch in `_buildCardChildren`, the `_sectionLabel` method, and the `analytics_screen_section_header.dart` import. The body is now a flat Column of visible cards with inter-card `SizedBox(8)` spacers + a trailing `SizedBox(64)`. The `FamilyInsightDataCard` shadowBooks shell-injection (D-F1) and the registry-derived `_refresh` union are unchanged.
- Removed the now-unused `dailyVsJoyRefreshTargets` / `perCategorySoloRefreshTargets` / `perCategoryFamilyRefreshTargets` functions + the `state_ledger_snapshot` import. `daily_vs_joy_card.dart` + `per_category_breakdown_card.dart` widget FILES retained (de-registered, keep their own tests).
- Deleted `best_joy_card.dart`, `kpi_hero_card.dart`, `largest_expense_card.dart`, `analytics_screen_section_header.dart` (`total_six_month_card.dart` + `monthly_spend_trend_bar_chart.dart` were already deleted in 46-01 — verified absent).
- Reworded the donut card's doc-comment that referenced `[KpiHeroCard]` (the only remaining dangling doc-link).
- build_runner clean (52 outputs, none in analytics changed); `flutter analyze lib/` 0 issues.

### Task 2 — Test updates (registry / screen / anti-toxicity), commit `cfb7b1bf`
- `analytics_card_registry_test.dart`: card count 9 → 6 (5 always-visible + 1 group-only); whitelist adds `WithinMonthCumulativeTrendProvider`/`JoyCategoryAmountsProvider`/`PerDayJoyCountsProvider` (old dead-card/de-registered providers kept as "legal" — whitelist = may-appear); visibility test now asserts exactly 1 group-gated spec; group-superset test asserts group adds EXACTLY `FamilyHappinessProvider`; the `(e)` single-source-keys test asserts the 3 new cards' targets (trend/calendar keyed on `trendAnchor`, joy_spend on start/end) + donut + histogram + shell. Dead-card imports swapped for the new cards.
- `analytics_screen_test.dart`: first test now asserts the flat 5-card lineup (`WithinMonthTrendCard`/`CategoryDonutCard`/`JoySpendCard`/`JoyCalendarCard`/`SatisfactionDistributionHistogram`) with no section headers; overrides the 3 new card providers with empty data; dropped the `KpiMiniHeroStrip`/`AnalyticsScreenSectionHeader`/`LargestExpenseStoryCard`/`BestJoyStoryStrip` imports + assertions; the "story cards" tap test replaced with a joy-card empty-path no-throw test.
- `anti_toxicity_phase17_test.dart`: added the 3 new cards (`WithinMonthTrendCard`/`JoySpendCard`/`JoyCalendarCard`) as scanned subjects across ja/zh/en (9 new tests) against the existing forbidden lists — GUARD-02 scan-ready (the full 扫描扩充 is Phase 47).

### Task 3 — Full-suite per-wave gate
- `flutter analyze` (whole project): **0 issues**.
- **FULL `flutter test`: 2971/2971 passed** (up from 2963 — the 8 new anti_toxicity card subjects). Includes anti_toxicity, hardcoded_cjk_ui_scan, import_guard, provider_graph_hygiene, registry-isolation, home_screen_isolation, and ADR-017 grep-ban — all green.
- `grep -rln "density|joyPerYen" lib/` == 0 (single-Joy-expression preserved).
- ADR-017 grep-ban: the only `生存/灵魂` match in analytics is a negated doc-comment in `within_month_cumulative_line_chart.dart` ("no 生存/灵魂", 46-04 file, unchanged here); the architecture grep-ban test passed in the full suite.

## Deviations from Plan

### Resolved-blocker adjustment (not a deviation rule — pre-flight correction)
The STATE.md "46-01 sequencing conflict" blocker was ALREADY RESOLVED by 46-01 (it deleted `total_six_month_card.dart` + `monthly_spend_trend_bar_chart.dart` + the Time section header and removed their specs, leaving 9 registry specs). The plan's `files_modified` still listed those two as deletion targets — they were GONE. Verified absent (no re-delete), completed the remaining 4 deletions. Blocker marked resolved in STATE.md.

### [Rule 3 - Blocking] Donut card dangling doc-link
- **Found during:** Task 1 (post-deletion grep)
- **Issue:** `category_donut_card.dart` had a doc-comment `[KpiHeroCard]` cross-reference that became a dangling dartdoc link after the card deletion.
- **Fix:** Reworded the comment to describe the `monthlyReportProvider` key tuple directly.
- **Commit:** `cc0b8534`

### Scope-boundary note (no fix — retained on purpose)
- `bestJoyMomentProvider` / `largestMonthlyExpenseProvider` providers + the `kpi_mini_hero_strip` / `best_joy_story_strip` / `largest_expense_story_card` helper widgets (with their own tests) were NOT deleted — they are NOT on the D-A3 hard-delete list, and `bestJoyMomentProvider` is consumed by HomeHero. Deleting them is out of Phase 46 scope (same de-register-not-delete nuance as daily_vs_joy/per_category).

## Deferred Items (for Phase 47 ARB sweep)

| Item | Status |
|------|--------|
| Orphaned ARB keys `analyticsGroupHeaderTime` / `analyticsGroupHeaderDistribution` / `analyticsGroupHeaderStories` (zero source consumers after the section-header deletion) | DEFER to Phase 47 — ARB removal needs gen-l10n + force-add of gitignored generated files; plan explicitly permits deferral |
| Full anti-toxicity 扫描扩充 (exhaustive new forbidden lists for the round-5 B card copy + the 7+4 new l10n keys from 46-04/05) | DEFER to Phase 47 (GUARD-03/04) — this plan only registers the new subjects against existing forbidden lists |
| macOS chart golden re-baseline for the new cards | DEFER to Phase 47 (macOS-only) |

## Known Stubs
None — every round-5 B card is wired to a live provider (withinMonthCumulativeTrend, monthlyReport, joyCategoryAmounts, perDayJoyCounts, happinessReport+satisfactionDistribution, familyHappiness). The de-registered daily_vs_joy/per_category widgets retain their providers and tests.

## Threat Model Adherence
- **T-46-07-01 (isolation integrity):** the registry imports zero `home/*` providers; the union test asserts ⊆ analytics + zero home/*; `home_screen_isolation_test.dart` green in the full suite.
- **T-46-07-02 (build coherence):** dead cards + their registry refs + their test assertions removed in the same change (Pitfall 4); the full-suite gate caught zero dangling refs.
- **T-46-07-03 (new card copy):** `anti_toxicity_phase17` now scans the 3 new card subjects (ja/zh/en) — no forbidden value-judgment/comparison substrings.
- **T-46-07-SC:** N/A — zero new packages this phase.

## Self-Check: PASSED
- Deleted files confirmed absent: best_joy_card.dart, kpi_hero_card.dart, largest_expense_card.dart, analytics_screen_section_header.dart.
- `sectionHeaderKey` count in registry = 0.
- Commits `cc0b8534` + `cfb7b1bf` present in git log.
- `analyticsCardRegistry.length` == 6 (asserted by the registry test).
- Full `flutter test` 2971/2971; `flutter analyze` 0 issues.

---
*Phase: 46-cards*
*Completed: 2026-06-17*

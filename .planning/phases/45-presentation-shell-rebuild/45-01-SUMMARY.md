---
phase: 45-presentation-shell-rebuild
plan: 01
subsystem: ui
tags: [riverpod, flutter, analytics, card-registry, refactor]

# Dependency graph
requires:
  - phase: 44-data-use-case-additions-reuse-first
    provides: locked analytics provider graph (monthlyReport/expenseTrend/happinessReport/satisfactionDistribution families, all auto-dispose)
provides:
  - "widgets/cards/analytics_data_card.dart — public AnalyticsDataCard shared title/caption/child shell (was _AnalyticsDataCard)"
  - "widgets/cards/kpi_hero_card.dart — public KpiHeroCard ConsumerWidget + kpiHeroRefreshTargets(ctx)"
  - "widgets/cards/total_six_month_card.dart — public TotalSixMonthCard ConsumerWidget + totalSixMonthRefreshTargets(ctx)"
  - "widgets/cards/category_donut_card.dart — public CategoryDonutCard ConsumerWidget + categoryDonutRefreshTargets(ctx)"
  - "widgets/cards/satisfaction_histogram_card.dart — public SatisfactionHistogramCard ConsumerWidget (async self-hide D-B5) + satisfactionHistogramRefreshTargets(ctx)"
  - "analytics_card_registry.dart — minimal AnalyticsCardContext stub (Plan 03 fills the registry list around it)"
affects: [45-02, 45-03, 45-04, 45-05, 46-presentation-shell-content]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single-source <card>RefreshTargets(AnalyticsCardContext) reused by build + error-retry + (future) registry union (D-B2 / 卡就是契约)"
    - "Byte-faithful structural extraction: move inline _*Card bodies verbatim, de-privatise class name, add super.key only (D-A1)"
    - "Card files import only analytics providers/widgets — physical home/* isolation source (D-B3 backing)"

key-files:
  created:
    - lib/features/analytics/presentation/widgets/cards/analytics_data_card.dart
    - lib/features/analytics/presentation/widgets/cards/kpi_hero_card.dart
    - lib/features/analytics/presentation/widgets/cards/total_six_month_card.dart
    - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
    - lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart
    - lib/features/analytics/presentation/analytics_card_registry.dart
  modified: []

key-decisions:
  - "Created the minimal AnalyticsCardContext stub in analytics_card_registry.dart (Plan 01) so Wave-1 cards compile independently; Plan 03 fills the registry list around the already-present context class (no duplication)."
  - "refreshTargets return type is List<ProviderBase<Object?>> (ProviderBase from flutter_riverpod/misc.dart, per RESEARCH); concrete Riverpod-3 $FutureProvider instances are covariantly assignable."
  - "For multi-error-branch cards (KpiHero, SatisfactionHistogram), the typed ref.watch stays byte-faithful while the two error retries invalidate elements of the locally-built *RefreshTargets(_ctx()) list (targets[0]/targets[1]) — single source without sacrificing static typing."

patterns-established:
  - "Pattern 1: each card builds a local _ctx() AnalyticsCardContext from its own fields, so build-watched keys and refreshTargets keys derive from ONE field set (no drift, satisfies a future Plan-05 keys-match assertion)."
  - "Pattern 2: single-target cards retry via targets.single; multi-target cards retry via positional targets[n]."

requirements-completed: [REDES-01]

# Metrics
duration: 22min
completed: 2026-06-17
---

# Phase 45 Plan 01: Card-layer extraction Summary

**Extracted the shared AnalyticsDataCard shell + KpiHero/TotalSixMonth/CategoryDonut/SatisfactionHistogram cards verbatim from the 739-LOC analytics_screen.dart monolith into public ConsumerWidgets under widgets/cards/, each with a single-source `<card>RefreshTargets(ctx)` (D-B2) and the SatisfactionHistogram async self-hide preserved in-card (D-B5).**

## Performance

- **Duration:** ~22 min
- **Started:** 2026-06-17T05:31Z
- **Completed:** 2026-06-17T05:53Z
- **Tasks:** 3
- **Files created:** 6 (5 card files + 1 registry stub)

## Accomplishments
- Promoted `_AnalyticsDataCard` → public `AnalyticsDataCard` shared shell (14px/12px/4px chrome byte-faithful).
- Extracted 4 inline cards (`KpiHeroCard`, `TotalSixMonthCard`, `CategoryDonutCard`, `SatisfactionHistogramCard`) as public `ConsumerWidget`s — `.when` logic moved verbatim, no copy/color/spacing change.
- Established the phase-wide `AnalyticsCardContext` contract (minimal stub now; Plan 03 fills the registry list) and the single-source `<card>RefreshTargets(ctx)` pattern reused by each card's error-retry.
- `SatisfactionHistogramCard` keeps its `report.totalJoyTx < 5 → SizedBox.shrink()` self-hide inside the `happinessAsync.when` data branch (D-B5), with `refreshTargets` returning both providers unconditionally.

## Task Commits

1. **Task 1: Promote AnalyticsDataCard shell + AnalyticsCardContext stub** - `add8746f` (feat)
2. **Task 2: Extract KpiHero + TotalSixMonth + CategoryDonut cards** - `7b50b996` (feat)
3. **Task 3: Extract SatisfactionHistogramCard (async self-hide D-B5)** - `377bfba2` (feat)

_(Plan metadata commit follows this SUMMARY.)_

## Files Created/Modified
- `lib/features/analytics/presentation/analytics_card_registry.dart` - Minimal `AnalyticsCardContext` (8 fields) so Wave-1 cards compile; Plan 03 fills `AnalyticsCardSpec` + registry list.
- `lib/features/analytics/presentation/widgets/cards/analytics_data_card.dart` - Shared `Card`→`Padding(14)`→`Column` title/caption/child shell.
- `lib/features/analytics/presentation/widgets/cards/kpi_hero_card.dart` - Two-provider nested `.when` KPI strip; `kpiHeroRefreshTargets` → [monthlyReport, happinessReport].
- `lib/features/analytics/presentation/widgets/cards/total_six_month_card.dart` - `expenseTrendProvider` keyed on `trendAnchor`; renders trend bar chart in shared shell.
- `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart` - `monthlyReportProvider` (same key tuple as KpiHero → dedupe in shell union); donut chart in shared shell.
- `lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart` - Nested `.when` + in-card async self-hide; both providers in refreshTargets.

## Decisions Made
- **AnalyticsCardContext stub location:** placed in `analytics_card_registry.dart` (not duplicated per-card), per Task 1's explicit "create the minimal stub if Plan 03 hasn't landed" instruction. Plan 03 will add `AnalyticsCardSpec` + the const registry list + `buildAnalyticsCardContext` around it.
- **refreshTargets typing:** `List<ProviderBase<Object?>>` with `ProviderBase` imported from `flutter_riverpod/misc.dart` (the type RESEARCH recommends and `anti_toxicity_phase16_test` already uses). Verified `flutter analyze` clean — Riverpod 3 `$FutureProvider` instances are covariantly assignable to `ProviderBase<Object?>`.
- **Multi-error-branch single-source:** for `KpiHeroCard` and `SatisfactionHistogramCard` (two distinct `.when` error branches retrying two distinct providers), the typed `ref.watch(provider(...))` stays byte-faithful for goldens, and the error retries invalidate `targets[0]`/`targets[1]` from the locally-built `*RefreshTargets(_ctx())` list — keeping single-source without losing static typing.

## Deviations from Plan

None - plan executed exactly as written. The two minor adjustments below were anticipated by the plan text itself, not deviations:
- Created the `AnalyticsCardContext` stub (Task 1 explicitly directs this when Plan 03 hasn't landed).
- Added a `state_analytics.dart` import to `satisfaction_histogram_card.dart` because `satisfactionDistributionProvider` lives in `state_analytics`, not `state_happiness` (the analog screen imports both). Caught and fixed via `flutter analyze` before committing Task 3.

## Issues Encountered
- Initial registry import path was wrong (`../../../../analytics/presentation/...` instead of `../../...`); fixed before any commit. `satisfactionDistributionProvider` undefined error (wrong source file assumption) — resolved by adding the `state_analytics.dart` import. Both caught by `flutter analyze` prior to commit; neither reached a commit.

## Note on success-criteria LOC
`kpi_hero_card.dart` (124 LOC) and `satisfaction_histogram_card.dart` (125 LOC) slightly exceed the "≤100 LOC" guideline in the plan's success criteria. The overage is docstrings + the `_ctx()` helper + the top-level `*RefreshTargets` function; the widget bodies are faithful moves. All files are far under the project 400-LOC card ceiling and 800-LOC hard max.

## Next Phase Readiness
- Plan 02 (the remaining 3 cards: largest_expense, best_joy, family_insight) can follow the same extraction + single-source refreshTargets pattern.
- Plan 03 can build the `AnalyticsCardSpec` registry against these real public classes and the already-present `AnalyticsCardContext`.
- Plan 04 will delete the inline `_*Card` copies from `analytics_screen.dart` and wire the shell to the registry. **The inline copies remain in `analytics_screen.dart` this plan (by design) — the shell still compiles against them.**
- No blockers.

## Self-Check: PASSED
- All 6 created files exist on disk (verified).
- All 3 task commits present in git log (`add8746f`, `7b50b996`, `377bfba2`).
- `flutter analyze lib/features/analytics/` → 0 issues.
- anti_toxicity_phase16 + anti_toxicity_phase17 + analytics_no_delta_ui → 36/36 green.

---
*Phase: 45-presentation-shell-rebuild*
*Completed: 2026-06-17*

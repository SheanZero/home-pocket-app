---
phase: 45-presentation-shell-rebuild
plan: 05
subsystem: ui
tags: [riverpod, flutter, analytics, card-registry, test, structural-invariant, home-isolation, guard-01]

# Dependency graph
requires:
  - phase: 45-presentation-shell-rebuild
    plan: 03
    provides: "analytics_card_registry.dart — AnalyticsCardSpec, ordered analyticsCardRegistry (10 specs), AnalyticsCardContext, shellRefreshTargets, group-aware dailyVsJoyRefreshTargets, perCategorySolo/FamilyRefreshTargets"
provides:
  - "test/widget/features/analytics/presentation/analytics_card_registry_test.dart — D-B3/GUARD-01 union test (⊆ analytics, 0 home/*) + render-order + D-B4 visibility + dailyVsJoySnapshotFamily group-presence (Blocker-1 guard) + D-B2 single-source keys + REDES-01 per-card structure"
affects: [45-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "No-widget-pump structural enumeration (RESEARCH A3): the _refresh union is computed by iterating `analyticsCardRegistry.where(isVisible).expand(refreshTargets) ∪ shellRefreshTargets` over a synthetic AnalyticsCardContext — the spec closures are pure over the ctx, so no ProviderContainer.test() pump is needed."
    - "Provider-origin assertion via runtimeType whitelist: each generated Riverpod family instance has a unique concrete type (MonthlyReportProvider, DailyVsJoySnapshotFamilyProvider, …); origin is asserted by membership in a 12-type analytics whitelist, with the home-feature ShadowBooksProvider explicitly negated."
    - "Combined runtime + source-grep gate (home_screen_isolation_test style): the runtime union origin check is paired with a File('…').readAsStringSync() grep over analytics_card_registry.dart asserting no `home/presentation/providers` import and no `shadowBooksProvider` literal."

key-files:
  created:
    - test/widget/features/analytics/presentation/analytics_card_registry_test.dart
  modified: []

key-decisions:
  - "Asserted provider origin by `runtimeType.toString()` membership in a 12-name analytics whitelist (not by `.argument` type reflection) — generated family providers each compile to a unique concrete type, so the type name IS the family identity; the negative `shadowBooksProvider` check compares `runtimeType == shadowBooksProvider.runtimeType`."
  - "Computed the union with `_union(ctx)` mirroring EXACTLY Plan 04's shell `_refresh` (where(isVisible).expand(refreshTargets) deduped by Set, unioned with shellRefreshTargets) so the test guards the real shell derivation, not a re-implementation."
  - "Imported the six per-card `*RefreshTargets` functions from the cards/*.dart files (kpiHero/totalSixMonth/categoryDonut/satisfactionHistogram/largestExpense/bestJoy) for the D-B2 key assertions — they are top-level functions in the card files, NOT re-exported by the registry (only dailyVsJoy/perCategorySolo/perCategoryFamily/shell live in the registry file)."
  - "Anti-vacuity guards (T-45-10): asserted registry length == 10, solo visible == 8, group visible == 10, union isNotEmpty, and cardFiles isNotEmpty — so an empty registry / empty cards dir cannot pass any loop falsely."

patterns-established:
  - "Structural-invariant tests for spec-list registries enumerate the const list directly (no widget tree); future card additions are automatically covered by the union-origin + per-card-structure loops."

requirements-completed: [REDES-01, GUARD-01]

# Metrics
duration: 18min
completed: 2026-06-17
---

# Phase 45 Plan 05: Registry union structural-invariant test Summary

**Authored `analytics_card_registry_test.dart` (458 LOC, 9 tests, all green) — the Nyquist Wave-0 deliverable that promotes Phase 45's "isolation by construction" from implicit to a directly-asserted invariant: the registry-derived `_refresh` union is enumerated over a synthetic solo + group `AnalyticsCardContext` with NO widget pump, proving it is ⊆ analytics `state_*` families with 0 `home/*` providers (D-B3/GUARD-01), preserves today's group-mode `dailyVsJoySnapshotFamilyProvider` invalidation (D-A1 Blocker-1 guard), and that every `cards/*.dart` wrapper is a < 400 LOC ConsumerWidget/StatelessWidget importing no `home/` (REDES-01).**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-06-17T06:06Z
- **Completed:** 2026-06-17T06:24Z
- **Tasks:** 1
- **Files created:** 1

## Accomplishments

- Created `test/widget/features/analytics/presentation/analytics_card_registry_test.dart` (9 tests across 3 groups), green, `flutter analyze` 0 issues.
- **(a) Union ⊆ analytics + 0 home/* (D-B3/GUARD-01):** computed `_union(ctx)` = `registry.where(isVisible).expand(refreshTargets) ∪ shellRefreshTargets` for both solo and group ctx; asserted every member's `runtimeType` is in a 12-name analytics whitelist and that `shadowBooksProvider`'s type appears in neither union.
- **(b) Render order (D-B1):** asserted `analyticsCardRegistry` is non-empty and has exactly 10 specs (declaration order == iteration order of a `final List`).
- **(c) D-B4 visibility:** asserted exactly 2 specs are group-gated (family PerCategory + FamilyInsight), every solo-visible spec stays group-visible, solo-visible == 8, group-visible == 10.
- **(c2) Blocker-1 guard (D-A1):** asserted `dailyVsJoySnapshotFamilyProvider(...)` ∈ group union ∧ ∉ solo union, AND that the group union is a strict superset of solo adding EXACTLY `{FamilyHappinessProvider, PerCategoryJoyBreakdownFamilyProvider, DailyVsJoySnapshotFamilyProvider}`.
- **(d) REDES-01 per-card structure:** source-read loop over `widgets/cards/*.dart` asserting each file < 400 LOC, `extends ConsumerWidget` (or `StatelessWidget` for `analytics_data_card.dart`), and `source.contains('home/')` is false.
- **(e) D-B2 single-source keys:** asserted each `*RefreshTargets(ctx)` returns providers whose argument equals the ctx fields — KPI (monthlyReport+happinessReport), TotalSixMonth (keyed on `trendAnchor`, the drift-prone key), CategoryDonut, SatisfactionHistogram, LargestExpense, BestJoy, perCategorySolo, and the shell `earliestTransactionMonthProvider`.
- **File-wide source-grep gate:** asserted `analytics_card_registry.dart` contains no `home/presentation/providers` import and no `shadowBooksProvider` literal.

## Task Commits

1. **Task 1: D-B3 registry union test + render-order + D-B4 visibility + dailyVsJoySnapshotFamily group-presence + per-card structure** — `09b225c1` (test)

_(Plan metadata commit follows this SUMMARY.)_

## Files Created

- `test/widget/features/analytics/presentation/analytics_card_registry_test.dart` (458 LOC) — 9 tests: 1 render-order, 2 union-origin (solo+group), 1 D-B4 visibility, 2 Blocker-1/superset (c2), 1 D-B2 keys, 1 source-grep gate, 1 per-card structure.

## Decisions Made

- **Origin by runtimeType whitelist:** each generated Riverpod family compiles to a unique concrete provider type, so `runtimeType.toString()` membership in a 12-name analytics whitelist is the family-identity check; the negative `shadowBooksProvider` assertion uses `runtimeType == shadowBooksProvider.runtimeType`. Robust and avoids reflecting `.argument` internals.
- **Union mirrors the shell exactly:** `_union(ctx)` reproduces Plan 04's `_refresh` derivation (`where(isVisible).expand(refreshTargets)` Set-deduped, unioned with `shellRefreshTargets`) so the test guards the real shell path, not a parallel re-implementation that could drift.
- **Per-card `*RefreshTargets` imported from card files:** the six leaf refresh-target functions are top-level in the `cards/*.dart` files (not re-exported by the registry); imported the card files to assert their D-B2 key tuples directly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added the six per-card `cards/*.dart` imports**
- **Found during:** Task 1 (first compile run).
- **Issue:** The plan's `read_first` lists the registry as the symbol source, but the per-card `kpiHeroRefreshTargets`/`totalSixMonthRefreshTargets`/`categoryDonutRefreshTargets`/`satisfactionHistogramRefreshTargets`/`largestExpenseRefreshTargets`/`bestJoyRefreshTargets` functions are top-level in the individual `widgets/cards/*.dart` files and are NOT re-exported by `analytics_card_registry.dart`. The first `flutter test` run failed with `Method not found` for all six.
- **Fix:** Added six `package:home_pocket/.../widgets/cards/*.dart` imports for the D-B2 key assertions. (`dailyVsJoyRefreshTargets`/`perCategorySolo`/`perCategoryFamily`/`shellRefreshTargets` come from the registry import.)
- **Files modified:** `test/widget/features/analytics/presentation/analytics_card_registry_test.dart`.
- **Commit:** `09b225c1`.

## RED Proof (T-45-10 anti-false-green — both reverted)

Per the plan's acceptance criterion and threat T-45-10, two temporary mutations to `analytics_card_registry.dart` were applied, the test was confirmed to FAIL, then reverted (registry restored byte-identical, `git status` clean):

1. **Reintroduced `shadowBooksProvider`** into `shellRefreshTargets` (with a `home/*` import): **4 tests failed** — (a) solo union origin (`"ShadowBooksProvider" is not in the analytics whitelist`), (a) group union origin, (e) D-B2 shell-key tuple mismatch, and the file-wide source-grep gate (`home/presentation/providers` + `shadowBooksProvider` present). Confirms the home/* exclusion is genuinely guarded at both the runtime-union and source levels.
2. **Removed the `if (ctx.isGroupMode)` guard** on `dailyVsJoySnapshotFamilyProvider` (made it unconditional): **2 tests failed** — (c2) Blocker-1 (`family snapshot must NOT be invalidated in solo mode`) and the strict-superset assertion. Confirms the group-aware DailyVsJoy invalidation (today's `_refresh:314`) is genuinely guarded — a defect goldens cannot catch.

Both mutations reverted; final state: 9/9 green, registry diff empty.

## Threat Surface

No new threat surface. Test-only plan, zero production code. T-45-10 (false-green) is mitigated by the RED proof above plus anti-vacuity asserts (registry length == 10, solo == 8, group == 10, union/cardFiles isNotEmpty). T-45-SC (package installs): none — all deps already present.

## Verification

- `flutter test test/widget/features/analytics/presentation/analytics_card_registry_test.dart` → **9/9 green** (`All tests passed!`).
- `flutter analyze test/.../analytics_card_registry_test.dart lib/.../analytics_card_registry.dart` → **No issues found**.
- RED proof 1 (shadowBooks reintroduced) → 4 failures, reverted.
- RED proof 2 (isGroupMode guard removed) → 2 failures, reverted.
- Post-revert `git status --short` on the registry → empty (byte-identical restore).

## Self-Check: PASSED

- FOUND: `test/widget/features/analytics/presentation/analytics_card_registry_test.dart`
- FOUND: commit `09b225c1`

## Next Phase Readiness

- Wave-0 structural gap (GUARD-01 / D-B3) is now closed by an automated test that runs the moment the registry exists, parallel to Plan 04's shell wiring.
- Plan 45-07 (Wave 4, after the shell is wired) adds the A1 group-mode pump test + the full-suite phase gate.

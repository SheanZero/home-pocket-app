---
phase: 45-presentation-shell-rebuild
plan: 03
subsystem: ui
tags: [riverpod, flutter, analytics, card-registry, refactor, home-isolation]

# Dependency graph
requires:
  - phase: 45-presentation-shell-rebuild
    plan: 01
    provides: AnalyticsCardContext stub + 4 cards (Kpi/TotalSixMonth/CategoryDonut/SatisfactionHistogram) + their *RefreshTargets + shared AnalyticsDataCard shell
  - phase: 45-presentation-shell-rebuild
    plan: 02
    provides: 3 Stories cards (LargestExpense/BestJoy/FamilyInsightData) + their *RefreshTargets (familyInsight drops shadow-books — D-B3 Option A)
provides:
  - "analytics_card_registry.dart — AnalyticsCardSpec type, ordered analyticsCardRegistry (10 specs), buildAnalyticsCardContext, shellRefreshTargets, dailyVsJoyRefreshTargets (group-aware), perCategorySolo/FamilyRefreshTargets"
affects: [45-04, 45-05, 46-presentation-shell-content]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Spec-list registry (RESEARCH Pattern 1): cards stay dumb ConsumerWidgets; the registry holds build/refreshTargets/isVisible closures over AnalyticsCardContext — trivially iterable by Plan-05 D-B3 test without widget pumps (D-B1)"
    - "Group-aware refreshTargets collection: a single always-visible card (DailyVsJoyCard) guards a conditional family-snapshot invalidation behind `if (ctx.isGroupMode)`, mirroring the card's conditional ref.watch (D-A1 behavior preservation)"
    - "Display-only home-feature read kept out of the registry: FamilyInsightDataCard's shadowBooksAsync is a Plan-04 shell-injected prop (null placeholder in the registry build) so the file imports zero home/* providers (D-B3 file-wide gate)"

key-files:
  created: []
  modified:
    - lib/features/analytics/presentation/analytics_card_registry.dart

key-decisions:
  - "Chose the spec-list (List<AnalyticsCardSpec>) over an abstract base class (RESEARCH Pattern 1 / D-B1 planner discretion): minimal diff, cards stay ConsumerWidgets, the Plan-05 union test iterates the const list directly."
  - "dailyVsJoyRefreshTargets is GROUP-AWARE (family snapshot only behind if(ctx.isGroupMode)) even though the DailyVsJoy spec is always-visible — this preserves today's _refresh:314 group-mode invalidation that goldens cannot catch. The family PerCategory spec covers a DIFFERENT provider (perCategoryJoyBreakdownFamilyProvider), so it does NOT cover the daily-vs-joy family snapshot."
  - "FamilyInsightDataCard's shadowBooksAsync display prop is passed as `const AsyncValue<List<Object>?>.data(null)` in the registry build closure. The registry MUST NOT import the home-feature shadowBooksProvider (D-B3 file-wide gate: grep home/presentation/providers → empty). Plan 04's shell — which already imports the home provider for display — injects the real shell-resolved shadowBooksAsync when it constructs this one card. The display read is never an invalidation target and never enters the union."
  - "Split the per-category refreshTargets into perCategorySoloRefreshTargets (solo/you scope → perCategoryJoyBreakdownProvider) and perCategoryFamilyRefreshTargets (family scope → perCategoryJoyBreakdownFamilyProvider) — one function per spec, since the two PerCategoryBreakdownCard specs watch different providers."

patterns-established:
  - "Each spec's refreshTargets is a top-level function reference (kpiHeroRefreshTargets, etc.) or a registry-local function (dailyVsJoy/perCategorySolo/perCategoryFamily) — never an inline list, so Plan 05 can assert on the named union sources."

requirements-completed: [REDES-01, GUARD-01]

# Metrics
duration: 3min
completed: 2026-06-17
---

# Phase 45 Plan 03: Card registry Summary

**Built the typed `analyticsCardRegistry` — a 10-spec `List<AnalyticsCardSpec>` that is the single source of truth for BOTH the shell's render order (declaration order == analytics_screen.dart:94–206 1:1) AND the `_refresh` invalidation union (D-B1), with the two family specs gated `isVisible: (ctx) => ctx.isGroupMode` (D-B4), a group-aware `dailyVsJoyRefreshTargets` that preserves today's group-mode family-snapshot invalidation (D-A1), and zero home/* imports (D-B3 file-wide).**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-06-17T06:07Z
- **Completed:** 2026-06-17T06:10Z
- **Tasks:** 2
- **Files modified:** 1 (expanded the Plan-01 registry stub in place)

## Accomplishments
- Expanded the Plan-01 `AnalyticsCardContext` stub into the full registry: added `AnalyticsCardSpec` (build/refreshTargets/isVisible-default-always/sectionHeaderKey), `buildAnalyticsCardContext` (analytics_screen.dart:42–67 reads verbatim), and `shellRefreshTargets` (the one non-card target `earliestTransactionMonthProvider`).
- Built the ordered 10-spec `analyticsCardRegistry` reproducing today's render order 1:1, including the two group-only specs (2nd `PerCategoryBreakdownCard(scope: family)` + `FamilyInsightDataCard`).
- Added group-aware `dailyVsJoyRefreshTargets(ctx)`: `dailyVsJoySnapshotProvider` unconditionally + `dailyVsJoySnapshotFamilyProvider` only behind `if (ctx.isGroupMode)` — mirroring the card's conditional `ref.watch` (daily_vs_joy_card.dart:50–69) and today's `_refresh:314`.
- Per-card refreshTargets delegate to Plans 01/02's `*RefreshTargets` functions (no second list); added registry-local `perCategorySoloRefreshTargets`/`perCategoryFamilyRefreshTargets` for the two distinct PerCategory specs.
- Exactly two `isVisible: (ctx) => ctx.isGroupMode` closures (family PerCategory + FamilyInsight); all others use the default always-true.
- Section-header keys (`analyticsGroupHeaderTime`/`Distribution`/`Stories`) carried on the first card of each group for Plan 04's 1:1 interleave.
- Zero drill/route artifact (D-C1/D-C2 deferred to Phase 46).

## Task Commits

1. **Task 1: AnalyticsCardSpec + buildAnalyticsCardContext + shellRefreshTargets** - `4d2bf105` (feat)
2. **Task 2: ordered analyticsCardRegistry + group-aware dailyVsJoyRefreshTargets** - `d34dde7f` (feat)

_(Plan metadata commit follows this SUMMARY.)_

## Files Modified
- `lib/features/analytics/presentation/analytics_card_registry.dart` (351 LOC) — full registry: `AnalyticsCardContext` (8 fields, from Plan 01), `AnalyticsCardSpec`, `buildAnalyticsCardContext`, `shellRefreshTargets`, `dailyVsJoyRefreshTargets`, `perCategorySoloRefreshTargets`, `perCategoryFamilyRefreshTargets`, and the ordered `analyticsCardRegistry` (10 specs).

## Decisions Made
- **Spec-list over abstract base (D-B1 discretion):** `List<AnalyticsCardSpec>` of `build`/`refreshTargets`/`isVisible` closures. Cards stay dumb `ConsumerWidget`s; the Plan-05 D-B3 union test can iterate the const list without widget pumps.
- **Group-aware DailyVsJoy refresh:** the DailyVsJoy spec is ALWAYS-visible (the card always renders), but its `refreshTargets` collection guards `dailyVsJoySnapshotFamilyProvider` behind `if (ctx.isGroupMode)`. This is a separate provider from the family PerCategory spec's `perCategoryJoyBreakdownFamilyProvider`; omitting it would silently drop today's group-mode pull-to-refresh of the family snapshot (a defect goldens cannot catch). See Critical Notes.
- **FamilyInsightDataCard shadowBooks (D-B3 file-wide gate):** the registry cannot import `shadowBooksProvider` (home-feature, at `home/presentation/providers/state_shadow_books.dart`) without tripping the file-wide `grep home/presentation/providers → empty` gate. The registry's `build` closure passes `const AsyncValue<List<Object>?>.data(null)`; **Plan 04's shell injects the real shell-resolved `shadowBooksAsync`** when it constructs this one card (the shell already imports the home provider for display). The display read is not an invalidation target and never enters the union. This is the planner's "keep shadowBooks resolution in the shell" option, chosen over the "Consumer reads shadowBooksProvider" option precisely because the latter would require a home import the file-wide gate forbids.
- **Section-header placement:** `sectionHeaderKey` is set on the first card of each group (TotalSixMonth=Time, CategoryDonut=Distribution, LargestExpense=Stories); KPI hero has `null` (sits above all headers). Plan 04 interleaves `AnalyticsScreenSectionHeader` + spacers from these keys.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `../domain/models/time_window.dart` import**
- **Found during:** Task 1.
- **Issue:** `buildAnalyticsCardContext` reads `window.range`, but the `range` getter is defined on `TimeWindow` in `domain/models/time_window.dart`, not in `providers/state_time_window.dart`. `flutter analyze` reported `undefined_getter` on `window.range`.
- **Fix:** Added `import '../domain/models/time_window.dart';` (the shell imports it the same way). Caught and fixed before the Task 1 commit.
- **Files modified:** `lib/features/analytics/presentation/analytics_card_registry.dart`.
- **Commit:** `4d2bf105`.

**2. [Rule 3 - Blocking] Split per-category refreshTargets into two functions**
- **Found during:** Task 2.
- **Issue:** The plan listed inline-list refreshTargets for the two PerCategory specs (`[perCategoryJoyBreakdownProvider(...)]` and `[perCategoryJoyBreakdownFamilyProvider(...)]`). Plans 01/02 did not provide a `perCategoryRefreshTargets` function (the leaf `PerCategoryBreakdownCard` is a pre-existing public widget, not a Plan-01/02 extraction, so it has no `*RefreshTargets`).
- **Fix:** Added two registry-local functions `perCategorySoloRefreshTargets` (solo/you → `perCategoryJoyBreakdownProvider`) and `perCategoryFamilyRefreshTargets` (family → `perCategoryJoyBreakdownFamilyProvider`), keeping the "named function per spec, no inline list" pattern so Plan 05 can assert on named union sources. Both contain only analytics providers (D-B3 holds).
- **Files modified:** `lib/features/analytics/presentation/analytics_card_registry.dart`.
- **Commit:** `d34dde7f`.

## Threat Surface
No new threat surface. T-45-05 (refreshTargets referencing a home/* provider) is mitigated: file-wide `grep home/presentation/providers` and `grep shadowBooksProvider` both return empty. T-45-06 (family specs not gated → solo over-invalidation) is mitigated: exactly two specs carry `isVisible: (ctx) => ctx.isGroupMode`; Plan 04's `_refresh` filters `where(isVisible)` before `expand(refreshTargets)`. The registry is a plain `final List<AnalyticsCardSpec>` — no new input/network/persistence/auth surface; no package installs (T-45-SC: accept).

## Known Stubs
- **FamilyInsightDataCard `shadowBooksAsync` placeholder:** the registry build closure passes `const AsyncValue<List<Object>?>.data(null)`. This is INTENTIONAL and resolved by Plan 04 (the shell injects the real shell-resolved `shadowBooksAsync` for this one card). It is documented inline and above; it does NOT affect the refresh union (display-only). Not a goal-blocking stub — the family insight DISPLAY data is wired by Plan 04's shell, by design (the registry must not import the home provider per D-B3).

## Verification
- `flutter analyze lib/features/analytics/` → **0 issues**.
- `flutter analyze lib/features/analytics/presentation/` → **0 issues**.
- `grep home/presentation/providers analytics_card_registry.dart` → **empty** (D-B3 physical guarantee).
- File-wide `grep -nE "home/presentation/providers|shadowBooksProvider"` → **0** (no home import, no shadow-books in any refreshTargets).
- `grep -nE "GoRouter|context.push|/drill|drillRoute"` → **0** (D-C1/D-C2 deferred).
- 10 card builds in exact render order; section keys = the three `analyticsGroupHeader*`; exactly 2 `isVisible: (ctx) => ctx.isGroupMode` closures (lines 305, 349).
- `dailyVsJoyRefreshTargets` includes both `dailyVsJoySnapshotProvider` (always) and `dailyVsJoySnapshotFamilyProvider` (behind `if (ctx.isGroupMode)`).
- anti_toxicity_phase16 + anti_toxicity_phase17 → **30/30 green**.

## Next Phase Readiness
- Plan 04 maps `analyticsCardRegistry.where(isVisible)` for `build` (interleaving section headers from `sectionHeaderKey`) and derives `_refresh` from `.expand(refreshTargets).toSet()` ∪ `shellRefreshTargets`, deletes the inline `_*Card` copies, and injects the real `shadowBooksAsync` into the FamilyInsightDataCard spec build.
- Plan 05's D-B3 union test iterates `analyticsCardRegistry` + `shellRefreshTargets` and asserts every provider origin is an analytics `state_*` family; the group-mode refresh test verifies the `dailyVsJoySnapshotFamilyProvider` guard + Assumption A1 transitive shadow-book re-read.
- No blockers.

## Self-Check: PASSED
- `lib/features/analytics/presentation/analytics_card_registry.dart` exists (351 LOC) — verified.
- Both task commits present in git log (`4d2bf105`, `d34dde7f`) — verified.
- `flutter analyze lib/features/analytics/` → 0 issues; anti-toxicity 30/30 green.

---
*Phase: 45-presentation-shell-rebuild*
*Completed: 2026-06-17*

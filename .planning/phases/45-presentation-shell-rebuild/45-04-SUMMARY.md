---
phase: 45-presentation-shell-rebuild
plan: 04
subsystem: ui
tags: [riverpod, flutter, analytics, card-registry, refactor, home-isolation, thin-shell]

# Dependency graph
requires:
  - phase: 45-presentation-shell-rebuild
    plan: 03
    provides: AnalyticsCardSpec + ordered analyticsCardRegistry (10 specs) + buildAnalyticsCardContext + shellRefreshTargets + group-aware dailyVsJoyRefreshTargets
  - phase: 45-presentation-shell-rebuild
    plan: 01
    provides: 4 extracted cards + shared AnalyticsDataCard shell + AnalyticsCardContext
  - phase: 45-presentation-shell-rebuild
    plan: 02
    provides: 3 Stories cards (LargestExpense/BestJoy/FamilyInsightData)
provides:
  - "analytics_screen.dart — thin AnalyticsScreen shell (176 LOC) consuming analyticsCardRegistry for build + registry-derived _refresh; inline _*Card classes deleted"
affects: [45-05, 46-presentation-shell-content]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Registry-driven shell (RESEARCH Pattern 3): build maps analyticsCardRegistry.where(isVisible) into a byte-faithful Column, interleaving section headers (from sectionHeaderKey) + verbatim 32/8/64 spacers; _refresh derives its union from the SAME registry — one ctx feeds both (D-A1/D-B2)"
    - "Shell-injected display prop: the FamilyInsightDataCard is identified by `built is FamilyInsightDataCard` and rebuilt with the real shell-resolved shadowBooksAsync; the registry's null placeholder keeps the registry home/*-import-free (D-B3) while display data stays wired"
    - "Registry-derived invalidation: where(isVisible).expand(refreshTargets).toSet() + shellRefreshTargets — no hand-listed providers, no home/* / shadowBooksProvider invalidate; HomeHero isolation guaranteed by construction (GUARD-01)"

key-files:
  created: []
  modified:
    - lib/features/analytics/presentation/screens/analytics_screen.dart

key-decisions:
  - "Combined the plan's Task 1 (build) and Task 2 (_refresh) into ONE atomic file rewrite + commit: the thin-shell rewrite is inseparable — deleting the 7 inline _*Card classes forces the registry-driven build, and the new build's onRefresh references the registry-derived _refresh. Both acceptance-grep sets verified in the single commit (0b745a03)."
  - "FamilyInsightDataCard shadow-books injection via `built is FamilyInsightDataCard` type-check (not a fragile registry index): the shell builds each spec; when the built widget is a FamilyInsightDataCard it rebuilds it with the real shell-resolved shadowBooksAsync. Robust to future registry reordering."
  - "Widened the shell's shadowBooksAsync to AsyncValue<List<Object>?> (matching the card's widened prop from Plan 02), dropping the local ShadowBookInfo type annotation — the shell no longer needs to name ShadowBookInfo, just whenData<List<Object>?>. Display value byte-identical."
  - "Section-label resolution via a small switch over the three analyticsGroupHeader* keys (sectionHeaderKey carries the l10n key as a String; the shell maps it to S.of(context).analyticsGroupHeader*). Keeps all UI text via S (CLAUDE.md i18n rule); no new ARB strings."

patterns-established:
  - "One canonical AnalyticsCardContext (buildAnalyticsCardContext) drives both the card map and _refresh in a single build pass — no build/invalidation key drift (D-A1/D-B2)."

requirements-completed: [REDES-01, GUARD-01]

# Metrics
duration: 7min
completed: 2026-06-17
---

# Phase 45 Plan 04: Thin shell rebuild Summary

**Rewrote `analytics_screen.dart` from a 739-LOC monolith into a 176-LOC thin shell: deleted the 7 inline `_*Card` classes + `_AnalyticsDataCard` (now in `widgets/cards/`), replaced the hand-written body with a registry-driven `Column` (byte-faithful section-header + spacer interleave, D-A1), and replaced the 108-line hand-listed `_refresh` with `registry.where(isVisible).expand(refreshTargets).toSet()` + `shellRefreshTargets` (no `home/*` invalidate — GUARD-01).**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-06-17T06:10Z
- **Completed:** 2026-06-17T06:17Z
- **Tasks:** 2 (executed as one atomic rewrite — see Decisions)
- **Files modified:** 1 (739 → 176 LOC)

## Accomplishments
- **Deleted** all 8 inline classes (`_KpiHero`, `_TotalSixMonthCard`, `_CategoryDonutCard`, `_SatisfactionHistogramOrFallback`, `_LargestExpenseCard`, `_BestJoyCard`, `_FamilyCard`, `_AnalyticsDataCard`) — they now live under `widgets/cards/` (Plans 01/02).
- **`build`** now calls `buildAnalyticsCardContext(context, ref, bookId: bookId)` once, then maps `analyticsCardRegistry.where(isVisible)` into the `Column` children via `_buildCardChildren`: each `sectionHeaderKey` opens a section with `SizedBox(32)` + `AnalyticsScreenSectionHeader` + `SizedBox(8)`; inter-card siblings get `SizedBox(8)`; the first card (KPI hero) has no leading spacer; a trailing `SizedBox(64)` closes the list — reproducing analytics_screen.dart:94–206 1:1.
- Kept `Scaffold` → `AppBar(title, actions:[TimeWindowChip(earliestData:…), JoyMetricVariantChip])` → `RefreshIndicator(onRefresh:_refresh)` → `SingleChildScrollView(AlwaysScrollableScrollPhysics, fromLTRB(16,16,16,24))` → `Column(stretch)` verbatim (the screen test flings the `SingleChildScrollView`).
- **`_refresh(ref, ctx)`** is fully registry-derived: `analyticsCardRegistry.where(isVisible).expand(refreshTargets).toSet()` then `ref.invalidate` each, plus a `shellRefreshTargets(ctx)` loop (the one non-card target `earliestTransactionMonthProvider`). No provider literal is hand-listed; `.toSet()` dedupes the shared `monthlyReport`/`happinessReport` instances.
- **Shadow-books injection:** the shell resolves `shadowBooksAsync` (display-only, `AsyncValue<List<Object>?>`) and injects it into the FamilyInsightDataCard via a `built is FamilyInsightDataCard` check (the registry passes a `null` placeholder per D-B3). The display read is NOT an invalidation target and never enters the `_refresh` union.
- Public ctor `const AnalyticsScreen({super.key, required this.bookId})` preserved (call sites home_screen.dart / main_shell_screen.dart unchanged).

## Task Commits

1. **Task 1 + Task 2 (atomic rewrite): registry-driven build + registry-derived _refresh; inline cards deleted** - `0b745a03` (feat)

_(Plan metadata commit follows this SUMMARY.)_

## Files Modified
- `lib/features/analytics/presentation/screens/analytics_screen.dart` (739 → 176 LOC) — thin shell: `build` maps `analyticsCardRegistry`, `_buildCardChildren` interleaves section headers + spacers, `_buildCard` injects shell-resolved `shadowBooksAsync` into FamilyInsightDataCard, `_sectionLabel` maps the three `analyticsGroupHeader*` keys, `_refresh` derives the union from the registry + `shellRefreshTargets`.

## Decisions Made
- **Tasks 1+2 executed as one atomic rewrite/commit:** the two plan tasks both rewrite the single `analytics_screen.dart` body and are inseparable — deleting the inline classes forces the registry-driven build, whose `onRefresh` references the new registry-derived `_refresh`. Splitting would leave an uncompilable intermediate state. Both acceptance-grep sets (Task 1: 0 inline classes, ctor preserved, <200 LOC, registry referenced; Task 2: registry-derived union, 0 hand-listed literals, 0 `shadowBooksProvider` in `_refresh`) are verified in the single commit.
- **`built is FamilyInsightDataCard` over a registry index** for shadow-books injection: robust to future registry reordering (Phase 46 will reorder the registry); never relies on a magic index.
- **Widened the shell's `shadowBooksAsync` to `AsyncValue<List<Object>?>`** to match the card's Plan-02-widened prop, so the shell drops the `ShadowBookInfo` type annotation entirely (only `whenData<List<Object>?>`). Display value byte-identical; one fewer place naming the home-feature model.
- **Section labels via a small `switch`** over the three header keys → `S.of(context).analyticsGroupHeader*`; all UI text stays via `S` (CLAUDE.md i18n rule), no new ARB strings (anti-toxicity gate untouched).

## Deviations from Plan

None — plan executed exactly as written. The only structural choice (merging the two tasks into one atomic commit) is documented under Decisions; it does not change the planned outcome, only the commit granularity, because the file body must be rewritten as a unit to stay compilable.

## Threat Surface
No new threat surface (behavior-preserving rewrite).
- **T-45-07 (tree drift):** mitigated — byte-faithful interleave; `analytics_screen_test` (3 section headers, KpiMiniHeroStrip×1, one of each chart leaf, fling) green; per-card golden tests green.
- **T-45-08 (home/* re-introduction in _refresh):** mitigated — union is registry-derived; `grep` of `_refresh` body shows 0 `shadowBooksProvider`; `home_screen_isolation_test` green (GUARD-01).
- **T-45-09 (build/refresh ctx drift):** mitigated — a single `buildAnalyticsCardContext` ctx feeds both build and `_refresh`; variant comes from `ctx.joyMetricVariant` (no re-read); `.toSet()` dedupes shared providers.

## Known Stubs
None. The FamilyInsightDataCard's `shadowBooksAsync` placeholder (a stub in Plan 03's registry) is RESOLVED here — the shell injects the real shell-resolved value. All cards are fully wired to their providers.

## Verification
- `flutter analyze lib/features/analytics/` → **0 issues** (No issues found!).
- `flutter test test/widget/features/analytics/presentation/screens/analytics_screen_test.dart test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` → **10/10 green** (GUARD-01).
- `flutter test test/widget/features/analytics/` → **120/120 green** (screen + no-delta + anti-toxicity + all per-card widget tests).
- `flutter test test/architecture/domain_import_rules_test.dart test/architecture/provider_graph_hygiene_test.dart` → **green** (no layer/provider-hygiene regression).
- Acceptance greps: inline card classes = 0; `const AnalyticsScreen({super.key, required this.bookId})` = 1; LOC = 176 (<200); hand-listed `ref.invalidate(monthlyReport|expenseTrend|happinessReport|bestJoyMoment)` = 0; `shadowBooksProvider` in `_refresh` body = 0.
- No analytics-screen-level golden test exists (chart goldens are authored from scratch on macOS in Phase 47, per v1.8 constraint); the per-card widget goldens that do exist are green.

## Next Phase Readiness
- Plan 05's D-B3 union test can iterate `analyticsCardRegistry` + `shellRefreshTargets` against the now-live registry-driven shell; the group-mode pull-to-refresh path (Assumption A1 transitive shadow-book re-read) is exercised by `analytics_screen_test`'s group-mode fling (green, no exception).
- Phase 46 reorders the registry list to land the round-5 B IA; the shell needs no further edits (the `built is FamilyInsightDataCard` injection is reorder-safe).
- No blockers.

## Self-Check: PASSED
- `lib/features/analytics/presentation/screens/analytics_screen.dart` exists (176 LOC) — verified.
- Task commit `0b745a03` present in git log — verified.
- `flutter analyze lib/features/analytics/` → 0 issues; analytics 120/120 + home isolation 4/4 green.

---
*Phase: 45-presentation-shell-rebuild*
*Completed: 2026-06-17*

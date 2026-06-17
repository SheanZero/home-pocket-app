---
phase: 45-presentation-shell-rebuild
plan: 02
subsystem: ui
tags: [riverpod, flutter, analytics, card-registry, refactor, home-isolation]

# Dependency graph
requires:
  - phase: 44-data-use-case-additions-reuse-first
    provides: locked analytics provider graph (largestMonthlyExpense / bestJoyMoment / familyHappiness families, all auto-dispose)
  - phase: 45-presentation-shell-rebuild
    plan: 01
    provides: AnalyticsCardContext stub + shared AnalyticsDataCard shell + single-source <card>RefreshTargets pattern
provides:
  - "widgets/cards/largest_expense_card.dart — public LargestExpenseCard ConsumerWidget + largestExpenseRefreshTargets(ctx)"
  - "widgets/cards/best_joy_card.dart — public BestJoyCard ConsumerWidget + bestJoyRefreshTargets(ctx)"
  - "widgets/cards/family_insight_data_card.dart — public FamilyInsightDataCard ConsumerWidget + familyInsightRefreshTargets(ctx) (NO shadow-books invalidate — D-B3 Option A)"
affects: [45-03, 45-04, 45-05, 46-presentation-shell-content]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single-source <card>RefreshTargets(AnalyticsCardContext) reused by build + error-retry + (future) registry union (D-B2 / 卡就是契约)"
    - "Byte-faithful structural extraction: move inline _*Card bodies verbatim, de-privatise class name, add super.key only (D-A1)"
    - "Home-isolation by construction: widen the display prop type so the card file imports zero home-feature providers; drop redundant transitive invalidates from refreshTargets (D-B3 Option A)"

key-files:
  created:
    - lib/features/analytics/presentation/widgets/cards/largest_expense_card.dart
    - lib/features/analytics/presentation/widgets/cards/best_joy_card.dart
    - lib/features/analytics/presentation/widgets/cards/family_insight_data_card.dart
  modified: []

key-decisions:
  - "FamilyInsightDataCard's shadowBooksAsync prop widened from AsyncValue<List<ShadowBookInfo>?> to AsyncValue<List<Object>?> (Rule 3 deviation): ShadowBookInfo is defined ONLY in the home-feature state_shadow_books provider file, so keeping the concrete type would force a home-feature import and break the T-45-03 mitigation. FamilyInsightCard.shadowBooks already accepts List<Object>?, and AsyncValue is covariant, so Plan 04's shell can pass its AsyncValue<List<ShadowBookInfo>?> unchanged. Display behavior is byte-identical."
  - "familyInsightRefreshTargets returns ONLY familyHappinessProvider; the direct shadow-books invalidate the old shell _refresh performed is dropped (D-B3 Option A / Assumption A1) — familyHappinessProvider re-reads shadow books transitively, so group-mode refresh still works (to be verified by the Plan 05 group-mode refresh test)."
  - "Card source files contain NO 'home/' substring at all (comments rephrased to avoid the literal) so the Plan 05 physical source-grep guarantee (source.contains('home/') == false) holds, not just the import-path gate."
  - "largestMonthlyExpenseProvider + bestJoyMomentProvider live in state_happiness.dart (not state_analytics.dart) — imported accordingly; familyHappinessProvider likewise in state_happiness.dart."

patterns-established:
  - "Pattern: each card builds a local _ctx() AnalyticsCardContext from its own fields so build-watched keys and refreshTargets keys derive from ONE field set (no drift)."
  - "Pattern: single-target cards retry via targets.single."

requirements-completed: [REDES-01, GUARD-01]

# Metrics
duration: 14min
completed: 2026-06-17
---

# Phase 45 Plan 02: Stories-section card extraction Summary

**Extracted the 3 Stories-section inline cards (LargestExpenseCard, BestJoyCard, FamilyInsightDataCard) verbatim from the analytics_screen.dart monolith into public ConsumerWidgets under widgets/cards/, each with a single-source `<card>RefreshTargets(ctx)` (D-B2); FamilyInsightDataCard drops the direct home-feature shadow-books invalidate (D-B3 Option A) and imports zero home-feature providers (T-45-03 mitigation).**

## Performance

- **Duration:** ~14 min
- **Tasks:** 2
- **Files created:** 3

## Accomplishments
- Extracted `_LargestExpenseCard` → public `LargestExpenseCard` (leaf `LargestExpenseStoryCard`, loading height 110) and `_BestJoyCard` → public `BestJoyCard` (leaf `BestJoyStoryStrip`, loading height 120) — both render their leaf strip directly, no `AnalyticsDataCard` shell.
- Extracted `_FamilyCard` → public `FamilyInsightDataCard` (watches `familyHappinessProvider`, loading height 110), display still passes `shadowBooksAsync.value` to `FamilyInsightCard`.
- `familyInsightRefreshTargets` returns ONLY `familyHappinessProvider` — the direct shadow-books invalidate (old shell `_refresh` line 304) is deliberately dropped (D-B3 Option A) with a citing comment; group-mode refresh stays correct via transitive re-read (Assumption A1).
- Single-source `largestExpenseRefreshTargets` / `bestJoyRefreshTargets` / `familyInsightRefreshTargets` each reused by their card's error-retry (D-B2).

## Task Commits

1. **Task 1: Extract LargestExpenseCard + BestJoyCard** - `95377bf4` (feat)
2. **Task 2: Extract FamilyInsightDataCard, drop shadow-books invalidate (D-B3 Option A)** - `03aaea36` (feat)

_(Plan metadata commit follows this SUMMARY.)_

## Files Created
- `lib/features/analytics/presentation/widgets/cards/largest_expense_card.dart` (89 LOC) — `largestMonthlyExpenseProvider` (from state_happiness); leaf render; `largestExpenseRefreshTargets` single target.
- `lib/features/analytics/presentation/widgets/cards/best_joy_card.dart` (87 LOC) — `bestJoyMomentProvider` (from state_happiness); leaf render; `bestJoyRefreshTargets` single target.
- `lib/features/analytics/presentation/widgets/cards/family_insight_data_card.dart` (106 LOC) — `familyHappinessProvider`; `isGroupMode`-gated (registered with `isVisible: (ctx) => ctx.isGroupMode` in Plan 03); widened `AsyncValue<List<Object>?>` display prop; `familyInsightRefreshTargets` drops shadow-books.

## Decisions Made
- **shadowBooksAsync prop widened to `AsyncValue<List<Object>?>`** (was `AsyncValue<List<ShadowBookInfo>?>` on the inline `_FamilyCard`). Reason: `ShadowBookInfo` is defined only in the home-feature `state_shadow_books.dart` provider file; importing it would carry a home-feature import into the cards/ layer and violate the T-45-03 mitigation + the D-B3 physical source-grep guarantee. `FamilyInsightCard.shadowBooks` already accepts `List<Object>?`, and `AsyncValue` is covariant in its type parameter, so Plan 04's shell passes its `AsyncValue<List<ShadowBookInfo>?>` to this widened prop with no change and identical displayed value.
- **Comments scrubbed of the literal `home/` substring** so a future `source.contains('home/')` assertion (Plan 05 physical source-grep, analog `home_screen_isolation_test`) sees a clean source, not just the import-path gate.
- **Single-target retry uses `targets.single`** (matching Plan 01's pattern for single-provider cards).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Widened FamilyInsightDataCard.shadowBooksAsync prop type to avoid a home-feature import**
- **Found during:** Task 2.
- **Issue:** The plan said keep the 6 constructor props "EXACTLY", including `shadowBooksAsync: AsyncValue<List<ShadowBookInfo>?>`. But `ShadowBookInfo` is defined ONLY in the home-feature provider file `state_shadow_books.dart` (no domain/model re-export exists anywhere in lib/), so keeping the concrete type would force `import '.../home/presentation/providers/state_shadow_books.dart'` into the card file — directly breaking the acceptance gate `grep -nE "home/presentation/providers" → nothing` and the T-45-03 mitigation.
- **Fix:** Widened the prop to `AsyncValue<List<Object>?>`. This is the path the plan itself sanctions in Task 2 ("if none exists, document the exception in SUMMARY ... the D-B3 union test asserts on the INVALIDATION union, not on type imports"). `FamilyInsightCard.shadowBooks` is already typed `List<Object>?`, so display behavior is byte-identical; the shell's `AsyncValue<List<ShadowBookInfo>?>` is covariantly assignable.
- **Files modified:** `lib/features/analytics/presentation/widgets/cards/family_insight_data_card.dart`.
- **Commit:** `03aaea36`.
- **Union-level guarantee preserved:** the D-B3 guarantee is about the invalidation union (which excludes shadow-books — Option A) AND the physical source-grep (no `home/` substring) — both hold. The type widening is the minimal change that keeps both true while preserving the displayed data exactly.

## Threat Surface
No new threat surface. T-45-03 (home-feature import into cards/) is fully mitigated: `grep home/presentation/providers` over the card file returns nothing and the file contains no `home/` substring at all. T-45-04 (stale family data from dropping the shadow-books invalidate) is mitigated by Assumption A1 (transitive re-read), to be explicitly verified by the Plan 05 group-mode pull-to-refresh test.

## Known Stubs
None. The 3 cards are fully wired to their real providers; `FamilyInsightDataCard` receives its display data via the shell-resolved prop (wired in Plan 04). The inline `_LargestExpenseCard` / `_BestJoyCard` / `_FamilyCard` copies intentionally remain in `analytics_screen.dart` this plan — Plan 04 deletes them and wires the shell to the registry (by design; the shell still compiles against them now).

## Verification
- `flutter analyze lib/features/analytics/` → **0 issues**.
- `flutter analyze lib/features/analytics/presentation/widgets/cards/` → **0 issues**.
- `flutter test anti_toxicity_phase16 + anti_toxicity_phase17` → **30/30 green**.
- Task-1 greps: `AnalyticsDataCard`=0 in both files; `largestExpenseRefreshTargets`=5 / `bestJoyRefreshTargets`=5 (≥2, reused by retry); banned-terms sweep empty; both `class … extends ConsumerWidget`.
- Task-2 greps: `class FamilyInsightDataCard extends ConsumerWidget`; `shadowBooksProvider`=0; `home/`=0; `familyHappinessProvider`=5; D-B3/Option A/A1 citing comment present.

## Next Phase Readiness
- Plan 03 can now build the `AnalyticsCardSpec` registry against all 7 public cards (Plan 01's 4 + this plan's 3) plus the 2 already-public leaf cards, gating `FamilyInsightDataCard` + the family-scope `PerCategoryBreakdownCard` with `isVisible: (ctx) => ctx.isGroupMode`.
- Plan 04 deletes the inline `_*Card` copies and wires the shell `_refresh` to `registry.where(isVisible).expand(refreshTargets).toSet()`.
- Plan 05's D-B3 union test + group-mode refresh test (Assumption A1) back the structural guarantees established here.
- No blockers.

## Self-Check: PASSED
- All 3 created files exist on disk (verified).
- Both task commits present in git log (`95377bf4`, `03aaea36`).
- `flutter analyze lib/features/analytics/` → 0 issues; anti-toxicity 30/30 green.

---
*Phase: 45-presentation-shell-rebuild*
*Completed: 2026-06-17*

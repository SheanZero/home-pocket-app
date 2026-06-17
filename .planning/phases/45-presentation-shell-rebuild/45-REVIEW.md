---
phase: 45-presentation-shell-rebuild
reviewed: 2026-06-17T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - lib/features/analytics/presentation/analytics_card_registry.dart
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/features/analytics/presentation/widgets/cards/analytics_data_card.dart
  - lib/features/analytics/presentation/widgets/cards/kpi_hero_card.dart
  - lib/features/analytics/presentation/widgets/cards/total_six_month_card.dart
  - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
  - lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart
  - lib/features/analytics/presentation/widgets/cards/largest_expense_card.dart
  - lib/features/analytics/presentation/widgets/cards/best_joy_card.dart
  - lib/features/analytics/presentation/widgets/cards/family_insight_data_card.dart
  - test/widget/features/analytics/presentation/analytics_card_registry_test.dart
  - test/widget/features/analytics/presentation/screens/analytics_refresh_group_mode_test.dart
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 45: Code Review Report

**Reviewed:** 2026-06-17
**Depth:** standard (Dart/Flutter + Riverpod 3 aware)
**Files Reviewed:** 11 (9 lib + 2 test)
**Status:** issues_found (no blockers; 1 warning is an inaccurate-comment defect, not a behavior regression against the locked decisions)

## Summary

Phase 45 is a behavior-preserving structural refactor (D-A1): the 739-LOC `analytics_screen.dart`
monolith was split into a thin registry-driven shell + a typed `AnalyticsCardSpec` registry + 8
extracted card files under `widgets/cards/`. I verified the extraction **against the pre-refactor
source** (`git show 0b745a03^:.../analytics_screen.dart`), not just against "looks reasonable".

What I confirmed sound:

- **Byte-faithful card bodies.** Every extracted card's `build` body is character-identical to its
  inline `_*Card` original (only the class de-privatised, `super.key` added, and error-retry literals
  rerouted through the single-source `*RefreshTargets` list). KPI, TotalSixMonth, CategoryDonut,
  Satisfaction, LargestExpense, BestJoy, FamilyInsight, and the `AnalyticsDataCard` shell all match.
- **Render order + spacing reproduced 1:1.** I traced `_buildCardChildren` against the legacy
  hand-written `Column` for BOTH solo and group mode: KPI (no header) → 32/header/8 per section →
  8px inter-card gaps → trailing 64. Identical in both modes, including the two `isGroupMode` cards.
- **`_refresh` union == today's union.** Solo derives the same 9 providers (deduped); group adds
  exactly `familyHappiness` + `perCategoryJoyBreakdownFamily` + `dailyVsJoySnapshotFamily`. The only
  intentional drop is `shadowBooksProvider` (D-B3 Option A).
- **HomeHero isolation (GUARD-01 / D-B3).** The registry imports zero `home/*` providers; the
  union ⊆ analytics families is directly asserted by the new structural test (11/11 green). The
  display-only `shadowBooksProvider` read stays in the shell and is shell-injected, never in the union.
- **Riverpod 3 hygiene.** Cards are `ConsumerWidget`s using `ref.watch` in `build` and `ref.invalidate`
  in callbacks; `_refresh` uses `ref.invalidate` (not `read`); the shadow-books display read uses
  `ref.watch(...).whenData(...)` — no `watch`-as-side-effect, no auto-dispose orphan-read antipattern.
- **`flutter analyze`** on all 3 lib targets: 0 issues. Both new tests pass (11/11).

The one Warning below is a documentation-accuracy defect in a load-bearing rationale comment, not a
regression versus the locked decisions. The Info items are micro-inefficiencies the refactor introduced.

## Warnings

### WR-01: "transitive re-read" comment overstates shadow-books freshness after D-B3 Option A

**File:** `lib/features/analytics/presentation/widgets/cards/family_insight_data_card.dart:90-97`
(mirrored in `test/widget/.../analytics_refresh_group_mode_test.dart:1-23`)

**Issue:** The rationale comment claims dropping the direct `shadowBooksProvider` invalidate is fully
compensated because `familyHappinessProvider` "re-reads it transitively via its internal
`ref.watch(...future)`". That is technically inaccurate. On pull-to-refresh the new `_refresh`
invalidates only `familyHappinessProvider`. When it rebuilds it calls
`ref.watch(shadowBooksProvider.future)` (`state_happiness.dart:118`), but `shadowBooksProvider` is
NOT invalidated and is kept alive (both the shell's display `ref.watch(shadowBooksProvider)` and
`familyHappinessProvider` hold it), so the read returns the **cached** shadow-book list — no fresh DB
re-fetch via `findShadowBooksByGroupId`. The pre-refactor `_refresh` invalidated `shadowBooksProvider`
directly (`orig:304`), forcing a real re-read of the shadow-book set from source.

This is a genuine, if small, behavior delta (stale shadow-book membership survives a manual refresh
until `activeGroupProvider`/auto-dispose forces a rebuild). It is the **explicitly locked D-B3 Option A
decision**, so it is NOT a blocker — but the code/test comments assert a stronger freshness guarantee
than the mechanism provides, which will mislead the next reader (and the Phase 46 drill work) into
believing shadow books are re-fetched on refresh. The group-mode test only proves the *use case* is
re-invoked; it cannot and does not prove the shadow-book list is re-fetched.

**Fix:** Soften the comment to state the actual mechanism and tradeoff — e.g.:

```dart
/// Returns ONLY `familyHappinessProvider` and DELIBERATELY DROPS the direct
/// shadow-books invalidate (D-B3 Option A). Invalidating `familyHappinessProvider`
/// re-runs its body, which RE-READS the *cached* `shadowBooksProvider.future`
/// (the provider is kept alive by the shell's display watch, so this is a cache
/// read, NOT a fresh DB re-fetch). The use case is re-invoked with the same book
/// ids; a changed shadow-book SET is not picked up until activeGroup/auto-dispose
/// rebuilds shadowBooksProvider. Accepted tradeoff to keep the union ⊆ analytics.
```

No code change required (the decision stands); fix the comment to match reality.

## Info

### IN-01: shell constructs a throwaway FamilyInsightDataCard then discards it

**File:** `lib/features/analytics/presentation/screens/analytics_screen.dart:128-139`

**Issue:** `_buildCard` calls `spec.build(ctx)` (which constructs a `FamilyInsightDataCard` with the
`const AsyncValue<List<Object>?>.data(null)` placeholder), then for that one spec immediately throws it
away and re-constructs the card with the real shell-resolved `shadowBooksAsync`. The placeholder widget
is allocated every rebuild only to be discarded. Harmless (const + cheap ctor) but slightly awkward.

**Fix:** Optional — skip building the placeholder for the family spec, e.g. branch on a stable marker
(a `bool needsShadowBooks` on the spec, or `spec.sectionHeaderKey == null && isVisible group`) before
calling `spec.build`. Low priority; current code is correct.

### IN-02: registry's FamilyInsightDataCard `build` placeholder is dead-on-arrival

**File:** `lib/features/analytics/presentation/analytics_card_registry.dart:339-350`

**Issue:** The registry spec for `FamilyInsightDataCard` passes
`shadowBooksAsync: const AsyncValue<List<Object>?>.data(null)`, but this constructed widget is never
rendered — the shell's `_buildCard` (IN-01) always replaces it. The placeholder exists only to satisfy
the `build` closure signature / keep the registry `home/*`-import-free. This is intentional per D-B3 and
well-commented, but the coupling between registry `build` and shell `_buildCard` (the shell must KNOW to
special-case `FamilyInsightDataCard`) is a hidden contract that a future card with a shell-injected prop
could silently break.

**Fix:** Optional — document the shell↔registry coupling at the spec site, or model the injected prop
explicitly (e.g. an `AnalyticsCardSpec` field for "needs shell-injected shadow books") so the special
case is declared rather than detected via `is FamilyInsightDataCard`. Not required for correctness.

### IN-03: per-card `_ctx()` helpers fabricate filler values for unused context fields

**Files:** `kpi_hero_card.dart:95-104`, `total_six_month_card.dart:70-79`,
`category_donut_card.dart:66-75`, `satisfaction_histogram_card.dart:94-103`,
`largest_expense_card.dart:66-75`, `best_joy_card.dart:66-75`,
`family_insight_data_card.dart:76-85`

**Issue:** Each card builds a local `AnalyticsCardContext` to feed its own `*RefreshTargets`, filling
fields the targets don't read with placeholders (`currencyCode: 'JPY'`, `isGroupMode: false`,
`locale: const Locale('ja')`, and for `TotalSixMonthCard` `startDate/endDate: anchor`). These are inert
for the targets actually returned, so there is no behavior bug. The risk is latent: if a card's
`*RefreshTargets` ever starts reading one of these filler fields, the card's own error-retry would
invalidate a wrong-keyed provider while the registry-driven `_refresh` (built from the REAL ctx) would
be correct — a silent build/refresh drift that the single-source design is meant to prevent.

**Fix:** Optional — pass the real `currencyCode`/`isGroupMode`/`locale` into the cards that have them
(most already receive these as constructor params) instead of fabricating, so the local `_ctx()` is a
faithful subset rather than a partly-fictional one. Cosmetic / defensive; current targets are correct.

---

## Inline Summary

| Severity | Count |
|----------|-------|
| Critical / Blocker | 0 |
| Warning | 1 |
| Info | 3 |
| **Total** | **4** |

Verdict: faithful, well-tested structural refactor. No behavior-preservation defect, no isolation leak
(union ⊆ analytics, 0 `home/*`, asserted), no Riverpod 3 misuse, no null-safety/type issue in the
shadow-books injection. The single Warning is an over-claiming comment around the (correctly
implemented, explicitly locked) D-B3 Option A shadow-books drop; fixing the comment removes a future
foot-gun without touching behavior.

---

_Reviewed: 2026-06-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

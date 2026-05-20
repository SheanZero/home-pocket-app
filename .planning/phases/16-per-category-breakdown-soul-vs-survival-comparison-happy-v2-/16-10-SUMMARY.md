---
phase: 16
plan: 10
subsystem: analytics/presentation
tags: [happy-v2, statsui-v2, presentation-layer, integration, isolation-test]
requires:
  - 16-06  # state_ledger_snapshot.dart providers (4 new)
  - 16-07  # PerCategoryBreakdownCard widget
  - 16-08  # SoulVsSurvivalCard widget
provides:
  - AnalyticsScreen Distribution-section integration of HAPPY-V2-01 + STATSUI-V2-01
  - Extended HomeHero isolation guarantee (Phase 16 providers covered)
affects:
  - lib/features/analytics/presentation/screens/  # +71 lines in analytics_screen.dart
  - test/widget/features/home/presentation/screens/  # +115 lines extending the isolation test
tech-stack:
  added: []  # no new deps
  patterns:
    - distribution-section-composition       # cards inserted per D-13 ordering
    - group-mode-stacked-cards               # PerCategoryBreakdownCard renders twice in group mode (D-17)
    - refresh-window-keyed-invalidation      # _refresh extends with (bookId, startDate, endDate) keys (matches build context)
    - homeher0-isolation-binding             # D-12 binding from Phase 15 preserved verbatim (comment + structural)
    - mocktail-verify-never                  # zero-invocation assertions on Phase 16 use cases from HomeHero context
    - source-import-guard                    # HomeScreen file MUST NOT import state_ledger_snapshot
key-files:
  created: []
  modified:
    - lib/features/analytics/presentation/screens/analytics_screen.dart           # +71 lines
    - test/widget/features/home/presentation/screens/home_screen_isolation_test.dart  # +115 lines
decisions:
  - "Distribution insertion order matches D-13 verbatim: _CategoryDonutCard → SoulVsSurvivalCard → _SatisfactionHistogramOrFallback → PerCategoryBreakdownCard (You/solo) → PerCategoryBreakdownCard (Family, group-only)."
  - "Group-mode stacked PerCategoryBreakdownCard pair per D-17: the You card uses PerCategoryScope.you (reads single-book provider), the Family card uses PerCategoryScope.family (reads family-aggregate provider that derives bookIds from shadowBooksProvider — D-20 gate is enforced upstream)."
  - "_refresh() invalidations use the SAME (bookId, startDate, endDate) window keys as the build context. Phase 15 D-12 binding preserved: HomeHero's happinessReportProvider is keyed by month-anchored (start, end), so the AnalyticsScreen invalidations (which may carry a year-2020 window) cannot match its instance. The D-12 comment at line ~168 is unchanged."
  - "Family-variant invalidations live INSIDE the existing `if (isGroupMode) {...}` block, after the existing shadowBooksProvider invalidation, so solo-mode runs do not unnecessarily evict the family providers."
  - "home_screen_isolation_test.dart uses `verifyNever(...)` with `any(named: ...)` for both startDate AND endDate parameters on the 4 new Phase 16 use cases — a stronger assertion than the original DateTime(2020) filter, since the goal is `HomeHero never invokes these use cases at all`, not `HomeHero never invokes them with the AnalyticsScreen window`. Single-shape verifyNever covers every parameter shape."
  - "Source-import assertion extended: HomeScreen file must not contain the substring `state_ledger_snapshot`. This is the cheapest structural guard against a future refactor accidentally importing the analytics-only providers into HomeHero."
metrics:
  duration: ~25 minutes
  completed: 2026-05-20
  tasks: 2
  files_modified: 2
  tests_added: 0  # extended existing tests; 4 new verifyNever assertions inside an existing testWidgets case
---

# Phase 16 Plan 10: AnalyticsScreen integration + HomeHero isolation extension

Final wiring step for Phase 16 — both HAPPY-V2-01 (per-category soul breakdown) and STATSUI-V2-01 (Soul-vs-Survival engagement snapshot) become user-visible by inserting their cards into the AnalyticsScreen Distribution section per D-13. `_refresh()` learns to invalidate the four new providers using the SAME `(bookId, startDate, endDate)` window keys as the build context, so HomeHero's month-anchored provider instances remain untouched (Phase 15 D-12 binding preserved). The existing `home_screen_isolation_test.dart` is extended with four `verifyNever` assertions proving HomeHero never invokes the Phase 16 use cases, plus a source-import guard preventing future regression.

## What Was Built

### Task 1 — AnalyticsScreen Distribution-section composition + `_refresh()` extension (commit `38ed9e6`)

**File:** `lib/features/analytics/presentation/screens/analytics_screen.dart` (587 → 658 lines, +71)

**Imports added (3):**

```dart
import '../providers/state_ledger_snapshot.dart';
import '../widgets/per_category_breakdown_card.dart';
import '../widgets/soul_vs_survival_card.dart';
```

**Distribution-section composition (D-13 ordering — lines 109-159):**

```
SizedBox(height: 8)
_CategoryDonutCard(bookId, startDate, endDate)
SizedBox(height: 8)
SoulVsSurvivalCard(bookId, startDate, endDate, currencyCode, locale, isGroupMode)   ← NEW (D-13)
SizedBox(height: 8)
_SatisfactionHistogramOrFallback(bookId, startDate, endDate, currencyCode)
SizedBox(height: 8)
PerCategoryBreakdownCard(bookId, startDate, endDate, locale,
                        scope: isGroupMode ? PerCategoryScope.you : PerCategoryScope.solo)   ← NEW (D-13)
if (isGroupMode) [
  SizedBox(height: 8),
  PerCategoryBreakdownCard(bookId, startDate, endDate, locale,
                          scope: PerCategoryScope.family),                           ← NEW (D-17 stacked)
]
SizedBox(height: 32)
```

The Family `PerCategoryBreakdownCard` still receives `bookId` (the widget's constructor requires it for uniform API), but the widget reads from `perCategorySoulBreakdownFamilyProvider` (no `bookId` arg — derives ids from `shadowBooksProvider`) once `scope == PerCategoryScope.family`.

**`_refresh()` extension (D-12 preserved — lines 207-289):**

Added 2 invalidations OUTSIDE the `if (isGroupMode)` block (always run):

```dart
ref.invalidate(perCategorySoulBreakdownProvider(bookId, startDate, endDate));
ref.invalidate(soulVsSurvivalSnapshotProvider(bookId, startDate, endDate));
```

Added 2 invalidations INSIDE the existing `if (isGroupMode) {...}` block (only when group mode active):

```dart
ref.invalidate(perCategorySoulBreakdownFamilyProvider(startDate, endDate));
ref.invalidate(soulVsSurvivalSnapshotFamilyProvider(startDate, endDate));
```

D-12 comment at line 168 unchanged: `// D-12: _refresh MUST NOT invalidate any home/* provider`. A second D-12 reference appears in the new code's adjacent comment for traceability.

### Task 2 — HomeHero isolation test extension (commit `eab64f8`)

**File:** `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` (251 → 366 lines, +115)

**Imports added (4 application-layer use case classes):**

```dart
import 'package:home_pocket/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart';
import 'package:home_pocket/application/analytics/get_per_category_soul_breakdown_use_case.dart';
import 'package:home_pocket/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart';
import 'package:home_pocket/application/analytics/get_soul_vs_survival_snapshot_use_case.dart';
```

**Mock classes (4):**

```dart
class _MockGetPerCategorySoulBreakdownUseCase                extends Mock implements GetPerCategorySoulBreakdownUseCase {}
class _MockGetPerCategorySoulBreakdownAcrossBooksUseCase     extends Mock implements GetPerCategorySoulBreakdownAcrossBooksUseCase {}
class _MockGetSoulVsSurvivalSnapshotUseCase                  extends Mock implements GetSoulVsSurvivalSnapshotUseCase {}
class _MockGetSoulVsSurvivalSnapshotAcrossBooksUseCase       extends Mock implements GetSoulVsSurvivalSnapshotAcrossBooksUseCase {}
```

**Stubbed `when(...)` clauses returning `const Empty()`** for each of the 4 use cases — the Empty stub keeps a hypothetical stray HomeHero read from throwing on a missing override (which would mask the `verifyNever` signal); the assertion proper is `verifyNever`.

**Provider overrides (4)** in `buildSubject()` overrides list — `getPerCategorySoulBreakdownUseCaseProvider`, `getPerCategorySoulBreakdownAcrossBooksUseCaseProvider`, `getSoulVsSurvivalSnapshotUseCaseProvider`, `getSoulVsSurvivalSnapshotAcrossBooksUseCaseProvider` each routed to its mock.

**`verifyNever` assertions (4)** inside the existing `testWidgets('HomeHero remains current-month keyed when Analytics window is year 2020', ...)` case:

```dart
verifyNever(() => perCategorySoulBreakdownUseCase.execute(
  bookId: any(named: 'bookId'),
  startDate: any(named: 'startDate'),
  endDate: any(named: 'endDate'),
));
verifyNever(() => perCategorySoulBreakdownAcrossBooksUseCase.execute(
  groupBookIds: any(named: 'groupBookIds'),
  startDate: any(named: 'startDate'),
  endDate: any(named: 'endDate'),
));
verifyNever(() => soulVsSurvivalSnapshotUseCase.execute(
  bookId: any(named: 'bookId'),
  startDate: any(named: 'startDate'),
  endDate: any(named: 'endDate'),
));
verifyNever(() => soulVsSurvivalSnapshotAcrossBooksUseCase.execute(
  groupBookIds: any(named: 'groupBookIds'),
  startDate: any(named: 'startDate'),
  endDate: any(named: 'endDate'),
));
```

These assertions use `any(named:)` on every parameter (stronger than the existing `DateTime(2020)` filter for the original 4 use cases) — they prove HomeHero never invokes the Phase 16 use cases AT ALL, regardless of parameter shape. This matches the actual design: HomeHero is current-month-anchored and does not consume any analytics ledger-snapshot providers.

**Source-import assertion extended** inside the existing `test('HomeScreen file does not import state_time_window', ...)` case:

```dart
expect(source.contains('state_ledger_snapshot'), isFalse,
  reason: 'D-12 + Phase 16: HomeScreen must not import analytics state_ledger_snapshot — those providers are AnalyticsScreen-only.');
```

This is the cheapest structural guard against a future refactor accidentally coupling HomeHero to the new analytics providers.

## How It Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  AnalyticsScreen (this plan extends it)                                      │
│                                                                              │
│    Distribution section (D-13 order):                                        │
│      _CategoryDonutCard                                                      │
│      SoulVsSurvivalCard      ← NEW (STATSUI-V2-01)                          │
│      _SatisfactionHistogramOrFallback                                        │
│      PerCategoryBreakdownCard(scope: solo/you)   ← NEW (HAPPY-V2-01)        │
│      if (isGroupMode)                                                        │
│        PerCategoryBreakdownCard(scope: family)   ← NEW (D-17 stacked)       │
│                                                                              │
│    _refresh() invalidations (D-12 binding preserved):                       │
│      monthlyReportProvider              (existing)                           │
│      expenseTrendProvider               (existing)                           │
│      earliestTransactionMonthProvider   (existing)                           │
│      happinessReportProvider            (existing — note: this is the        │
│                                          provider HomeHero also reads, but   │
│                                          with month-anchored keys; D-12      │
│                                          relies on key-divergence here)     │
│      satisfactionDistributionProvider   (existing)                           │
│      bestJoyMomentProvider              (existing)                           │
│      largestMonthlyExpenseProvider      (existing)                           │
│      perCategorySoulBreakdownProvider   ← NEW                                │
│      soulVsSurvivalSnapshotProvider     ← NEW                                │
│      if (isGroupMode):                                                       │
│        familyHappinessProvider                     (existing)                │
│        shadowBooksProvider                         (existing)                │
│        perCategorySoulBreakdownFamilyProvider     ← NEW                      │
│        soulVsSurvivalSnapshotFamilyProvider       ← NEW                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  home_screen_isolation_test.dart (this plan extends it)                      │
│                                                                              │
│    setUp:                                                                    │
│      mock 8 use cases (4 existing + 4 new Phase 16)                          │
│      stub Empty() on all 4 new ones                                          │
│                                                                              │
│    buildSubject:                                                             │
│      override 4 new Phase 16 providers → routed to mocks                     │
│      override selectedTimeWindowProvider → TimeWindow.year(year: 2020)       │
│                                                                              │
│    testWidgets:                                                              │
│      pump HomeScreen                                                         │
│      verify HomeHero called the 4 original use cases with CURRENT MONTH      │
│      verifyNever the 4 original use cases with DateTime(2020)                │
│      verifyNever the 4 NEW Phase 16 use cases AT ALL (any startDate)         │
│                                                                              │
│    test 'HomeScreen file does not import ...':                              │
│      grep source for `state_time_window`         → isFalse                   │
│      grep source for `selectedTimeWindowProvider` → isFalse                  │
│      grep source for `state_ledger_snapshot`     → isFalse  ← NEW            │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Verification

- `flutter analyze lib/features/analytics/presentation/screens/analytics_screen.dart` → **No issues found** (0)
- `flutter analyze test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` → **No issues found** (0)
- `flutter analyze` (whole project) → **No issues found** (0)
- `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart -r expanded` → **2/2 passing** (`+2: All tests passed!`):
  - `HomeHero remains current-month keyed when Analytics window is year 2020` — green (existing assertions + 4 new verifyNever for Phase 16)
  - `HomeScreen file does not import state_time_window` — green (existing + new `state_ledger_snapshot` import check)
- Acceptance criteria checks (all pass):
  - SoulVsSurvivalCard + PerCategoryBreakdownCard references in analytics_screen.dart: **3** (1 SoulVsSurvival + 2 PerCategory)
  - References to the 4 new providers in analytics_screen.dart: **5** (1 comment + 4 invalidations across solo + family blocks)
  - D-12 comment intact: **2 occurrences** (1 original + 1 adjacent traceability comment in new code)
  - `grep -E 'ref\.invalidate\(homeHero|ref\.invalidate\(home[A-Z]'` → empty (no HomeHero invalidation introduced)
  - Distribution section insertion order (line numbers): `_CategoryDonutCard@113 < SoulVsSurvivalCard@121 < _SatisfactionHistogramOrFallback@130 < PerCategoryBreakdownCard@140 < PerCategoryBreakdownCard@154` — matches D-13 ✓
  - PerCategoryScope.{solo,you,family} references: **3** (1 solo, 1 you, 1 family in card construction)
  - 4 Mock class declarations + 4 late + 4 setUp instantiations: **12 mock-class references** ✓
  - verifyNever calls: **11 total** (7 original + 4 Phase 16) ✓
  - source-import assertion mentions `state_ledger_snapshot`: **2 occurrences** (1 expect + 1 reason) ✓

## Layer-Purity Check

`lib/features/analytics/presentation/screens/analytics_screen.dart` (now imports):
- `flutter/material.dart` (allowed)
- `flutter_riverpod/flutter_riverpod.dart` (allowed; presentation layer)
- `features/accounting/presentation/providers/repository_providers.dart` (allowed; cross-feature presentation)
- `features/family_sync/presentation/providers/state_active_group.dart` (allowed)
- `features/home/presentation/providers/state_shadow_books.dart` (allowed)
- `features/settings/presentation/providers/state_locale.dart` (allowed)
- `generated/app_localizations.dart` (allowed; i18n)
- `features/analytics/domain/models/time_window.dart` (allowed; same feature, domain)
- `features/analytics/presentation/providers/*.dart` (allowed; same feature, same layer — now includes `state_ledger_snapshot.dart`)
- `features/analytics/presentation/widgets/*.dart` (allowed; same feature, same layer — now includes `per_category_breakdown_card.dart` + `soul_vs_survival_card.dart`)

**No new imports from `lib/data/`** — CLAUDE.md Pitfall #2 honored.

## CLAUDE.md Rule Adherence

- ✅ Provider invalidations follow Riverpod 3 conventions (family params keyed identically to the build context).
- ✅ Immutability: no mutation in the screen; new card constructions are immutable Widget instances.
- ✅ Widget parameter pattern: `bookId / startDate / endDate / locale / currencyCode / isGroupMode` are all passed through; none hardcoded.
- ✅ File organization: analytics_screen.dart still at 658 lines (under 800 limit).
- ✅ All UI text via `S.of(context)` — no new hardcoded strings added.
- ✅ Test code adheres to mocktail/Riverpod 3 conventions (`overrideWith`, `verifyNever`, `any(named:)`).
- ✅ Zero analyzer warnings — `flutter analyze` clean on both modified files and the whole project.

## Deviations from Plan

### Minor adjustment (still within plan intent)

**1. [Discretion exercised] verifyNever uses `any(named: 'startDate')` instead of `startDate: DateTime(2020)` on the 4 new Phase 16 assertions.**

- **Why:** The plan's `<action>` step 4 sketched the assertions with `startDate: DateTime(2020)` matchers (mirroring the existing 4 assertions). However, the actual product invariant is stronger: HomeHero must NEVER invoke any of the 4 new Phase 16 use cases at all, irrespective of date — because the HomeHero widget tree does not consume `perCategorySoulBreakdownProvider` or `soulVsSurvivalSnapshotProvider` or their family variants. Using `any(named: 'startDate')` rather than `DateTime(2020)` produces a stronger zero-invocation assertion. This matches the spirit of the plan's acceptance criterion: *"prove that AnalyticsScreen's `_refresh()` invalidating the Phase 16 providers (with a year-2020 window) does NOT trigger calls to those same providers in HomeHero's context"* — the strictest interpretation of which is "no calls at all".
- **Outcome:** Same passing tests, stronger invariant. No regression risk because the test framework requires zero invocations across all parameter shapes — strictly stronger than zero invocations at a specific date.
- **Files modified:** `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart`
- **Commit:** `eab64f8`

### Auto-fixed Issues

None — the plan was executed exactly as written aside from the minor adjustment above.

## Deferred Issues (out of scope per SCOPE BOUNDARY rule)

Logged in `.planning/phases/16-per-category-breakdown-soul-vs-survival-comparison-happy-v2-/deferred-items.md`:

- **`test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart`** — `renders highlights sentence from aggregate value` and a couple of related cases fail looking for Japanese strings ("今月、家族の小確幸 23回", etc.) that no longer match the current ARB values. The test was NOT modified by 16-10 and the failure reproduces independent of my changes. This is a pre-existing ARB-key drift from a previous phase (likely Phase 14 ARB reconciliation or Phase 11/12 family insight refactor) that did not propagate to this widget test. Should be addressed in a separate ARB hygiene plan; out of 16-10 scope.

## TDD Gate Compliance

Plan 16-10 is `type: execute` (not `type: tdd`) — no plan-level RED/GREEN/REFACTOR sequence is required. The two tasks are individual `type="auto"` (not `tdd="true"`):

- Task 1 (analytics_screen.dart wiring): commit `feat(16-10): ...` — the only test exercising the integration is the existing `home_screen_isolation_test.dart` (extended in Task 2) and the per-widget tests created in Plans 16-07 + 16-08. No new test was authored alongside Task 1 because the wiring is structurally trivial (3 imports + 3 card constructions + 4 invalidations) and exercised by the extension in Task 2.
- Task 2 (isolation test extension): commit `test(16-10): ...` — extends a pre-existing test rather than authoring a new file; the new assertions pass on the first run because Task 1's `_refresh()` was carefully written to preserve D-12.

## Self-Check: PASSED

Created files:
- FOUND: `.planning/phases/16-per-category-breakdown-soul-vs-survival-comparison-happy-v2-/deferred-items.md`

Modified files:
- FOUND: `lib/features/analytics/presentation/screens/analytics_screen.dart` (verified via `git diff HEAD~2 -- lib/.../analytics_screen.dart` — 71 lines inserted)
- FOUND: `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` (verified via `git diff HEAD~1 -- test/.../home_screen_isolation_test.dart` — 115 lines inserted)

Commits:
- FOUND: `38ed9e6` feat(16-10): wire Phase 16 cards + invalidations into AnalyticsScreen
- FOUND: `eab64f8` test(16-10): extend HomeHero isolation test for Phase 16 providers

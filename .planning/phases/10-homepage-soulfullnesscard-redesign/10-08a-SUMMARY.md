---
phase: 10-homepage-soulfullnesscard-redesign
plan: 08a
subsystem: ui
tags: [home-screen, integration, wire-up, riverpod, async-resolution, flutter]

# Dependency graph
requires:
  - phase: 10-homepage-soulfullnesscard-redesign/07b
    provides: HomeHeroCard StatelessWidget with locked 10-field constructor (report/happiness/bestJoy/family/shadowBooks/shadowAggregate/currencyCode/locale/isGroupMode/onTap)
  - phase: 10-homepage-soulfullnesscard-redesign/05
    provides: bookByIdProvider for currency-code resolution (Pitfall #9 fallback)
provides:
  - "home_screen.dart wire-up to HomeHeroCard via single consolidated provider-resolution Builder"
  - "currency-code lookup through bookByIdProvider with documented JPY fallback"
  - "tap navigation from HomePage to AnalyticsScreen(bookId: bookId)"
  - "isGroupMode short-circuit gating for the 3 group-mode-only providers"
affects:
  - 10-08b (helper deletion + line-count enforcement; depends_on 08a)
  - 10-09 (test fixture cleanup; depends on this wire-up)
  - 10-10 (new test scaffold population)
  - Phase 11 (AnalyticsRegion enum will eventually replace bare bookId navigation)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Container-Widget-With-Async-Provider — parent screen resolves AsyncValue via .when() chain and passes resolved Freezed aggregates to a pure StatelessWidget child"
    - "Group-mode short-circuit — wrap optional providers behind isGroupMode and substitute const AsyncData(null/[]) when the gate is closed so the .when() chain resolves immediately in single mode"
    - "Pitfall #9 documented currency fallback — `'JPY'` literal is permitted only at the Book lookup boundary with an inline comment marker; future grep audits enforce single-occurrence invariant"

key-files:
  created: []
  modified:
    - lib/features/home/presentation/screens/home_screen.dart

key-decisions:
  - "Removed both SectionDivider blocks (homeMonthlyExpense / homeLedgersSection) — labels are subsumed by HomeHeroCard's internal hero label, so retaining them would duplicate copy"
  - "Kept top-level locale/isGroupMode/todayTxAsync watches outside the Builder because they are also consumed by the transaction-list section below; only the providers exclusive to HomeHeroCard moved inside the Builder"
  - "Added `// TODO(plan-10-08b): delete this helper` + `// ignore: unused_element` directives above each of the 3 dead helpers — analyzer-as-warning would otherwise block the commit gate; 10-08b removes both helper bodies and the markers atomically"
  - "Used local `loading()` / `error()` helper closures inside the Builder instead of repeating the SizedBox+CircularProgressIndicator literal six times — keeps the .when() chain compact without introducing a private method"
  - "Did NOT introduce an AsyncValue.combine extension or refactor the deeply nested .when() chain — explicit project convention per plan, scope is wire-up only"

patterns-established:
  - "Single Builder + .when() ladder — sequence the AsyncValue resolution at the boundary widget (not inside HomeHeroCard) so the leaf widget stays a pure StatelessWidget"
  - "isGroupMode-conditional const AsyncData fallback — `isGroupMode ? ref.watch(...).whenData((v)=>v) : const AsyncData<T?>(null)` lets the same .when() chain serve both modes without per-mode branches in the leaf widget"

requirements-completed: [HOMEUI-05, HOMEUI-06, HOMEUI-07, FAMILY-03]

# Metrics
duration: ~25min
completed: 2026-05-02
---

# Phase 10 Plan 08a: Wire HomeHeroCard into home_screen Summary

**HomeScreen now renders a single HomeHeroCard via a consolidated provider-resolution Builder, replacing MonthOverviewCard + LedgerComparisonSection + SoulFullnessCard while leaving the 3 inline helpers in place as marked dead code for Plan 10-08b cleanup.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-02
- **Completed:** 2026-05-02
- **Tasks:** 1 / 1
- **Files modified:** 1

## Accomplishments
- Replaced 3 separate widget call sites (`MonthOverviewCard`, `LedgerComparisonSection`, `SoulFullnessCard`) and their preceding section dividers with a single consolidated `HomeHeroCard` render under a `Builder` that resolves 6 providers via a nested `.when()` ladder.
- Wired currency-code lookup through `bookByIdProvider`, with a single documented `'JPY'` fallback firing only when the Book lookup itself fails (CLAUDE.md Pitfall #9 / B4 strict guard).
- Wired tap target to `Navigator.of(context).push(MaterialPageRoute(builder: (_) => AnalyticsScreen(bookId: bookId)))` per Pitfall #9 / D-11 — no `AnalyticsRegion` enum introduced (Phase 11 work).
- Implemented `isGroupMode` gating for the 3 group-mode-only providers (`familyHappinessProvider`, `shadowBooksProvider`, `shadowAggregateProvider`) so single-mode does not block on never-watched providers.
- Removed the now-unused widget imports (`month_overview_card.dart`, `ledger_comparison_section.dart`, `soul_fullness_card.dart`, `section_divider.dart`) and added `home_hero_card.dart`, `analytics_screen.dart`, `state_happiness.dart`, `family_happiness.dart`, and `accounting/repository_providers.dart`.
- All 3 inline helpers (`_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows`) remain in place, marked with `// TODO(plan-10-08b): delete this helper` + `// ignore: unused_element` per checker B3 split — Plan 10-08b removes them and the markers atomically.
- `flutter analyze lib/features/home/` reports 0 issues.

## Task Commits

Each task was committed atomically:

1. **Task 8a.1: Wire HomeHeroCard into home_screen.dart (no helper deletion)** — `801e807` (feat)

## Files Created/Modified

- `lib/features/home/presentation/screens/home_screen.dart` — Replaced 3 widget renders + 2 SectionDividers with one `Builder` (lines 79–186) that resolves `monthlyReportProvider`, `bookByIdProvider`, `happinessReportProvider`, `bestJoyMomentProvider`, plus 3 group-mode-gated providers (`familyHappinessProvider`, `shadowBooksProvider`, `shadowAggregateProvider`), then passes resolved values into `HomeHeroCard`. Added the 5 new imports and removed the 4 obsolete imports. The 3 dead-code helpers (`_buildLedgerRows`, `_computeSatisfaction`, `_computeHappinessROI`) remain at lines 303–414 with TODO + ignore markers awaiting 10-08b deletion.

### Pre/post line count

- Before: 386 lines (baseline from plan frontmatter)
- After: 435 lines (consolidated Builder + .when() ladder is verbose; helpers preserved)
- Plan 10-08b target: ≤349 lines (W7 floor; ~85-line decrease from helper deletion + import strip)

### New consolidated block line range

- `Builder(...)`: lines 79–186 (108 lines)
- Inside the Builder:
  - Provider watches: lines 81–113
  - `currencyCode` resolution + Pitfall #9 comment marker: lines 92–97
  - Group-mode gate (`familyAsync` / `shadowBooksAsync` / `shadowAggregateAsync`): lines 115–136
  - `loading()` / `error()` closures: lines 138–142
  - `.when()` ladder culminating in `HomeHeroCard(...)`: lines 144–184

### Imports diff

Added (5):
- `'../../../../application/accounting/category_localization_service.dart'` (re-ordered into the alphabetical block; was already imported)
- `'../../../../features/accounting/presentation/providers/repository_providers.dart'` — for `bookByIdProvider`
- `'../../../../features/analytics/domain/models/family_happiness.dart'` — for `FamilyHappiness?` type annotation in the conditional `whenData`
- `'../../../../features/analytics/presentation/providers/state_happiness.dart'` — for `happinessReportProvider`, `bestJoyMomentProvider`, `familyHappinessProvider`
- `'../../../../features/analytics/presentation/screens/analytics_screen.dart'` — for the `Navigator.push` target
- `'../widgets/home_hero_card.dart'` — for the new render

Removed (4):
- `'../widgets/ledger_comparison_section.dart'`
- `'../widgets/month_overview_card.dart'`
- `'../widgets/soul_fullness_card.dart'`
- `'../widgets/section_divider.dart'` (no remaining usage after the 2 dividers were removed)

Kept (unchanged):
- `'../models/ledger_row_data.dart'` — still consumed by `_buildLedgerRows` body; Plan 10-08b removes this import alongside the helper.

### Confirmation: 3 dead-code helpers still present

```
$ grep -E "_computeHappinessROI|_computeSatisfaction|_buildLedgerRows" lib/features/home/presentation/screens/home_screen.dart
  List<LedgerRowData> _buildLedgerRows(
  int _computeSatisfaction(AsyncValue<List<Transaction>> txAsync) {
  double _computeHappinessROI(MonthlyReport report) {
```

All 3 helpers retain their full bodies with `// TODO(plan-10-08b): delete this helper` and `// ignore: unused_element` directives above each declaration. Plan 10-08b owns their removal plus the line-count tightening (target < 350 lines).

## Decisions Made

- **Removed both `SectionDivider` blocks** (`homeMonthlyExpense` / `homeLedgersSection`) instead of keeping them above the new card — the HomeHeroCard's internal hero label (`homeHeroCardLabelSingle` / `homeHeroCardLabelGroup`) provides the section heading function. Keeping the dividers would duplicate copy and visually fragment what is now a single integrated card.
- **Kept top-level `localeAsync`, `isGroupMode`, `todayTxAsync` watches outside the Builder** — they are also consumed by the transaction-list section further down in `build()`. Watching them only inside the Builder would break those downstream consumers.
- **Added `// ignore: unused_element` directives** above each of the 3 dead helpers — the project's `analysis_options.yaml` treats `unused_element` as a warning, and the project commit gate is `flutter analyze` clean. Per the plan's explicit instruction (action Step 5), the suppressions are paired with `// TODO(plan-10-08b): delete this helper` markers so 10-08b removes the markers and helper bodies atomically.
- **Used local `loading()` / `error()` closure helpers** inside the Builder instead of inlining the `SizedBox(height: 320, child: Center(...))` literal six times — keeps the `.when()` ladder readable. This is purely a code-organization choice within the Builder body; no scope creep.
- **Did NOT extract the `.when()` ladder into a private method** — the plan explicitly forbids "introducing new top-level constants or private helpers beyond the `_ErrorText` already present" in 10-08a. (Plan 10-08b's escape hatch permits a `_buildHomeHeroCardSection` extraction if line-count compliance demands it.)
- **Did NOT introduce a combine-AsyncValues extension** — the plan calls the deeply nested `.when()` chain "hostile but matches the project's existing pattern" and explicitly defers any refactor.

## Deviations from Plan

**1. [Rule 1 - Bug] Comment text contained quoted `'JPY'` causing the `grep -c "'JPY'" == 1` acceptance criterion to fail with count=2**
- **Found during:** Task 8a.1, post-edit verification
- **Issue:** The Pitfall #9 comment originally read `// This is the SOLE legitimate 'JPY' literal in the home feature` — the quoted token in the comment matched `grep "'JPY'"` and produced a count of 2 instead of 1.
- **Fix:** Reworded the comment to `// This is the SOLE legitimate JPY currency-code literal in the home feature` (unquoted in prose).
- **Files modified:** `lib/features/home/presentation/screens/home_screen.dart`
- **Verification:** `grep -c "'JPY'" lib/features/home/presentation/screens/home_screen.dart` returns 1.
- **Committed in:** `801e807` (folded into Task 8a.1 commit before staging)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug; the prose phrasing accidentally matched the grep guard)
**Impact on plan:** Cosmetic correction so the B4 strict-guard `grep -c "'JPY'" == 1` passes. No functional change.

## Issues Encountered

- The plan template inside Task 8a.1's `<action>` block proposed `final locale = ref.watch(currentLocaleProvider);` and passed `locale: locale` directly. `currentLocaleProvider` actually returns `AsyncValue<Locale>`, not `Locale` — the plan flagged this as a possible adjustment ("if it IS an AsyncValue, adjust the `.when()` accordingly"). Resolved by reusing the existing top-level `locale` variable (`localeAsync.valueOrNull ?? const Locale('ja')`), which is already the project's established pattern in `home_screen.dart`. No `.when()` adjustment needed; passed `Locale` directly to `HomeHeroCard`.
- The plan template did not address whether to remove the 2 `SectionDivider` blocks. Resolved by removing both — see Decisions Made above. Side-effect: the `section_divider.dart` import had no remaining usage and was also removed (otherwise the analyzer would emit `unused_import`).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- HomeHeroCard now renders correctly on the home screen with both single-mode and group-mode data flows resolved at the parent.
- Plan 10-08b is unblocked: the 3 dead-code helpers carry the `// TODO(plan-10-08b)` + `// ignore: unused_element` markers it expects to remove, and the import diff has stabilized so 10-08b's only remaining import to drop is `'../models/ledger_row_data.dart'` (per its own action Step 2).
- `home_screen_test.dart` is expected to fail (uses `find.byType(MonthOverviewCard)` etc. — those widgets no longer render) — Plan 10-09 owns deletion of obsolete tests; Plan 10-10 owns the new test scaffold.

## Self-Check: PASSED

Verified:
- File `lib/features/home/presentation/screens/home_screen.dart` exists at the expected absolute path.
- Commit `801e807` exists in `git log --oneline`.
- `flutter analyze lib/features/home/` reports `No issues found!`.
- All 10 acceptance criteria pass:
  1. `home_hero_card.dart` import present
  2. No imports of the 3 obsolete widgets
  3. No call sites of the 3 obsolete widgets
  4. `HomeHeroCard(` call site present
  5. `bookByIdProvider` referenced
  6. Pitfall #9 / "fallback only when Book is missing" comment marker present
  7. `'JPY'` literal count == 1
  8. `AnalyticsScreen(bookId: bookId)` navigation present
  9. No `AnalyticsRegion` / `initialRegion` references
  10. 3 dead-code helpers still present (10-08b deletes them)

---
*Phase: 10-homepage-soulfullnesscard-redesign*
*Plan: 08a*
*Completed: 2026-05-02*

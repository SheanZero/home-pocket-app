---
phase: 10-homepage-soulfullnesscard-redesign
plan: 09
subsystem: home/presentation
tags: [deletion, cleanup, test-retarget]

# Dependency graph
requires:
  - phase: 10-homepage-soulfullnesscard-redesign
    provides: 10-08a + 10-08b (HomeHeroCard wired in home_screen.dart, all imports of the 3 obsolete widgets removed, dead helpers + LedgerRowData usages purged)
provides:
  - 3 obsolete production widgets physically removed (soul_fullness_card.dart, month_overview_card.dart, ledger_comparison_section.dart)
  - 1 obsolete model removed (ledger_row_data.dart + its generated freezed file)
  - 6 obsolete unit/widget test files removed (the duplicate home_screen_test.dart under test/features/ was a Rule 3 deletion — it imported the deleted classes and was superseded by the canonical test/widget/.../home_screen_test.dart)
  - 1 obsolete golden image + golden test deleted
  - test/widget/features/home/presentation/screens/home_screen_test.dart retargeted from 3 separate widget finders to a single HomeHeroCard finder, with ProviderScope overrides wired for happinessReportProvider / bestJoyMomentProvider / bookByIdProvider via the Plan 10-03 fixtures
affects: [home-screen-test]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Rule 1 documentation hygiene: when deleting a class, comments naming the deleted class were rewritten to refer to the cards by description (e.g., 'the legacy month-overview, ledger-comparison, and soul-fullness cards') so the static-analysis grep for dangling symbols stays at zero matches without losing migration context."

key-files:
  created:
    - .planning/phases/10-homepage-soulfullnesscard-redesign/10-09-SUMMARY.md
  modified:
    - lib/features/home/presentation/screens/home_screen.dart (comment reword only — strip dangling class names from migration comment)
    - lib/features/home/presentation/widgets/home_hero_card.dart (comment reword only — strip dangling class names from doc comment)
    - test/widget/features/home/presentation/screens/home_screen_test.dart (rewritten: drop 3 deleted-widget finders + 3 deleted-widget imports → single HomeHeroCard finder + happinessReport/bestJoyMoment/bookById overrides)
  deleted:
    - lib/features/home/presentation/widgets/soul_fullness_card.dart
    - lib/features/home/presentation/widgets/month_overview_card.dart
    - lib/features/home/presentation/widgets/ledger_comparison_section.dart
    - lib/features/home/presentation/models/ledger_row_data.dart
    - lib/features/home/presentation/models/ledger_row_data.freezed.dart
    - test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart
    - test/widget/features/home/presentation/widgets/month_overview_card_test.dart
    - test/features/home/presentation/widgets/soul_fullness_card_test.dart
    - test/features/home/presentation/widgets/ledger_comparison_section_test.dart
    - test/features/home/presentation/models/ledger_row_data_test.dart
    - test/features/home/presentation/screens/home_screen_test.dart
    - test/golden/soul_fullness_card_golden_test.dart
    - test/golden/goldens/soul_fullness_card_ja.png

key-decisions:
  - "Comment-reword instead of comment-delete: keeps migration context (what HomeHeroCard replaces) without leaving dangling symbol references in the codebase."
  - "Delete test/features/home/presentation/screens/home_screen_test.dart (Rule 3 deviation): it was an obsolete duplicate of the canonical test/widget/.../home_screen_test.dart, imported all 3 deleted widgets, and asserted shadow-book ledger-row rendering that the new HomeHeroCard owns and tests separately."
  - "Drop SectionDivider / homeMonthlyExpense / homeLedgersSection assertions in the retargeted home_screen_test.dart: the new flat layout introduced in earlier Phase 10 waves no longer renders SectionDividers (verified: `grep SectionDivider lib/features/home/presentation/screens/home_screen.dart` → 0)."

patterns-established:
  - "Deletion plan + grep-zero verification: every named class targeted for deletion is grep'd lib-wide before the commit; if comments still match (only legitimate doc references remain), the comments are reworded to remove the dangling symbol so the grep returns 0 matches."

requirements-completed: [HOMEUI-01]

# Metrics
duration: ~25min
completed: 2026-05-02
---

# Phase 10 Plan 09: Delete Obsolete Cards + Retarget Home Test

**Removed 3 production widgets, 1 model (+ its freezed companion), 6 obsolete test files, and 1 golden image. Updated home_screen_test.dart to assert against HomeHeroCard with the Plan 10-03 happiness fixtures. flutter analyze: 0 issues. flutter test (home/): 74 passed.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-05-02
- **Tasks:** 2
- **Files deleted:** 13 (5 lib + 8 test)
- **Files modified:** 3

## Accomplishments

### Task 9.1 — Delete obsolete production widgets + LedgerRowData model
- Verified zero remaining consumers: `grep -rE "SoulFullnessCard|MonthOverviewCard|LedgerComparisonSection|LedgerRowData" lib/ --include="*.dart"` (excluding the targets themselves) returned only:
  - 2 doc-comment references in `home_screen.dart` and `home_hero_card.dart` (migration comments naming the deleted classes)
  - 30+ matches inside `ledger_row_data.freezed.dart` (generated companion of the model — auto-removed when the source is removed)
- `git rm`-ed the 4 production targets + the freezed companion (5 files total).
- Reworded the 2 migration doc comments to no longer name the deleted classes (kept the migration context as a description: "the legacy month-overview, ledger-comparison, and soul-fullness cards").
- `flutter analyze lib/features/home/` → **No issues found**.
- `flutter analyze lib/` → **No issues found**.
- Final grep `grep -rE "SoulFullnessCard|MonthOverviewCard|LedgerComparisonSection|LedgerRowData" lib/ --include="*.dart"` → **0 matches**.

### Task 9.2 — Delete obsolete tests + retarget home_screen_test on HomeHeroCard
- `git rm`-ed 6 test files referencing the deleted widgets/model:
    - `test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart`
    - `test/widget/features/home/presentation/widgets/month_overview_card_test.dart`
    - `test/features/home/presentation/widgets/soul_fullness_card_test.dart` (parallel duplicate path)
    - `test/features/home/presentation/widgets/ledger_comparison_section_test.dart` (Rule 3: file imported a deleted widget)
    - `test/features/home/presentation/models/ledger_row_data_test.dart` (Rule 3: file imported the deleted model)
    - `test/features/home/presentation/screens/home_screen_test.dart` (Rule 3: obsolete duplicate of the canonical test under `test/widget/...`; imported all 3 deleted widgets and asserted shadow-book ledger-row rendering that HomeHeroCard now owns and tests separately)
- `git rm` `test/golden/soul_fullness_card_golden_test.dart` + the `test/golden/goldens/soul_fullness_card_ja.png` golden image.
- Rewrote `test/widget/features/home/presentation/screens/home_screen_test.dart`:
    - Removed imports for the 3 deleted widgets.
    - Added imports: `home_hero_card.dart`, `state_happiness.dart`, accounting `repository_providers.dart` (for `bookByIdProvider`), `Book` model, and `helpers/happiness_test_fixtures.dart`.
    - Replaced 3 separate `find.byType(...)` assertions (one per deleted card) with a single `find.byType(HomeHeroCard)` assertion in 2 retained tests.
    - Wired `ProviderScope` overrides for `happinessReportProvider` / `bestJoyMomentProvider` / `bookByIdProvider` using the Plan 10-03 fixture factories (`fixtureMonthlyReportRich`, `fixtureHappinessReportRich`, `fixtureBestJoyResultRich`) plus a local `_mockBook` Book.
    - Dropped the SectionDivider / `homeMonthlyExpense` / `homeLedgersSection` assertions (the new flat home_screen no longer renders SectionDividers — verified by grep).
- `flutter analyze test/widget/features/home/presentation/screens/home_screen_test.dart` → **No issues found**.
- `flutter test test/widget/features/home/presentation/screens/home_screen_test.dart` → **11 passed**.
- `flutter test test/widget/features/home/ test/features/home/` → **74 passed, 20 skipped, 0 failed** (skipped are the Phase 10 placeholder tests in `home_hero_card_test.dart` etc., not introduced by this plan).
- `flutter analyze` (project-wide) → **No issues found**.

## Task Commits

1. **Task 9.1: Delete obsolete production widgets + LedgerRowData model** — `7874a93` `refactor(10-09): delete obsolete widgets + LedgerRowData model`
2. **Task 9.2: Delete obsolete tests + retarget home_screen_test on HomeHeroCard** — `9f4918b` `test(10-09): delete obsolete tests + golden, retarget home_screen_test on HomeHeroCard`

## Files Deleted (13)

### Production (5)
- `lib/features/home/presentation/widgets/soul_fullness_card.dart`
- `lib/features/home/presentation/widgets/month_overview_card.dart`
- `lib/features/home/presentation/widgets/ledger_comparison_section.dart`
- `lib/features/home/presentation/models/ledger_row_data.dart`
- `lib/features/home/presentation/models/ledger_row_data.freezed.dart` (generated companion)

### Tests (7)
- `test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart`
- `test/widget/features/home/presentation/widgets/month_overview_card_test.dart`
- `test/features/home/presentation/widgets/soul_fullness_card_test.dart`
- `test/features/home/presentation/widgets/ledger_comparison_section_test.dart`
- `test/features/home/presentation/models/ledger_row_data_test.dart`
- `test/features/home/presentation/screens/home_screen_test.dart`
- `test/golden/soul_fullness_card_golden_test.dart`

### Golden image (1)
- `test/golden/goldens/soul_fullness_card_ja.png`

## Files Modified (3)

- `lib/features/home/presentation/screens/home_screen.dart` — comment reword (3 lines) so the dangling class names disappear from the migration comment.
- `lib/features/home/presentation/widgets/home_hero_card.dart` — comment reword (3 lines) for the same reason in the doc comment.
- `test/widget/features/home/presentation/screens/home_screen_test.dart` — full rewrite (236 → 213 lines) to assert against HomeHeroCard.

## Decisions Made

- **Comment reword instead of comment delete.** The plan's `must_haves.truths` says "0 matches in lib/" for the deleted class names. Comments matched the grep too. Rather than deleting the comments (which would lose migration context for future maintainers), the comments were reworded to refer to the cards by description ("the legacy month-overview, ledger-comparison, and soul-fullness cards"). This satisfies the grep-zero acceptance criterion and keeps the migration trail.
- **Bulk deletion exceeds the 5-file guard.** This plan deletes 13 files; the plan briefing notes the orchestrator will set `ALLOW_BULK_DELETE=1` for this wave's merge. No action required from the executor.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reworded migration comments to keep grep at zero matches**
- **Found during:** Task 9.1 verification step.
- **Issue:** Plan must-have "no Dart file in `lib/` references the deleted widgets" via `grep -rE 'SoulFullnessCard|MonthOverviewCard|LedgerComparisonSection|LedgerRowData' lib/` returns 0 matches. After deleting the production files, two comments still matched (one in `home_screen.dart`, one in `home_hero_card.dart`).
- **Fix:** Reworded both comments to refer to the cards by description, not class name. Migration context preserved.
- **Files modified:** `lib/features/home/presentation/screens/home_screen.dart`, `lib/features/home/presentation/widgets/home_hero_card.dart`.
- **Commit:** `7874a93`.

**2. [Rule 3 - Blocking] Deleted ledger_row_data.freezed.dart generated companion**
- **Found during:** Task 9.1 grep for remaining references after `git rm`-ing `ledger_row_data.dart`.
- **Issue:** The generated `ledger_row_data.freezed.dart` was committed alongside its source. Removing only the source leaves the freezed file referencing nothing → it would error out on next `dart format` / `flutter analyze` because its `part of` directive points at a missing source. The plan's `<files>` list mentioned only `ledger_row_data.dart`.
- **Fix:** `git rm`-ed the freezed file in the same commit. (The freezed file is a build_runner artifact normally excluded from VCS via `.gitignore`, but this project commits generated freezed files so they need to be removed manually here.)
- **Files modified:** `lib/features/home/presentation/models/ledger_row_data.freezed.dart` deleted.
- **Commit:** `7874a93`.

**3. [Rule 3 - Blocking] Deleted 3 obsolete tests not in the plan's `<files>` list**
- **Found during:** Task 9.2 grep for remaining references in `test/`.
- **Issue:** Three test files outside the plan's `<files>` list referenced the deleted classes and would block the build:
    - `test/features/home/presentation/widgets/soul_fullness_card_test.dart`
    - `test/features/home/presentation/widgets/ledger_comparison_section_test.dart`
    - `test/features/home/presentation/models/ledger_row_data_test.dart`
- **Fix:** `git rm`-ed all three. They are widget/model tests for symbols that no longer exist; their coverage is irrelevant once the symbols are gone.
- **Commit:** `9f4918b`.

**4. [Rule 3 - Blocking] Deleted obsolete duplicate home_screen_test.dart**
- **Found during:** Task 9.2 grep for remaining references in `test/`.
- **Issue:** `test/features/home/presentation/screens/home_screen_test.dart` is an obsolete duplicate of the canonical `test/widget/features/home/presentation/screens/home_screen_test.dart` (the file the plan instructed me to update). It imported all 3 deleted widgets, used a stale ProviderScope override pattern, and asserted shadow-book ledger-row rendering ("田中の帳本" rows), which the new `HomeHeroCard` now owns and tests in `home_hero_card_test.dart` (Plan 10-04). Updating it would have meant duplicating the canonical test for the same coverage.
- **Fix:** `git rm`-ed it. Coverage of the assertions worth keeping (group-mode badge, member-initial-in-tag, FamilyInviteBanner show/hide) is preserved in the canonical retargeted home_screen_test.dart and in `home_hero_card_test.dart` / `home_transaction_tile_test.dart`.
- **Commit:** `9f4918b`.

**5. [Rule 1 - Bug] Dropped SectionDivider assertions in the retargeted home_screen_test.dart**
- **Found during:** Task 9.2 retarget of `test/widget/.../home_screen_test.dart`.
- **Issue:** The original test asserted `find.byType(SectionDivider) findsNWidgets(2)` plus 2 `Text` finders for `homeMonthlyExpense` / `homeLedgersSection` labels. The new flat home_screen.dart (introduced in earlier Phase 10 waves) no longer renders SectionDividers — verified by grep. Keeping the assertions would make the test fail.
- **Fix:** Removed the SectionDivider-related assertions; kept all other assertions and only swapped widget-type targets. The retained 11 tests still cover layout structure, mode switching, transactions, localization, and HomeHeroCard presence.
- **Commit:** `9f4918b`.

## Authentication Gates

None.

## Issues Encountered

None.

## Verification

- `test ! -f lib/features/home/presentation/widgets/soul_fullness_card.dart` → exit 0 ✓
- `test ! -f lib/features/home/presentation/widgets/month_overview_card.dart` → exit 0 ✓
- `test ! -f lib/features/home/presentation/widgets/ledger_comparison_section.dart` → exit 0 ✓
- `test ! -f lib/features/home/presentation/models/ledger_row_data.dart` → exit 0 ✓
- `test ! -f test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart` → exit 0 ✓
- `test ! -f test/widget/features/home/presentation/widgets/month_overview_card_test.dart` → exit 0 ✓
- `test ! -f test/golden/soul_fullness_card_golden_test.dart` → exit 0 ✓
- `test ! -f test/golden/goldens/soul_fullness_card_ja.png` → exit 0 ✓
- `grep -rE "SoulFullnessCard|MonthOverviewCard|LedgerComparisonSection|LedgerRowData" lib/ --include="*.dart"` → 0 matches ✓
- `grep -rE "SoulFullnessCard|MonthOverviewCard|LedgerComparisonSection|LedgerRowData" test/ --include="*.dart"` → 0 matches ✓
- `grep -q "find.byType(HomeHeroCard)" test/widget/features/home/presentation/screens/home_screen_test.dart` → exit 0 ✓
- `flutter analyze lib/features/home/` → No issues found ✓
- `flutter analyze` (project-wide) → No issues found ✓
- `flutter test test/widget/features/home/presentation/screens/home_screen_test.dart` → 11 passed ✓
- `flutter test test/widget/features/home/ test/features/home/` → 74 passed, 20 skipped, 0 failed ✓

## Next Phase Readiness

- All Phase 10 deletions are complete. The codebase no longer contains any reference (production or test) to `SoulFullnessCard`, `MonthOverviewCard`, `LedgerComparisonSection`, or `LedgerRowData`.
- HomeHeroCard is the sole owner of the previous-trio's rendering responsibilities and is exercised by `home_hero_card_test.dart` (Plan 10-04) + the retargeted `home_screen_test.dart` (this plan).
- Wave 6 wraps Phase 10. Future plans that touch the home screen can rely on the canonical test path under `test/widget/.../`.

## Self-Check

```
$ git log --oneline -2
9f4918b test(10-09): delete obsolete tests + golden, retarget home_screen_test on HomeHeroCard
7874a93 refactor(10-09): delete obsolete widgets + LedgerRowData model
```

### Files claimed deleted — verified

| File | Status |
| --- | --- |
| lib/features/home/presentation/widgets/soul_fullness_card.dart | MISSING (deleted) ✓ |
| lib/features/home/presentation/widgets/month_overview_card.dart | MISSING (deleted) ✓ |
| lib/features/home/presentation/widgets/ledger_comparison_section.dart | MISSING (deleted) ✓ |
| lib/features/home/presentation/models/ledger_row_data.dart | MISSING (deleted) ✓ |
| lib/features/home/presentation/models/ledger_row_data.freezed.dart | MISSING (deleted) ✓ |
| test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart | MISSING (deleted) ✓ |
| test/widget/features/home/presentation/widgets/month_overview_card_test.dart | MISSING (deleted) ✓ |
| test/features/home/presentation/widgets/soul_fullness_card_test.dart | MISSING (deleted) ✓ |
| test/features/home/presentation/widgets/ledger_comparison_section_test.dart | MISSING (deleted) ✓ |
| test/features/home/presentation/models/ledger_row_data_test.dart | MISSING (deleted) ✓ |
| test/features/home/presentation/screens/home_screen_test.dart | MISSING (deleted) ✓ |
| test/golden/soul_fullness_card_golden_test.dart | MISSING (deleted) ✓ |
| test/golden/goldens/soul_fullness_card_ja.png | MISSING (deleted) ✓ |

### Commits — verified

- `7874a93` — found in `git log` ✓
- `9f4918b` — found in `git log` ✓

## Self-Check: PASSED

---
*Phase: 10-homepage-soulfullnesscard-redesign*
*Completed: 2026-05-02*

---
phase: 11-statistics-surface-for
plan: 06
subsystem: analytics
tags: [widget, story, family, fallback, anti-leaderboard, flutter]

requires:
  - phase: 11-statistics-surface-for
    provides: Plan 11-03 analytics providers, ARB keys, and story-card domain contracts
provides:
  - LargestExpenseStoryCard for the stories-group total ledger card
  - BestJoyStoryStrip with the Empty / sat<=2 / sat>2 three-arm contract
  - FamilyInsightCard sentence-form aggregate rendering gated to group mode with shadow books
  - JoyLedgerThinSampleFallback for n<5 Joy trend + histogram replacement
affects: [11-statistics-surface-for, analytics, statsui]

tech-stack:
  added: []
  patterns: [sealed MetricResult widget dispatch, caller-owned navigation callbacks, aggregate-only family rendering]

key-files:
  created:
    - lib/features/analytics/presentation/widgets/largest_expense_story_card.dart
    - lib/features/analytics/presentation/widgets/best_joy_story_strip.dart
    - lib/features/analytics/presentation/widgets/family_insight_card.dart
    - lib/features/analytics/presentation/widgets/joy_ledger_thin_sample_fallback.dart
    - test/widget/features/analytics/presentation/widgets/largest_expense_story_card_test.dart
    - test/widget/features/analytics/presentation/widgets/best_joy_story_strip_test.dart
    - test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart
  modified: []

key-decisions:
  - "TransactionDetailScreen is absent in this branch, so story cards expose caller-owned tap callbacks for Plan 11-07 wiring."
  - "FamilyInsightCard reads only familyHighlightsSum and sharedJoyInsight; medianSatisfaction and any per-person concepts stay out of the widget."

patterns-established:
  - "Story widgets localize category IDs through CategoryLocalizationService.resolveFromId and format dates/currency before rendering ARB templates."
  - "Family mode cards use the explicit isGroupMode && shadowBooks.isNotEmpty render gate."

requirements-completed: [STATSUI-02, STATSUI-06]

duration: 8min
completed: 2026-05-03
---

# Phase 11 Plan 06: Story and Family Analytics Widgets Summary

**Variant δ story cards now render total-ledger largest expense, Best Joy, family aggregate insight, and the n<5 Joy fallback without opening any leaderboard or free-text exposure surface.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-03T15:03:11Z
- **Completed:** 2026-05-03T15:11:22Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `LargestExpenseStoryCard` with localized category, JPY-aware amount formatting, short date formatting, empty state, safe semantics, and caller-owned tap handling.
- Added `BestJoyStoryStrip` with the required sealed three-arm switch: `Empty`, `Value` with `soulSatisfaction <= 2`, and high-rated `Value`.
- Added `FamilyInsightCard` using only aggregate family fields and the `isGroupMode && shadowBooks.isNotEmpty` gate.
- Added `JoyLedgerThinSampleFallback` for Plan 11-07 to replace both Joy trend and histogram cards when sample size is below 5.

## Task Commits

Each TDD gate/task was committed atomically:

1. **Task 1 RED: story card widget tests** - `ca22a59` (test)
2. **Task 1 GREEN: largest expense and Best Joy story cards** - `5a1cb59` (feat)
3. **Task 2 RED: family insight widget tests** - `bbb85a7` (test)
4. **Task 2 GREEN: family insight and thin-sample fallback** - `e31715d` (feat)

**Plan metadata:** committed separately with this SUMMARY only. Shared `.planning/STATE.md` and `.planning/ROADMAP.md` were intentionally left untouched for the orchestrator.

## Files Created/Modified

- `lib/features/analytics/presentation/widgets/largest_expense_story_card.dart` - Total-ledger largest expense story card with survival tint.
- `lib/features/analytics/presentation/widgets/best_joy_story_strip.dart` - Joy story strip with anti-`¥10 candy` low-satisfaction empty handling.
- `lib/features/analytics/presentation/widgets/family_insight_card.dart` - Group-mode-only family aggregate sentence card with olive tint.
- `lib/features/analytics/presentation/widgets/joy_ledger_thin_sample_fallback.dart` - Joint thin-sample fallback card with add-entry CTA.
- `test/widget/features/analytics/presentation/widgets/largest_expense_story_card_test.dart` - Rendering, empty, tap, and semantics coverage.
- `test/widget/features/analytics/presentation/widgets/best_joy_story_strip_test.dart` - Three-arm switch, tap, and style coverage.
- `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` - Render gate, aggregate sentence, empty sentence, and source guard coverage.
- `.planning/phases/11-statistics-surface-for/11-06-SUMMARY.md` - Plan completion record.

## Decisions Made

- Used caller-provided callbacks instead of direct navigation because `TransactionDetailScreen` does not exist in this branch. This follows the plan fallback for absent transaction-detail navigation infrastructure.
- Used existing `AppColors.olive` alpha tint for FamilyInsightCard because the olive token exists.
- Kept `BestJoyStoryStrip` separate from `HomeHeroCard` per D-14; no shared base widget was extracted.

## Deviations from Plan

None - plan executed within its allowed fallback path.

## Issues Encountered

- `flutter test` and `flutter analyze` still print the existing pub advisory decode warning: `FormatException: advisoriesUpdated must be a String`. The commands exited 0 after dependency resolution.
- Plans 11-04/11-05 had concurrent uncommitted files in the worktree, so final analyzer verification was scoped to the four owned 11-06 widget files.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The `= null` matches in the owned widgets are conditional callback/empty-state branches, not UI stubs.

## Threat Flags

None. This plan added presentation widgets only; no endpoint, auth path, file access, schema, persistence, or network trust boundary was introduced.

## Security and Contract Evidence

- T-Information-1: story-card semantic labels include localized category, amount, and date/score only. Widget source grep for `description|merchant|note` returned `0` in both story widgets.
- D-13 anti-leaderboard: `FamilyInsightCard` source grep for `byMemberId|memberContribution|perMember|memberId` returned `0`.
- D-14: `BestJoyStoryStrip` is a standalone widget and does not extract or share HomeHeroCard code.
- Phase 10 D-04: `BestJoyStoryStrip` renders the empty state for `soulSatisfaction <= 2`.
- Phase 10 D-08 / Pitfall 6: `FamilyInsightCard` renders only when `isGroupMode && shadowBooks.isNotEmpty`.

## Verification

- RED Task 1: `flutter test test/widget/features/analytics/presentation/widgets/largest_expense_story_card_test.dart test/widget/features/analytics/presentation/widgets/best_joy_story_strip_test.dart` failed because the two widget files did not exist.
- GREEN Task 1: `flutter test test/widget/features/analytics/presentation/widgets/largest_expense_story_card_test.dart test/widget/features/analytics/presentation/widgets/best_joy_story_strip_test.dart` passed with 9 tests.
- Task 1 analyzer: `flutter analyze lib/features/analytics/presentation/widgets/largest_expense_story_card.dart lib/features/analytics/presentation/widgets/best_joy_story_strip.dart` reported `No issues found!`.
- RED Task 2: `flutter test test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` failed because `family_insight_card.dart` did not exist.
- GREEN Task 2: `flutter test test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` passed with 7 tests.
- Task 2 analyzer: `flutter analyze lib/features/analytics/presentation/widgets/family_insight_card.dart lib/features/analytics/presentation/widgets/joy_ledger_thin_sample_fallback.dart` reported `No issues found!`.
- Plan-level targeted tests: `flutter test test/widget/features/analytics/presentation/widgets/largest_expense_story_card_test.dart test/widget/features/analytics/presentation/widgets/best_joy_story_strip_test.dart test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` passed with 16 tests.
- Plan-level owned analyzer: `flutter analyze lib/features/analytics/presentation/widgets/largest_expense_story_card.dart lib/features/analytics/presentation/widgets/best_joy_story_strip.dart lib/features/analytics/presentation/widgets/family_insight_card.dart lib/features/analytics/presentation/widgets/joy_ledger_thin_sample_fallback.dart` reported `No issues found!`.

## Next Phase Readiness

Plan 11-07 can import the four new widgets and wire the caller-owned callbacks from `AnalyticsScreen`. The thin-sample fallback is ready to replace both Joy chart slots when `dailyJoyPerYen.totalSampleSize < 5`.

## Self-Check: PASSED

- Found all four created widget files.
- Found task commits `ca22a59`, `5a1cb59`, `bbb85a7`, and `e31715d`.
- Targeted widget tests and owned-file analyzer checks passed.
- No `.planning/STATE.md` or `.planning/ROADMAP.md` edits were made.

---
*Phase: 11-statistics-surface-for*
*Completed: 2026-05-03*

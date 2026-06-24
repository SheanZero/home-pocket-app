---
phase: 52-recognition-ux-english-voice
plan: 03
subsystem: ui
tags: [riverpod, voice, recognition, learning-table, correction, recux, flutter, widget-test]

# Dependency graph
requires:
  - phase: 52-01
    provides: VoiceParseResult.resolvedKeyword (verbatim write==read key) + band/alternates threaded from RecognitionOutcome
  - phase: 52-02
    provides: AlternateCategoryChips chip-tap onSelect path + band/chips wiring in transaction_details_form.dart (_applyCategorySelection shared write set)
provides:
  - "Deferred category-correction reflux: pending stash set on category change, ONE KEYWORD-table write fired at confirmed save (D-05)"
  - "Both chip-tap and full-selector paths count as corrections through the shared _applyCategorySelection (D-06)"
  - "discardPendingCorrection() public hook wired into host reset / 连续记账 / back paths"
  - "Null/empty resolvedKeyword writes nothing; merchant table never touched on the correction path (D-07/D-16)"
  - "transaction_details_form_correction_test.dart — 6 widget cases proving defer/chip/selector/null/merchant/revert"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Deferred-write stash: capture (resolvedKeyword, correctedCategoryId) on interactive change; fire once at confirmed save; discard on abandon"
    - "Host-driven imperative setters (updateCategory) clear the stash — a fresh-slate push is never an interactive correction"

key-files:
  created:
    - test/widget/features/accounting/presentation/widgets/transaction_details_form_correction_test.dart
  modified:
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/accounting/presentation/screens/manual_one_step_screen.dart

key-decisions:
  - "D-20 (52-03): the deferred correction is a stash field (_PendingCategoryCorrection) set in _applyCategorySelection and fired in submit()'s .new success path — chip-tap and full-selector both flow through the shared write set so both count (D-06); save-time gate re-checks final category != recognized original (defense-in-depth)"
  - "D-21 (52-03): the host-driven updateCategory (voice batch-fill / snapshot-restore / continuous re-seed) clears the stash since a fresh slate is not an interactive correction; reset/连续记账/back additionally call discardPendingCorrection() explicitly for robustness against null-category snapshots"

patterns-established:
  - "Defer-to-save reflux: never write a learning table on exploratory UI change; stash + fire once at the confirmed terminal action; discard on abandon to avoid table pollution"

requirements-completed: [RECUX-03]

# Metrics
duration: ~25min
completed: 2026-06-24
status: complete
---

# Phase 52 Plan 03: Deferred Category-Correction Reflux Summary

**Moved the `category_keyword_preferences` learning write from immediate-on-category-change to a single deferred write at confirmed transaction save, counting both the chip-tap and full-selector paths as corrections, with discard-on-abandon and null-keyword/merchant-table protection (RECUX-03 / D-05/D-06/D-07).**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-24
- **Completed:** 2026-06-24
- **Tasks:** 2
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- Replaced the immediate `correctionUseCase.execute()` inside `_applyCategorySelection` with a pending stash (`_PendingCategoryCorrection`: `resolvedKeyword` verbatim + `correctedCategoryId`).
- Wired the deferred write to fire exactly once on the `.new` confirmed-save path, gated on a non-empty keyword AND the final category differing from the recognized original.
- Made both the chip-tap (52-02 `onSelect`) and the full-selector (`_editCategory` / exit-chip) paths record corrections through the shared `_applyCategorySelection` write set.
- Added `discardPendingCorrection()` and wired it into the host's 重置·恢复账目 (snapshot-restore) and 连续记账 (continuous-entry) reset paths; `updateCategory` (host-driven push) clears the stash too.
- Authored a 6-case widget test proving defer-on-abandon, chip-path single write, selector-path single write, null-keyword skip, no-merchant-table write, and revert-to-original discard.

## Task Commits

1. **Task 1: Defer the correction write from change to save (stash pending)** — `c4b44141` (refactor)
2. **Task 2: Deferred-correction widget tests (TDD)** — `77689a6c` (test)

## Files Created/Modified
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` — replaced immediate write with `_PendingCategoryCorrection` stash; set/clear in `_applyCategorySelection`; clear in `updateCategory`; fire once in `submit()` `.new` success path; new `discardPendingCorrection()` + `_PendingCategoryCorrection` class.
- `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` — call `discardPendingCorrection()` in `_onVoiceReset` (重置·恢复账目) and `_resetForContinuousEntry` (连续记账).
- `test/widget/features/accounting/presentation/widgets/transaction_details_form_correction_test.dart` — NEW; spy `RecordCategoryCorrectionUseCase` + spy `MerchantCategoryPreferenceRepository`; 6 cases.

## Decisions Made
- **D-20 / D-21** (see frontmatter). The stash approach makes the defer-to-save intent explicit and robust: reverting to the recognized-original category clears the stash, so no spurious correction is recorded; the host-driven imperative `updateCategory` is treated as a fresh slate (not a user correction). The save-time gate re-checks `_category.id != _initialCategoryId` as defense-in-depth.
- Write key stays `resolvedKeyword` verbatim (write==read identity, 260526-pg6); a null/empty keyword produces no stash, so save writes nothing and never falls back to the merchant table (D-07/D-16).
- The pre-existing Phase-18 merchant→category ML hook (`merchantCategoryLearningServiceProvider.recordSelection`) in `submit()` is unchanged and out of scope — it only fires when a merchant string is filled and is NOT part of the correction path. The test asserts the merchant table is never written when no merchant is entered on the correction flow.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- The "revert to original" test initially tapped the original chip after a first chip tap, but D-09 collapses the chips on the first pick. Resolved by re-pushing recognition (`updateRecognition`) to re-render the chips before the second tap — exercising the genuine revert-clears-stash path. Minor test-construction issue, no production-code impact.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- RECUX-03 complete. Remaining incomplete plan in the phase: 52-06 (the trilingual ARB-parity + anti-toxicity sweep + golden re-baseline close-out wave). The new test file and the band/chips/correction surfaces from 52-01/02/03 are inputs to that inline close-out gate.
- No blockers. `flutter analyze` clean (0 issues project-wide); the correction widget test and the existing form/host tests are green.

## Self-Check: PASSED

All claimed files exist on disk; both task commits (`c4b44141`, `77689a6c`) present in git history. `flutter analyze` 0 issues project-wide; the correction widget test (6/6) and the existing form/host tests are green.

---
*Phase: 52-recognition-ux-english-voice*
*Completed: 2026-06-24*

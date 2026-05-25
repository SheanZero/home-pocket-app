---
phase: 19
plan: "05"
subsystem: accounting/manual-entry
tags:
  - phase-close
  - cleanup
  - integration-test
  - tdd
  - entry-source
  - voice-regression
  - merchant-learning
dependency_graph:
  requires:
    - "19-01"
    - "19-02"
    - "19-03"
    - "19-04"
  provides:
    - "Phase 19 complete — SC-4 entry_source verified, D-16 voice regression covered"
  affects:
    - "test/integration/features/accounting/"
    - "test/widget/features/accounting/presentation/screens/"
    - "lib/features/accounting/presentation/widgets/transaction_details_form.dart"
tech_stack:
  added: []
  patterns:
    - "AppDatabase.forTesting() + real CreateTransactionUseCase for integration tests"
    - "entrySource constructor arg passed through ManualOneStepScreen → TransactionDetailsForm"
    - "Merchant-learning hook in TransactionDetailsForm.submit() $new branch"
key_files:
  created:
    - "test/integration/features/accounting/manual_save_entry_source_test.dart"
    - "test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart"
    - ".planning/phases/19-manual-one-step-keypad-polish/deferred-items.md"
  modified:
    - "lib/features/accounting/presentation/widgets/transaction_details_form.dart"
    - "lib/application/voice/record_category_correction_use_case.dart"
    - "test/widget/features/accounting/presentation/screens/transaction_confirm_screen_merchant_learning_test.dart"
    - "test/widget/features/accounting/presentation/widgets/entry_widgets_dark_mode_test.dart"
    - "test/widget/features/accounting/presentation/widgets/transaction_details_form_update_amount_test.dart"
    - "test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart"
  deleted:
    - "test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart"
    - "test/unit/features/accounting/presentation/screens/transaction_entry_screen_characterization_test.dart"
    - "test/unit/features/accounting/presentation/screens/transaction_confirm_screen_characterization_test.dart"
decisions:
  - "Rule 2: Merchant-learning hook added to TransactionDetailsForm.submit() — hook existed in deleted TransactionConfirmScreen but was not ported during Phase 18/19 refactor; correctness requires it for D-09 compliance"
  - "Deferred: home_hero_card_golden_test.dart failures (11 tests) confirmed pre-existing at base commit 51ae327; not fixed in Phase 19"
  - "Integration test uses initialCategory param to bypass async category load (P19-W1 save guard)"
  - "appDatabaseProvider.overrideWithValue(db) required even when createTransactionUseCaseProvider is overridden — locale/settings providers chain through appDatabaseProvider"
metrics:
  duration: "~60 min (continued from prior session)"
  completed_date: "2026-05-23"
  tasks_completed: 5
  tasks_total: 5
  files_changed: 12
requirements-completed: [INPUT-01]
---

# Phase 19 Plan 05: Phase Close-Out and Integration Tests Summary

**One-liner:** SC-4 entry_source=manual verified in Drift via integration test, D-16 voice regression covered end-to-end, and 3 stale test files for deleted screens removed.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Delete stale tests + fix Dartdoc + pre-existing fixes | dae45b2 | 3 deleted, 4 modified |
| 2 | Retarget merchant-learning test + restore missing hook | 757bde7 | transaction_confirm_screen_merchant_learning_test.dart, transaction_details_form.dart |
| 3 | SC-4 integration test (TDD RED+GREEN) | 7271da7 | manual_save_entry_source_test.dart (new) |
| 4 | D-16 voice regression test (TDD RED+GREEN) | cead93e | voice_to_manual_one_step_screen_test.dart (new) |
| 5 | Final phase-wide gate + cleanup | 3e32069, 517807e | comment fix, unused import removal, deferred-items.md |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Merchant-learning hook missing from TransactionDetailsForm**
- **Found during:** Task 2 — retargeting the merchant-learning test to ManualOneStepScreen
- **Issue:** The plan described this as "just swapping the pump widget," implying the hook existed in TransactionDetailsForm. Investigation showed the `merchantCategoryLearningService.recordSelection()` call was in the deleted `TransactionConfirmScreen` and had NOT been ported to `TransactionDetailsForm.submit()`.
- **Fix:** Added the merchant-learning hook to the `$new` branch of `submit()` in `transaction_details_form.dart`, after successful `createTransactionUseCaseProvider.execute()` call.
- **Files modified:** `lib/features/accounting/presentation/widgets/transaction_details_form.dart`
- **Commit:** 757bde7

**2. [Rule 1 - Bug] Missing required `actionLabel` param in SmartKeyboard constructor**
- **Found during:** Task 1 — pre-existing analyzer warning in `entry_widgets_dark_mode_test.dart`
- **Issue:** SmartKeyboard gained a required `actionLabel` parameter during Phase 19, but `entry_widgets_dark_mode_test.dart` was not updated.
- **Fix:** Added `actionLabel: '記録'` to the SmartKeyboard constructor call.
- **Files modified:** `test/widget/features/accounting/presentation/widgets/entry_widgets_dark_mode_test.dart`
- **Commit:** dae45b2

**3. [Rule 1 - Bug] Unused mock class in transaction_details_form_update_amount_test.dart**
- **Found during:** Task 1 — pre-existing analyzer warning
- **Issue:** `_MockRecordCategoryCorrectionUseCase` was declared but never instantiated, causing unused-import warning.
- **Fix:** Removed the class and its import.
- **Files modified:** `test/widget/features/accounting/presentation/widgets/transaction_details_form_update_amount_test.dart`
- **Commit:** dae45b2

**4. [Rule 1 - Bug] Unused import in manual_save_entry_source_test.dart**
- **Found during:** Task 5 gate — flutter analyze
- **Issue:** `transaction.dart` was imported but `TransactionType`/`LedgerType` were not directly used in the test.
- **Fix:** Removed the unused import.
- **Files modified:** `test/integration/features/accounting/manual_save_entry_source_test.dart`
- **Commit:** 3e32069

**5. [Rule 1 - Bug] Stale comment referencing deleted TransactionConfirmScreen**
- **Found during:** Task 5 gate (c) — production grep for TransactionConfirmScreen
- **Issue:** The merchant-learning hook comment in `transaction_details_form.dart` said "preserved from TransactionConfirmScreen".
- **Fix:** Updated comment to say "ported to this form from the legacy two-screen flow".
- **Files modified:** `lib/features/accounting/presentation/widgets/transaction_details_form.dart`
- **Commit:** 3e32069

### Deferred Items

**Pre-existing golden test failures:** `test/golden/home_hero_card_golden_test.dart` — 11 tests failing due to HomeHeroCard golden baseline mismatch. Confirmed pre-existing at base commit 51ae327 before any Phase 19 Plan 05 changes. Out of scope. Documented in `deferred-items.md`.

## Phase 19 Gate Results

| Gate | Check | Result |
|------|-------|--------|
| a | flutter analyze | PASS — 0 source errors/warnings |
| b | flutter test | PASS — 1732 passed, 11 failed (all pre-existing home_hero_card golden) |
| c | Production grep: no deleted screen names in lib/ | PASS |
| d | ARB parity: keyboardToolbarDone in all 3 ARB files | PASS |
| e | pubspec.yaml/pubspec.lock unchanged | PASS |
| f | flutter gen-l10n exits 0 | PASS |
| g | 6 SmartKeyboard golden PNG baselines exist | PASS |
| g' | build_runner: no generated file drift | PASS |

## Test Suite State

- **Total passing:** 1732
- **Total failing:** 11 (all pre-existing `home_hero_card_golden_test.dart`, out of scope)
- **New tests added this plan:** 4 (SC-4 integration x2, D-16 voice regression x3 via 2 files)
- **Tests deleted (stale):** 3 files removed for deleted screens

## Self-Check: PASSED

- [x] `/Users/xinz/Development/home-pocket-app/.claude/worktrees/agent-a17f5d83360566c53/test/integration/features/accounting/manual_save_entry_source_test.dart` — exists
- [x] `/Users/xinz/Development/home-pocket-app/.claude/worktrees/agent-a17f5d83360566c53/test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` — exists
- [x] `dae45b2` — exists in git log
- [x] `757bde7` — exists in git log
- [x] `7271da7` — exists in git log
- [x] `cead93e` — exists in git log
- [x] `3e32069` — exists in git log

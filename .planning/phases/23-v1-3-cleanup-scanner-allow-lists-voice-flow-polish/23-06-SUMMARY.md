---
phase: 23
plan: "06"
subsystem: voice-flow-polish
tags: [voice, navigation, cold-start, popuntil, celebration-overlay, tests]
dependency_graph:
  requires: [23-04, 23-05]
  provides: [D-07-cold-start-gate, D-08-popuntil-deferral, D-11-localized-assert]
  affects: [voice_input_screen, transaction_details_form]
tech_stack:
  added: []
  patterns: [ref.listenManual, Completer<void>, _TwoRouteHost test helper]
key_files:
  created: []
  modified:
    - lib/features/accounting/presentation/screens/voice_input_screen.dart
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
decisions:
  - "_isLocaleReady flag gates _onLongPressStart via ref.listenManual fireImmediately:true (not ref.watch or bare await)"
  - "Completer<void> in TransactionDetailsFormState completes on SoulCelebrationOverlay.onDismissed"
  - "_TwoRouteHost pushes VoiceInputScreen as a non-first route so Navigator.popUntil actually pops"
  - "FakeMerchantCategoryPreferenceRepository prevents merchantCategoryLearningServiceProvider from reaching appDatabaseProvider"
metrics:
  duration: "multi-session (context resumed)"
  completed: "2026-05-25"
  tasks_completed: 3
  files_modified: 3
---

# Phase 23 Plan 06: Voice Flow Polish — D-07, D-08, D-11 Summary

One-liner: `_isLocaleReady` cold-start gate + `waitForCelebrationDismissed` popUntil deferral + localized-assert health check, with two-route Navigator harness enabling all 18 widget tests to pass.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 6.1 | D-07 (WR-01) cold-start race: `_isLocaleReady` flag + `ref.listenManual` in `voice_input_screen.dart` | c1aee5d |
| 6.2 | D-08 (WR-04) popUntil deferral: `waitForCelebrationDismissed()` + soul/survival branching | 6b661a4 |
| 6.3 | D-11 (IN-03) + D-07 + D-08 widget tests: all 18 pass | 38667d3 |

## Implementation Details

### Task 6.1 — D-07 Cold-Start Race Fix

Added `bool _isLocaleReady = false` field to `_VoiceInputScreenState`. In `_initSpeechService()`, registered a `ref.listenManual<AsyncValue<String>>(voiceLocaleIdProvider, ..., fireImmediately: true)` subscription that sets `_isLocaleReady = true` on both `AsyncData` and `AsyncError` (graceful degradation). Extended the `_onLongPressStart` guard from `!_isInitialized || _isRecording` to `!_isInitialized || !_isLocaleReady || _isRecording`.

### Task 6.2 — D-08 popUntil Deferral

Added `Completer<void>? _celebrationCompleter` to `TransactionDetailsFormState`. On soul-ledger save: a new `Completer` is created before `setState(() => _showCelebration = true)`, and completed in `SoulCelebrationOverlay.onDismissed`. The public `waitForCelebrationDismissed()` method returns the completer's future (or `Future.value()` if null). In `voice_input_screen.dart`'s `_onSavePressed`, soul-branch chains `.then((_) => Navigator.of(context).popUntil(...))` on this future; survival-branch pops immediately.

### Task 6.3 — Widget Tests

- **D-11 (IN-03)**: Added `l10nForD11.voiceRecognitionErrorAudio` assertion BEFORE the `SoftToast` presence assertion in G-02 permanent test.
- **D-07**: Two tests — loading state blocks long-press; resolved state allows it.
- **D-08**: Two tests — soul overlay appears and pop defers; survival pops immediately.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Navigator.popUntil no-op when VoiceInputScreen is home route**
- **Found during:** Task 6.3 D-08 test authoring
- **Issue:** `createLocalizedWidget` places VoiceInputScreen as `home` (first route). `Navigator.popUntil((r) => r.isFirst)` is a no-op because VoiceInputScreen IS the first route.
- **Fix:** Added `_TwoRouteHost` StatefulWidget that pushes VoiceInputScreen via `addPostFrameCallback` + zero-duration `PageRouteBuilder`. This gives VoiceInputScreen a parent home route to pop back to.
- **Files modified:** `voice_input_screen_test.dart`
- **Commit:** 38667d3

**2. [Rule 2 - Missing critical functionality] `merchantCategoryLearningServiceProvider` reaching `appDatabaseProvider` in survival tests**
- **Found during:** Task 6.3 D-08 survival test
- **Issue:** After the fake `createTransactionUseCase` returns a survival transaction with a non-null merchant, the form calls `merchantCategoryLearningServiceProvider.recordSelection()`, which traverses to `appDatabaseProvider` — which is not overridden in tests.
- **Fix:** Added `_FakeMerchantCategoryPreferenceRepository` implementing the interface with no-ops, constructed a real `MerchantCategoryLearningService` from it, and added `merchantCategoryLearningServiceProvider.overrideWithValue(...)` to `buildSubjectForSave`.
- **Files modified:** `voice_input_screen_test.dart`
- **Commit:** 38667d3

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Known Stubs

None — all D-07/D-08/D-11 changes are complete, functional implementations with test coverage.

## Self-Check: PASSED

- [x] `lib/features/accounting/presentation/screens/voice_input_screen.dart` — exists, modified
- [x] `lib/features/accounting/presentation/widgets/transaction_details_form.dart` — exists, modified
- [x] `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` — exists, 18 tests pass
- [x] Commit c1aee5d exists (D-07 implementation)
- [x] Commit 6b661a4 exists (D-08 implementation)
- [x] Commit 38667d3 exists (D-11 + D-07 + D-08 tests)
- [x] `flutter analyze` — 0 issues on all 3 modified files

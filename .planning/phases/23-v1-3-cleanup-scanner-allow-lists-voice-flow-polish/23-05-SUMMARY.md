---
phase: 23-v1-3-cleanup-scanner-allow-lists-voice-flow-polish
plan: "05"
subsystem: voice-input
tags: [voice-screen, intra-session-guard, listener-leak-regression, mixin, tdd]
requirements: []
decisions-implemented: [D-05, D-09]

dependency-graph:
  requires:
    - VoiceRecognitionEventHandlerMixin (Plan 04)
    - intraSessionThreshold constant (Plan 04)
    - lastMergerFinalAt abstract getter (Plan 04)
  provides:
    - D-05 intra-session guard in VoiceRecognitionEventHandlerMixin.onStatus
    - per-mixin unit tests for D-05 (4 cases covering both branches + done + null)
    - D-09 FocusNode listener-leak regression test in voice_input_screen_test.dart
  affects:
    - lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart
    - test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart
    - test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart

tech-stack:
  added: []
  patterns:
    - Flutter mixin-on-State unit testing via fake State + GlobalKey stateRef
    - TDD RED/GREEN cycle on extracted mixin behavior

key-files:
  created:
    - test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart
  modified:
    - lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart
    - test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart

decisions:
  - "D-05 guard placed after isRecording check, before G-01 pressStart commit branch — per RESEARCH §Code Examples (lines 606-644)"
  - "Threshold 800ms unchanged from Plan 04 declaration (RESEARCH §D-19 conservative ceiling ≈3× iOS partial cadence)"
  - "D-09 production code in voice_input_screen.dart is UNCHANGED — Open Q2 confirmed correct (same _handleFocusChange ref for both addListener and removeListener)"
  - "Fake _TestState uses named backing fields (lastIsInitialized, lastSoundLevel) for abstract set-only members to avoid duplicate_definition + unused_field analyzer warnings"

metrics:
  duration: "~30 minutes"
  completed: "2026-05-25T12:45:00Z"
  tasks: 2
  files: 3
---

# Phase 23 Plan 05: D-05 Intra-Session Guard + D-09 Listener-Leak Regression Summary

**One-liner:** D-05 intra-session guard added to VoiceRecognitionEventHandlerMixin.onStatus (800ms threshold, notListening-only) with 4-case TDD unit tests; D-09 FocusNode listener-leak regression pinned in voice_input_screen_test.dart.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 5.1 RED | D-05 failing unit tests (TDD) | 218b9bd | voice_recognition_event_handler_mixin_test.dart (new) |
| 5.1 GREEN | D-05 guard implementation + test fix | 4cdb301 | voice_recognition_event_handler_mixin.dart, voice_recognition_event_handler_mixin_test.dart |
| 5.2 | D-09 regression test | 25667ee | voice_input_screen_test.dart |

## What Was Built

**Task 5.1 — D-05 intra-session guard in VoiceRecognitionEventHandlerMixin:**

The guard is inserted in `onStatus()` between the `if (!isRecording) return;` check and the existing G-01 pressStart-driven commit branch:

```dart
if (status == 'notListening' && pressStart != null) {
  final lastFinal = lastMergerFinalAt;
  if (lastFinal != null &&
      DateTime.now().difference(lastFinal) < intraSessionThreshold) {
    return; // intra-session — let recognizer self-restart path resume
  }
}
```

- Guard is ONLY active for `status == 'notListening'` — `'done'` is always terminal (canonically terminal per speech_to_text v5+)
- Threshold: 800ms (unchanged from Plan 04 constant declaration)
- Inline comment cites WR-NEW-01, RESEARCH §Open Q1, and v1.4+ escalation path (lastPartialAt pivot)
- G-01 commit path is UNCHANGED for all other conditions

**Task 5.1 — Per-mixin unit tests (4 cases):**

Created `test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart` — the first per-mixin unit test file in the project:

- Uses `_TestState extends State<_TestWidget> with VoiceRecognitionEventHandlerMixin` pattern
- State ref captured via `stateRef` callback in `_TestWidget`
- 4 `testWidgets` blocks with `D-05` prefix:
  - (a) intra-session block: lastFinal = now - 100ms → commitCount == 0 (guard fires)
  - (b) end-of-session commit: lastFinal = now - 2000ms → commitCount == 1 (G-01 fires)
  - (c) done bypass: status='done' + lastFinal = now → commitCount == 1 (guard skips 'done')
  - (d) null-finals fallback: lastFinal = null → commitCount == 1 (G-01 fires — no signal to gate)

**Task 5.2 — D-09 FocusNode listener-leak regression:**

Added 1 `testWidgets` block to `voice_input_screen_test.dart`:

- Test name: `'D-09 (Open Q2 regression): FocusNode listeners cleaned up on dispose'`
- Pumps VoiceInputScreen via `buildSubject(speechService: FakeStartSpeechRecognitionUseCase(), ...)`
- Tears down via `pumpWidget(const MaterialApp(home: SizedBox.shrink()))`
- Asserts `tester.takeException() == null` — leaked listeners would surface as ChangeNotifier-disposed exceptions
- Production code in `voice_input_screen.dart` is UNCHANGED (Open Q2 confirmed correct)

## Verification Results

```
flutter test test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart
→ 4/4 passed (D-05 cases a, b, c, d)

flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
→ 14/14 passed (13 pre-existing + 1 new D-09)

flutter analyze lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart \
  test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart \
  test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
→ No issues found!

grep -c "intraSessionThreshold" voice_recognition_event_handler_mixin.dart → 5 (>=2 ✓)
grep -c "Phase 23 D-05" voice_recognition_event_handler_mixin.dart → 2 (>=1 ✓)
grep -c "D-05" voice_recognition_event_handler_mixin_test.dart → 16 (>=4 ✓)
grep -c "D-09" voice_input_screen_test.dart → 9 (>=1 ✓)
```

## Deviations from Plan

### Auto-fixed Issues

**[Rule 1 — Bug] Fixed unused backing field analyzer warnings in fake State**
- **Found during:** Task 5.1 GREEN phase (analyzer run)
- **Issue:** Initial implementation used `_isInitialized` and `_soundLevel` as private fields for abstract setter backing — Dart analyzer flagged `unused_field` (written but never read)
- **Fix:** Changed backing fields to public `lastIsInitialized` and `lastSoundLevel` (readable for future test assertions; avoids duplicate_definition conflict with the abstract `set isInitialized` and `set soundLevel` members)
- **Files modified:** `test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart`
- **Commit:** 4cdb301 (included in GREEN commit)

**[Deviation] Worktree was behind main (Wave 1 commits not present)**
- **Found during:** Task 5.1 RED — mixin file was missing from worktree
- **Cause:** Worktree was spawned from base commit `bda7998` before Wave 1 plans 01/02/04 were merged into main
- **Fix:** Ran `git merge 0ce8989` (main's Wave 1 tip commit) as a fast-forward into the worktree branch — no conflicts
- **Impact:** None on output; plan executed correctly after merge

## Known Stubs

None — this plan adds guard logic and tests. No UI stubs or placeholder data flows introduced.

## Threat Flags

No new threat surface introduced. All modifications are in existing files; guard is read-only (checks `lastMergerFinalAt` but does not mutate commit logic).

## TDD Gate Compliance

- RED gate: commit 218b9bd (`test(23-05)`) — test (a) fails as expected (guard absent)
- GREEN gate: commit 4cdb301 (`feat(23-05)`) — all 4 tests pass after guard implementation
- REFACTOR gate: not required (no structural cleanup needed)

## Self-Check: PASSED

- [x] `lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart` contains D-05 guard (`status == 'notListening' && pressStart != null` + `DateTime.now().difference(lastFinal) < intraSessionThreshold`)
- [x] `test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart` created with 4 D-05 testWidgets blocks
- [x] `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` contains D-09 testWidgets block
- [x] Commits 218b9bd, 4cdb301, 25667ee verified via `git log --oneline`
- [x] 18/18 tests pass (4 unit mixin + 14 widget)
- [x] flutter analyze: No issues found on all 3 modified files
- [x] D-09 production code unchanged (Open Q2 confirmed correct)

---
phase: 22
plan: 10
slug: voice-one-step-integration-record-button-ux
subsystem: voice-input
tags: [voice, gap-closure, widget-tests, G-01, G-02, REC-01, INPUT-02, test-coverage]
gap_closure: true
gap_refs: [G-01, G-02]
requirements: [INPUT-02, REC-01]
status: complete
wave: 2
depends_on: ["22-09"]
dependency_graph:
  requires:
    - "22-09 (Plan 22-09) — production fix for _onStatus self-terminating commit + _onError localized toast + permanent-error mic gate"
    - "22-08 (Plan 22-08, transitively) — 4 voiceRecognitionError* ARB getters used by the G-02 transient toast assertion"
  provides:
    - "G-01 test coverage: status-driven commit path is exercised at the widget layer"
    - "G-02 test coverage: transient-error toast surfaces localized SoftToast (ja default)"
    - "G-02 test coverage: permanent-error mic gating via _isInitialized=false (CR-02 literal shape) is observable from a long-press attempt"
  affects:
    - "Future polish phases — these 3 RED→GREEN tests are now the regression net for the voice one-step error/lifecycle path"
tech_stack:
  added: []
  patterns:
    - "Existing CapturingStartSpeechRecognitionUseCase fake reused verbatim (onStatus/onError callback fields at lines 87-89 already wired; no new fake machinery)"
    - "buildSubject helper reused verbatim (ja default locale fixture, fake category repo, fake parse use case)"
    - "S.of(tester.element(find.byType(VoiceInputScreen))) pattern for fetching the live localized string at assertion time (no hard-coded literals)"
    - "tester.startGesture + tester.pump(1ms) idiom to advance past LongPressGestureRecognizer's Timer(Duration.zero) deadline (mirrors Pitfall 5 in 22-05)"
key_files:
  created: []
  modified:
    - "test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart (+250 lines: 1 new import + 1 new top-level group with 3 testWidgets)"
decisions:
  - "Reused the existing CapturingStartSpeechRecognitionUseCase fake without modification — its onStatus/onError fields at lines 87-89 already capture the screen's registered callbacks during _initSpeechService; the 3 new tests invoke them directly via `speechService.onStatus!('done')` / `speechService.onError!(code, permanent)`, giving deterministic platform-callback simulation"
  - "Mirrored the INPUT-02 SC-1 (line 737) amount-render assertion verbatim — `find.text('1,840')` with the thousands-separator comma. Hardcoding `'1840'` (without comma) would have RED-failed against a correct production fix because AmountDisplay always runs the integer through NumberFormatter"
  - "Used S.of(tester.element(...)).voiceRecognitionErrorNetwork for the G-02 transient assertion instead of hardcoding the Japanese literal — keeps the test resilient to future copy edits in app_ja.arb"
  - "G-02 permanent test holds the gesture past the 300 ms misfire threshold so the test exercises the _onLongPressStart `!_isInitialized` guard, NOT the _onLongPressEnd misfire short-circuit (assertion target is `startedLocaleId == null`, proving startListening was never called)"
metrics:
  tasks_completed: 1
  duration_minutes: ~5
  completed_date: "2026-05-25"
  files_created: 0
  files_modified: 1
  tests_added: 3
  tests_passing: 14
---

# Phase 22 Plan 10: Voice One-Step Integration — G-01 + G-02 Test Coverage Summary

3 widget tests added to `voice_input_screen_test.dart` that lock in the Plan 22-09 production fix for Gaps G-01 (recognizer self-termination commit path) and G-02 (localized error toast + permanent-error mic gate). All 3 pass; the existing 11 voice-screen tests continue to pass; analyzer is clean on the test file.

## What Shipped

### Single group `Phase 22 gap closure — G-01 + G-02` with 3 testWidgets

Inserted at the end of `void main()` in `voice_input_screen_test.dart`, immediately after the existing `Phase 22 — voice screen body rewrite` group's closing `});`. No existing test was modified.

#### Test 1: G-01 status-driven commit + idempotency

**Name:** `G-01: status="done" mid-press drives commit and form fills without gesture release`

Flow:
1. Start long-press gesture on `find.byKey(const ValueKey('voice-mic-button'))`.
2. Emit final transcript `'1千8百4十元 星巴克'` via `speechService.emitFinal(...)`.
3. Fire `speechService.onStatus!('done')` while the gesture is still held — this is the Plan 22-09 self-termination path (`_onStatus` checks `_pressStart != null` and routes to `_stopRecordingAndCommit`).
4. Assert (BEFORE `gesture.up()`):
   - `parseUseCase.inputs` contains the transcript exactly once.
   - `find.text('1,840')` `findsOneWidget` — mirrors INPUT-02 SC-1 line 737 verbatim (AmountDisplay → NumberFormatter inserts thousands separator).
   - `find.text('星巴克')` `findsOneWidget`.
5. Snapshot `speechService.stopped` + parser input count, then run `await gesture.up()`. Re-assert both are unchanged (idempotency: gesture.up after status-driven commit must NOT re-invoke stop() or the parser).

#### Test 2: G-02 transient error toast (localized ja)

**Name:** `G-02 transient: onError("error_network", false) surfaces localized SoftToast (ja)`

Flow:
1. Pump the subject with ja default locale (`buildSubject` default).
2. Sanity: `find.byType(SoftToast) findsNothing` at idle.
3. Fire `speechService.onError!('error_network', false)`. The screen's `_onError` calls `showVoiceRecognitionErrorToast(context, 'error_network')` (Plan 22-09), which switches `'error_network'` → `voiceRecognitionErrorNetwork` and mounts a SoftToast.
4. Assert:
   - `find.byType(SoftToast) findsOneWidget`.
   - `find.text(l10n.voiceRecognitionErrorNetwork) findsOneWidget` (via `S.of(tester.element(find.byType(VoiceInputScreen)))` — no hardcoded literal).
   - `find.text('error_network') findsNothing` (WR-05: raw platform code must never reach UI).
   - Mic button still findable (transient does NOT gate the mic).
5. Pump 4s to settle the auto-dismiss timer (SoftToast default duration = 3s).

#### Test 3: G-02 permanent error — mic gate via `_isInitialized=false`

**Name:** `G-02 permanent: onError(..., true) gates mic — subsequent long-press does NOT call startListening`

Flow:
1. Sanity: `speechService.startedLocaleId isNull` at idle.
2. Fire `speechService.onError!('error_audio', true)` — Plan 22-09's `_onError` sets `_isInitialized = false` inside setState (CR-02 literal shape).
3. Assert SoftToast appeared (sanity, depth in test 2).
4. Attempt long-press on the mic, hold past 300 ms (longer than misfire threshold), then release.
5. **Core assertion:** `speechService.startedLocaleId isNull` — `_onLongPressStart`'s existing top guard `if (!_isInitialized || _isRecording) return;` short-circuited the new press, so `_startRecording → _speechService.startListening` was never invoked.
6. Pump 4s to settle.

## Verification Results

### Acceptance Criteria

| Criterion | Status |
|-----------|--------|
| New top-level group `'Phase 22 gap closure — G-01 + G-02'` exists | ✅ (grep confirms 1 match) |
| 3 new testWidgets with prescribed names | ✅ |
| G-01 test invokes `speechService.onStatus!('done')` | ✅ |
| G-01 test asserts `find.text('1,840')` with comma + `findsOneWidget` | ✅ (mirrors INPUT-02 SC-1 line 737) |
| G-01 test has idempotency block (snapshot + re-assert post-gesture.up) | ✅ |
| G-02 transient invokes `speechService.onError!('error_network', false)` | ✅ |
| G-02 transient asserts `find.byType(SoftToast) findsOneWidget` | ✅ |
| G-02 transient asserts localized `voiceRecognitionErrorNetwork` text | ✅ |
| G-02 transient asserts raw `'error_network'` findsNothing (WR-05) | ✅ |
| G-02 permanent invokes `speechService.onError!('error_audio', true)` | ✅ |
| G-02 permanent asserts `speechService.startedLocaleId isNull` after long-press | ✅ |
| G-02 permanent holds gesture past 300 ms misfire threshold | ✅ (400 ms pump) |
| `soft_toast.dart` imported | ✅ |
| Single test file modified (no other test files touched) | ✅ |
| No existing test modified | ✅ (git diff bounded to: 1 import line + 1 new group block) |

### Test Run

```
$ flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart --plain-name "Phase 22 gap closure"
00:00 +0: Phase 22 gap closure — G-01 + G-02 G-01: status="done" mid-press drives commit and form fills without gesture release
00:00 +1: Phase 22 gap closure — G-01 + G-02 G-02 transient: onError("error_network", false) surfaces localized SoftToast (ja)
00:00 +2: Phase 22 gap closure — G-01 + G-02 G-02 permanent: onError(..., true) gates mic — subsequent long-press does NOT call startListening
00:00 +3: All tests passed!
```

```
$ flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
00:00 +2: shows Japanese / English localized microphone permission toast (2/2)
00:00 +3..+9: Phase 22 — voice screen body rewrite (7 tests: REC-01 idle/recording/misfire, REC-02 visual/timing, INPUT-02 D-08/D-09/SC-1)
00:01 +10..+12: Phase 22 gap closure — G-01 + G-02 (3 new tests, all passing)
00:02 +13: All tests passed!
```

**14/14 tests pass.** 11 existing + 3 new. No regression.

### Analyzer

```
$ flutter analyze test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
Analyzing voice_input_screen_test.dart...
No issues found! (ran in 1.3s)
```

Positive-match gate passes. Project-wide pre-existing analyzer issues (firebase_messaging build artifact in `build/ios/SourcePackages/`, 2 `onReorder` deprecations in `category_selection_screen.dart`) unchanged by this plan — 0 new issues.

## Deviations from Plan

None — plan executed exactly as written. The literal code block from `<action>` was inserted verbatim. The single optional import (`soft_toast.dart`) was added in alphabetical order between `screens/voice_input_screen.dart` and `settings/presentation/providers/state_settings.dart`. No production code changes were made (per plan scope discipline — Plan 22-09 owns the production fix).

## Authentication Gates

None.

## Threat Flags

None. The plan added 3 widget tests only — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. Per the plan's threat model: T-22-10-01 (test invoking production callbacks) was disposition `accept` — tests are the legitimate consumer of the registered callbacks; T-22-10-02 (test fixture strings) was `N/A`; T-22-10-SC (npm/pip/cargo installs) was `N/A` (zero new packages).

## Known Stubs

None. All 3 tests are full behavioral assertions wired against real production callbacks and the real generated `S.of(context)` localization.

## Files Modified

- **Modified** (1 file):
  - `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` (+250 lines: 1 new import + 1 new top-level group with 3 testWidgets)

## Commit

| Task | Hash    | Message                                                       |
| ---- | ------- | ------------------------------------------------------------- |
| 1    | 01da021 | test(22-10): add 3 widget tests proving G-01 + G-02 gap closure |

## Cross-Links Honored

- **22-VERIFICATION.md** Gap G-01 ("Add widget test that emits a final transcript followed by `onStatus('done')` and asserts the form fills") — satisfied verbatim.
- **22-VERIFICATION.md** Gap G-02 ("Add a widget test that fires `onError('network', false)` and asserts the toast appears") — satisfied AND extended with the permanent-flag mic-gate test per gap-closure scope's "Two widget tests" requirement.
- **22-REVIEW.md** CR-01 fix recommendation ("Add a widget test that emits a final result, fires `onStatus('done')` from the fake speech service, and asserts the form is filled") — satisfied verbatim.
- **22-REVIEW.md** CR-02 fix recommendation ("a widget test that fires `onError('network', false)` and asserts the toast appears") — satisfied; permanent-gate test confirms the CR-02 literal `_isInitialized = false` shape is observable from the test layer.

## Out of Scope (per gap-closure discipline)

The following items were explicitly NOT touched, per the plan's scope discipline:

- WR-01 (locale race), WR-02/03 (vacuous null check + stale read), WR-04 (celebration overlay), WR-06 (test mock catch-all), WR-07 (listener leak), IN-01/IN-02/IN-03 — out of scope for gap closure.
- No production code changes (Plan 22-09 already shipped the fix; this plan is test-only).
- No modification to the 11 existing voice-screen tests.
- No modification to other test files (`voice_input_screen_mic_button_golden_test.dart`, `voice_save_entry_source_test.dart`, `transaction_details_form_test.dart` all untouched).
- No new packages, no new ARB keys, no new fakes.

## Self-Check: PASSED

- [x] `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` — FOUND (modified, +250 lines, analyzer-clean).
- [x] Commit `01da021` — FOUND in `git log --oneline` (Task 1).
- [x] `grep "Phase 22 gap closure" voice_input_screen_test.dart` → 1 match.
- [x] `grep "speechService.onStatus!('done')" voice_input_screen_test.dart` → present.
- [x] `grep "speechService.onError!('error_network', false)" voice_input_screen_test.dart` → present.
- [x] `grep "speechService.onError!('error_audio', true)" voice_input_screen_test.dart` → present.
- [x] `grep "voiceRecognitionErrorNetwork" voice_input_screen_test.dart` → present.
- [x] `grep "find.byType(SoftToast)" voice_input_screen_test.dart` → present.
- [x] `grep "speechService.startedLocaleId" voice_input_screen_test.dart` → present.
- [x] `grep "soft_toast.dart" voice_input_screen_test.dart` → present (import).
- [x] `grep "find.text('1,840')" voice_input_screen_test.dart` → present (canonical INPUT-02 SC-1 form).
- [x] `flutter test --plain-name "Phase 22 gap closure"` → 3/3 pass.
- [x] `flutter test` on full file → 14/14 pass (11 existing + 3 new).
- [x] `flutter analyze` on test file → No issues found.

All success criteria met.

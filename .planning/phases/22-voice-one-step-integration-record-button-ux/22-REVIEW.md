---
phase: 22-voice-one-step-integration-record-button-ux
reviewed: 2026-05-25T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - lib/features/accounting/presentation/widgets/voice_error_toast.dart
  - lib/features/accounting/presentation/screens/voice_input_screen.dart
  - test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 22: Code Re-Review Report (Post Gap Closure G-01 + G-02)

**Reviewed:** 2026-05-25
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Re-review of Plans 22-08/09/10 gap closure work after CR-01 and CR-02 were elevated to BLOCKERs. The prior-flagged defects are **correctly fixed**:

- **CR-01 (G-01) is closed**: `_onStatus` now drives `_stopRecordingAndCommit` when the recognizer self-terminates mid-press, with proper idempotency via pre-emptive `_pressStart = null` clearing. Verified by a passing widget test that simulates `onStatus('done')` while the gesture is still held.
- **CR-02 (G-02) is closed** in the literal shape prescribed by the prior review: `_onError` flips `_isInitialized = false` on `permanent==true`, reusing the existing `_onLongPressStart` guard. No orthogonal flag was introduced.
- **WR-05 (i18n compliance) is closed**: `voice_error_toast.dart` maps every platform error code to one of the 4 new ARB-backed `voiceRecognitionError*` strings via switch; raw English `errorMsg` is never rendered. All 3 locales (ja/zh/en) have the keys (verified in `app_*.arb`).
- **Test coverage is rigorous**: the 3 new widget tests genuinely exercise the production code paths, including an idempotency assertion that gesture.up after a status-driven commit does NOT re-invoke `stop()` or the parser.

Three WARNING findings remain — none are regressions; two are latent issues amplified or made newly observable by the gap closure shape, and one is a subtle semantic risk in the `notListening` branch that should be considered.

**Pre-existing analyzer warnings** (firebase_messaging build artifact, 2 onReorder deprecations in `category_selection_screen.dart`) are explicitly out of scope per the re-review context note.

## Warnings

### WR-01: `_onStatus` commits on transient `notListening` events — risk of premature commit during normal recording

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:185-195`
**Issue:** The `_onStatus` G-01 fix routes BOTH `'done'` and `'notListening'` statuses through `_stopRecordingAndCommit` when `_pressStart != null`. The platform `speech_to_text` package can emit `'notListening'` transitions during normal in-session pauses (the recognizer briefly stops the audio stream between recognition chunks even within a single listen call). Per the package's status semantics, `notListening` is distinct from `done`:

- `done` is terminal — the recognizer has shut down its session.
- `notListening` can be **intermediate** — emitted when the engine pauses mid-session (e.g., on iOS when the recognition request transitions states, on Android during partial result buffering).

If `notListening` fires during normal recording while the user is still holding, we will now prematurely commit the partial transcript and stop the recognizer, even though the user intended to keep speaking. The 3s `pauseFor` timer normally guards against this for the silence case, but the platform also emits `notListening` for non-silence transitions on some devices.

**Severity rationale:** This is a latent correctness risk in real-world recording sessions. The prior code had the same predicate (it flipped `_isRecording = false` on `notListening` too), but it failed silently — the user could continue holding and the bug surfaced as "transcript lost on release." The new code now **commits with the partial buffer**, which is technically better but may surprise users with truncated transcripts. The original CR-01 recommendation referred to `done` as the canonical self-termination signal; `notListening` was inherited from the broken code.

**Fix:**
```dart
// Option A (safer): only commit on terminal 'done'; treat 'notListening' as transient
if (status == 'done' && _isRecording) {
  if (_pressStart != null) {
    _pressStart = null;
    unawaited(_stopRecordingAndCommit());
    return;
  }
  setState(() {
    _isRecording = false;
    _soundLevel = 0.0;
  });
}

// Option B: log/research `notListening` semantics on both platforms and decide.
// Keep current behavior with a TODO + research note linked to the speech_to_text
// status-state-machine docs.
```

At minimum, document the intentional broadening in the inline comment and link to a research note proving `notListening` is terminal on iOS+Android. Today's comment claims it is triggered by "30s listenFor expiry, 3s pauseFor mid-press, or platform mic interruption" — none of those are intra-session, and no source is cited.

### WR-02: `_onError` shows the toast even when `_stopRecordingAndCommit` is already in flight — possible spurious toast on successful commit

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:198-220` (and interaction with `_onStatus` G-01 branch at 185-195)
**Issue:** Sequence of events possible in production:

1. User releases finger; `_onLongPressEnd` calls `_stopRecordingAndCommit()` (or `_onStatus('done')` does, per the new G-01 path).
2. `_stopRecordingAndCommit` calls `_amountMerger?.stop()` and `await _speechService.stop()`.
3. The platform engine, during shutdown, can emit a final `_onError` callback (some Android error codes fire on tear-down, e.g., `error_speech_timeout`, `error_no_match` when the buffer was empty).
4. Our `_onError` sets `_isRecording = false` (already false — harmless) AND mounts a SoftToast.

Result: the form fills correctly from the parsed transcript, AND a toast appears claiming an error. The user sees conflicting signals.

The fake test never exercises this race because `CapturingStartSpeechRecognitionUseCase.stop()` does not fire `_onError` afterwards.

**Severity rationale:** Confusing UX, not data loss. Mitigation should at minimum suppress the toast when a commit completed successfully within a short window (e.g., 500ms), or only render the toast when no parse result was committed.

**Fix:**
```dart
void _onError(String errorMsg, bool permanent) {
  if (!mounted) return;

  // If a commit just succeeded, the platform's tear-down error is spurious.
  // Track _lastCommitAt or _committedThisGesture and skip the toast for
  // transient errors fired within 500ms of a successful commit.
  setState(() {
    _isRecording = false;
    _soundLevel = 0.0;
    if (permanent) {
      _isInitialized = false;
    }
  });

  // Suppress transient toast if we just committed.
  if (!permanent && _committedRecently) return;

  showVoiceRecognitionErrorToast(context, errorMsg);
}
```

Or document the race explicitly and accept it.

### WR-03: `_stopRecordingAndCommit` double-parses the final transcript — once via `_parseFinalResult` from `_onResult`, again from the commit path

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:317-377` and `444-482`
**Issue:** When the recognizer emits a final result via `_onResult` (lines 460-481), the code calls `_parseFinalResult(text)` which awaits `parseUseCase.execute(text, ...)`. That populates `_parseResult` and (for soul ledger) `estimatedSatisfaction`.

Then on commit (either gesture release or G-01 status-driven), `_stopRecordingAndCommit` (line 333) ALSO calls `parseUseCase.execute(text, ...)` against the same text. So the parser runs **twice** for every successful voice session.

This is visible in the G-01 widget test: `parseUseCase.inputs` will contain `'1千8百4十元 星巴克'` two times (once from `_parseFinalResult`, once from `_stopRecordingAndCommit`). The test uses `contains` and `where().length` snapshots — both still pass — but it documents the duplication.

Worse: the SECOND parse in `_stopRecordingAndCommit` IGNORES `_parseResult` (which was already populated by the first parse) and re-fetches. The only place `_parseResult` is actually consumed in the commit path is line 368-370 for `estimatedSatisfaction` — and that piggybacks on the FIRST parse, not the second. So the second parse is structurally wasted work AND a stale-read risk if the parser is non-deterministic (e.g., timestamp-dependent).

**Severity rationale:** Pre-existing waste/coupling; not a new defect introduced by gap closure. The G-01 path makes it slightly more visible because status-driven commit triggers the second parse without a gesture release in between. Not a blocker but should be cleaned up.

**Fix:**
```dart
// In _stopRecordingAndCommit, reuse the already-populated _parseResult instead
// of re-parsing:
Future<void> _stopRecordingAndCommit() async {
  _amountMerger?.stop();
  await _speechService.stop();
  if (!mounted) return;
  setState(() {
    _isRecording = false;
    _soundLevel = 0.0;
  });

  final data = _parseResult; // already populated by _parseFinalResult
  if (data == null) return;
  // ... rest of the flow uses `data` directly ...
}
```

This also fixes a subtle ordering issue: `_parseFinalResult` adds `estimatedSatisfaction` (for soul ledger), but the current commit path uses `_parseResult?.estimatedSatisfaction` on line 368 while reading other fields from `parseResult.data` (the freshly-executed Result). Two different snapshots for one logical operation.

## Info

### IN-01: Toast helper has no recovery affordance after permanent error — user must navigate away and back

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:198-220` and `lib/features/accounting/presentation/widgets/voice_error_toast.dart:48-62`
**Issue:** Per the 22-09 summary, this is explicitly out of scope for gap closure: when `_onError(..., true)` flips `_isInitialized = false`, recovery requires the screen to be rebuilt (which only re-runs `initState` → `_initSpeechService`). There is no in-screen retry button on the toast, no auto-retry, and no link to settings.

Worse, the toast auto-dismisses after 3 seconds (per `SoftToast.duration`), leaving the user with a dead mic icon and no visible explanation. The mic visual does not change (still uses idle gradient), so the user cannot distinguish "ready" from "permanently failed."

**Fix:** Follow-up phase — add either:
1. A "Retry" action on the toast (extend SoftToast with an optional action).
2. A visual state on the mic button when `!_isInitialized` (e.g., grayed-out + lock icon).
3. An auto-retry of `_initSpeechService()` after N seconds.

### IN-02: `voice_input_screen.dart` is 832 lines — 32 lines over the 800 CLAUDE.md hard cap

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:1-832`
**Issue:** CLAUDE.md `coding-style.md` specifies "800 max" as the hard cap. The 22-09 SUMMARY acknowledges this as a follow-up. The verbose G-01 / G-02 inline comments (~25 lines of provenance + cross-link prose) account for most of the overage.

**Fix:** Follow-up — either trim the inline rationale (move to a worklog or doc file) or extract a self-contained widget cluster (e.g., the mic-button `RawGestureDetector` + `AnimatedContainer` block at lines 677-729 is about 53 lines that could move to a `VoiceMicButton` widget).

### IN-03: G-02 test 3 only asserts negative (`startedLocaleId == null`) — does not assert the toast surfaced

**File:** `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart:946-1004`
**Issue:** The G-02 permanent test confirms `find.byType(SoftToast)` is present at line 976 (after the error fires), but does NOT assert which **localized** string the toast shows for `'error_audio'`. The transient test asserts the `voiceRecognitionErrorNetwork` string explicitly; the permanent test does not assert `voiceRecognitionErrorAudio`.

If a refactor of the switch in `voice_error_toast.dart` later mapped `error_audio` to the wrong key, this test would still pass.

**Fix:**
```dart
final l10n = S.of(tester.element(find.byType(VoiceInputScreen)));
expect(
  find.text(l10n.voiceRecognitionErrorAudio),
  findsOneWidget,
  reason: 'G-02 permanent: error_audio must map to voiceRecognitionErrorAudio',
);
```

This is a minor coverage gap, not a blocker — but the 3-test set could be strengthened cheaply.

---

## Cross-Reference: Prior BLOCKER Closure

| Prior Finding | Status | Evidence |
|---------------|--------|----------|
| **CR-01 (G-01)**: `_onStatus` silently dropped transcript on self-termination | **CLOSED** | `voice_input_screen.dart:185-195` routes to `_stopRecordingAndCommit` when `_pressStart != null`; widget test at `voice_input_screen_test.dart:774-865` proves form fills without gesture release; idempotency block at lines 848-863 proves no double-commit on subsequent `gesture.up`. |
| **CR-02 (G-02 part A)**: `_onError` silently reset to idle | **CLOSED** | `voice_input_screen.dart:198-220` now calls `showVoiceRecognitionErrorToast(context, errorMsg)`; widget test at `voice_input_screen_test.dart:875-936` asserts `SoftToast` mounts with localized text and raw `error_network` is NOT visible (WR-05 i18n compliance). |
| **CR-02 (G-02 part B)**: permanent error did not gate the mic | **CLOSED** | `voice_input_screen.dart:215-217` flips `_isInitialized = false` when `permanent==true`, reusing the existing `_onLongPressStart` guard at line 244; widget test at `voice_input_screen_test.dart:946-1004` proves `startListening` is never called after a permanent error. |
| **WR-05 (i18n)**: raw English errorMsg surfaced to UI | **CLOSED** | `voice_error_toast.dart:32-46` switches on the error code and renders ONLY ARB-backed `voiceRecognitionError*` strings. ARB keys verified in `app_ja.arb`, `app_zh.arb`, `app_en.arb` at line 1648-1660 each. |
| **Adoption of CR-02 LITERAL shape** (no `_hasPermanentError` field) | **CONFIRMED** | `grep -r _hasPermanentError lib/ test/` returns zero matches. The existing `_isInitialized` guard at line 244 is byte-identical to pre-22-09 state. |

The closure work was executed faithfully to the prescribed shape. The remaining WR findings above are either latent pre-existing issues (WR-03), new semantic risks made visible by the broadened commit path (WR-01, WR-02), or follow-up polish items (IN-01/02/03). None require re-opening the phase.

---

_Reviewed: 2026-05-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

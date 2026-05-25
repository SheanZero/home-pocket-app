---
phase: 22-voice-one-step-integration-record-button-ux
reviewed: 2026-05-25T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - lib/core/theme/app_colors.dart
  - lib/features/accounting/presentation/screens/voice_input_screen.dart
  - lib/features/accounting/presentation/widgets/transaction_details_form.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - test/integration/features/accounting/voice_save_entry_source_test.dart
  - test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart
  - test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
  - test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart
findings:
  critical: 2
  warning: 7
  info: 3
  total: 12
status: issues_found
---

# Phase 22: Code Review Report

**Reviewed:** 2026-05-25
**Depth:** standard
**Files Reviewed:** 10 (4 auto-generated localization Dart files and 1 PNG golden baseline skipped)
**Status:** issues_found

## Summary

The hold-to-record rewrite is structurally coherent: gesture dispatch, the 300 ms misfire gate, mic-button AnimatedContainer morph, EntrySource.voice stamping, and the GlobalKey batch-fill into TransactionDetailsForm all line up with Plan 22's design. Tests cover the happy path, misfire, focus interruption, idempotency of the new setters, and the SC-2 schema CHECK round-trip end-to-end.

That said, two correctness gaps will surface in real use:

1. **Self-terminated sessions silently drop the transcript.** The speech service's "done"/"notListening" status callback flips `_isRecording` to false but never invokes the parse + batch-fill path. Once the recognizer ends itself (any 30 s holdover, network glitch, or `pauseFor` timeout), the subsequent finger-release falls through both guards in `_onLongPressEnd` and the user's transcript evaporates with no UI signal.
2. **Errors from the speech service are swallowed.** `_onError` discards `errorMsg` and `permanent`, so permission revocation, network failures, and unavailable engines reset the UI to idle with zero feedback — indistinguishable from a normal end-of-recording.

Beyond those, several issues add up to a fragile commit path: the `_voiceLocaleId` initial value can leak through if the user holds the mic before `voiceLocaleIdProvider` resolves; the satisfaction batch-fill reads a stale `_parseResult` instead of the just-resolved parse; and a vacuous null check papers over the model contract. The l10n ARB parity is correct (`holdToRecord`, `recording`, `voiceMicrophonePermissionRequired` exist in all three locales with matching `@meta` blocks).

The two new colors (`recordingGradientStart`/`recordingGradientEnd`, light + dark) are well-scoped. Tests have minor cleanup leaks but assertions are sound.

## Critical Issues

### CR-01: Speech service self-termination silently drops the user's transcript and batch-fill

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:171-180, 217-229`
**Issue:** `_onStatus` flips `_isRecording = false` when the recognizer reports "done" or "notListening", but performs no parse / commit / batch-fill. After the flag clears, `_onLongPressEnd` short-circuits at line 220 (`!_isRecording → return`) on the eventual finger release, so neither `_stopRecordingAndCommit` nor `_cancelRecordingAndDiscard` ever runs.

Real-world triggers:
- `listenFor: Duration(seconds: 30)` expiry mid-press (long voice notes).
- `pauseFor: Duration(seconds: 3)` triggering between phrases (very common in Japanese hesitation patterns).
- Platform-side mic interruption (incoming call audio routing changes, audio focus loss on Android).

The user holds, speaks "1千8百4十元 星巴克", the engine emits a final transcript, status flips to "notListening" 3 s after the last word, `_isRecording = false`, user releases their finger expecting the transaction to be filled — nothing happens and the mic returns to idle with no feedback. The comment at lines 434-438 of `_onResult` even acknowledges path (b) as the auto-termination route, but the handler doesn't implement the commit.

Compare with the legacy two-screen flow (per CONTEXT/Plan 22): there, "done" status drove the navigation to confirm-screen, which itself displayed the parsed result. After Phase 22's collapse to one screen, that exit path was deleted but no replacement was wired into `_onStatus`.

**Fix:** Drive the same commit path from `_onStatus` when the recognizer self-terminates while the user still has the finger down (`_pressStart != null`):

```dart
void _onStatus(String status) {
  if (!mounted) return;
  if ((status == 'done' || status == 'notListening') && _isRecording) {
    // If the user is still pressing, treat self-termination as a successful
    // commit — same path as releasing past the 300 ms threshold.
    if (_pressStart != null) {
      _pressStart = null;
      // Fire-and-forget — _stopRecordingAndCommit already gates on mounted.
      unawaited(_stopRecordingAndCommit());
      return;
    }
    setState(() {
      _isRecording = false;
      _soundLevel = 0.0;
    });
  }
}
```

Also add a widget test that emits a final result, fires `onStatus('done')` from the fake speech service, and asserts the form is filled.

### CR-02: `_onError` swallows all speech-recognition errors with zero user feedback

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:182-188`
**Issue:** The error callback receives `errorMsg` and a `permanent` flag but ignores both. The UI silently resets to the idle state — visually identical to a successful end-of-recording — even when the failure is unrecoverable (e.g., permission revoked mid-session, no network for cloud recognizer, engine unavailable).

Two consequences:
1. Users who lose mic permission while the screen is open see no signal that recording is broken; the permission toast (`_showPermissionError`) only fires once during initial `_initSpeechService`.
2. Transient network errors look the same as the user manually stopping early — there's no retry affordance or even a hint to check connection.

CLAUDE.md security/error-handling rules require "user-friendly error messages in UI-facing code" and "never silently swallow errors". `_onError` does exactly that.

**Fix:** Surface the error via the existing `SoftToast` infrastructure already used for `_showPermissionError`. At minimum, log + show a localized toast; for `permanent=true`, gate the mic button until re-initialization. Example:

```dart
void _onError(String errorMsg, bool permanent) {
  if (!mounted) return;
  setState(() {
    _isRecording = false;
    _soundLevel = 0.0;
    if (permanent) _isInitialized = false;
  });
  _showRecognitionErrorToast(errorMsg, permanent);
}
```

Add a corresponding ARB key (e.g., `voiceRecognitionError`, `voiceRecognitionErrorPermanent`) in all three locales and a widget test that fires `onError('network', false)` and asserts the toast appears.

## Warnings

### WR-01: First-tap race condition leaks default `_voiceLocaleId = 'zh-CN'` to the recognizer

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:73, 239-280, 540-546`
**Issue:** `_voiceLocaleId` is initialized to `'zh-CN'` at line 73 and updated only inside `build()` when `voiceLocaleIdProvider` resolves to `AsyncData`. If the user holds the mic before the first build completes the provider load (or during the loading state on a cold start), `_startRecording` reads the default `'zh-CN'` and passes that to the speech engine and to the numeral-machine parser selection (lines 261-263).

For a Japanese-default device this is the worst-case mismatch:
- The platform recognizer is asked for `zh-CN` but the user speaks Japanese → either no result or garbage transcripts.
- `_amountMerger`'s parser is the Chinese state machine, so cross-final merging of "千 / 百" tokens runs the wrong tokenizer.

The integration test (`voice_save_entry_source_test.dart`) hides this with `await tester.pumpAndSettle()` after the override, so the bug doesn't appear in tests. The mic-button golden test similarly settles before any interaction is possible.

**Fix:** Either (a) gate the mic button's `onLongPressStart` on `voiceLocaleAsync is AsyncData` so taps before resolution are ignored, or (b) make `_voiceLocaleId` nullable and treat null as "not ready" with a localized hint. A simple guard:

```dart
void _onLongPressStart(LongPressStartDetails details) {
  if (!_isInitialized || _isRecording) return;
  if (_voiceLocaleId.isEmpty) return; // or check a separate _isLocaleReady flag
  _pressStart = DateTime.now();
  _startRecording();
}
```

Backed by an explicit `_isLocaleReady` flag set only inside the `AsyncData` branch of `build()`.

### WR-02: Vacuous null check on non-nullable `estimatedSatisfaction`

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:336-338`
**Issue:**

```dart
if (_parseResult?.estimatedSatisfaction != null) {
  state.updateSatisfaction(_parseResult!.estimatedSatisfaction);
}
```

`VoiceParseResult.estimatedSatisfaction` is `@Default(5) int` (non-nullable) per `voice_parse_result.dart:27`. The inner expression `_parseResult!.estimatedSatisfaction != null` is always `true` whenever `_parseResult != null`, so the gate is equivalent to a plain non-null check on `_parseResult`. Worse, the check obscures the real semantic — survival-ledger transactions get satisfaction = 5 pushed into the form unconditionally (technically harmless because `submit()` discards it for non-soul ledgers, but it makes the intent unclear and the form state inconsistent with the displayed ledger).

The deeper problem: the value being pushed is the *stale* `_parseResult` from a previous partial/final-result handler (see WR-03), not the satisfaction computed for the in-flight `parseResult` at lines 302-307. The two `_parseResult` writers (`_parseFinalResult` on line 484 and `_parseVoiceInput` on line 457) race against `_stopRecordingAndCommit`.

**Fix:** Compute satisfaction from the just-resolved `parseResult.data` (re-run the soul-ledger estimator inline, or have `parseUseCase.execute` return satisfaction directly when ledgerType==soul). Skip when ledger is survival:

```dart
if (data.ledgerType == LedgerType.soul) {
  final features = _buildAudioFeatures();
  final estimator = ref.read(voiceSatisfactionEstimatorProvider);
  final satisfaction = estimator.estimate(
    audioFeatures: features,
    recognizedText: text,
  );
  state.updateSatisfaction(satisfaction);
}
```

### WR-03: Satisfaction batch-fill reads a stale `_parseResult` racing with `_parseFinalResult`

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:336-338, 412-450, 461-485`
**Issue:** Two independent async pipelines write to `_parseResult`:

1. `_parseFinalResult(text)` (fire-and-forget from `_onResult` line 447) — runs the parser, optionally invokes the soul estimator, and writes `_parseResult` at line 484.
2. `_stopRecordingAndCommit` (line 286) — runs its own `parseUseCase.execute` at line 302 (independent invocation, different timing) and then reads `_parseResult` at line 336 to grab the satisfaction.

Whether pipeline 1 wins the race against pipeline 2 depends on microtask scheduling and how fast the parse use case resolves. If pipeline 2 races ahead, `_parseResult` is the *previous* recording's result (or null), and the satisfaction either uses a stale value or is skipped entirely. The integration tests don't catch this because the fake `_FakeParseVoiceInputUseCase` resolves synchronously in a single microtask.

**Fix:** Coupled with WR-02 — compute satisfaction inline from the in-scope `data` rather than from a side-channel field. Eliminating `_parseResult` reads at line 336 removes the race entirely.

### WR-04: Soul-celebration overlay is unreachable from the voice flow (host pops route before animation)

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:365-392`, `lib/features/accounting/presentation/widgets/transaction_details_form.dart:425-428, 737-750`
**Issue:** `_onSavePressed` calls `Navigator.of(context).popUntil((route) => route.isFirst)` immediately on `success` (line 376). Inside `submit()`, the form sets `_showCelebration = true` for soul saves (line 427) — but the Stack overlay rendering this only runs on the next frame, which never arrives because the route is popped first. The form is disposed before the celebration overlay paints.

Phase 22 explicitly preserves D-15 ("celebration only for .new soul saves"), but the celebration is now invisible in the voice flow. Tests at `transaction_details_form_test.dart:392-437` assert the overlay exists *if* you don't pop, but no test asserts the integrated voice→celebration→pop sequence.

**Fix:** Either (a) defer the pop until the celebration's `onDismissed` callback fires (refactor: pass a continuation through `submit()`, or expose `_showCelebration` as a public listener on the form state), or (b) move celebration ownership to the host so it can be sequenced with navigation. Approach (a) is less invasive:

```dart
result.when(
  success: (tx) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).transactionSaved)),
    );
    if (tx.ledgerType == LedgerType.soul) {
      // Wait for celebration animation to complete before popping.
      // (Pseudo-API — actual implementation needs SoulCelebrationOverlay
      //  to expose a Future<void> dismissal signal.)
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  },
  ...
);
```

### WR-05: `_onError` is also non-localized when surfaced (compounds CR-02)

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:182-188`
**Issue:** Even if CR-02 is fixed by showing a toast with `errorMsg`, the underlying string comes from the platform speech engine and is typically English-only ("network", "no-speech", "error_audio", etc.). Surfacing those verbatim violates the project's i18n rule ("All UI text via `S.of(context)` — never hardcode strings").

**Fix:** When fixing CR-02, map the platform error codes to a localized message in all three ARBs. Common codes from `speech_to_text`:
- `error_network` / `error_network_timeout`
- `error_no_match`
- `error_audio`
- `error_permission` (overlaps with permanent=true)
- `error_speech_timeout`

Define `voiceRecognitionErrorNetwork`, `voiceRecognitionErrorNoMatch`, `voiceRecognitionErrorAudio`, `voiceRecognitionErrorUnknown` in all three locales and switch on `errorMsg`.

### WR-06: Integration-test mocktail `findById(any())` catch-all overrides specific stubs

**File:** `test/integration/features/accounting/voice_save_entry_source_test.dart:192-201`
**Issue:**

```dart
when(() => categoryRepository.findById(_category.id))
    .thenAnswer((_) async => _category);
when(() => categoryRepository.findById(_parentCategory.id))
    .thenAnswer((_) async => _parentCategory);
when(() => categoryRepository.findById(any()))     // ← LAST wins for any matching id
    .thenAnswer((_) async => _category);
```

In mocktail, later `when` calls registered with broader matchers (`any()`) take precedence over earlier specific argument stubs when both can match. As a result, the parent lookup at `voice_input_screen.dart:320` (`repo.findById(category.parentId!)` where `parentId == 'cat_food'`) returns `_category` (the L2 cafe) instead of `_parentCategory` (the L1 food).

For the test's assertion (`rows.first.entrySource == 'voice'` and `rows.first.amount == 500`), this doesn't matter because the use case stores `categoryId = _category.id` regardless. But the test creates a misleading impression that the parent-resolution path works — if a future change starts asserting parent fields, this latent mock issue will misdirect debugging.

**Fix:** Drop the catch-all and rely on the two specific stubs. If the test legitimately needs a fallback for other ids, use a `when(() => findById(any(that: isNot(equals(_category.id) | equals(_parentCategory.id)))))`-style guard, or throw on unexpected ids to make missing stubs loud.

### WR-07: TextEditingController listener removal in tests uses a new lambda — listener leak

**File:** `test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart:910-911, 1056-1057`
**Issue:**

```dart
var notifications = 0;
controller.addListener(() => notifications++);
addTearDown(() => controller.removeListener(() => notifications++));
```

`addListener` and `removeListener` are passed two *different* closure instances (each `() => notifications++` literal builds a new `Function` object), so `removeListener` does nothing — the listener stays attached for the controller's remaining lifetime. The test currently passes because the controller is disposed shortly after via the parent widget's dispose, but the cleanup is purely cosmetic: it doesn't actually remove anything, and a future refactor that keeps the controller alive longer (e.g., a shared controller across tests) would surface stale-listener crashes or counter inflation.

**Fix:** Hoist the listener into a named variable so the same reference is used in both calls:

```dart
var notifications = 0;
void listener() => notifications++;
controller.addListener(listener);
addTearDown(() => controller.removeListener(listener));
```

## Info

### IN-01: Dead/unused parameter — `LongPressStartDetails details` and `LongPressEndDetails details`

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:211, 217`
**Issue:** Both `_onLongPressStart(LongPressStartDetails details)` and `_onLongPressEnd(LongPressEndDetails details)` ignore the `details` argument (no use of `globalPosition`, `velocity`, etc.). The signatures are imposed by `LongPressGestureRecognizer`, so the parameters can't be dropped, but a leading underscore (`_`) clarifies intent and matches Dart conventions.

**Fix:**

```dart
void _onLongPressStart(LongPressStartDetails _) { ... }
void _onLongPressEnd(LongPressEndDetails _) { ... }
```

### IN-02: `_extractVoiceKeyword` particle list is hardcoded to ja/zh only

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:510-531`
**Issue:** The regex lists `[のにでをはがもへとや]` (JP particles) and `[的了吗呢吧啊呀哦]` (CN particles). For English / future locales, no cleanup runs, so the voice-correction keyword would include stop words like "at", "the", etc. The function returns whatever remains after the amount + merchant strip, which is acceptable as a fallback, but worth documenting or extending if English voice input becomes a target.

**Fix:** Either add a comment ("ja/zh only — English path returns the raw remainder by design"), or factor the particle set into a `Map<String, RegExp>` keyed by locale prefix.

### IN-03: Magic number 300 (ms) for misfire threshold appears in code without a named constant

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:224`
**Issue:** `const Duration(milliseconds: 300)` appears as a literal at the gesture decision boundary. The same threshold is implicit in three tests (300, 350, 400 ms wait values across `voice_input_screen_test.dart`). A named constant would keep code and tests synchronized:

```dart
static const _misfireThreshold = Duration(milliseconds: 300);
```

Referenced from both production code and a publicly exported constant the tests import would prevent silent drift if the threshold is ever tuned.

**Fix:** Add a class-private constant; expose via a `@visibleForTesting` getter if tests need to reference it.

---

_Reviewed: 2026-05-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

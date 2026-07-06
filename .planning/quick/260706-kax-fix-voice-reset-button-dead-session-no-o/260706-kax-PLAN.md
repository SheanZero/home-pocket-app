---
phase: quick-260706-kax
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
  - lib/features/accounting/presentation/widgets/voice_listening_overlay.dart
  - test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
  - test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart
autonomous: true
requirements: [VRESET-01, VRESET-02, VRESET-03]
user_setup: []

must_haves:
  truths:
    - "After a fatal recognizer error terminates the continuous session (panel stuck on 停止聆听 + red reset square), tapping the red square restores the snapshot AND restarts a fresh listening session — pttContinuousActive back true, a new startListening issued, pttListenStatus listening, and a subsequent speech-final auto-fills the form (VRESET-01)"
    - "Two back-to-back resetPttSessionAndRestart calls inside the cancel→start window produce exactly ONE additional startListening — the second call early-returns on the _restarting guard, no double-start plugin hang (VRESET-02)"
    - "In the stopped state, tapping the 「点击重置重新录入」 caption at its VISUAL (Transform-shifted) position fires onReset and NOT onExit; in the listening state a tap at the same spot still falls through to the panel exit, unchanged (VRESET-03)"
    - "flutter analyze reports 0 issues; the full flutter test suite is green; no golden re-baseline needed (gesture-only widget change, no paint change)"
  artifacts:
    - path: "lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart"
      provides: "resetPttSessionAndRestart with dead-session recovery semantics: _restarting reentrancy guard at entry, _continuousActive=true restored in the buffer-clear setState, belt-and-braces speech-service re-initialize when !isAvailable"
    - path: "lib/features/accounting/presentation/widgets/voice_listening_overlay.dart"
      provides: "voiceTapResetToRerecord caption made a reset hit-target via Transform.translate → Visibility → GestureDetector(onReset) nesting"
    - path: "test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart"
      provides: "3 new tests: fatal-error→reset recovery, reset reentrancy single-start, unavailable-service re-init-before-restart"
    - path: "test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart"
      provides: "new test: stopped-state tap on the reset caption fires onReset not onExit"
  key_links:
    - from: "manual_one_step_screen.dart _onVoiceReset (line ~350)"
      to: "voice_ptt_session_mixin.dart resetPttSessionAndRestart"
      via: "sole caller — snapshot restore then session restart; must no longer silently no-op when the session died via onError fatal branch"
    - from: "voice_listening_overlay.dart caption GestureDetector"
      to: "onReset callback prop"
      via: "hit test must traverse RenderTransform (skips own bounds check) then Visibility's IgnorePointer (gates listening state)"
---

<objective>
Fix the dead voice-reset button: after a fatal speech-recognition error kills the continuous tap session, the red reset square in the voice panel does nothing because `resetPttSessionAndRestart()` early-returns on `!_continuousActive`. Also fix the missing reentrancy guard on the same function (double-tap → concurrent cancel→start race → plugin hang) and make the 「点击重置重新录入」 caption a real reset hit-target instead of a trap that exits the panel.

Purpose: the panel's stopped state promises "tap to reset and re-record"; that promise must hold no matter how the previous session ended.
Output: patched `voice_ptt_session_mixin.dart` + `voice_listening_overlay.dart`, 4 new regression tests, analyze 0, full suite green.
</objective>

<context>
Root cause is fully diagnosed (verified against current source; no re-investigation needed):

- BUG 1 (primary): `voice_ptt_session_mixin.dart` line 607, guard `if (!_continuousActive || !mounted) return;`. The `onError` fatal branch (lines 714-727) sets `_continuousActive=false` + `_listenStatus=stopped` but the host panel stays open (`_voiceModalOpen` only flips in `_onVoiceModalExit`). Every reset tap then silently early-returns.
- BUG 2: `_restarting` is set inside the function but never checked at entry — reentrant call in the cancel→start window double-starts the recognizer (the exact hang the function's own doc comment describes for the onStatus path).
- BUG 3: the caption at `voice_listening_overlay.dart` lines 214-235 is painted 34px above its layout box via `Transform.translate` and sits outside `_CentralSquare`'s GestureDetector; a tap at the visual position falls through to the panel-root opaque GestureDetector → `onExit` (accidental panel exit).

Files:
@lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
@lib/features/accounting/presentation/widgets/voice_listening_overlay.dart
@lib/features/accounting/presentation/screens/manual_one_step_screen.dart (lines 296-352 — host wiring `_onVoiceReset` / `_onVoiceModalExit`; read-only, no edits expected)
@test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart (harness: `CapturingSpeechService` fake at lines 42-129 with `emitError`/`emitFinal`/`emitTerminalStatus`, `_MixinHost` host widget, `buildHost`/`hostOf` helpers; model new tests on the R4 BUG A/B tests at lines 605-745 and the R5 fatal-recovery test at line 1051)
@test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart (harness: plain `MaterialApp`+`Scaffold` pumps with counter callbacks; model the new test on the "stopped: tapping the central red square fires onReset and NOT onExit" test at line 130)

Confirmed: no existing test asserts the old `!_continuousActive` no-op guard, so changing it breaks nothing. `StartSpeechRecognitionUseCase` exposes `bool get isAvailable` (line 51 of start_speech_recognition_use_case.dart) and an idempotent `initialize(onStatus:, onError:)`.
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Make resetPttSessionAndRestart recover a dead session + guard reentrancy (mixin)</name>
  <files>lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart, test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart</files>
  <behavior>
    RED first — add 3 tests to voice_ptt_session_mixin_test.dart (follow the existing buildHost/hostOf/CapturingSpeechService patterns; new group or appended after the R5/R6 tests):
    - Test 1 (VRESET-01, headline): start a tap session, drive a fatal error via speech.emitError('error_retry', permanent: true) — asserts precondition pttContinuousActive false + pttListenStatus stopped (session dead, panel would show the red square). Then await host.resetPttSessionAndRestart() + pumpAndSettle. Assert: cancelCount incremented; startCount incremented (fresh startListening); pttContinuousActive true again; pttIsRecording true; pttListenStatus listening. Then speech.emitFinal with a parseable utterance (reuse the '1千8百4十元 星巴克' fixture pattern from the R4 BUG A second test) and assert the form fills (find.text('星巴克')) — proves the recovered session's _onResult continuous branch works (i.e. _continuousActive was restored BEFORE the fill path runs).
    - Test 2 (VRESET-02): from a live tap session, call resetPttSessionAndRestart() twice WITHOUT awaiting the first (final f1 = ...; final f2 = ...; await f1; await f2;). Dart async bodies run synchronously to the first await, so the second call must hit the _restarting entry guard. Assert startCount increased by exactly 1 across both calls (one from the first reset only) and the session is listening.
    - Test 3 (belt-and-braces): make CapturingSpeechService.isAvailable field-backed — replace the hardcoded `true` getter with a mutable `available` field defaulting true, and add a mutable `initializeResult` (default true) returned by initialize (all existing tests unaffected: defaults preserve current behavior). After a fatal error, set speech.available = false, then reset: assert initializeCount incremented (re-init attempted before restart) AND startCount incremented (restart proceeded on successful re-init). Sub-case: with initializeResult = false, reset must NOT call startListening and must end with pttListenStatus stopped + pttContinuousActive false + pttIsRecording false (no optimistic listening flip).
    Run the suite — all 3 MUST fail against current code (test 1 fails on the guard no-op; test 2 on double start; test 3 on missing re-init branch).
  </behavior>
  <action>
    GREEN — modify resetPttSessionAndRestart in voice_ptt_session_mixin.dart:
    1. Entry guard: replace the `!_continuousActive || !mounted` check with a check on `_restarting || !mounted` (fixes BUG 2 reentrancy AND stops gating recovery on a live session). `_restarting = true` must remain the first statement after the guard, BEFORE any await, so a synchronous second call sees it.
    2. In the buffer-clear onPttSessionChanged block (step 2 of the existing body), add `_continuousActive = true` — the recovery semantic: the reset button always honors 重新录入 regardless of how the previous session died. It MUST be set before startListening so the `_onResult` continuous-branch fill works in the recovered session.
    3. Belt-and-braces before the fresh startListening (step 3): if `!pttSpeechService.isAvailable`, first `await pttSpeechService.initialize(onStatus: onStatus, onError: onError)` (idempotent; the fatal path's async `_recoverBarAfterFatalError` may not have completed yet). If initialize returns false (or `!mounted` after the await), roll state back — `_continuousActive = false`, `_isRecording = false`, `_listenStatus = PttListenStatus.stopped` via onPttSessionChanged — and return WITHOUT calling startListening (the finally still clears `_restarting`, so a later tap can retry).
    4. Update the function's doc comment: it now also revives a session killed by the onError fatal branch, and the entry guard is the reentrancy fence (keep the existing BUG A/BUG B explanation).
    Do NOT touch onError/onStatus/exitPttTapSession/startPttTapSession or any hold-path code. No `// ignore:` suppressions.
    Then grep-confirm the caller inventory: `grep -rn "resetPttSessionAndRestart(" lib/` must show only the mixin definition + the single `manual_one_step_screen.dart` `_onVoiceReset` call site (no other caller depends on the old no-op semantics). If another caller appears, stop and re-evaluate before proceeding.
  </action>
  <verify>
    <automated>flutter test test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart</automated>
  </verify>
  <done>All 3 new tests pass; every pre-existing test in the file passes unmodified (especially R4 BUG A/B and the R5 fatal-recovery tests); grep shows exactly one production call site in manual_one_step_screen.dart.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Make the 「点击重置重新录入」 caption a reset hit-target (widget)</name>
  <files>lib/features/accounting/presentation/widgets/voice_listening_overlay.dart, test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart</files>
  <behavior>
    RED first — add to voice_listening_overlay_test.dart (model on the line-130 "stopped: tapping the central red square" test):
    - Test: pump VoiceRecordPanel with status stopped and exits/resets counters; `await tester.tap(find.text(l10n.voiceTapResetToRerecord))` (tester.tap resolves the center through localToGlobal, i.e. the VISUAL Transform-shifted position — exactly where a user taps); assert resets == 1 and exits == 0. Do NOT pass warnIfMissed: false — the fix must make the hit real, and warnIfMissed is the canary.
    - The existing listening-state tests (grey-square tap fires onExit; caption hidden-but-reserved) must stay green — they pin the listening-state fall-through and the equal-height invariant.
    Run — the new test MUST fail on current code (tap misses the caption; exits increments via the panel-root handler, or warnIfMissed flags the miss).
  </behavior>
  <action>
    GREEN — in voice_listening_overlay.dart, restructure the caption subtree (currently Visibility → Transform.translate → Padding → Text) into this exact nesting order:
    Transform.translate(offset 0,-34) → Visibility(visible: isStopped, maintainSize/maintainAnimation/maintainState: true) → GestureDetector(behavior: HitTestBehavior.opaque, key: ValueKey('voice-reset-caption'), onTap: onReset) → Padding(bottom: 8) → Text(l10n.voiceTapResetToRerecord).
    WHY this order is load-bearing (do not deviate):
    - Transform MUST be outermost: RenderTransform.hitTest skips its own size check and inverse-maps the tap into child layout coordinates, so a tap at the visual position (34px above the layout box, which does NOT overlap it in the 141dp bottom-zone geometry) still reaches the subtree. With Visibility outermost (the naive wrap), its maintainSize Opacity/IgnorePointer proxy boxes bounds-check the un-shifted layout box first and the visual tap misses entirely.
    - GestureDetector MUST be inside the Visibility: maintainSize keeps an IgnorePointer(ignoring: !visible) wrapper, so in the listening state the detector is inert and the tap falls through to the panel-root exit handler exactly as today. Placing an opaque GestureDetector above the Visibility would hijack listening-state taps at that spot into phantom resets.
    Layout math is unchanged (Transform sizes to child; the Column sees the same reserved box), so the equal-height / exit-hint-position invariants from fast-hint2 hold; paint output is identical — no golden impact expected. Update the surrounding R7/fast-hint2 comments to document the new nesting rationale. No other visual or copy change; zero ARB changes.
  </action>
  <verify>
    <automated>flutter test test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart</automated>
  </verify>
  <done>New caption-tap test passes (onReset fired, onExit not); all pre-existing panel tests pass unmodified, including listening-state fall-through and equal-height invariant tests.</done>
</task>

<task type="auto">
  <name>Task 3: Full verification + commit</name>
  <files>(verification only — no new source edits expected)</files>
  <action>
    Run `flutter analyze` — MUST be 0 issues (no `// ignore:` added anywhere in this task set).
    Run the FULL `flutter test` suite directly (never piped through tail/head — the exit code and final counter are the evidence; scoped runs miss architecture tests). Expect all green, no golden diffs (Task 2 is hit-test-only; if any golden fails, the widget change altered paint — go back and fix the widget, do not re-baseline).
    Commit the work as atomic commits per the repo convention (test-first commits already made in Tasks 1-2 if executor commits per RED/GREEN; otherwise one fix commit per bug area): suggested types `test:` for RED additions and `fix:` for the mixin/widget changes, e.g. "fix: voice reset button revives dead session + caption hit-target (quick-260706-kax)".
  </action>
  <verify>
    <automated>flutter analyze && flutter test</automated>
  </verify>
  <done>flutter analyze 0 issues; full suite green (all tests pass, counter visible in output); changes committed; working tree clean apart from .planning artifacts.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| (none new) | Bug fix in on-device UI/session state only; no new inputs cross a trust boundary, no crypto/storage/network paths touched, no package installs |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-kax-01 | DoS (self) | resetPttSessionAndRestart double-start | low | mitigate | _restarting entry guard (Task 1) — the fix itself removes the plugin-hang path |
</threat_model>

<verification>
- `flutter analyze` → 0 issues
- `flutter test test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart` → green incl. 3 new tests
- `flutter test test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart` → green incl. 1 new test
- Full `flutter test` → green, no golden re-baseline
- `grep -rn "resetPttSessionAndRestart(" lib/` → definition + single manual_one_step_screen call site only
</verification>

<success_criteria>
- VRESET-01: dead-session reset revives listening (test-proven end-to-end through form fill)
- VRESET-02: reset is reentrancy-safe (exactly one startListening per reset window)
- VRESET-03: caption tap = reset, not exit; listening-state behavior byte-identical
- Zero analyzer issues, full suite green, no ARB/generated/golden churn
</success_criteria>

<output>
On completion create `.planning/quick/260706-kax-fix-voice-reset-button-dead-session-no-o/260706-kax-SUMMARY.md` (quick-task summary: what changed, root cause, test evidence, commit hashes).
</output>

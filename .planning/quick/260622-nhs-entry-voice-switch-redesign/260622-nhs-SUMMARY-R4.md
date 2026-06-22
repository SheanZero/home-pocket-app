---
task: 260622-nhs
round: R4
title: Voice session lifecycle — 4 runtime/timing fixes (reset accumulation, post-reset freeze, hardcoded status, slow parse)
type: fix
subsystem: accounting/voice (single-page push-to-talk continuous tap session)
branch: main
worktree: false
human_verify: pending
gate:
  analyze: "0 issues"
  test: "3117 passed, 0 failed (full suite incl. architecture tests)"
  goldens: "no re-baseline needed (default status=listening keeps prior title/red dot byte-identical; full suite green)"
commits:
  - d690f472 fix(260622-nhs): reset cancels recognizer + fresh restart, serialized to suppress double re-arm (BUG A+B)
  - 1eee90a6 feat(260622-nhs): live listen status (listening/processing/stopped) (BUG C)
  - ccc4cde6 perf(260622-nhs): host wiring — reset-and-restart + live status + dedupe/partial fill (BUG D + integration)
key-files:
  modified:
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - lib/features/accounting/presentation/widgets/voice_listening_overlay.dart
    - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations*.dart (gen-l10n, force-added)
    - test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
    - test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart
    - test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart
---

# 260622-nhs R4 — Voice Session Lifecycle Fixes Summary

One-liner: Fixed 4 device-found voice-session bugs in the continuous tap session — reset now cancels the iOS recognizer (clears its accumulated buffer) and serially re-arms (no freeze), the panel shows live listening/processing/stopped status, and parsing dedupes + drives sub-second live partial auto-fill — all under strict TDD with a fake speech service; legacy hold path untouched.

## What changed (per bug)

### BUG A — reset clears the recognizer buffer + restarts fresh
- New `resetPttSessionAndRestart()` in the mixin: `cancel()` (discards the recognizer's accumulated in-window buffer — the real cause of the old transcript re-surfacing) → clear `_finalText/_partialText/_parseResult/_mergedAmount` + rebuild merger (`_rebuildAmountMerger()`) → fresh `startListening`.
- Host `_onVoiceReset` now calls it, replacing the weak R3 `resetPttSessionState() + restartPttListening()` pair (app-side clear only; restart was a no-op while `isListening`, so the iOS buffer survived).

### BUG B — post-reset freeze (假死)
- Root cause confirmed as hypothesized: reset's cancel→start raced `onStatus` auto-re-arm (cancel emits notListening/done → onStatus → second `startListening` → plugin hang).
- Fix: `_restarting` guard suppresses the `onStatus` auto-re-arm across the whole cancel→start window; `await cancel()` then `await startListening()`, guard cleared in `finally`.
- Hardening: `_parseFinalResult` is now null-safe (unparseable text no longer throws on `result.data!`), so an empty/failed parse during the post-reset window can't crash the session.

### BUG C — live listen status (not hardcoded 正在聆听)
- New `PttListenStatus { listening, processing, stopped }` enum + `pttListenStatus` getter, driven by `onStatus` (listening↔stopped) and a `_parsing` in-flight flag (processing overrides listening).
- `VoiceRecordPanel` gains a `status` param → title + pulse-dot colour: listening 「正在聆听…」(red) / processing 「正在解析…」(amber/`palette.warning`) / stopped 「停止聆听」(grey/`palette.textTertiary`). Defaults to `listening` so existing callers/goldens are unaffected.
- New ARB keys `voiceStatusProcessing` / `voiceStatusStopped` in ja/zh/en + gen-l10n; host passes `pttListenStatus`.

### BUG D — slow parse
- Dedupe: `_parseFinalResult` now returns the parsed result; the final branch reuses it for the fill instead of `_fillFormFromText` re-parsing the same text. `_fillFormFromText` accepts an optional `preParsed`.
- Live partial fill: the existing 300ms debounced partial parse (`_parseVoiceInput`) now also drives a form-fill in the continuous session, so the entry updates sub-second as the user speaks rather than after the 3s pauseFor final. Idempotent, overwritten by the final fill, revertible by reset (snapshot baseline unchanged).
- JPY stays off the network path; the foreign triple still fetches only on a detected foreign currency.

## Deviations from Plan

None material. Root causes matched the FIX-R4 hypotheses. One extra correctness fix beyond the spec (Rule 1 — bug): made `_parseFinalResult` null-safe against an empty/failed parse (the prior `result.data!` would crash on unparseable post-reset text), surfaced by the BUG B test driving a final with no parse mapping.

One required test-assertion update (NOT a legacy hold-path change): the host's R2/R3 continuous-session reset test (`manual_one_step_screen_test.dart`) previously asserted `speech.canceled == isFalse` (the old R3 reset semantics). BUG A's whole point is that reset MUST cancel to clear the recognizer buffer, so that assertion was corrected to `canceled == isTrue` + `isListening == isTrue`. This is the continuous tap path the fix targets, not the legacy hold path (which is byte-unchanged and green).

## Constraints honored
- Only the continuous tap session path changed. Legacy `voice_input_screen` hold path + tests are byte-unchanged and green (23 tests pass, zero assertion changes).
- D-2 fill-and-stay (no auto-save), foreign triple / satisfaction / JPY-native / merger semantics preserved.
- analyze 0; full `flutter test` 3117 green (architecture tests included). New ARB keys in ja/zh/en + gen-l10n + `git add -f lib/generated/`.
- palette-only (status colours via `palette.warning` / `palette.textTertiary` / `palette.recordingGradientStart`; zero raw hex).
- `manual_one_step_screen.dart` LOC: 1012 → 1012 (no growth; the reset-wiring change is net-neutral, the panel `status:` line offsets the removed second reset call).
- Strict TDD: fake speech service drives result/status sequences (accumulate→reset-clears→restart-produces; double-start suppression; status transitions; partial auto-fill; final dedupe-once).
- Branch main, no worktree. Docs (SUMMARY/FIX-R4/STATE) left uncommitted for orchestrator; worklog left staged-uncommitted; ROADMAP untouched.

## Known Stubs
None.

## On-device recheck (PENDING — human, blocking)
1. Reset → transcript clears, recognizer restarts; the next utterance is fresh content (no old-text accumulation).
2. After reset the voice responds normally (no freeze); repeated reset+respeak works.
3. Panel status tracks the real recognizer state: listening / processing / stopped.
4. Speak-to-update latency is visibly faster (partial updates live, no 3s wait).

## Self-Check: PASSED
- Files verified present (modified in-place).
- Commits verified in git log: d690f472, 1eee90a6, ccc4cde6.
- analyze 0, full suite 3117/3117 green.

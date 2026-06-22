---
task: 260622-nhs
revision: R6
title: One-shot listen (停止聆听 + tap-reset hint) + amount parse 99999→9
date: 2026-06-22
status: automated-gate-passed
human_verify: pending
branch: main
commits:
  - e5d64133  # fix: final parse authoritatively overrides partial amount (99999 not 9)
  - d2656847  # fix: one-shot listen — stop after recognizer ends, 停止聆听 + tap-reset hint
  - d2773edf  # fix: decouple voice panel visibility from isRecording
gate:
  analyze: 0 issues
  test: 3132 passed / 0 failed (full suite, incl. architecture + golden)
  zh_corpus: 54/55 (98.2%, up from 53/55)
  goldens: no rebaseline (voice panel has no golden coverage; full golden suite green)
files_changed:
  - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
  - lib/features/accounting/presentation/widgets/voice_listening_overlay.dart
  - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
  - lib/infrastructure/voice/chinese_numeral_state_machine.dart
  - lib/infrastructure/voice/japanese_numeral_state_machine.dart
  - lib/application/voice/voice_text_parser.dart
  - lib/l10n/app_{ja,zh,en}.arb (+ lib/generated)
---

# 260622-nhs R6 Summary

Fixed two on-device bugs surfaced after R5, with systematic root-cause debugging
then TDD. Modifies R5 continuous-tap code in place; hold path + voice_input_screen
tests unchanged.

## BUG 1 — one-shot listen + correct stopped status + tap-reset hint

**Root cause:** iOS continuous re-arm is unreliable. `onStatus` terminal and the
`error_no_match`/timeout `onError` paths optimistically re-called `startListening`
and set `_listenStatus=listening`, but the mic frequently did NOT actually restart
→ status stuck on 「正在聆听」 with a dead mic.

**Fix:**
- `voice_ptt_session_mixin.dart`: when the recognizer naturally terminates
  (`done`/`notListening` terminal, or `error_no_match`/`error_speech_timeout`
  silence) in the continuous tap session → set `_isRecording=false`,
  `_listenStatus=stopped`, and **do NOT re-arm**. `error_no_match` still swallows
  the toast (R5 preserved) but now goes to stopped. Removed the now-dead
  `_reArmPttListening` / `_reArmAfterTransientError` / public `restartPttListening`.
  `pauseFor:3s` tolerates in-sentence pauses for a single listen.
- `VoiceRecordPanel` stopped state: grey static (non-pulsing) dot + flat muted mic
  (no recording-red gradient/shadow) + new 「点击重置重新录入」 hint below the mic.
  New ARB key `voiceTapResetToRerecord` ×ja/zh/en + gen-l10n. 「轻点空白处退出」 hint
  and the 「重置·恢复账目」 button both retained.
- `manual_one_step_screen.dart`: introduced `_voiceModalOpen`. The inline panel is
  now gated on this flag, **NOT `pttIsRecording`** — the one-shot recognizer
  stopping (isRecording=false) no longer snaps the keypad back; the panel STAYS
  (showing 停止聆听 + tap-reset hint) until the user taps the blank area. Exit closes
  the modal (keeps content); 重置 → `resetPttSessionAndRestart` (fresh recording,
  status→listening, panel stays open).

## BUG 2 — "99999日元" parsed to 9

**Root cause (confirmed, matched the FIX-R6 hypothesis at the parser layer, NOT the
partial-fill):** the sentence 「…一共用了99999日元」 contains 「一」 (in 一共) which trips
`_numeralHintPattern` → the zh numeral state machine runs. Its scanner is a
positional accumulator that does `digit = value` per token (overwrite, not
accumulate), so a run of bare Arabic digits keeps only the LAST → 99999 → **9**.
Comma-grouped 「99,999」 additionally has the comma dropped and the run split.
`_mergedAmount` / partial-fill were NOT the culprit — the final parse itself was
wrong, so 「final authoritatively overrides」 alone would still fill 9.

**Fix:**
- `chinese_numeral_state_machine.dart` / `japanese_numeral_state_machine.dart`:
  `normalize` now accumulates **adjacent** consecutive Arabic digits into ONE
  multi-digit `Digit` (a non-Arabic rune flushes the run). 「99999」 → 99999;
  「2千304」 → 2304 (also fixed a corpus-tolerated failure). A separating char (a
  stray 「一」 + intervening text) flushes, so noise never merges into the amount.
- `voice_text_parser.dart`: when the text contains a comma-grouped Arabic number
  (`\d[,，]\d`) the Arabic regex is authoritative over the state machine → handles
  「99,999」 / 「1,234,567」 even when a stray kanji numeral trips the hint.

This makes the FINAL parse authoritative for the amount (it reads the full number
correctly), which is what overrides any earlier partial fill.

## Deviations from Plan

None beyond the documented commit split: the FIX-R6 commit list named BUG 1 as two
commits (one-shot listen; decouple panel visibility) and BUG 2 as one — implemented
exactly that (3 commits). The BUG 2 root cause matched the spec's parser-layer
hypothesis (multi-digit/comma-grouped parse), not the partial-fill alternative — so
the fix is in the parser/normalize, not the fill path.

## Constraints honored

- Only the continuous tap path changed; hold path + voice_input_screen tests green
  with zero assertion changes. Foreign-triple / JPY-native / satisfaction / merger
  cases preserved (corpus improved 53→54/55).
- Strict TDD: RED repro tests (99999/99,999; one-shot terminal→stopped+hint; no
  re-arm loop; panel stays open via `_voiceModalOpen`) → GREEN.
- analyze 0; FULL `flutter test` 3132/0; palette-only; new ARB ×3 + gen-l10n +
  git add -f generated. manual_one_step_screen.dart 1020 LOC (was 1014; +6 net).
- No ROADMAP touched. Docs (SUMMARY/FIX/STATE) left for orchestrator; worklog
  staged-uncommitted.

## On-device recheck (human, PENDING)

1. **Stopped status + tap-reset hint:** speak one utterance → after the recognizer
   ends, the panel shows 「停止聆听」 (grey, non-pulsing mic) + 「点击重置重新录入」; the
   status NEVER sticks on 「正在聆听」 with a dead mic. Tapping 重置 starts a fresh
   recording (status → 聆听). Tapping the blank area exits and the keypad returns.
2. **99999 parse:** say 「99999日元」 (or 「今天买手机，一共用了99999日元」) → the amount
   fills 99,999, NOT 9. Verify other amounts (foreign triple, JPY-native, comma
   forms) do not regress.

## Self-Check: PASSED

- All 3 commits exist on main (e5d64133, d2656847, d2773edf).
- analyze 0; full test 3132/0.
- New ARB key present in all 3 locales + generated.
- Files changed exist and compile.

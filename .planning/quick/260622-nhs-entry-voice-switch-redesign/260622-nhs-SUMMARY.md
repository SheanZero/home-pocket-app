---
status: complete
phase: quick-260622-nhs
plan: 01
subsystem: accounting/presentation
human_verify: pending
tasks_completed: 4
tasks_total: 5
duration_min: ~60
completed: 2026-06-22
tags: [push-to-talk, voice, single-page-entry, refactor, l10n, golden]
key-files:
  created:
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - lib/features/accounting/presentation/widgets/hold_to_talk_bar.dart
    - lib/features/accounting/presentation/widgets/voice_listening_overlay.dart
    - lib/features/accounting/presentation/screens/manual_one_step_foreign_card.dart
    - test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
    - test/widget/features/accounting/presentation/widgets/hold_to_talk_bar_test.dart
    - test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart
  modified:
    - lib/features/accounting/presentation/screens/voice_input_screen.dart
    - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
    - lib/features/accounting/presentation/screens/ocr_scanner_screen.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
  deleted:
    - lib/features/accounting/presentation/widgets/entry_mode_switcher.dart
    - lib/features/accounting/presentation/widgets/input_mode_tabs.dart
    - lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart
requirements_completed: [D-1, D-2, D-3, D-4]
---

# Quick 260622-nhs: 记账录入「按住说话」单页重构 Summary

Single-page push-to-talk 记账 entry — the 手工/语音 mode Tab is gone, a full-width
樱粉「按住说话」 bar sits below the keypad; hold raises a listening overlay (transcript
+ waveform + recording-red mic), release batch-fills the SAME form and stays on the
manual page (no auto-save). Voice logic is reused via the extracted
`VoicePttSessionMixin` (not rewritten); foreign-triple / 悦己 satisfaction / JPY-native
/ 2.5s chunk-merger behavior unchanged.

## Tasks 1–4 — complete; automated gate green. Task 5 on-device verify — PENDING.

| Task | Name | Commit | Result |
| ---- | ---- | ------ | ------ |
| 1 | Extract VoicePttSessionMixin (no behavior change) | `4c651bbc` | voice suite 35/35 zero-assertion-change ✓ |
| 2 | HoldToTalkBar + VoiceListeningOverlay + 3 ARB keys | `180c1325` | widget + arb-parity/color/CJK ✓ |
| 3 | Wire PTT into ManualOneStepScreen (fill-and-stay) | `c2921b5b` | bar-below-keypad, overlay, voice/manual provenance ✓ |
| 4 | Remove mode-switch surface + voice route; prune ARB | `24898044` | grep gate 0; deletions clean ✓ |
| (gate) | test-only lint cleanup | `b68f6ccf` | analyze 0 ✓ |
| 5 | Full gate + on-device PTT verify | — | automated portion done; **on-device PENDING** |

## Automated Gate Results (Task 5)

- `flutter analyze` = **0 issues** (whole project).
- FULL `flutter test` = **3097 / 3097 passed** (architecture tests included:
  hardcoded_cjk_ui_scan, color_literal_scan, arb_key_parity, provider_graph_hygiene).
- Goldens re-baselined on macOS (scoped, only the widget that changed): **1** —
  `voice_input_screen_mic_button_idle.png` (the voice screen lost its mode Tab, shifting
  the mic). No other golden changed (full suite confirmed no further golden diffs).
- gen-l10n regenerated; `lib/generated/*` force-added (gitignored-yet-tracked gotcha).
- `grep -rn "EntryModeSwitcher\|navigateToEntryMode" lib/` = **0**.

## must_haves verification

- 手工/语音 Tab gone; manual keypad the only resident state — ✓ (EntryModeSwitcher/InputModeTabs deleted; manual_one_step_screen_test asserts HoldToTalkBar present, no switcher).
- Full-width 樱粉 bar below the keypad; hold → overlay, release → close — ✓ (HoldToTalkBar + VoiceListeningOverlay; manual screen test "hold → overlay → release").
- Release fills the SAME form, stays on the manual page, nothing auto-saves — ✓ (D-2 test: overlay gone, merchant filled, screen still present, `verifyNever(create)`).
- Foreign triple / 悦己 satisfaction / JPY-native / chunk-merger unchanged — ✓ (voice behavior + foreign-save suites pass with zero assertion changes; logic reused verbatim in the mixin).
- voice_input_screen still compiles + characterization/Phase 22/23 tests green — ✓.
- OCR stays hidden behind kOcrEntryEnabled; removing the Tab does not surface OCR — ✓ (flag untouched; ocrScanTitle/ocrHint retained).
- analyze 0; full test green; ARB ja/zh/en parity; gen-l10n regenerated — ✓.

## Deviations from Plan

### Auto-fixed / structural (Rule 3)

**1. [Rule 3 - LOC management] Extracted the foreign-currency card helpers to a sibling file**
- **Found during:** Task 3.
- **Issue:** Adding the PTT mixin wiring + hold lifecycle to `manual_one_step_screen.dart`
  pushed it further over the CLAUDE.md 800-LOC guideline (the file was already 975 LOC
  before this task).
- **Fix:** Moved `AddScreenForeignCard` + `_RateRequiredRow` + `kAddScreenForeignCardLoadingHeight`
  to new `manual_one_step_foreign_card.dart` (byte-faithful move). `foreignPushIsStale`
  kept in the screen file so the existing stale-guard test import path is unchanged.
  Net effect: 975 → 955 LOC.
- **Commit:** `c2921b5b`.

**2. [Rule 1 - test] Updated arb_key_parity OCR-stub assertion**
- **Found during:** Task 4. The architecture test pinned `ocrScan` as a "preserved OCR
  stub", but `ocrScan` was the mode-Tab label (now removed with the switcher). Dropped it
  from `_ocrStubKeys`; `ocrScanTitle`/`ocrHint` (the OCR scanner screen's own strings) stay
  pinned. **Commit:** `24898044`.

## Known residual (advisory, non-blocking)

- `manual_one_step_screen.dart` is **955 LOC** — still over the CLAUDE.md 800 guideline
  (no automated lint enforces file size; the file was 975 pre-task and this task reduced it).
  A deeper extraction of the foreign-currency push logic was judged too risky for a quick
  task (it is entangled with ~8 private fields). Left for a future cleanup.

## Threat register dispositions (all mitigated)

- T-nhs-01 (stale-rate foreign push): the verbatim `pushVoiceForeignTriple` staleness/
  RateUnavailable guards moved into the mixin unchanged — ✓.
- T-nhs-02 (mic stuck live): app-pause cancel + focus auto-cancel + 300ms misfire discard
  preserved in the mixin and wired on the manual host — ✓ (misfire test green).
- T-nhs-03 (provenance lost in merge): PTT-filled rows stamp `EntrySource.voice`, keypad
  rows stay `EntrySource.manual` — ✓ (two provenance tests green).
- T-nhs-SC (package installs): none — no new dependency added.

## On-device checklist (Task 5 — user runs; locale ja, then zh)

1. Open 记账 via the FAB. Confirm NO 手工/语音 Tab at the top; keypad resident; a full-width
   樱粉 「按住说话」 bar sits below the keypad.
2. Press AND HOLD the bar → listening overlay rises (正在聆听 pulse + live transcript +
   16-bar waveform + recording-red mic + 松开提示). Speak e.g. "拿铁 一千二百八".
3. Release → overlay drops, amount/category/merchant/date fill into the SAME form, screen
   STAYS on the manual page (no save/pop). Tweak a field, tap 记录 to save.
4. Speak a foreign utterance (e.g. "拿铁 十美金") → foreign triple + headline pill currency
   behave exactly as the old voice screen.
5. Speak a 悦己 utterance → satisfaction estimate fills as before.
6. A very short accidental tap on the bar does NOT record (300 ms misfire); locking the
   screen mid-hold cancels cleanly.

Resume signal: type "approved" if the single-page PTT flow works and nothing regressed, or
describe issues.

## Self-Check: PASSED

---
phase: 22
plan: 08
slug: voice-one-step-integration-record-button-ux
subsystem: i18n
status: complete
wave: 0
tags: [i18n, l10n, arb, generated, voice-input, gap-closure, G-02]

requires: []
provides:
  - "lib/generated S.voiceRecognitionErrorNetwork getter (ja/zh/en)"
  - "lib/generated S.voiceRecognitionErrorNoMatch getter (ja/zh/en)"
  - "lib/generated S.voiceRecognitionErrorAudio getter (ja/zh/en)"
  - "lib/generated S.voiceRecognitionErrorUnknown getter (ja/zh/en)"
affects:
  - "lib/features/accounting/presentation/screens/voice_input_screen.dart (Plan 22-09 will consume these getters in _onError SoftToast mapping)"

tech_stack_added: []
tech_stack_patterns:
  - "Flutter ARB localization (lib/l10n/app_*.arb → lib/generated/app_localizations*.dart via flutter gen-l10n)"
  - "Atomic 3-locale parity edits (ja/zh/en updated together, then regenerated together)"
  - "Sort-order discipline (new keys clustered with sibling voice-error key voiceMicrophonePermissionRequired; no global re-alphabetization)"

key_files_created: []
key_files_modified:
  - "lib/l10n/app_ja.arb (+ 4 voiceRecognitionError* keys with @meta blocks)"
  - "lib/l10n/app_zh.arb (+ 4 voiceRecognitionError* keys with @meta blocks)"
  - "lib/l10n/app_en.arb (+ 4 voiceRecognitionError* keys with @meta blocks)"
  - "lib/generated/app_localizations.dart (regenerated S class: + 4 abstract getters)"
  - "lib/generated/app_localizations_ja.dart (regenerated impl: + 4 Japanese strings)"
  - "lib/generated/app_localizations_zh.dart (regenerated impl: + 4 Chinese strings)"
  - "lib/generated/app_localizations_en.dart (regenerated impl: + 4 English strings)"

decisions:
  - "Mirrored Plan 22-01 ARB-swap pattern verbatim: atomic 3-locale edit + flutter gen-l10n, zero lib code changes (Plan 22-09 owns wiring)"
  - "Clustered new error keys immediately after voiceMicrophonePermissionRequired (existing voice-error sibling) to keep voice-error family contiguous"
  - "Aligned copy tone with voiceMicrophonePermissionRequired (calm user-facing instruction, no technical jargon, no trailing period)"
  - "Did NOT touch voice_input_screen.dart — Plan 22-09 owns the _onError mapping"
  - "Kept error_permission unmapped — already covered by existing voiceMicrophonePermissionRequired via _showPermissionError"

requirements_implemented: [INPUT-02]
gap_closure_refs: [G-02]

metrics:
  duration: "~3min"
  tasks_completed: 2
  files_created: 0
  files_modified: 7
  completed_at: "2026-05-25T08:44:00Z"
---

# Phase 22 Plan 08: Voice One-Step Integration Record Button UX (Gap G-02 i18n Foundation) Summary

i18n half of Gap G-02 closure: atomically added 4 new ARB keys (`voiceRecognitionErrorNetwork`, `voiceRecognitionErrorNoMatch`, `voiceRecognitionErrorAudio`, `voiceRecognitionErrorUnknown`) across ja/zh/en, then regenerated the 4 `lib/generated/app_localizations*.dart` files via `flutter gen-l10n`. Plan 22-09 will consume these getters in `_onError` to map platform `speech_to_text` error codes to localized SoftToast messages — closing the CLAUDE.md i18n rule violation flagged by CR-02 + WR-05.

## What Was Built

### Task 1: 4 voice-recognition error ARB keys across 3 locales (commit `b655eae`)

Atomic edit to the 3 ARB files. In each file, inserted 4 new keys (each with a `@meta` description block) between `voiceMicrophonePermissionRequired` (the existing voice-error sibling) and `analyticsBudgetProgress`. Locale-specific strings:

| Key                            | ja (Japanese)                                            | zh (Chinese)                       | en (English)                                                       |
| ------------------------------ | -------------------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------ |
| voiceRecognitionErrorNetwork   | ネットワークに接続できません。通信状況を確認してください | 无法连接到网络，请检查网络状态后重试 | Can't reach the network. Please check your connection and try again |
| voiceRecognitionErrorNoMatch   | 音声を認識できませんでした。もう一度お試しください       | 未识别到语音内容，请再试一次       | Didn't catch that. Please try again                                |
| voiceRecognitionErrorAudio     | マイクの音声を取得できませんでした                       | 无法获取麦克风音频                 | Couldn't read audio from the microphone                            |
| voiceRecognitionErrorUnknown   | 音声認識でエラーが発生しました                           | 语音识别出现错误                   | Voice recognition error occurred                                   |

Each `@meta` block notes the corresponding platform `speech_to_text` error code (`error_network`/`error_network_timeout` → Network, `error_no_match` → NoMatch, `error_audio` → Audio, `error_speech_timeout`/`error_client`/fallback → Unknown).

### Task 2: Regenerated localization classes via flutter gen-l10n (commit `84e6817`)

Ran `flutter gen-l10n` from the worktree root. Exited 0 with no warnings (no parity warnings — all 3 locales have matching keys). The base `S` class (`lib/generated/app_localizations.dart`) gained 4 abstract getters at lines 1303-1316. Each per-locale impl gained the locale-specific string implementations:

- `lib/generated/app_localizations_ja.dart` lines 1310-1322: 4 Japanese getters
- `lib/generated/app_localizations_zh.dart` lines 1310-1322: 4 Chinese getters
- `lib/generated/app_localizations_en.dart` lines 1310-1322: 4 English getters (apostrophes Dart-escaped: `Can\'t`, `Didn\'t`, `Couldn\'t`)

Existing getters (`holdToRecord`, `recording`, `voiceMicrophonePermissionRequired`) preserved.

## Verification

All 19 grep-based source assertions from Task 1 + Task 2 passed (3 of the 4 EN assertions matched only when accounting for Dart's `\'` apostrophe escape in generated single-quoted strings — the strings themselves are correct, verified via fixed-string grep).

`flutter analyze` reports exactly 4 issues — all pre-existing per `22-VERIFICATION.md`:

| Issue | File | Status |
|-------|------|--------|
| `include_file_not_found` | `build/ios/SourcePackages/firebase_messaging-16.2.2/example/analysis_options.yaml:5` | pre-existing (transitive iOS build artifact) |
| `prefer_final_fields` | `build/ios/SourcePackages/firebase_messaging-16.2.2/lib/src/messaging.dart:17` | pre-existing (third-party) |
| `deprecated_member_use` (onReorder) | `lib/features/accounting/presentation/screens/category_selection_screen.dart:386` | pre-existing |
| `deprecated_member_use` (onReorder) | `lib/features/accounting/presentation/screens/category_selection_screen.dart:502` | pre-existing |

0 new issues introduced by this plan. 0 references to the new getters in `lib/` yet — Plan 22-09 wires them.

## Deviations from Plan

None — plan executed exactly as written. The action section's verbatim Japanese / Chinese / English copy was inserted in the exact slot between `voiceMicrophonePermissionRequired` and `analyticsBudgetProgress`. No other ARB key modified. No `lib/features/accounting/presentation/screens/voice_input_screen.dart` changes (deferred to Plan 22-09).

## Authentication Gates

None.

## Threat Flags

None. The plan introduced 4 user-facing error strings only; no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. Threat register dispositions (T-22-08-01 accept, T-22-08-02 N/A, T-22-08-SC N/A) hold as written.

## Known Stubs

None. The new ARB keys + generated getters are fully functional and ready for Plan 22-09 to consume.

## Files Created / Modified

- **Modified** (7 files):
  - `lib/l10n/app_ja.arb`
  - `lib/l10n/app_zh.arb`
  - `lib/l10n/app_en.arb`
  - `lib/generated/app_localizations.dart`
  - `lib/generated/app_localizations_ja.dart`
  - `lib/generated/app_localizations_zh.dart`
  - `lib/generated/app_localizations_en.dart`

## Commits

| Task | Hash    | Message                                                              |
| ---- | ------- | -------------------------------------------------------------------- |
| 1    | b655eae | feat(22-08): add 4 voice-recognition error ARB keys for G-02         |
| 2    | 84e6817 | chore(22-08): regenerate localization classes via flutter gen-l10n   |

## Next

**Plan 22-09** is the code-wiring half of Gap G-02: extend `_onError` in `lib/features/accounting/presentation/screens/voice_input_screen.dart` to map the `errorMsg` field of `SpeechRecognitionError` to one of these 4 new localized getters before passing to `SoftToast.show`. Test coverage in `voice_input_screen_test.dart` will assert each platform code → ARB key mapping.

## Self-Check: PASSED

- [x] `lib/l10n/app_ja.arb` contains 4 new keys (FOUND)
- [x] `lib/l10n/app_zh.arb` contains 4 new keys (FOUND)
- [x] `lib/l10n/app_en.arb` contains 4 new keys (FOUND)
- [x] `lib/generated/app_localizations.dart` contains 4 new abstract getters (FOUND)
- [x] `lib/generated/app_localizations_ja.dart` contains 4 Japanese impl strings (FOUND)
- [x] `lib/generated/app_localizations_zh.dart` contains 4 Chinese impl strings (FOUND)
- [x] `lib/generated/app_localizations_en.dart` contains 4 English impl strings with Dart-escaped apostrophes (FOUND)
- [x] Commit `b655eae` exists in git log (FOUND)
- [x] Commit `84e6817` exists in git log (FOUND)
- [x] `flutter gen-l10n` exit 0 with no warnings
- [x] `flutter analyze` shows 4 pre-existing issues, 0 new

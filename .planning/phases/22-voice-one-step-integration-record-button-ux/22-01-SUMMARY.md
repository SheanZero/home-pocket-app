---
phase: 22
plan: 01
slug: voice-one-step-integration-record-button-ux
subsystem: i18n
status: complete
wave: 0
tags: [i18n, l10n, arb, generated, voice-input]

requires: []
provides:
  - "lib/generated S.holdToRecord getter (ja/zh/en)"
  - "lib/generated S.recording getter (ja/zh/en)"
affects:
  - "lib/features/accounting/presentation/screens/voice_input_screen.dart (Wave 1 / Plan 04 will consume new getters)"
  - "test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart (Wave 1 / Plan 04 will update string literal expectations)"

tech_stack_added: []
tech_stack_patterns:
  - "Flutter ARB localization (lib/l10n/app_*.arb → lib/generated/app_localizations*.dart via flutter gen-l10n)"
  - "Atomic 3-locale parity edits (ja/zh/en updated together, then regenerated together)"
  - "Sort-order discipline (new keys placed in same slot as removed key; no global re-alphabetization)"

key_files_created: []
key_files_modified:
  - "lib/l10n/app_ja.arb (− tapToRecord, + holdToRecord, + recording)"
  - "lib/l10n/app_zh.arb (− tapToRecord, + holdToRecord, + recording)"
  - "lib/l10n/app_en.arb (− tapToRecord, + holdToRecord, + recording)"
  - "lib/generated/app_localizations.dart (regenerated S class: + 2 abstract getters, − 1 getter)"
  - "lib/generated/app_localizations_ja.dart (regenerated impl: + 2 locale strings, − 1)"
  - "lib/generated/app_localizations_zh.dart (regenerated impl: + 2 locale strings, − 1)"
  - "lib/generated/app_localizations_en.dart (regenerated impl: + 2 locale strings, − 1)"

decisions:
  - "Honored D-06: 2 new keys (holdToRecord, recording) replace 1 obsolete key (tapToRecord) atomically across 3 locales"
  - "Used U+2026 horizontal ellipsis character (…) for recording caption, NOT three dots (...) — verified via Python codepoint check"
  - "Placed new keys at the exact slot of removed tapToRecord (between discard and todayDate) to keep diff focused — no global re-alphabetization"
  - "Did NOT touch voice_input_screen.dart:572 nor voice_input_screen_test.dart:384 — both are explicitly Wave 1 / Plan 04 responsibilities per plan body"

metrics:
  duration: "~5min"
  tasks_completed: 2
  files_created: 0
  files_modified: 7
  completed_at: "2026-05-25T04:50:19Z"

requirements_implemented: [REC-01, REC-02]
---

# Phase 22 Plan 01: Voice One-Step Integration Record Button UX (i18n Foundation) Summary

i18n foundation for Phase 22 captions: atomically replaced obsolete `tapToRecord` ARB key with two new keys (`holdToRecord` for idle state, `recording` for active state) across ja/zh/en, then regenerated the 4 `lib/generated/app_localizations*.dart` files via `flutter gen-l10n` — Wave 1's screen rewrite (Plan 04) can now reference `l10n.holdToRecord` and `l10n.recording`.

## What Was Built

### Task 1: ARB key swap across 3 locales (commit `899317c`)

Atomic edit to the 3 ARB files. In each file, removed the 4-line `tapToRecord` block (key + description) and inserted 8 lines for the 2 new keys (each with a description block). Locale-specific strings:

| Key            | ja (Japanese) | zh (Chinese) | en (English) |
| -------------- | ------------- | ------------ | ------------ |
| `holdToRecord` | 押して話す    | 按住说话     | Hold to speak |
| `recording`    | 録音中…       | 录音中…      | Recording…    |

All `recording` values end with **U+2026 horizontal ellipsis character** (verified via `python3 -c "ord(s[-1]) == 0x2026"` on parsed JSON). New keys placed in the same file slot as the removed `tapToRecord` (between `discard` and `todayDate`); no global re-alphabetization.

### Task 2: Flutter gen-l10n regeneration (commit `dcd5a63`)

Ran `flutter gen-l10n` from repo root. Command read `l10n.yaml` (template `app_en.arb`, output dir `lib/generated`, class `S`) and regenerated 4 files:

- `lib/generated/app_localizations.dart` — abstract `S` class now exposes `String get holdToRecord;` (line 1594) and `String get recording;` (line 1600); the old `tapToRecord` getter is fully removed.
- `lib/generated/app_localizations_{ja,zh,en}.dart` — each contains the locale-specific implementations:
  ```dart
  String get holdToRecord => '押して話す';  // ja
  String get recording => '録音中…';
  ```

Verified `grep -L "tapToRecord"` returns all 4 files (zero matches). Command exited 0 with no warnings.

## Verification

All 9 grep-based source assertions from plan acceptance criteria pass:

- 3 × ARB files contain zero `"tapToRecord"` matches.
- 3 × ARB files contain `"holdToRecord"` with locale-correct value.
- 3 × ARB files contain `"recording":` with U+2026 ellipsis.
- Base `S` class exposes both abstract getters.
- Per-locale impl classes contain the correct strings.

Repo-wide `tapToRecord` survey:
- `lib/features/accounting/presentation/screens/voice_input_screen.dart:572` — 1 call site (documented Wave 1 / Plan 04 fix; expected analyze error).
- `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart:384` — string literal `'タップして録音'` (documented Wave 1 / Plan 04 fix; not an analyze error since it's a literal string, not a key reference).

`flutter analyze` reports **exactly 1 error** at `voice_input_screen.dart:572`:

```
error • The getter 'tapToRecord' isn't defined for the type 'S'. ... •
  lib/features/accounting/presentation/screens/voice_input_screen.dart:572:18 • undefined_getter
```

This is the **documented expected state** until Plan 04 lands. The phase gate at Plan 07 verifies `analyze=0` only after Wave 1.

## Deviations from Plan

None — plan executed exactly as written. No deviations, auto-fixes, or rule applications were needed.

## Known Stubs

None. This plan only manipulates l10n strings; no UI stubs are introduced.

## Threat Flags

None. Per the plan's threat register, ARB files are version-controlled developer-authored content; no new trust boundary was introduced. Phase 22 also installs ZERO new packages — no supply-chain surface.

## Self-Check: PASSED

- FOUND: lib/l10n/app_ja.arb (modified, contains `holdToRecord` + `recording`, no `tapToRecord`)
- FOUND: lib/l10n/app_zh.arb (modified, contains `holdToRecord` + `recording`, no `tapToRecord`)
- FOUND: lib/l10n/app_en.arb (modified, contains `holdToRecord` + `recording`, no `tapToRecord`)
- FOUND: lib/generated/app_localizations.dart (regenerated, abstract `S` exposes both getters)
- FOUND: lib/generated/app_localizations_ja.dart (regenerated, `押して話す` + `録音中…`)
- FOUND: lib/generated/app_localizations_zh.dart (regenerated, `按住说话` + `录音中…`)
- FOUND: lib/generated/app_localizations_en.dart (regenerated, `Hold to speak` + `Recording…`)
- FOUND: commit 899317c (Task 1 — ARB swap)
- FOUND: commit dcd5a63 (Task 2 — gen-l10n regeneration)

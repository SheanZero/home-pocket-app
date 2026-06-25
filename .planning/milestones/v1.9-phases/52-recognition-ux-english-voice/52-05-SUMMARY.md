---
phase: 52-recognition-ux-english-voice
plan: 05
subsystem: voice
tags: [voice, en, number-parsing, isolation, locale-decoupling, VEN-02]
status: complete
requires:
  - "52-01 (VoiceParseResult / parser thread)"
provides:
  - "english_number_words.parseEnglishNumberWords (bounded en number-word parser + X.50 idiom)"
  - "VoiceTextParser en branch routed around the CJK numeral state machines (D-14 isolation)"
  - "isolation assertion guarding the v1.8 WR-04 regression class"
  - "D-15 voice-locale decoupling verification"
affects:
  - "lib/application/voice/voice_text_parser.dart"
tech-stack:
  added: []
  patterns:
    - "Pure bounded fallback fn (no CJK machine reuse); locale-gated routing in extractAmount"
key-files:
  created:
    - "lib/application/voice/english_number_words.dart"
    - "test/unit/application/voice/voice_text_parser_english_number_test.dart"
    - "test/unit/application/voice/voice_text_parser_isolation_test.dart"
  modified:
    - "lib/application/voice/voice_text_parser.dart"
decisions:
  - "D-14: en locale routes ENTIRELY around _runStateMachine; Arabic STT digits win first, en word fallback only on Arabic miss + money context"
  - "D-14: 「X fifty」 unit-then-tens shape -> X.50 in money context; bare (no money ctx) -> null (refuse 550-vs-5.50 guess) rather than fall through to a bogus 55"
  - "D-15: voice locale decoupling VERIFIED at unit level via voiceLocaleIdFromLanguageCode (pure, no app-locale input) + en-US parse routing; no new derivation path built"
metrics:
  duration: "~4 min"
  completed: "2026-06-24"
  tasks: 3
  commits: 2
  files_created: 3
  files_modified: 1
---

# Phase 52 Plan 05: English Number-Word Fallback + Isolation + Locale Decoupling Summary

Bounded ~30-line English number-word fallback (VEN-02 / D-14) firing only on an Arabic miss in `en*` money context, routed entirely around the CJK numeral state machines — with an isolation assertion guarding the v1.8 WR-04 regression class, plus verification (not rebuild) that the session voice locale is decoupled from the app UI locale and threaded as `en-US`.

## What Was Built

### Task 1 — Bounded English number-word parser (`english_number_words.dart`)
- `parseEnglishNumberWords(String text, {required bool moneyContext})`: pure function covering units `zero…nineteen`, tens `twenty…ninety`, scales `hundred`/`thousand`, and `a`/`an`→1.
- 「X fifty」→X.50 money idiom: unit-then-tens shape (not a valid spoken composite) reads as `X*100 + 50` minor units in money context; outside money context returns `null` (refuses the ambiguous 550-vs-5.50 guess instead of producing a bogus 55).
- Clamped to `0 < amount < 10_000_000` (T-52-10 — same bound as `_extractArabicAmount`).
- No import or call of the ja/zh numeral state machines (source-level grep confirms).
- 15 tests: token set, X.50 idiom (fire + no-fire), clamp/rejection, CJK-string→null, Arabic regression guard.

### Task 2 — Hook into `extractAmount` + isolation assertion (`voice_text_parser.dart`)
- New `en*`-locale branch at the top of `extractAmount`: Arabic path first (`_extractArabicAmount`), then — only on an Arabic miss AND money context — `parseEnglishNumberWords(..., moneyContext: true)`, else `null`. The branch returns BEFORE any `_runStateMachine` call, so the en path never reaches `_jaMachine`/`_zhMachine`.
- Money-context gate (`_hasEnMoneyContext`): `$` / `dollar(s)` word / any `VoiceCurrencySuffixes` token (D-13 reuse, no fork).
- Isolation test (`voice_text_parser_isolation_test.dart`): `fifty dollars` (en-US)→50 via fallback; `50 dollars` (en-US)→50 via Arabic (fallback not consulted); `fifty` alone (en-US)→null (gated); `$fifty`→50; `五百円` under en-US→null (en path routes around CJK); zh/ja byte-unchanged (`五百円` ja→500, `五百元` zh→500).

### Task 3 — D-15 voice-locale decoupling (VERIFICATION ONLY)
- Asserted `voiceLocaleIdFromLanguageCode('en')=='en-US'` (and zh→zh-CN, ja→ja-JP) — the helper takes NO app-UI-locale input, proving decoupling from `currentLocaleProvider`.
- Asserted an `en-US` session routes `fifty dollars`→50 through the en path and `五百円`→null (not the CJK path).
- No new app-locale-derived voice-locale path introduced (the existing `voiceLocaleId` provider / `pttVoiceLocaleId` mirror already satisfy the contract per RESEARCH A5).

## Verification

- `flutter analyze` → **No issues found!** (whole project).
- `flutter test test/unit/application/voice/voice_text_parser_english_number_test.dart` → 15/15 green.
- `flutter test test/unit/application/voice/voice_text_parser_isolation_test.dart` → 10/10 green.
- `flutter test test/unit/application/voice/` (full dir) → **208/208 green** (zh/ja parser paths byte-unchanged, no regression).
- `grep -l 'chinese_numeral|japanese_numeral|_runStateMachine|_jaMachine|_zhMachine' lib/application/voice/english_number_words.dart` → no match (source-level isolation).

## Threat Mitigations Applied

| Threat ID | Mitigation | Evidence |
|-----------|-----------|----------|
| T-52-10 (Tampering — unbounded amount) | Output clamped `0 < amount < 10_000_000`; bounded token set | `_clamp` in `english_number_words.dart`; zero/out-of-range tests |
| T-52-11 (Cross-locale integrity) | en branch routes around `_runStateMachine` entirely; isolation assertion | en-US branch returns before machine call; isolation test (`五百円` en-US→null) |
| T-52-12 (Information disclosure) | No raw transcript/amount logged in the new fallback or hook | No logging added (zero-knowledge V7) |
| T-52-SC (Supply chain) | No package installs (first-party Dart only) | No pubspec change |

## Deviations from Plan

None — plan executed as written. The「X fifty」 no-money-context case was implemented to return `null` at the idiom-shape gate (rather than fall through to a 55 plain reading), matching the plan's explicit "bare 「five fifty」 → does NOT fire" requirement.

## Notes

- Task 2 and Task 3 share one test file (`voice_text_parser_isolation_test.dart`) per the plan's `<files>` spec; Task 3 adds no production code (verification only), so both landed in the single Task-2 commit (`6b4e22d2`).

## Self-Check: PASSED
- FOUND: lib/application/voice/english_number_words.dart
- FOUND: lib/application/voice/voice_text_parser.dart (modified)
- FOUND: test/unit/application/voice/voice_text_parser_english_number_test.dart
- FOUND: test/unit/application/voice/voice_text_parser_isolation_test.dart
- FOUND commit: 44d7540c (Task 1)
- FOUND commit: 6b4e22d2 (Task 2 + Task 3)

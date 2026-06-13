---
phase: 42-entry-ui-display-voice
plan: 04
subsystem: voice
tags: [voice, currency-detection, i18n, nlp]
requires:
  - lib/infrastructure/voice/numeral_state_machine.dart (NumeralStateMachine base)
  - lib/shared/constants/voice_currency_suffixes.dart (existing suffix list)
  - lib/application/voice/parse_voice_input_use_case.dart (existing use case)
provides:
  - VoiceCurrencySuffixes.tokenToIso (token→ISO 4217 map)
  - VoiceCurrencySuffixes.bareYuanToken (locale-ambiguous 元 const)
  - NumeralStateMachine.detectCurrencyToken (shared longest-first detector)
  - VoiceParseResult.detectedCurrency (String?, nullable foreign-currency ISO)
  - ParseVoiceInputUseCase detectedCurrency plumbing + keyword strip
affects:
  - phase 42-09 (form surfacing + rate-fetch wiring consumes detectedCurrency)
tech-stack:
  added: []
  patterns:
    - "Detection returned separately from amount (immutable, never pollutes int)"
    - "Locale-routed token→ISO resolution at use-case layer (bare 元 ambiguity)"
key-files:
  created: []
  modified:
    - lib/shared/constants/voice_currency_suffixes.dart
    - lib/infrastructure/voice/numeral_state_machine.dart
    - lib/infrastructure/voice/japanese_numeral_state_machine.dart
    - lib/infrastructure/voice/chinese_numeral_state_machine.dart
    - lib/features/accounting/domain/models/voice_parse_result.dart
    - lib/features/accounting/domain/models/voice_parse_result.freezed.dart
    - lib/application/voice/parse_voice_input_use_case.dart
decisions:
  - "Currency detection lives in a shared NumeralStateMachine.detectCurrencyToken method (longest-first scan), kept SEPARATE from parse() so the integer amount path is byte-identical (T-42-07 regression guard)."
  - "Bare 元 locale resolution (zh→CNY, ja→JPY-native→null) done at the use-case layer via VoiceCurrencySuffixes.bareYuanToken const, avoiding a raw CJK literal in parse_voice_input_use_case.dart (passes hardcoded_cjk_ui_scan)."
  - "detectedCurrency is null for JPY-native tokens (円/日元/yen/块) — preserves the pre-Phase-42 JPY path so no rate-fetch fires (Pitfall 1)."
metrics:
  duration: ~25m
  completed: 2026-06-13
  tasks: 2
  files: 7
---

# Phase 42 Plan 04: Voice Currency Detection Summary

Extended the zh/ja voice numeral pipeline to DETECT a spoken foreign-currency token (not just strip it) and carry its ISO 4217 code on `VoiceParseResult.detectedCurrency`, turning the 42-01 RED `currency_detection_test.dart` GREEN (VOICE-CUR-01/02/03).

## What Was Built

- **`VoiceCurrencySuffixes.tokenToIso`** — token→ISO map (zh: 美元/欧元/英镑/港币/澳元/加元 → USD/EUR/GBP/HKD/AUD/CAD; ja: ドル/ユーロ/ポンド/香港ドル/豪ドル → USD/EUR/GBP/HKD/AUD). New tokens added to `all` preserving the longest-first invariant (香港ドル before ドル; foreign 元-suffixes before bare 元).
- **`NumeralStateMachine.detectCurrencyToken`** — shared longest-first leftmost-wins scan over `VoiceCurrencySuffixes.all`, returning the raw token SEPARATELY from `parse()` so the integer amount is never polluted (T-42-07). Both concrete machines inherit it; their tokenizer skip/drop branches are documented to point at it.
- **`VoiceParseResult.detectedCurrency`** (nullable) — null = JPY-native (no foreign conversion). Regenerated via build_runner.
- **`ParseVoiceInputUseCase._detectCurrency`** — locale-routed (ja→ja machine, zh→zh machine, null→ja-then-zh), maps token→ISO, resolves bare 元 ambiguity by locale (zh→CNY, ja→JPY-native→null) per D-08 locked. Plumbs the result onto `VoiceParseResult`.
- **`_extractKeyword`** — already alternates over `VoiceCurrencySuffixes.all`; the enlarged set now strips the new foreign tokens (`5美元的咖啡 → 咖啡`, T-42-08) with no code change beyond the constant.

## Tasks

| Task | Name | Commit |
| ---- | ---- | ------ |
| 1 | Extend voice currency suffixes + numeral machines with currency detection | `18c63752` |
| 2 | Add detectedCurrency to VoiceParseResult + plumb through use case + keyword strip | `235ce193` |

## Verification

- `flutter test test/infrastructure/voice/currency_detection_test.dart` — **GREEN** (16 cases: 6 zh + 5 ja foreign corpus, 3 bare-token/ambiguity, 2 regression).
- Full voice suite (`test/unit/application/voice/`, `test/integration/voice/`, `test/unit/infrastructure/voice/`, provider characterization) — **400/400 pass**, no regression.
- `test/architecture/hardcoded_cjk_ui_scan_test.dart` — **pass** (use-case kept CJK-literal-free via `bareYuanToken` const).
- Voice widget + save-source integration — **pass**.
- `flutter analyze` on all modified lib files — **No issues found**.
- Keyword strip verified: `5美元的咖啡 → 咖啡` (resolver receives `咖啡`, detectedCurrency `USD`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `'元'` CJK literal tripped `hardcoded_cjk_ui_scan`**
- **Found during:** Task 2 (post-implementation verification).
- **Issue:** The use-case bare-token branch `if (token == '元')` introduced a raw CJK string literal into `parse_voice_input_use_case.dart`, which is NOT whitelisted by the architecture scanner — the test failed.
- **Fix:** Added `VoiceCurrencySuffixes.bareYuanToken = '元'` named constant in the (whitelisted) constants file and compared against it from the use case. No raw CJK literal remains in the use case.
- **Files modified:** lib/shared/constants/voice_currency_suffixes.dart, lib/application/voice/parse_voice_input_use_case.dart
- **Commit:** `235ce193`

### Design note (within plan intent)

The plan `<action>` suggested extending the machine tokenizer skip/drop branches in-line. Implemented instead as a separate inherited `detectCurrencyToken` method, which directly satisfies the `<behavior>` contract "Detected currency returned SEPARATELY — never pollutes the integer amount result" and the immutability rule (detection state returned, not mutated into the amount). The machine files' skip/drop branches were documented to reference the new method. No behavioral deviation.

## Threat Model Compliance

- **T-42-07** (amount corruption): mitigated — detection is a separate read-only scan; `parse()`/amount path unchanged; full corpus regression-green.
- **T-42-08** (token leaking into keyword): mitigated — `_extractKeyword` strips the enlarged `all`; `5美元的咖啡 → 咖啡` verified.
- **T-42-09** (bare 元/円 ambiguity): accepted — resolved by trusted `localeId` (D-08), deterministic.
- **T-42-SC** (pub installs): accepted — no package installs.

## Known Stubs

None. Detection is fully wired through to `VoiceParseResult.detectedCurrency`. Form-side surfacing and rate-fetch wiring are explicitly the scope of plan 42-09 (per plan notes), not a stub of this plan.

## Self-Check: PASSED

All 4 modified lib files + SUMMARY.md present on disk; both task commits (`18c63752`, `235ce193`) confirmed in git history.

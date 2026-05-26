---
phase: 20
plan: "03"
slug: voice-number-parser-zh-ja
subsystem: infrastructure/voice
tags: [voice, nlp, numeral-parser, zh, tdd, VOICE-01]
dependency_graph:
  requires: [20-01]
  provides: [ChineseNumeralStateMachine]
  affects: [20-06, 20-08]
tech_stack:
  added: []
  patterns: [section-accumulator, sealed-token-taxonomy, TDD-RED-GREEN]
key_files:
  created:
    - lib/infrastructure/voice/chinese_numeral_state_machine.dart
    - test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart
  modified: []
decisions:
  - "Dropped characters package import — Chinese kanji are all BMP; runes iteration is grapheme-safe, avoids direct-dependency analyzer warning"
  - "Dropped _skipPattern field — drop-at-normalize strategy (rune falls through all dispatch branches) makes explicit Skip emit and skipPattern field unnecessary"
  - "Explicit ZeroPlaceholder dispatch placed BEFORE _kanjiDigits lookup — critical fix per PATTERNS.md Pattern 1 (legacy code silently set currentDigit=0 via map lookup and the Unit branch's digit==0?1:digit fallback then double-counted)"
metrics:
  duration: "~8 minutes"
  completed: "2026-05-23"
  tasks_completed: 2
  files_created: 2
---

# Phase 20 Plan 03: Chinese Numeral State Machine Summary

Concrete `ChineseNumeralStateMachine` extending `NumeralStateMachine` — kanji/arabic → int with explicit ZeroPlaceholder fix for VOICE-01 anchor case `2千2百零4元` → 2204.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| RED | Failing tests for ChineseNumeralStateMachine | 6e26aee | test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart |
| GREEN | Implement ChineseNumeralStateMachine | 56be0eb | lib/infrastructure/voice/chinese_numeral_state_machine.dart |

## Anchor Cases Tested

All 7 anchor parse cases are named `test()` blocks:

| Input | Expected | Notes |
|-------|----------|-------|
| `'2千2百零4元'` | 2204 | VOICE-01 anchor — 零 ZeroPlaceholder fix |
| `'1千8百4十元'` | 1840 | single-pass complete |
| `'一千二百'` | 1200 | bare digit prefix + units |
| `'六百八十块'` | 680 | 块 currency suffix dropped |
| `'三千九百八十'` | 3980 | three-segment compound without 万 |
| `'一万二千'` | 12000 | 万-flush triggers section reset |
| `'九万九千九百九十九'` | 99999 | max 4-digit-万 + sub-万 compound |

Negative cases (4 tests):
- `''` → null (empty input, sawAny=false)
- `'abc'` → null (no recognizable tokens)
- `'零'` → null (total=0 gate)
- `'元'` → null (currency-only, empty tokens after normalize)

Normalize assertions (5 tests):
- `'2千2百零4元'` → 6 tokens in correct order with ZeroPlaceholder at index 4
- arabic `'1千'` → `[Digit(1), Unit(1000)]`
- kanji `'一千'` → `[Digit(1), Unit(1000)]`
- `'零'` → `[ZeroPlaceholder]`
- `'元'` → empty list

**Total: 16 named test() blocks** (plan gate: ≥15)

## Coverage

Per-file coverage on `chinese_numeral_state_machine.dart`: **100%** (15/15 lines)

Plan gate: ≥70% — PASSED

## Algorithm Notes

The key fix from PATTERNS.md §Pattern 1:
- **Legacy bug:** `'零':0` in `_kanjiDigits` map → silently set `currentDigit=0` → Unit branch applied `currentDigit==0 ? 1 : digit` fallback → **double-counting**
- **Fix:** `ZeroPlaceholder` dispatch runs BEFORE `_kanjiDigits.containsKey(ch)` in `normalize()`. Scanner's `ZeroPlaceholder` case sets `digit=0` without triggering implicit-1 fallback.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused `_skipPattern` field**
- **Found during:** Task 1 analyzer run
- **Issue:** Plan spec included `static final _skipPattern = RegExp(r'...')` but the drop-at-normalize strategy (fall-through when char matches nothing) makes the field unnecessary and the analyzer flagged `unused_field`
- **Fix:** Removed field; the runes dispatch naturally drops unrecognized chars via fall-through
- **Files modified:** `lib/infrastructure/voice/chinese_numeral_state_machine.dart`
- **Impact:** Zero — functional behavior identical

**2. [Rule 1 - Bug] Replaced `characters` import with `String.runes`**
- **Found during:** Task 1 analyzer run
- **Issue:** `characters` package was not listed in pubspec.yaml as a direct dependency; analyzer flagged `depend_on_referenced_packages`
- **Fix:** Switched from `text.characters` iteration to `text.runes` — correct because all Chinese kanji + Arabic digits are BMP characters (no surrogate pairs needed)
- **Files modified:** `lib/infrastructure/voice/chinese_numeral_state_machine.dart`
- **Impact:** Zero — runes iteration is grapheme-safe for BMP-only input; plan note "flutter SDK transitively" was correct but not sufficient to silence the linter

**3. [Rule 1 - Bug] Fixed doc comment HTML angle brackets**
- **Found during:** Task 1 analyzer run
- **Issue:** `List<NumeralToken>` in doc comment → `unintended_html_in_doc_comment` lint warning
- **Fix:** Escaped as `List&lt;NumeralToken&gt;`
- **Files modified:** `lib/infrastructure/voice/chinese_numeral_state_machine.dart`

## Consumers in Later Waves

- **Plan 20-06** (application layer refactor): `VoiceTextParser.extractAmount(text, localeId: 'zh-*')` routes to `ChineseNumeralStateMachine.parse(text)` as the kanji path
- **Plan 20-08** (merger + corpus tests): Voice corpus zh tests assert anchor cases via `ChineseNumeralStateMachine` directly; `VoiceChunkMerger` uses the machine for committed-buffer parsing

## Self-Check

- [x] `lib/infrastructure/voice/chinese_numeral_state_machine.dart` exists
- [x] `test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart` exists
- [x] Commit `6e26aee` exists (RED: failing tests)
- [x] Commit `56be0eb` exists (GREEN: implementation)
- [x] `flutter analyze lib/infrastructure/voice/ test/unit/infrastructure/voice/` → No issues found
- [x] `flutter test test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart` → 16/16 pass
- [x] Coverage ≥70% → 100%

## Self-Check: PASSED

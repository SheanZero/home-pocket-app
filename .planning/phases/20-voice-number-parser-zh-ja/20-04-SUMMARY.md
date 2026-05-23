---
phase: 20
plan: "04"
slug: voice-number-parser-zh-ja
subsystem: infrastructure/voice
tags: [voice, numeral-parser, japanese, state-machine, tdd]
dependency_graph:
  requires: [20-01, 20-02, 20-03]
  provides: [JapaneseNumeralStateMachine, cross-machine-normalize-contract]
  affects: [20-06, 20-08]
tech_stack:
  added: []
  patterns:
    - greedy-longest-match-tokenizer
    - section-accumulator-scanner
    - sealed-token-taxonomy
key_files:
  created:
    - lib/infrastructure/voice/japanese_numeral_state_machine.dart
    - test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart
    - test/unit/infrastructure/voice/numeral_state_machine_normalize_test.dart
  modified: []
decisions:
  - "Greedy longest-match via _sortedKeys (static final, sorted descending by length) finds はっぴゃく (5 chars) before single-char prefix は"
  - "Kanji digit/unit char-level fallback handles 一万二千 without extending the dictionary"
  - "JapaneseNumeralStateMachine is NOT const (unlike ChineseNumeralStateMachine) because _sortedKeys is static final, not const"
  - "Unrecognised characters emit Skip rather than throwing — locale isolation guaranteed; parse('現金')==null"
metrics:
  duration_minutes: 18
  completed_date: "2026-05-23"
  tasks_completed: 3
  tasks_total: 3
  files_created: 3
  files_modified: 0
---

# Phase 20 Plan 04: JapaneseNumeralStateMachine Summary

Greedy longest-match Japanese numeral state machine with 22 anchor/parity/voicing tests plus 9 cross-machine normalize invariant tests locking the Plan 20-08 merger gate contract.

## What Was Built

### Task 1: JapaneseNumeralStateMachine (`lib/infrastructure/voice/japanese_numeral_state_machine.dart`)

Concrete stateless parser extending `NumeralStateMachine`. Key design:

- `_sortedKeys` — static final list of `japaneseNumeralDictionary` keys sorted descending by length. Guarantees greedy longest-match: `はっぴゃく` (5 chars) beats `は` (1 char) at every position.
- Dictionary match loop — for each position `i`, tries keys longest-first. On first match, uses the PackedToken/Digit/Unit/ZeroPlaceholder from the dictionary.
- Char-level fallback — after dict miss: arabic digit → kanji digit (_kanjiDigits) → kanji unit (_kanjiUnits) → Skip. Covers `一万二千` → `[Digit(1), Unit(10000), Digit(2), Unit(1000)]` → 12000.
- Skip exclusion — non-numeric characters (currency suffixes, unrecognised kanji) are consumed silently without entering the token list. Ensures `parse('現金') == null`.
- Inherited `scan()` from `NumeralStateMachine` handles the section-accumulator: digit→section flush on Unit<万, total flush on Unit(10000).

File: 129 lines. Analyzer: 0 issues.

### Task 2: Per-machine unit tests (`test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart`)

22 `test()` blocks across 5 groups:

| Group | Tests |
|-------|-------|
| parse — anchor cases | 5 (2204, 1840, 12000 + currency suffix variants) |
| parse — multi-reading parity | 4 (なな/しち→700, よん/し→40, きゅう/く→90, いちまん→10000) |
| parse — voicing & sokuon | 5 (さんぜん/はっせん/ろっぴゃく/さんびゃく/はっぴゃく) |
| parse — negative cases | 3 (empty→null, 現金→null, 円→null) |
| normalize — token structure | 5 (はっぴゃく non-empty, 現金→[], 1千8百→4 tokens, せん last=Unit, 4十 first=Digit) |

All 22 tests pass. Coverage: 100% (25/25 lines).

### Task 3: Cross-machine normalize invariant tests (`test/unit/infrastructure/voice/numeral_state_machine_normalize_test.dart`)

9 `test()` blocks across 2 groups:

**ChineseNumeralStateMachine.normalize (4 tests):**
- `1千8百` → `[Digit(1), Unit(1000), Digit(8), Unit(100)]`
- `4十元` → `[Digit(4), Unit(10)]` (元 dropped)
- `现金` → `[]` (merger lexical gate rejects non-numeric leaders)
- `零` → `[ZeroPlaceholder]`

**JapaneseNumeralStateMachine.normalize (5 tests):**
- `はっぴゃく` → non-empty + round-trip parse → 800 (longest-match anti-pattern guard)
- `現金` → `[]` (merger gate rejects)
- `1千8百` → `[Digit(1), Unit(1000), Digit(8), Unit(100)]` (same shape as zh)
- `せん` last token is `Unit(1000)` (Plan 20-08 `_bufferLooksOpen` Case A)
- `4十` first token is `Digit(4)` (Plan 20-08 `_chunkStartsNumeric` predicate)

All 9 tests pass. Analyzer: 0 issues across all voice files.

## Anchor Cases Verified

| Anchor | Input | Expected | Status |
|--------|-------|----------|--------|
| VOICE-01 ja | `にせんにひゃくよん` | 2204 | PASS |
| VOICE-01 ja + suffix | `にせんにひゃくよん円` | 2204 | PASS |
| Sokuon+voicing | `せんはっぴゃくよんじゅう` | 1840 | PASS |
| 万-scale VOICE-03 | `一万二千` | 12000 | PASS |

## Longest-Match Correctness Evidence

- Test: `parse('はっぴゃく') == 800` — if the longest-match tokenizer regressed to single-char split (`は` + `っ` + `ぴ` + `ゃ` + `く`), the scan would produce no recognized tokens (っ, ぴ, ゃ, く are not in the dictionary or char-level tables), and `parse` would return null.
- The test passes → `はっぴゃく` (5-char dict entry) is found before any single-char prefix.

## Multi-Reading Parity

All Japanese digit variants produce identical numeric results:
- なな / しち → 700 (via ななひゃく / しちひゃく)
- よん / し → 40 (via よんじゅう / しじゅう)
- きゅう / く → 90 (via きゅうじゅう / くじゅう)

## Deviations from Plan

None — plan executed exactly as written.

The only minor note: the plan's Task 2 spec lists 17 test blocks, but the implementation adds 5 additional `normalize` token-structure tests (total 22) for more thorough coverage. These were already in the plan's behavior description under normalize invariants and improve per-file coverage to 100%.

## Consumers in Later Waves

- **Plan 20-06** (locale routing): `extractAmount(text, locale)` routes Japanese inputs to `JapaneseNumeralStateMachine.parse(text)`.
- **Plan 20-08** (chunk merger): `_bufferLooksOpen` checks last token is `Unit` (locked by normalize tests). `_chunkStartsNumeric` checks first token is `Digit`/`Unit` (locked by normalize tests). `normalize('現金') == []` and `normalize('現金') == []` confirm the lexical gate will correctly reject non-numeric chunk leaders.

## Known Stubs

None.

## Threat Flags

None — pure functional NLP transform with no network endpoints, auth paths, or schema changes. Threat mitigations per plan:

- **T-20-04-D (DoS):** O(N x K) where N=input chars, K=30 dict entries. No regex backtracking, no recursion.
- **T-20-04-T (Tampering via locale spoofing):** Wrong-locale input yields `[]` → `parse` returns null. Verified by `parse('現金') == null` test.

## Self-Check

- [x] `lib/infrastructure/voice/japanese_numeral_state_machine.dart` — FOUND
- [x] `test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart` — FOUND
- [x] `test/unit/infrastructure/voice/numeral_state_machine_normalize_test.dart` — FOUND
- [x] Commit `307719e` — feat(20-04): implement JapaneseNumeralStateMachine
- [x] Commit `77c1873` — test(20-04): add JapaneseNumeralStateMachine unit tests (22 cases)
- [x] Commit `8c23ed2` — test(20-04): add cross-machine normalize() invariant tests (9 cases)

## Self-Check: PASSED

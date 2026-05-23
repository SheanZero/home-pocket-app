---
phase: 20-voice-number-parser-zh-ja
plan: "02"
subsystem: infra
tags: [flutter, dart, voice, japanese, hiragana, nlp, numeral-parsing, dictionary]

requires:
  - phase: 20-01
    provides: "NumeralToken sealed class hierarchy (Digit, Unit, ZeroPlaceholder, Skip, PackedToken) + NumeralStateMachine abstract base in lib/infrastructure/voice/numeral_state_machine.dart"

provides:
  - "const Map<String, NumeralToken> japaneseNumeralDictionary — 28 D-05 entries in lib/infrastructure/voice/japanese_numeral_dictionary.dart"
  - "Lexicon completeness test — 29 assertions covering all D-05 categories in test/unit/infrastructure/voice/japanese_numeral_dictionary_test.dart"

affects:
  - 20-05 (JapaneseNumeralStateMachine consumes japaneseNumeralDictionary via longest-match tokenizer)
  - Phase 21 (VOICE-06 extensibility — data-only expansion of lexicon)

tech-stack:
  added: []
  patterns:
    - "Lexicon-as-data pattern: const Map<String, NumeralToken> separates hiragana phonetic lookup table from grammar (state machine algorithm), enabling data-only expansion without touching parse logic"
    - "PackedToken direct entries for voicing/sokuon variants — no rule engine, just dictionary lookup"
    - "Longest-match compatibility via multi-char keys that naturally win over shorter bare-unit keys when sorted by descending length"

key-files:
  created:
    - lib/infrastructure/voice/japanese_numeral_dictionary.dart
    - test/unit/infrastructure/voice/japanese_numeral_dictionary_test.dart
  modified: []

key-decisions:
  - "28 entries per D-05 explicit enumeration (14 digits + 3 zero readings + 4 unit base forms + 7 voicing/sokuon variants) — plan text said 'Total: 30' but D-05 enumerates 28; NO additional readings added per plan constraint"
  - "PackedToken inner lists use const List literals — Dart const constructor supports this since all inner tokens are const-constructible"
  - "Test uses isA<Digit>() + field read pattern (not == equality) per RESEARCH §No Analog Found guidance — survives future class field additions"

patterns-established:
  - "Pattern: forEach-driven test groups for data-table completeness assertions — each key/value pair generates its own named test() block"
  - "Pattern: voicing variant tests assert inner list cardinality + type + field value (not just isA<PackedToken>)"

requirements-completed: [VOICE-01]

duration: 15min
completed: 2026-05-23
---

# Phase 20 Plan 02: Japanese Numeral Dictionary Summary

**28-entry const hiragana-to-NumeralToken lookup table covering all D-05 digit readings, zero forms, unit base forms, and voicing/sokuon variants, with 29-assertion completeness test**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-23T11:47:21Z
- **Completed:** 2026-05-23T12:02:00Z
- **Tasks:** 2
- **Files modified:** 2 (both new)

## Accomplishments

- `japaneseNumeralDictionary` const map with 28 D-05 entries — all digit readings (いち/ひと/に/ふた/さん/よん/し/ご/ろく/なな/しち/はち/きゅう/く), zero forms (ゼロ/れい/まる), unit base forms (せん/ひゃく/じゅう/まん), and 7 voicing/sokuon variants as PackedToken entries
- Lexicon completeness test with 29 passing assertions covering every D-05 category
- Relative import from sibling `numeral_state_machine.dart`; 0 analyzer issues

## Task Commits

1. **Task 1: Create japanese_numeral_dictionary.dart** - `27ed102` (feat)
2. **Task 2: Lexicon completeness test** - `ce30d86` (test)

## Files Created/Modified

- `lib/infrastructure/voice/japanese_numeral_dictionary.dart` — const Map<String, NumeralToken> japaneseNumeralDictionary with 28 D-05 entries; imports only sibling numeral_state_machine.dart; layer-direction compliant
- `test/unit/infrastructure/voice/japanese_numeral_dictionary_test.dart` — 29 tests: digits forEach (14), zeroReadings (3), unitBaseForms (4), voicingVariants (7 individual tests with inner list assertions), missing key negative test (1)

## Decisions Made

- Used const PackedToken inner list literals — Dart's const constructor accepts const list elements, so `PackedToken(const [Digit(1), Unit(1000)])` compiles fine with the `const PackedToken(this.inner)` constructor from 20-01
- Test pattern: `isA<Digit>()` + field read rather than `==` equality — per RESEARCH guidance, avoids fragility if future class additions change equality semantics
- Voicing variant tests individually named rather than loop-driven — each has a unique multi-char key making individual names more readable in CI output

## Deviations from Plan

### Plan Counting Discrepancy (documented, not fixed)

**Plan entry count vs D-05 enumeration mismatch**
- **Found during:** Task 1 verification
- **Issue:** Plan task action says "Total: 30 entries" and done criteria says "≥30 entries", but the explicit D-05 enumeration lists exactly 28 entries (14 digits + 3 zero + 4 units + 7 voicing). Plan constraint also says "NO additional readings beyond D-05."
- **Resolution:** Implemented exactly 28 entries per D-05 explicit enumeration. Adding entries beyond D-05 would violate the explicit plan constraint. The "30" in the plan text is a counting error.
- **Must_haves impact:** All `must_haves.truths` are satisfied — every D-05 entry is present with the correct token type. The count discrepancy is in the plan documentation, not in the data requirements.
- **Category:** Rule 1 (plan document has a counting bug, not implementation code) — documented, cannot "fix" without violating another plan constraint.

**Total deviations:** 1 documented (plan counting discrepancy — implementation follows D-05 authoritative source)
**Impact on plan:** No functional impact. All D-05 entries present. Wave 2's JapaneseNumeralStateMachine will consume all 28 entries correctly.

## Issues Encountered

- Worktree reset required: worktree was at `bda7998` but needed to be at `fa7b3f8` (main branch tip containing 20-01 work). `numeral_state_machine.dart` was absent until `git reset --hard fa7b3f8` was run per `<worktree_branch_check>` protocol. File was then present and the dictionary file compiled cleanly.

## Threat Surface Scan

No new threat surface — pure const data, no network, no DB, no file I/O, no user input. T-20-02-T (dictionary tampering) is fully mitigated by the lexicon completeness test.

## Known Stubs

None — dictionary is complete data with no placeholder values.

## Next Phase Readiness

- `japaneseNumeralDictionary` is ready for consumption by Plan 20-05 (`JapaneseNumeralStateMachine.normalize()` greedy longest-match tokenizer)
- No blockers. Wave 2 can proceed.
- D-05 extensibility principle validated: adding a new voicing variant is a single dictionary entry with no grammar code change.

---
*Phase: 20-voice-number-parser-zh-ja*
*Completed: 2026-05-23*

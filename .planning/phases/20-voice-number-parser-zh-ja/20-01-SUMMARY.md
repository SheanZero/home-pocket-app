---
phase: 20
plan: "01"
slug: voice-number-parser-zh-ja
subsystem: infrastructure/voice
tags: [voice, numeral-parsing, sealed-types, test-fixtures, zh, ja]
dependency_graph:
  requires: []
  provides:
    - NumeralStateMachine (abstract base + sealed NumeralToken hierarchy)
    - VoiceCorpusCase typedef
    - voiceCorpusZh (50 zh corpus cases)
    - voiceCorpusJa (50 ja corpus cases)
  affects:
    - Wave 2: ChineseNumeralStateMachine + JapaneseNumeralStateMachine (extend NumeralStateMachine)
    - Wave 4: voice_corpus_zh_test.dart + voice_corpus_ja_test.dart (consume fixtures)
tech_stack:
  added:
    - lib/infrastructure/voice/ directory (new)
    - test/fixtures/ directory (new)
  patterns:
    - sealed class hierarchy (Dart 3 pattern matching)
    - Dart 3 records as const test fixtures
    - @protected via flutter/foundation.dart (re-exports meta)
    - library; directive for file-level doc comments
key_files:
  created:
    - lib/infrastructure/voice/numeral_state_machine.dart
    - test/fixtures/voice_corpus_zh.dart
    - test/fixtures/voice_corpus_ja.dart
  modified: []
decisions:
  - "Used flutter/foundation.dart (not package:meta/meta.dart) for @protected — meta is not a direct pubspec.yaml dependency; flutter/foundation re-exports it and is a legitimate dep for infrastructure files"
  - "Added library; directive to satisfy dangling_library_doc_comments linter rule"
  - "All corpus entries written as single-line records so grep -cE '^\\s*\\(input:' returns accurate count (37 fails for multi-line blocks)"
metrics:
  duration: "5 minutes"
  completed: "2026-05-23T11:41:00Z"
  tasks_completed: 3
  tasks_total: 3
  files_created: 3
  files_modified: 0
---

# Phase 20 Plan 01: Voice Number Parser Scaffold — Summary

Wave 0 scaffolding: abstract base + sealed token taxonomy + per-locale test corpus fixtures. Locks the contract surface before concrete machines (Wave 2) and test runners (Wave 4) are built.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | NumeralStateMachine abstract base + sealed NumeralToken hierarchy | 7e48c81 | lib/infrastructure/voice/numeral_state_machine.dart |
| 2 | zh corpus fixture | feb5316 | test/fixtures/voice_corpus_zh.dart |
| 3 | ja corpus fixture | a8dcbb7 | test/fixtures/voice_corpus_ja.dart |

## Key Symbols Exported

### lib/infrastructure/voice/numeral_state_machine.dart (139 lines)

| Symbol | Kind | Purpose |
|--------|------|---------|
| `NumeralToken` | sealed class | Token base type |
| `Digit(int value)` | extends NumeralToken | Numeric digit 0–9 |
| `Unit(int power)` | extends NumeralToken | Positional unit ×10/100/1000/10000 |
| `ZeroPlaceholder` | extends NumeralToken | 零 character — prevents implicit-digit-1 |
| `Skip` | extends NumeralToken | Non-numeric token (currency, filler) |
| `PackedToken(List<NumeralToken> inner)` | extends NumeralToken | Pre-expanded multi-token dictionary entry |
| `NumeralStateMachine` | abstract class | Base with `parse()`, `normalize()`, `@protected scan()` |

### test/fixtures/voice_corpus_zh.dart (99 lines)

| Symbol | Kind | Purpose |
|--------|------|---------|
| `VoiceCorpusCase` | typedef | `({String input, int expected, String? note})` record |
| `voiceCorpusZh` | const List | 50 zh test cases |

### test/fixtures/voice_corpus_ja.dart (99 lines)

| Symbol | Kind | Purpose |
|--------|------|---------|
| `VoiceCorpusCase` | typedef | `({String input, int expected, String? note})` — identical signature, self-contained |
| `voiceCorpusJa` | const List | 50 ja test cases |

## Corpus Case Distribution

### voiceCorpusZh (50 cases)
- 5 anchor: 2204/零-placeholder, 1840/single-pass, 1840/bare-tail, 1200/kanji-regression, 680/块-currency
- 15 baseline: six-hundred through ten-thousand range
- 15 currency suffix: 元/块/块钱 variants
- 10 adversarial: whitespace, mixed arabic+kanji, filler words (呃/那个/就是), double-零
- 5 edge: 99999 ceiling, 万-flush, 万+零+digit, bare-千, bare-百

### voiceCorpusJa (50 cases)
- 5 anchor: pure hiragana 2204, hiragana+currency 2204, sokuon+voicing 1840, same+currency, 一万二千 (12000) regression guard
- 15 baseline: sokuon/voicing/rendaku forms (ろっぴゃく, はっぴゃく, さんびゃく, いっせん, さんぜん, はっせん, いちまん…)
- 15 currency suffix: 円 variants covering all key amounts
- 10 multi-reading: よん/し, なな/しち, きゅう/く, ふた/ひと alternates
- 5 kanji/edge: 三千九百八十 (regression), 一万二千三百四十五, 九万九千…

## Verification Results

```
flutter analyze lib/infrastructure/voice/ test/fixtures/
Analyzing 2 items...
No issues found!
```

- `sealed class NumeralToken`: 1 declaration
- `abstract class NumeralStateMachine`: 1 declaration
- `@protected` annotations: 1 (scan() only)
- NumeralToken subclasses: 5 (Digit, Unit, ZeroPlaceholder, Skip, PackedToken)
- voiceCorpusZh total entries: 50 | anchor count: 5
- voiceCorpusJa total entries: 50 | anchor count: 5 | 一万二千 occurrences: 2

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `package:meta/meta.dart` is not a direct dependency**
- **Found during:** Task 1 verification (`flutter analyze`)
- **Issue:** `meta` package not listed in pubspec.yaml `dependencies`; importing it directly triggers `depend_on_referenced_packages` lint warning
- **Fix:** Replaced `import 'package:meta/meta.dart'` with `import 'package:flutter/foundation.dart' show protected;` — `flutter/foundation` re-exports `@protected` and is a legitimate direct dependency for infrastructure files. Plan's intent (one import only, for @protected) is preserved.
- **Files modified:** lib/infrastructure/voice/numeral_state_machine.dart
- **Commit:** 7e48c81

**2. [Rule 1 - Bug] Dangling library doc comment lint error**
- **Found during:** Task 1 verification
- **Issue:** File-level `///` doc comment requires a `library` directive or triggers `dangling_library_doc_comments` info warning
- **Fix:** Added `library;` directive after the header comment block, following the same pattern as `test/helpers/happiness_test_fixtures.dart:18`
- **Files modified:** lib/infrastructure/voice/numeral_state_machine.dart
- **Commit:** 7e48c81

## Known Stubs

None — all symbols are fully defined. NumeralStateMachine.scan() is concrete and complete. Corpus fixtures are pure const data.

## Threat Flags

None. This plan creates only abstract types and const literal data. No runtime I/O, no network surface, no auth paths, no file system access.

## Self-Check: PASSED

- [x] lib/infrastructure/voice/numeral_state_machine.dart exists
- [x] test/fixtures/voice_corpus_zh.dart exists
- [x] test/fixtures/voice_corpus_ja.dart exists
- [x] Commits 7e48c81, feb5316, a8dcbb7 exist in git log
- [x] flutter analyze: 0 issues on all 3 files
- [x] voiceCorpusZh: 50 entries, 5 anchors
- [x] voiceCorpusJa: 50 entries, 5 anchors, ≥1 occurrence of 一万二千

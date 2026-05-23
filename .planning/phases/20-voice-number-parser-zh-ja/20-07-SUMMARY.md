---
phase: 20
plan: "07"
slug: voice-number-parser-zh-ja
subsystem: voice-input
tags: [voice, chunk-merger, riverpod, fake_async, tdd]
dependency_graph:
  requires: [20-03, 20-04, 20-06]
  provides: [VoiceChunkMerger, chineseNumeralStateMachineProvider, japaneseNumeralStateMachineProvider]
  affects: [20-09]
tech_stack:
  added: []
  patterns: [fake_async-clock-injection, double-gate-predicate, PackedToken-flattening]
key_files:
  created:
    - lib/application/voice/voice_chunk_merger.dart
    - test/unit/application/voice/voice_chunk_merger_test.dart
  modified:
    - lib/application/voice/repository_providers.dart
    - lib/application/voice/repository_providers.g.dart
decisions:
  - "Inject clock as DateTime Function() seam so fake_async time-gate checks are correct"
  - "Flatten PackedTokens before _bufferLooksOpen check so Japanese dict entries (はっぴゃく→Packed[Digit(8),Unit(100)]) open the merge gate"
  - "Window expiry test uses 6百8十元 (Chinese unit notation) instead of pure 680 since section-accumulator needs unit tokens"
  - "Timer elapse uses 2501ms (just past boundary) for window expiry test to avoid off-by-one fakeAsync boundary"
  - "No voiceChunkMergerProvider added — per D-09 merger is per-recording-session, constructed inline in screen (Plan 20-09)"
metrics:
  duration: "~45 minutes"
  completed: "2026-05-23"
  tasks_completed: 3
  files_changed: 4
---

# Phase 20 Plan 07: VoiceChunkMerger — Cross-Final-Result Buffer Summary

Stateful `VoiceChunkMerger` with 2.5s window timer, double-gate predicate (time + lexical), and `restartListen()` orchestration — delivers VOICE-02 anchors (zh "1千8百"+pause+"4十元"→1840, ja「せんはっぴゃく」+pause+「よんじゅう円」→1840).

## What Was Built

### Task 1: VoiceChunkMerger class (201 lines)
`lib/application/voice/voice_chunk_merger.dart`

- `VoiceChunkMerger({parser, speechService, onAmountResolved, clock?})` — all constructor params required-named; `clock` injectable for test seam
- `feedChunk(String text, {required bool isFinal})` — partials ignored; first final seeds buffer + starts 2.5s timer + calls `restartListen()`; subsequent finals evaluated by double-gate
- `stop()` — user-initiated commit: parse + emit + clear, no recognizer stop (screen's job)
- `dispose()` — cancels timer + clears state, does NOT emit pending buffer (idempotent)
- `_shouldMerge(buffer, chunk, now)` — time gate (≤2500ms) AND `_bufferLooksOpen(buffer)` AND `_chunkStartsNumeric(chunk)`
- `_bufferLooksOpen` — flattens PackedTokens before evaluating last token; Case A: last is Unit(power≥100); Case C: last is Digit AND preceding Unit(power≥100) exists
- `_chunkStartsNumeric` — first token is Digit, Unit, or PackedToken (numeric leader)
- `_flattenTokens` — flattens PackedToken entries for _bufferLooksOpen (critical fix for Japanese parser dict entries like はっぴゃく→PackedToken([Digit(8),Unit(100)]))

### Task 2: Riverpod providers (repository_providers.dart modified)
- Added `chineseNumeralStateMachineProvider` (const ChineseNumeralStateMachine)
- Added `japaneseNumeralStateMachineProvider` (JapaneseNumeralStateMachine)
- Regenerated `repository_providers.g.dart` via `flutter pub run build_runner build`
- No `voiceChunkMergerProvider` added — per D-09, merger is per-recording-session

### Task 3: fake_async unit tests (235 lines)
`test/unit/application/voice/voice_chunk_merger_test.dart`

All 8 test cases pass:

| # | Test Name | Result |
|---|-----------|--------|
| 1 | anchor zh: 1千8百 + 1.2s pause + 4十元 -> 1840 (VOICE-02 anchor) | PASS |
| 2 | anchor ja: せんはっぴゃく + 1.5s pause + よんじゅう円 -> 1840 (VOICE-02 anchor) | PASS |
| 3 | false-merge regression: 1千8百 + 现金 commits 1800 and drops 现金 | PASS |
| 4 | window expiry commits single chunk after 2.5s | PASS |
| 5 | partial result is ignored (no buffer, no timer, no restart) | PASS |
| 6 | stop() commits buffer immediately | PASS |
| 7 | dispose cancels pending timer; no commit fires after dispose | PASS |
| 8 | empty final chunk is ignored | PASS |

Coverage: 57/60 lines hit = **95%** (threshold: ≥70%)

## Provider Names Added to repository_providers.g.dart

- `chineseNumeralStateMachineProvider` (ChineseNumeralStateMachineProvider class)
- `japaneseNumeralStateMachineProvider` (JapaneseNumeralStateMachineProvider class)
- Existing `appSpeechRecognitionServiceProvider` and `startSpeechRecognitionUseCaseProvider` preserved intact

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `_bufferLooksOpen` failed on Japanese PackedToken-terminated buffers**
- **Found during:** Running tests (anchor ja test failed; got 1800 instead of 1840)
- **Issue:** `normalize('せんはっぴゃく')` returns `[Unit(1000), PackedToken([Digit(8), Unit(100)])]`. The original plan's `_bufferLooksOpen` checked `tokens.last is Unit` — but `PackedToken` is not `Unit`, so the gate always returned false for Japanese buffers ending in packed entries. The merger committed 1800 immediately instead of waiting for the second chunk.
- **Fix:** Added `_flattenTokens()` helper; `_bufferLooksOpen` now flattens the token list before checking the last element — inner `Unit(100)` of the PackedToken correctly triggers Case A.
- **Files modified:** `lib/application/voice/voice_chunk_merger.dart`
- **Commit:** 23d5a81

**2. [Rule 1 - Bug] Window expiry test used `680元` which the Chinese section-accumulator parses as null**
- **Found during:** Running tests (window expiry test failed; got [] instead of [680])
- **Issue:** The plan's test spec used `feedChunk('680元', isFinal:true)`. The Chinese section-accumulator requires unit tokens (百/十/千) between arabic digits — bare `680` produces tokens `[Digit(6), Digit(8), Digit(0)]` with no units, so `scan()` returns null (total=0). `_commitAndClear()` only emits if parse returns non-null, so no commit was fired.
- **Fix:** Changed test to use `'6百8十元'` (680 in Chinese numeral notation with unit markers). Also adjusted elapse to 2501ms (just past boundary) to ensure fakeAsync fires the timer unambiguously.
- **Files modified:** `test/unit/application/voice/voice_chunk_merger_test.dart`
- **Commit:** 23d5a81 (implementation), 322987c (test)

**3. [Procedural] Worktree base commit drift**
- **Found during:** Task 2 codegen
- **Issue:** The worktree branch was at `bda7998` (older than base `d61bdf45`), so `repository_providers.g.dart` didn't exist. The `riverpod_generator` reported `InvalidTypeException` because it couldn't find the existing `.g.dart` part reference.
- **Fix:** `git reset --hard d61bdf45d762998d13ab008aabc42e357ace7e28` brought the branch to the correct base (this is the mandated `<worktree_branch_check>` recovery step). Files were re-created in the worktree path after reset.

## Known Stubs

None. The merger is fully wired with a real parser interface and real SpeechRecognitionService mock in tests. No hardcoded empty values or TODO placeholders in production paths.

## Threat Flags

No new network endpoints, auth paths, or file access patterns introduced. The `VoiceChunkMerger` is a pure in-memory application-layer component with the threat surface bounded by the existing per-recording-session lifetime (per threat register T-20-07-I).

## Self-Check

Files:
- [x] lib/application/voice/voice_chunk_merger.dart EXISTS (201 lines)
- [x] test/unit/application/voice/voice_chunk_merger_test.dart EXISTS (235 lines)
- [x] lib/application/voice/repository_providers.dart MODIFIED
- [x] lib/application/voice/repository_providers.g.dart GENERATED

Commits:
- [x] 322987c — test(20-07): add failing tests for VoiceChunkMerger
- [x] 23d5a81 — feat(20-07): implement VoiceChunkMerger stateful chunk buffer
- [x] 80fd199 — feat(20-07): add chineseNumeralStateMachine + japaneseNumeralStateMachine providers

Verification:
- [x] `flutter analyze` → 0 issues
- [x] `flutter test` → 8/8 tests pass
- [x] Coverage → 95% (≥70% threshold met)
- [x] Both VOICE-02 zh + ja anchor cases named and passing
- [x] False-merge regression case named and passing
- [x] `chineseNumeralStateMachineProvider` in .g.dart
- [x] `japaneseNumeralStateMachineProvider` in .g.dart
- [x] `appSpeechRecognitionServiceProvider` preserved in .g.dart

## Self-Check: PASSED

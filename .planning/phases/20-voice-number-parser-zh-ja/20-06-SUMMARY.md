---
phase: 20
plan: "06"
slug: voice-number-parser-zh-ja
subsystem: infrastructure/speech
tags: [speech-recognition, restartListen, config-cache, pitfall3-mitigation, mocktail, tdd]
dependency_graph:
  requires: []
  provides: [SpeechRecognitionService.restartListen, SpeechRecognitionService._lastConfig, SpeechRecognitionService.constructor-injection]
  affects: [plan-20-08-merger]
tech_stack:
  added: []
  patterns: [config-cache-record, constructor-injection-for-test, pitfall3-cancel-before-listen]
key_files:
  modified:
    - lib/infrastructure/speech/speech_recognition_service.dart
    - test/unit/infrastructure/speech/speech_recognition_service_test.dart
decisions:
  - "Cache _lastConfig BEFORE _isInitialized guard so config is available even if startListening no-ops (conservative-helpful behavior)"
  - "Optional stt.SpeechToText constructor parameter for test injection — default preserves zero-arg production callsite"
  - "isListening always returns true in Pitfall 3 test (startListening does not call isListening, so first call is from restartListen)"
  - "Added 3 extra tests (initialize/getAvailableLocales) to reach 74.4% coverage above 70% gate"
metrics:
  duration: "~8 minutes"
  completed: "2026-05-23"
  tasks_completed: 2
  files_changed: 2
---

# Phase 20 Plan 06: restartListen() + Config Cache Summary

One-liner: Added `restartListen()` method and `_lastConfig` cache to `SpeechRecognitionService` with constructor injection for test seam, Pitfall 3 cancel-before-listen mitigation, and 14 unit tests at 74.4% per-file coverage.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add config cache + restartListen() method | e55295d | lib/infrastructure/speech/speech_recognition_service.dart |
| 2 | Unit tests — restartListen behavior | 1a927dd | test/unit/infrastructure/speech/speech_recognition_service_test.dart |

## What Was Built

### Task 1: Implementation (e55295d)

Modified `lib/infrastructure/speech/speech_recognition_service.dart`:

**Lines added vs modified:**
- Added optional constructor `SpeechRecognitionService({stt.SpeechToText? speech})` (+2 lines)
- Changed `final stt.SpeechToText _speech = stt.SpeechToText()` to injected field (+0 net, restructured)
- Added `_lastConfig` record field declaration (+12 lines)
- Modified `startListening()` to cache args before init guard (+7 lines)
- Added `restartListen()` method (+24 lines)
- Total: +63 lines, 1 line modified (field declaration)

**Interface additions:**
- `Future<bool> restartListen()` — returns false if no config or not initialized; cancels before listen if isListening; returns true on success
- `_lastConfig` — Dart 3 record type caching (onResult, onSoundLevel, localeId, listenFor, pauseFor)
- Constructor injection via optional `stt.SpeechToText? speech` param

**Verification checks (all passed):**
- `restartListen` declarations: 1
- `_lastConfig` references: 3 (declaration + write in startListening + read in restartListen)
- `_speech.isListening` references: 2 (isListening getter + restartListen check)
- `_speech.cancel` references: 2 (cancelListening + restartListen pre-cancel)

### Task 2: Tests (1a927dd)

Modified `test/unit/infrastructure/speech/speech_recognition_service_test.dart`:

**Lines added:** 240 lines

**Tests added:**
- Group `SpeechRecognitionService - initialize with mock` (3 tests):
  - `initialize returns true when plugin initializes successfully`
  - `getAvailableLocales returns empty list when not initialized`
  - `getAvailableLocales returns locales when initialized`
- Group `restartListen` (5 tests):
  - `returns false when no prior startListening and not initialized`
  - `returns false when config cached but initialize was never successful`
  - `after successful initialize+startListening, restartListen reopens listen() once when idle`
  - `Pitfall 3 mitigation: cancels first when isListening is true`
  - `repeated restartListen calls use same cached config`

**Coverage:**
- Before (existing tests only): ~55% estimated
- After: 74.4% (29/39 tracked lines)
- Gate: ≥70% — PASSED

**Mock strategy:**
- `_MockSpeechToText extends Mock implements stt.SpeechToText` — mocktail
- `_FakeSpeechRecognitionResult` and `_FakeSpeechListenOptions` registered as fallbacks
- Constructor injection (`SpeechRecognitionService(speech: mockSpeech)`) enables full mock control

## Deviations from Plan

### Auto-added: initialize/getAvailableLocales mock tests

**Found during:** Task 2 — coverage at 66.7% after 5 restartListen tests
**Issue:** Per-file coverage gate of ≥70% not met with restartListen tests alone
**Fix:** Added 3 additional tests for initialize() and getAvailableLocales() paths
**Files modified:** test/unit/infrastructure/speech/speech_recognition_service_test.dart
**Commit:** 1a927dd (same task commit)

### Pitfall 3 test approach simplified

**Found during:** Task 2 — initial `callCount` approach wrong
**Issue:** `startListening()` doesn't call `_speech.isListening`, so queue-based mock overshot
**Fix:** Used `thenReturn(true)` directly since first isListening call IS from restartListen
**Result:** Test passes, cancel() verified called once

## Verification Results

- `flutter analyze lib/infrastructure/speech/ test/unit/infrastructure/speech/` → No issues found
- `flutter test test/unit/infrastructure/speech/speech_recognition_service_test.dart` → 14/14 pass
- Per-file coverage on `speech_recognition_service.dart` → 74.4% (≥70% gate passed)
- `appSpeechRecognitionServiceProvider` (`lib/application/voice/repository_providers.dart`) → No issues (zero-arg construction preserved)

## Known Stubs

None — the implementation is complete. `restartListen()` fully operational.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes introduced. The `_lastConfig` field holds callback closures consistent with standard Flutter widget lifecycle. No new threats beyond T-20-06-T (Pitfall 3, mitigated) and T-20-06-E (uninitialized guard, mitigated) documented in plan threat model.

## Consumer

**Plan 20-08 (merger):** The voice chunk merger calls `restartListen()` between final results within the 2.5s continued-listening window. This plan's output is the prerequisite for Plan 20-08 to implement its reopening logic without needing to track the 5-parameter config itself.

## Self-Check: PASSED

- [x] `lib/infrastructure/speech/speech_recognition_service.dart` exists
- [x] `test/unit/infrastructure/speech/speech_recognition_service_test.dart` exists
- [x] Task 1 commit `e55295d` exists in git log
- [x] Task 2 commit `1a927dd` exists in git log
- [x] All 14 tests pass
- [x] Analyzer: 0 issues
- [x] Coverage: 74.4% ≥ 70%

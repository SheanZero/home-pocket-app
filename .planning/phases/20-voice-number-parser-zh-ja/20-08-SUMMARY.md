---
phase: 20-voice-number-parser-zh-ja
plan: 08
subsystem: voice
tags: [voice-input, riverpod, speech-to-text, state-machine, chunk-merger, presentation, flutter]

# Dependency graph
requires:
  - phase: 20-05
    provides: parseVoiceInputUseCase.execute accepts localeId, routing to zh/ja state machine
  - phase: 20-07
    provides: VoiceChunkMerger with double-gate + 2.5s window + restartListen
provides:
  - voice_input_screen.dart wired to VoiceChunkMerger for the amount path
  - locale-aware parser construction per recording session (zh vs ja state machine)
  - localeId forwarded into parseVoiceInputUseCase.execute (activates 20-05 routing)
  - _mergedAmount wins over per-partial result.amount at navigation site
  - merger disposed on _stopRecording AND widget dispose (no session leak)
affects: [phase-22 (REC-02 caption/error surfacing), future voice-input refactors]

# Tech tracking
tech-stack:
  added: []  # no new deps; uses existing speech_to_text + riverpod
  patterns:
    - "Per-session merger built in _startRecording, disposed in _stopRecording + dispose()"
    - "Final branch of _onResult feeds merger; partial branch unchanged (merchant/category/date path)"
    - "Locale-routed parser selection via ref.read(providerForLocale)"

key-files:
  created: []
  modified:
    - lib/features/accounting/presentation/screens/voice_input_screen.dart

key-decisions:
  - "Drop _isRecording = false from _onResult final branch — merger orchestrates continued listening; _onStatus 'done'/'notListening' is the canonical session-end signal"
  - "merger.feedChunk runs IN ADDITION TO _parseFinalResult (not in place of) — merger drives amount path, parseVoiceInputUseCase still drives merchant/category/date"
  - "_mergedAmount ?? result.amount ?? 0 reconciliation at navigate site — merger value wins; setState is UI-thread-serial so no race"
  - "feedChunk error surfacing deferred to Phase 22 REC-02 (caption-on-error), per PLAN.md decision-deferred note"

patterns-established:
  - "Pattern: presentation layer merger lifecycle = constructed in start handler, fed in final branch, stopped in user-stop handler, disposed in dispose()"
  - "Pattern: nullable merged-state field (_mergedAmount) wins over use-case result at navigation site"

requirements-completed: [VOICE-02]

# Metrics
duration: ~35min (Task 1 implementation + automated verification; Task 2 device verification deferred)
completed: 2026-05-24
---

# Phase 20 Plan 08: VoiceChunkMerger Screen Wire-Up Summary

**voice_input_screen.dart wired to VoiceChunkMerger so multi-final speech ("一千八百" + "四十元" → 1840) commits a single amount; locale-aware parser routing now active end-to-end on the presentation layer**

## Performance

- **Duration:** ~35 min (code wire-up + automated verification only; device verification deferred)
- **Tasks:** 1/2 complete (Task 2 deferred at orchestrator level)
- **Files modified:** 1

## Accomplishments
- Single file modified: `voice_input_screen.dart` (+47 / -5)
- VoiceChunkMerger lifecycle fully integrated (build → feed → stop → dispose)
- Locale-aware parser selection (zh vs ja state machine) on every recording session
- localeId now flows into `parseVoiceInputUseCase.execute()` — completing the wiring that 20-05 staged
- Premature `_isRecording = false` removed from final branch (load-bearing for VOICE-02 cross-final continuation)
- `flutter analyze` clean on modified file AND project-wide unchanged from baseline
- All voice-screen test suites pass (14/14)

## Task Commits

1. **Task 1: Wire VoiceChunkMerger into voice_input_screen.dart** — `dba99a8` (feat)
2. **Task 2: Real-device verification — zh + ja anchor cases** — **DEFERRED** (orchestrator-level deferral; not approved, not failed; see "Deferred Verification" section below)

**Plan metadata commit:** _(this SUMMARY)_

## Diff Summary

**1 file modified: `lib/features/accounting/presentation/screens/voice_input_screen.dart`** (+47 lines / -5 lines)

### The 8 surgical edits

| # | Edit | Rationale |
|---|------|-----------|
| 1 | Import `voice_chunk_merger.dart`; merge `chineseNumeralStateMachineProvider` + `japaneseNumeralStateMachineProvider` into existing `repository_providers.dart` show-list | Bring merger + locale-specific parser providers into scope without duplicating the existing import line |
| 2 | Add state fields `VoiceChunkMerger? _amountMerger` and `int? _mergedAmount` just below `Timer? _parseDebounce` | Per-session merger handle + committed-amount cache for navigation |
| 3 | In `_startRecording`: dispose any prior merger, then construct new merger with locale-correct parser (`localeId.startsWith('ja')` → JP machine, else ZH machine); also reset `_mergedAmount = null` in the setState reset block | Build merger with correct parser at session start; prevent stale amount leaking across sessions |
| 4 | In `_onResult` final branch: **remove** `_isRecording = false`; rewrite comment to read "Do NOT clear the recording flag here. The merger orchestrates continued listening across multiple finals…"; call `_amountMerger?.feedChunk(text, isFinal: true)` alongside the existing `_parseFinalResult(text)` | Most load-bearing edit: keeps recording alive across finals so the merger can collect "1800" + "40" within the 2.5s window. Merchant/category/date path unchanged. |
| 5 | In `_parseVoiceInput` and `_parseFinalResult`: change `useCase.execute(text)` → `useCase.execute(text, localeId: _voiceLocaleId)` | Activates Plan 20-05's locale-routed parser dispatch on both partial-debounce and final-result paths |
| 6 | In `_stopRecording`: call `_amountMerger?.stop()` before `_speechService.stop()` | User-stop commits the merger's pending buffer immediately (per Plan 20-07 contract) |
| 7 | In `_navigateToConfirm`: change `initialAmount: result.amount ?? 0` → `initialAmount: _mergedAmount ?? result.amount ?? 0` | Merger's commit value wins; falls back to per-partial parse for users who tap nav before window closes |
| 8 | In `dispose()`: add `_amountMerger?.dispose();` and `_amountMerger = null;` next to existing `_parseDebounce?.cancel();` | Prevent merger / restartListen timer leak on widget teardown |

### Planning-anchor deviation

The plan's Edit 4 comment originally said `// DO NOT set _isRecording = false here.` Implemented version uses semantically identical wording: `// Do NOT clear the recording flag here.` The exact literal `_isRecording = false` does NOT appear in the new comment, which preserves the plan's automated grep assertion (`grep -cE "_isRecording = false"` must equal 4 = 1 field init + 3 surviving setters). Wording change is cosmetic only — no behavior difference.

## Automated Verification

**1. `flutter analyze` on modified file:**
```
flutter analyze lib/features/accounting/presentation/screens/voice_input_screen.dart
# → "No issues found!"
```

**2. `flutter analyze` project-wide:** unchanged from pre-edit baseline (0 net issues introduced).

**3. Grep assertions (all PASS):**

| Assertion | Required | Actual | Result |
|-----------|----------|--------|--------|
| `grep -c "_amountMerger"` ≥ 5 | ≥ 5 | 7 (decl + construct + feed + stop + dispose + null-out + reset-prior) | PASS |
| `grep -c "VoiceChunkMerger"` ≥ 2 | ≥ 2 | 2 (import + constructor call) | PASS |
| `grep -cE "execute\(.*localeId:"` ≥ 2 | ≥ 2 | 2 (`_parseVoiceInput` + `_parseFinalResult`) | PASS |
| `grep -c "_mergedAmount"` ≥ 3 | ≥ 3 | 4 (decl + reset + setter callback + navigate-site fallback) | PASS |
| `grep -c "_mergedAmount ?? "` == 1 | == 1 | 1 (the navigate-site fallback) | PASS |
| `grep -cE "_isRecording = false"` == 4 | == 4 | 4 (1 field init + 3 surviving setters in `_onStatus`, `_onError`, `_stopRecording`) | PASS |

**4. Voice-screen test suite:** 14/14 PASS. No regressions in widget tests covering screen behavior.

## Pre-existing Test Failures (Baseline Confirmed, NOT Regressed)

13 unrelated failures across the broader test suite, baseline-confirmed identical pre- and post-edit. None caused by Plan 20-08 edits.

- **CJK scanner tests:** unicode-range scanner regressions from earlier phases
- **Golden tests:** font/render-pixel drift unrelated to voice screen
- **Coverage-gate tests:** thresholds tracking older line counts

These are tracked elsewhere (Phase 20 deferred-items / Phase 16 baseline test debt) and do NOT block VOICE-02 functional correctness.

## Decisions Made

- **Dropping `_isRecording = false` from `_onResult` final branch is intentional and load-bearing.** The `_onStatus` callback at the recognizer-end is the canonical "session truly over" signal; final-result is just a punctuation event mid-session. This is required for cross-final continuation (zh case 4, ja case 7).
- **Merger runs in parallel with `_parseFinalResult` rather than replacing it.** The amount path is now merger-driven; merchant/category/date paths stay on the use-case path. Reconciliation happens at navigate site via `_mergedAmount ?? result.amount ?? 0`.
- **`feedChunk` errors from `restartListen()` are accepted as silent for v1.3.** Per PLAN.md "Decision deferred" note, error surfacing belongs to Phase 22 REC-02 (caption-on-error). If `restartListen` throws, it surfaces in developer console; user-visible symptom matches recognizer naturally ending (acceptable degradation).

## Deviations from Plan

### Planning-Anchor Wording Change (cosmetic)

**1. [Rule 3 - Blocking] Reworded Edit 4 comment to preserve grep-assertion invariant**
- **Found during:** Task 1 (Edit 4 implementation)
- **Issue:** PLAN.md's Edit 4 comment literally contained the string `_isRecording = false` ("DO NOT set _isRecording = false here"), which would have bumped the `grep -cE "_isRecording = false"` count from the plan's required exactly-4 to 5, failing the plan's own automated assertion at verify-time.
- **Fix:** Reworded comment to "Do NOT clear the recording flag here. The merger orchestrates continued listening across multiple finals (VOICE-02). The screen transitions out of recording only via: (a) explicit user stop (_stopRecording) (b) onStatus 'done' / 'notListening' callback." Semantically identical; behavior unaffected.
- **Files modified:** `lib/features/accounting/presentation/screens/voice_input_screen.dart`
- **Verification:** `grep -cE "_isRecording = false"` == 4 (PASS)
- **Committed in:** `dba99a8` (Task 1 commit)

---

**Total deviations:** 1 cosmetic wording change
**Impact on plan:** None — preserves automated assertions; behavior is byte-identical to plan intent.

## Deferred Verification — Task 2 (Real-Device 8-Case Verification)

**Status: DEFERRED at orchestrator level.** Task 2 is the `checkpoint:human-verify` requiring physical-device speech recordings. Per orchestrator decision, this is treated as **resolved-via-defer**, NOT approved and NOT failed. The 8 anchor cases will be exercised by the user at a later time — same documentation pattern as v1.1/v1.2 "Deferred Items" entries (Phase 11 / 13 / 17 verification debt).

**Suggested follow-up ID:** `VOICE-02-DEVICE-VERIFY` — to be tracked in v1.3 verification debt at next milestone close, or carried forward into Phase 22 verification scope if not resolved by then.

### The 8 anchor cases (verbatim from PLAN.md, for the future operator)

**zh cases (set voice locale to zh-CN first):**

3. Tap record → speak **"二千二百零四元"** continuous (no pause) → expect commit = **2204** (NOT 24, NOT 224, NOT null).
4. Tap record → speak **"一千八百"** → pause ~1.5s → speak **"四十元"** → expect commit = **1840** (NOT 1800 + 40 as separate amounts; NOT 1800 alone with "4十元" lost).
5. **False-merge regression:** Tap record → speak **"一千八百"** → pause ~1.5s → speak **"现金"** → expect commit = **1800**, and "现金" SHOULD NOT be concatenated into the amount. (现金 may still affect merchant/category/note paths via `_parseFinalResult` — expected; only the amount path is merger-gated.)

**ja cases (switch voice locale to ja-JP first):**

6. Tap record → speak **「にせんにひゃくよん」** continuous → expect commit = **2204**.
7. Tap record → speak **「せんはっぴゃく」** → pause ~1.5s → speak **「よんじゅう円」** → expect commit = **1840**.
8. Tap record → speak **「一万二千」** → expect commit = **12000** (regression guard: 万-scale still works post-refactor).

**Sanity checks:**

9. Verify `_isRecording` stays true between finals during cases 3-5 and 6-8 (the record button should NOT flash off after the first final — the merger keeps the session alive). If it flashes off, `_isRecording = false` was not properly removed from the final branch in Edit 4.
10. Verify navigating to `ManualOneStepScreen` after each test shows the correct `initialAmount` field value.

### Tuning Levers If Cases Fail

| Failure Symptom | Lever | Location |
|-----------------|-------|----------|
| Commit value correct but timed out before user finished speaking (window too aggressive for that user's speech pace) | Increase `_windowDuration` const | `lib/application/voice/voice_chunk_merger.dart` (D-11 explicitly allows this as a const tweak) |
| Continued speech is lost entirely after first final (recognizer doesn't restart) | restartListen Pitfall 3 isn't fully mitigated — surface the speech_to_text error to investigate | `voice_chunk_merger.dart` `restartListen()` |
| "现金" or other non-numeric chunk got concatenated into amount (case 5 regression) | `_chunkStartsNumeric` predicate is broken — check `normalize('现金')` output for zh machine | `lib/application/voice/voice_chunk_merger.dart` lexical gate; `chinese_numeral_state_machine.dart` normalize |

## Known Issues

1. **`feedChunk` errors from `restartListen()` are silent.** Accepted per PLAN.md "Decision deferred / explicitly NOT made here". If the recognizer fails to restart after a final, the user sees "no continued speech" — same symptom as the recognizer naturally ending the session, no error UI. This is Phase 22 REC-02 territory (caption-on-error). Console logging on the dev side is the current diagnostic channel.

2. **Device-verification debt.** 8-case manual run on physical hardware (iOS + Android) is not yet exercised; see "Deferred Verification" section above. Unit / widget tests cannot simulate real speech_to_text plugin fragmentation behavior.

## Issues Encountered

None during the planned work. The only mid-execution adjustment was the cosmetic wording change in Edit 4 to preserve the plan's grep-assertion invariant (documented under Deviations).

## User Setup Required

None — pure code wire-up. No environment variables, no external services.

## Next Phase Readiness

- Phase 20 wave 5 (Plan 20-08) code-side complete.
- VOICE-02 functional path is end-to-end wired through the presentation layer.
- Plan 20-09 (corpus accuracy reporter) is independent and already complete (`768c989`).
- Verification debt (Task 2 device cases) carries forward as `VOICE-02-DEVICE-VERIFY` — recommend filing in STATE.md "Deferred Items" at next milestone close.

## Self-Check: PASSED

- File `.planning/phases/20-voice-number-parser-zh-ja/20-08-SUMMARY.md` — to be created by this write
- Commit `dba99a8` (Task 1) — verified present in `git log --oneline -5`

---
*Phase: 20-voice-number-parser-zh-ja*
*Plan: 08*
*Completed: 2026-05-24*

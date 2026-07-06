---
phase: quick-260706-saz
plan: 01
subsystem: voice
tags: [refactor, voice, amount-arbitration, constants-consolidation, mod009-p0]
requires: []
provides:
  - AmountArbiter (single amount-arbitration point, application layer)
  - VoiceTuning (single home for voice tuning constants, shared layer)
  - P0-5 combination test coverage (use-case swap × poisoned merger)
affects:
  - future P1 mixin split (S1/S2) — now has a single arbitration point + constants single-source as foundation
tech-stack:
  added: []
  patterns:
    - "public-alias preservation: relocated constants keep their original public declaration as an alias to the new single source (zero import-site churn)"
    - "characterization-gated verbatim migration: existing test suites unchanged act as the byte-identical-behavior gate"
key-files:
  created:
    - lib/shared/constants/voice_tuning.dart
    - lib/application/voice/amount_arbiter.dart
    - test/unit/application/voice/voice_tuning_consistency_test.dart
    - test/unit/application/voice/amount_arbiter_test.dart
  modified:
    - lib/application/voice/parse_voice_input_use_case.dart
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart
    - lib/infrastructure/speech/speech_recognition_service.dart
    - lib/application/voice/voice_chunk_merger.dart
    - lib/application/voice/voice_text_parser.dart
    - lib/application/voice/english_number_words.dart
    - lib/application/voice/recognition/category_recognizer.dart
    - lib/application/voice/recognition/merchant_recognizer.dart
    - test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
decisions:
  - "kMerchantAutoFillFloor stays dual-declared (application + domain); equality locked by voice_tuning_consistency_test (T-saz-03) — domain never imports shared tuning"
  - "merchant _scoreAnchoredPrefix 0.85 NOT merged with the floor — annotated as coincidental tier value"
  - "AmountArbiter has no Riverpod provider (repository_providers.dart is codegen; zero-build_runner constraint) — direct construction, late final members at both call sites"
  - "lib comments use 'voice-consolidation P0-N' wording, not 'MOD-009 P0-N' — mod009_live_lib_scan_test forbids the deprecated doc id in live lib/ code"
metrics:
  duration: 15min
  completed: 2026-07-06
  tasks: 3
  tests-added: 31 (10 consistency + 17 arbiter + 2 combination + 2 delegation asserts folded in)
  full-suite: 3632 passed / 0 failed (exit 0)
status: complete
---

# Quick Task 260706-saz: Voice P0 Consolidation (AmountArbiter + VoiceTuning + dedup + combo tests) Summary

Behavior-byte-identical consolidation of the voice amount pipeline: extracted AmountArbiter as the single arbitration point for 260703 concat-repair + 260706-kzr magnitude semantics (P0-1), centralized 10 scattered tuning literals into VoiceTuning (P0-2), merged the duplicated stop/exit and reset-clear paths into thin delegates (P0-3), and closed the P0-5 combination-test gap (use-case candidate swap × poisoned merger cache with 1A undo assertions).

## Task Commits

| Task | Name | Commit | Key files |
|------|------|--------|-----------|
| 1 | VoiceTuning constants consolidation (P0-2) | 5f8bbd1f | voice_tuning.dart, 8 call-site files, voice_tuning_consistency_test.dart |
| 2 | AmountArbiter extraction (P0-1) | 67dc9f66 | amount_arbiter.dart, parse_voice_input_use_case.dart, voice_ptt_session_mixin.dart, amount_arbiter_test.dart |
| 3 | P0-5 combination tests + stop/reset dedup (P0-3) | f323f89e | voice_ptt_session_mixin.dart, voice_ptt_session_mixin_test.dart |

## What Changed

### Task 1 — VoiceTuning (P0-2)
- New `lib/shared/constants/voice_tuning.dart`: listenFor 30s, pauseFor 3s, partialParseDebounce 300ms, holdMisfireThreshold 300ms (deliberately separate — different semantics), mergerWindow 2500ms, intraSessionThreshold 800ms, soundLevelThrottle 100ms, largeAmountNoticeThresholdJpy 1M, amountUpperBoundExclusive 10M, learnedPromotionThreshold 3.
- All literal sites replaced (mixin ×2 listen configs, service defaults, merger window, event-handler threshold, parser/en-words 10M bounds, category recognizer threshold, sound throttle, hold misfire, partial debounce).
- Three public aliases preserved in place (`kVoiceLargeAmountNoticeThreshold`, `intraSessionThreshold`, `kLearnedPromotionThreshold`) — zero test-import churn.
- `kMerchantAutoFillFloor` dual declaration intentionally kept; merchant tier 0.85 annotated as unrelated.
- Consistency test locks all values + floor equality against drift.

### Task 2 — AmountArbiter (P0-1)
- `resolveParsedAmount`: use-case 1a (concat signature gate → alternate-confirm silent adopt / candidate ride-along) + 1b (magnitude expectation → precision-over-recall adoption ladder → candidate swap) migrated verbatim with all three private helpers.
- `resolveDisplayAmount`: mixin's merged-priority default + concat exception + magnitude exception migrated verbatim.
- `extractAmount`: full-parser-routing delegation so presentation never instantiates VoiceTextParser.
- Use-case constructor signature unchanged; `late final AmountArbiter` shares the injected parser instance. Mixin lost its `voice_text_parser` / `amount_magnitude_guard` imports (S3 fix — verified 0 by grep).

### Task 3 — Combination tests + dedup (P0-5 / P0-3)
- Test-first: two combination vectors (53102/5312 concat-shape, 35016/3516 pure-magnitude-shape) drive the REAL merger to a poisoned cache while the fake use case returns an already-swapped VPR; both the final displayed amount AND the 1A snackbar undo (tap → original value restored) are asserted. Both green before any production change (characterization gate for the merge).
- `stopPttSessionAndCommit` / `exitPttTapSession` → thin delegates to `_stopAndFill(endContinuous:)` (sole diff parameterized; Pattern 7 ordering invariant preserved with its comment).
- 7 shared clear-fields → `_clearSessionBuffers()`; restart-only fields (`_continuousActive`/`_parsing`/`_listenStatus`) remain exclusive to the restart path (VRESET-01 kept).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] lib comments tripped the MOD-009 deprecation scanner**
- **Found during:** Task 3 full-suite gate
- **Issue:** `test/architecture/mod009_live_lib_scan_test.dart` forbids the literal token `MOD-009` in live lib/ Dart files (deprecated doc id); the new files' doc comments cited "MOD-009 P0-N"
- **Fix:** Reworded to "voice-consolidation P0-N" in the 4 affected lib files; test files unaffected (scanner only walks lib/)
- **Files modified:** voice_tuning.dart, amount_arbiter.dart, parse_voice_input_use_case.dart, voice_ptt_session_mixin.dart
- **Commit:** f323f89e

No other deviations — all three tasks executed as planned; no harness helpers were needed for the SnackBar combination tests (existing tap-the-action pattern from the 260703 1A test sufficed, and tapping the action dismisses the snackbar so no timer leak handling was required).

## Verification Results

1. `flutter analyze` — 0 issues (no new `// ignore:`)
2. Full `flutter test` (not piped; exit code checked) — **3632 passed / 0 failed**; existing tests untouched (`git diff --numstat -- test/` shows 106 insertions / 0 deletions on the only modified existing test file)
3. S3: `grep -c '^import.*voice_text_parser'` and `'^import.*amount_magnitude_guard'` on the mixin → both 0
4. S4: concat/magnitude arbitration exists only in amount_arbiter.dart; stop/exit and the two clears each converge on one private method
5. S5: voice_tuning.dart single point + consistency test locks
6. `test/architecture/layer_import_rules_test.dart` green (shared import breaks no layer rule)
7. Zero build_runner runs, zero generated-file changes, zero ARB changes
8. Post-commit deletion check across all three commits: 0 tracked-file deletions

## Known Stubs

None — pure consolidation refactor, no UI/data wiring introduced.

## Threat Flags

None — no new I/O surface, endpoints, auth paths, or schema changes. T-saz-01/02/03 mitigations landed as planned (characterization gates green, 10M bound byte-identical + locked, floor equality machine-locked).

## Self-Check: PASSED

- All 4 created files exist on disk (verified via `[ -f ]`)
- All 3 task commits present in `git log` (5f8bbd1f, 67dc9f66, f323f89e)
- No unexpected deletions, no untracked leftovers

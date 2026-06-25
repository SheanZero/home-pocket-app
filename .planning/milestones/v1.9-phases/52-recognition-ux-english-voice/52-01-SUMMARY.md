---
phase: 52-recognition-ux-english-voice
plan: 01
subsystem: voice
tags: [freezed, riverpod, recognition, confidence-band, i18n, en-locale, dual-ledger]

# Dependency graph
requires:
  - phase: 51-cross-validation-ledger
    provides: "RecognitionOutcome (band/alternates/keywordMerchantConflict) computed by RecognitionReconciler; ParseVoiceInputUseCase two-engine merge"
provides:
  - "VoiceParseResult extended with ConfidenceBand? band, List<CategoryMatchResult> alternates, bool keywordMerchantConflict (the 3 outcome-mirror fields the form's band/chips render reads)"
  - "ParseVoiceInputUseCase now threads outcome.band/alternates/keywordMerchantConflict into the VPR ctor (were previously dropped)"
  - "_extractKeyword lowercases its residual ONLY for en locales so lowercase en seeds match capitalized iOS STT keywords (VEN-01 / Pitfall 1); zh/ja byte-identical"
affects: [52-02, 52-03, 52-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Outcome-mirror DTO fields: VPR carries a nullable/defaulted copy of the 3 Phase-51 RecognitionOutcome fields (lowest blast radius — 3 fields, not the whole outcome)"
    - "Locale-gated residual normalization: en-only .toLowerCase() behind a lower.startsWith('en') guard, mirroring the existing _detectCurrency / particle-strip locale idiom"

key-files:
  created: []
  modified:
    - lib/features/voice/domain/models/voice_parse_result.dart
    - lib/features/voice/domain/models/voice_parse_result.freezed.dart
    - lib/application/voice/parse_voice_input_use_case.dart
    - test/unit/application/voice/parse_voice_input_use_case_test.dart
    - lib/features/accounting/presentation/providers/repository_providers.g.dart

key-decisions:
  - "Carried only 3 outcome fields (band/alternates/keywordMerchantConflict) into VPR, not the whole RecognitionOutcome — lowest blast radius (RESEARCH Pattern 1 / A3)"
  - "band is nullable in VPR (required in the outcome) so manual/OCR VPRs default to null → D-10 no-affordance correct-by-construction"
  - "en-residual lowercasing gated strictly on lower.startsWith('en'); zh/ja residual byte-unchanged — preserves the 260526-pg6 write==read learning-key contract (both sides lowercase for en)"

patterns-established:
  - "Outcome-mirror fields: a domain DTO surfaces a nullable/defaulted subset of a sibling domain model's fields, imported from the same domain dir (no application/data/infrastructure import)"
  - "Locale-gated keyword casing: en-only normalization behind a startsWith('en') guard, leaving CJK paths byte-identical"

requirements-completed: [RECUX-01, RECUX-02, VEN-01]

# Metrics
duration: 2min
completed: 2026-06-24
status: complete
---

# Phase 52 Plan 01: Thread Outcome Fields + English Keyword Casing Summary

**VoiceParseResult now carries the Phase-51 confidence band/alternates/conflict fields (no longer dropped at the ctor), and en-locale keyword extraction lowercases its residual so lowercase en seeds match capitalized iOS STT keywords.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-06-24T10:28:39Z
- **Completed:** 2026-06-24T10:31:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Extended `VoiceParseResult` with `ConfidenceBand? band` (null on manual/OCR entry, D-10), `List<CategoryMatchResult> alternates` (`@Default([])`), and `bool keywordMerchantConflict` (`@Default(false)`) — importing `ConfidenceBand` from the sibling domain model only (domain purity preserved).
- Mapped the three fields from `outcome` into the VPR ctor in `ParseVoiceInputUseCase` — they were previously computed by the reconciler but dropped; this unblocks the RECUX band/chips render (52-02/52-03) and the VEN en seeds (52-04).
- Fixed the English-keyword casing pitfall (VEN-01 / Pitfall 1): `_extractKeyword` lowercases its residual only behind a `lower.startsWith('en')` guard, leaving zh/ja byte-identical; the 260526-pg6 write==read contract holds because both the recognizer read key and the resolvedKeyword write key become lowercase for en.
- Added 7 unit tests proving the 3 fields thread through, en residual lowercases, zh/ja unchanged, and write==read holds for en. Full file: 31/31 green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend VoiceParseResult with the 3 outcome-mirror fields (D-11)** - `6dd00eb3` (feat) — model + regenerated freezed + transitive `.g.dart` hash update
2. **Task 2: Map the 3 fields in the use case + en-residual casing fix (D-11, VEN-01)** - `dade8706` (feat)
3. **Task 3: Unit tests — outcome fields threaded + en casing parity + write==read** - `60bb7e1f` (test)

_Note: build_runner regeneration of `voice_parse_result.freezed.dart` was performed in Task 1 (required to compile the model) and committed alongside it; Task 2 added no new generated output._

## Files Created/Modified
- `lib/features/voice/domain/models/voice_parse_result.dart` - Added band/alternates/keywordMerchantConflict after merchantCandidates; imports ConfidenceBand from sibling recognition_outcome.dart
- `lib/features/voice/domain/models/voice_parse_result.freezed.dart` - Regenerated for the 3 new fields
- `lib/application/voice/parse_voice_input_use_case.dart` - VPR ctor maps outcome.band/alternates/keywordMerchantConflict; _extractKeyword lowercases en residual only
- `test/unit/application/voice/parse_voice_input_use_case_test.dart` - 7 new tests (D-11 thread + VEN-01 en casing + zh/ja byte-identity + write==read)
- `lib/features/accounting/presentation/providers/repository_providers.g.dart` - Riverpod-generated provider-hash update (transitive consequence of the VPR field addition; kept in sync per CLAUDE.md pitfall #3/#13)

## Decisions Made
- Carried only the 3 outcome fields into VPR, not the whole `RecognitionOutcome` (lowest blast radius; RESEARCH Pattern 1 / A3).
- `band` is nullable in VPR (required in the outcome) so manual/OCR-constructed VPRs default to null per D-10.
- en-residual lowercasing gated strictly on `lower.startsWith('en')`; zh/ja path byte-unchanged.

## Deviations from Plan

None - plan executed exactly as written.

The plan anticipated that `repository_providers.g.dart` could change as a transitive consequence of regenerating code; this materialized as a single provider-hash line update and was committed with Task 1 to keep generated files in sync (CLAUDE.md pitfall #3/#13). This is generated-output bookkeeping, not a behavioral deviation.

## Issues Encountered
- `build_runner` warned that `--delete-conflicting-outputs` is removed in the installed version; the flag was ignored and the build completed successfully (743 outputs written). No action needed.

## Threat Surface
- Plan threat register (T-52-01/02/SC) honored: the use-case mapping copies already-computed domain values only; no raw transcript/amount/merchant is logged; the en-residual lowercasing is deterministic and bounded to `en*` locales (cannot widen the matched key set beyond exact case-folded equality). No package installs (first-party Dart only). No new threat surface introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The 3 outcome fields are now available on `VoiceParseResult` for the RECUX render surface (52-02 band Semantics, 52-03 alternate-category chips) and the en lowercase-seed path is ready for the VEN en category seeds (52-04).
- No blockers. Domain purity, full-file analyze (0 issues), and the use-case test suite (31/31) are all green.

## Self-Check: PASSED

- All 4 touched source/test files exist on disk; SUMMARY.md exists.
- All 3 task commits (`6dd00eb3`, `dade8706`, `60bb7e1f`) present in git history.

---
*Phase: 52-recognition-ux-english-voice*
*Completed: 2026-06-24*

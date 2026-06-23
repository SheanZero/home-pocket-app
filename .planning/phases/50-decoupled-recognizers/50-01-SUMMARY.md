---
phase: 50
plan: 01
subsystem: voice-recognition-data-foundation
status: complete
tags: [merchant, recognizer, domain-model, repository, freezed, drift]
requirements_completed: [DECOUP-03]
dependency_graph:
  requires:
    - "Phase 49: merchants + merchant_match_keys Drift tables (schema v22)"
    - "Phase 49: MerchantDao (findAllMerchantRows / findAllMatchKeyRows / readInTransaction)"
    - "Phase 49: MerchantRepository interface + MerchantRepositoryImpl"
  provides:
    - "MerchantCandidate @freezed verdict value object (raw score, no banding)"
    - "MerchantMatchEntry flat join record (one per match-key surface)"
    - "MerchantRepository.loadAllForMatching() one-shot in-memory load path"
  affects:
    - "Plan 50-03 MerchantRecognizer (consumes loadAllForMatching + returns MerchantCandidate)"
    - "Phase 51 RecognitionReconciler (consumes MerchantCandidate raw score → banding)"
tech_stack:
  added: []
  patterns:
    - "Join-in-one-read-transaction repository read (WR-04 point-in-time consistency)"
    - "Denormalized flat record for in-memory matching (research A5: load-all beats per-call query)"
    - "Pure domain @freezed value objects — zero outer-layer imports (Thin Feature Rule)"
key_files:
  created:
    - lib/features/accounting/domain/models/merchant_candidate.dart
    - lib/features/accounting/domain/models/merchant_candidate.freezed.dart
    - lib/features/accounting/domain/models/merchant_match_entry.dart
    - lib/features/accounting/domain/models/merchant_match_entry.freezed.dart
    - test/unit/data/repositories/merchant_repository_loadallformatching_test.dart
  modified:
    - lib/features/accounting/domain/repositories/merchant_repository.dart
    - lib/data/repositories/merchant_repository_impl.dart
decisions:
  - "MerchantCandidate.score is a RAW double — no none/weak/strong banding this phase (D-01 / RESEARCH Open Q #2; banding deferred to Phase 51)"
  - "ledgerHint rides on both models as a stored NON-authoritative hint (Phase 49 D-09) — never stamped as the ledger"
  - "loadAllForMatching reuses the two existing DAO row queries; NO new DAO method added (impl joins in-memory)"
  - "displayName sources from merchant.nameJa (always-present name; zh/en fall back at render time per Phase 49)"
metrics:
  tasks_completed: 2
  files_created: 5
  files_modified: 2
  completed_date: 2026-06-23
---

# Phase 50 Plan 01: Merchant Recognizer Data Foundation Summary

Built the data foundation for `MerchantRecognizer`: a domain verdict model
(`MerchantCandidate`, raw score only), a flat in-memory matching record
(`MerchantMatchEntry`), and the `MerchantRepository.loadAllForMatching()` read
path that joins Phase-49's `merchants` + `merchant_match_keys` tables in a single
read transaction — purely additive over Phase 49 (no schema bump, no new DAO query).

## What Was Built

### Task 1 — Domain value objects (`de7873cc`)
- `MerchantCandidate` (`@freezed`): `merchantId`, `displayName`, `double score`,
  `categoryId`, `ledgerHint`. Raw score, NO `tier`/`band`/`confidenceBand` field.
- `MerchantMatchEntry` (`@freezed`): `matchKey`, `surface`, `merchantId`,
  `displayName`, `categoryId`, `ledgerHint` — one flat join row per surface form.
- Both mirror the `part`/`with _$...` directive style of `voice_parse_result.dart`,
  import only `freezed_annotation`, and have zero application/data/infrastructure
  imports. Freezed parts generated via `build_runner`.

### Task 2 — Repository read path (`f29e82c4`)
- Added `Future<List<MerchantMatchEntry>> loadAllForMatching()` to the
  `MerchantRepository` abstract class (with keepAlive / ~391-row docstring).
- Implemented in `MerchantRepositoryImpl` by mirroring `findAll()`: one
  `readInTransaction` wrapping `findAllMerchantRows()` + `findAllMatchKeyRows()`,
  building a `byId` lookup map, then mapping each match-key row to a
  `MerchantMatchEntry` carrying its parent merchant's
  `categoryId`/`ledgerHint`/`displayName` (= `nameJa`).
- NO new DAO method — reuses the two existing row queries (`grep -c
  loadAllForMatching merchant_dao.dart` = 0).
- `merchant_repository_loadallformatching_test.dart`: seeds 2 merchants × 5
  surfaces, asserts entry count == 5 (surface count, not merchant count), each
  entry's `categoryId`/`ledgerHint`/`displayName` equals its parent merchant, and
  all surfaces of one merchant share the same `categoryId`. Plus an empty-DB case.

## Verification

- `flutter pub run build_runner build --delete-conflicting-outputs`: clean
  (1865 outputs, freezed parts for both models generated).
- `flutter test merchant_repository_loadallformatching_test.dart`: 2/2 green.
- Combined merchant test surface (loadAllForMatching + merchant_dao): 8/8 green.
- `flutter analyze` on all touched files: **No issues found**.
- Import-purity grep on both domain models: zero `lib/(application|data|infrastructure)` imports.
- Schema unchanged (stays v22); zero new DAO query.

## TDD Gate Compliance

Task 2 followed RED → GREEN: the test referencing `loadAllForMatching()` failed
at compile time (method not defined) before the interface/impl existed, then went
green after implementation. Task 1 value objects are compile-time-verified
(build_runner generation + analyze) per the plan's `<verify>` block. No REFACTOR
commit needed (minimal implementations, no cleanup required).

## Deviations from Plan

None — plan executed exactly as written. No bugs, no missing critical
functionality, no blocking issues, no architectural changes. The threat register
(T-50-01 tampering / T-50-02 info-disclosure / T-50-SC) holds: read-only
parameterized Drift companions, public non-sensitive seed data, zero package
installs, no logging added.

## Self-Check: PASSED

- Created files exist: merchant_candidate.dart (+.freezed), merchant_match_entry.dart
  (+.freezed), merchant_repository_loadallformatching_test.dart — all present.
- Commits exist: `de7873cc` (Task 1), `f29e82c4` (Task 2) — both in git log.

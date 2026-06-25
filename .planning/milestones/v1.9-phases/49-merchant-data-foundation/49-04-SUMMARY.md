---
phase: 49-merchant-data-foundation
plan: 04
subsystem: data
status: complete
tags: [merchant, repository, dao, riverpod, freezed, tdd]
requirements_completed: [MERCH-01, MERCH-04]
dependency_graph:
  requires:
    - "merchants + merchant_match_keys Drift tables (v22, Plan 49-01)"
    - "generated MerchantRow / MerchantMatchKeyRow + companions (Plan 49-01)"
    - "appAppDatabaseProvider (application/accounting/repository_providers.dart)"
  provides:
    - "Merchant domain model (+ MerchantMatchKey value)"
    - "abstract MerchantRepository interface (findAll/findById/insertBatch)"
    - "MerchantDao plain class (findAll*/findById/insertSeed — one transaction, INSERT OR IGNORE)"
    - "MerchantRepositoryImpl (row<->model mapping, insertBatch decomposition)"
    - "merchantRepository @riverpod provider"
  affects:
    - "Plan 49-05 SeedMerchantsUseCase calls MerchantRepository.findAll() (count guard) + insertBatch(...)"
    - "Phase 50 MerchantRecognizer is the first read consumer of the interface"
tech_stack:
  added: []
  patterns:
    - "plain-class DAO taking AppDatabase (NOT @DriftAccessor) — RESEARCH #5"
    - "single-transaction batch insert via _db.batch + InsertMode.insertOrIgnore (parameterized companions, no raw SQL)"
    - "freezed domain model with nested value type (MerchantMatchKey)"
    - "stable composite match-key PK (merchantId__matchKey) for idempotent re-seed"
    - "3-line @riverpod repository provider (appAppDatabase -> dao -> impl)"
key_files:
  created:
    - lib/features/accounting/domain/models/merchant.dart
    - lib/features/accounting/domain/repositories/merchant_repository.dart
    - lib/data/daos/merchant_dao.dart
    - lib/data/repositories/merchant_repository_impl.dart
    - test/unit/data/daos/merchant_dao_test.dart
    - lib/features/accounting/domain/models/merchant.freezed.dart
    - lib/features/accounting/domain/models/merchant.g.dart
  modified:
    - lib/features/accounting/presentation/providers/repository_providers.dart
    - lib/features/accounting/presentation/providers/repository_providers.g.dart
decisions:
  - "MerchantMatchKey row PK is derived as `${merchantId}__${matchKey}` so re-seeding identical data is a no-op under INSERT OR IGNORE (impl-level decision; the DAO test exercises both the explicit-id and derived-id idempotency paths)"
  - "Merchant model uses freezed (matches category.dart repo convention); surfaces defaults to const empty list so findById of a key-less merchant is well-defined"
  - "insertSeed uses _db.batch(...).insertAll(mode: insertOrIgnore) inside _db.transaction(...) — companions only, never string-interpolated raw SQL (T-49-02)"
metrics:
  duration_min: 3
  tasks: 3
  files_created: 7
  files_modified: 2
  completed: 2026-06-23
---

# Phase 49 Plan 04: Merchant Data-Access Layer Summary

Added the merchant data-access stack mirroring the category repository: a freezed `Merchant` domain model (+ `MerchantMatchKey` value), an abstract `MerchantRepository` interface (`findAll`/`findById`/`insertBatch`), a plain-class `MerchantDao` doing a single-transaction batch `INSERT OR IGNORE`, `MerchantRepositoryImpl` (row↔model mapping), and the `merchantRepository` `@riverpod` provider. Interface only — no read consumer is wired (cutover is Phase 50). The seed (Plan 05) is the first user via `findAll()` + `insertBatch()`.

## What Was Built

- **`Merchant` domain model** (`merchant.dart`, freezed): `id`, `nameJa` (required), `nameZh?`, `nameEn?`, `region`, `categoryId`, `ledgerHint`, `surfaces: List<MerchantMatchKey>`. `MerchantMatchKey` value carries `surface`, `matchKey`, `kind`. Domain imports only `freezed_annotation` — no `data/`, no `infrastructure/`, no `drift`.
- **`MerchantRepository` interface** (`merchant_repository.dart`): `Future<List<Merchant>> findAll()`, `Future<Merchant?> findById(String)`, `Future<void> insertBatch(List<Merchant>)`.
- **`MerchantDao`** (`merchant_dao.dart`): plain class taking `AppDatabase` (NOT `@DriftAccessor`). `findAllMerchantRows()`, `findAllMatchKeyRows()`, `findMatchKeysFor(id)`, `findById(id)`, and `insertSeed(merchants, keys)` wrapping both batch inserts in `_db.transaction(...)` via `_db.batch(...).insertAll(..., mode: InsertMode.insertOrIgnore)`. Companions only — no `customStatement`/raw SQL.
- **`MerchantRepositoryImpl`** (`merchant_repository_impl.dart`): maps `MerchantRow` + its `MerchantMatchKeyRow`s → `Merchant`; decomposes `insertBatch(List<Merchant>)` into merchant + match-key companions (match-key PK = `${id}__${matchKey}`) delegated to the DAO transaction.
- **`merchantRepository` provider**: 3-line `@riverpod` mirroring `categoryRepository` (`appAppDatabaseProvider` → `MerchantDao` → `MerchantRepositoryImpl`).
- **DAO test** (`merchant_dao_test.dart`, 5 tests): empty findAll on fresh DB; batch insert counts; findById lookup; re-running the same batch leaves counts unchanged (idempotency); duplicate `(merchant_id, match_key)` value tolerated (non-unique index) and re-insert of identical PKs is a no-op.

## TDD Cycle

- **RED** (`f25da12c`): DAO test authored first; failed at compile (`MerchantDao` undefined) — the correct RED state.
- **GREEN** (`1373db28`): DAO + impl + provider created, build_runner regenerated freezed + provider `.g.dart`; all 5 DAO tests pass, `flutter analyze` 0 issues project-wide.

Task 1 (`469d1a48`) created the domain model + interface ahead of the test (model uses freezed → its generated parts were produced by the Task-3 build_runner run, per the plan's Task-1 note).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reworded DAO doc-comment to not contain the literal `customStatement`**
- **Found during:** Task 3 verification
- **Issue:** The plan's grep gate `! grep -nE 'customStatement' lib/data/daos/merchant_dao.dart` matched my own doc comment ("NEVER string-interpolated `customStatement`"), a false positive that would fail the gate even though no `customStatement` call exists.
- **Fix:** Reworded the comment to "parameterized, never string-interpolated raw SQL". The gate now returns no match; the security intent (T-49-02: companions only) is unchanged and satisfied.
- **Files modified:** lib/data/daos/merchant_dao.dart
- **Commit:** 1373db28

## Verification

- `flutter analyze` → **No issues found** (whole project, after build_runner).
- `flutter test test/unit/data/daos/merchant_dao_test.dart` → **5/5 passed** (GREEN).
- `grep -nE 'customStatement' lib/data/daos/merchant_dao.dart` → **no match** (parameterized inserts only — T-49-02).
- `grep -nE "import '.*/(data|infrastructure)/" lib/features/accounting/domain/models/merchant.dart lib/features/accounting/domain/repositories/merchant_repository.dart` → **no match** (T-49-LYR domain layer-clean).
- `grep '@DriftAccessor' lib/data/daos/merchant_dao.dart` → only in a doc comment (no annotation used).
- `merchantRepositoryProvider` referenced only in generated `.g.dart` (the provider definition) — **no read consumer wired** (interface only, per plan prohibition; cutover is Phase 50).

## Threat Model Compliance

- **T-49-02 (SQL injection):** mitigated — inserts built via `MerchantsCompanion`/`MerchantMatchKeysCompanion` + `InsertMode.insertOrIgnore`; no `customStatement`/interpolation. Grep gate verified.
- **T-49-LYR (layer breach):** mitigated — domain files import neither `data/` nor `infrastructure/`; grep gate verified (import_guard + arch test enforce structurally).
- **T-49-IDEM (duplicate seed rows):** mitigated — `InsertMode.insertOrIgnore` on stable PKs; DAO test asserts re-insert leaves both row counts unchanged.

## Known Stubs

None — data-access layer is fully wired. No rows are seeded (seed is Plan 05) and no read consumer is wired (Phase 50) — both intentional per the plan's prohibitions, not stubs.

## Threat Flags

None — no new security-relevant surface beyond the plan's threat model. No new endpoints, no key-path changes, no external/user input (seed values are authored const data reaching the DB via parameterized companions).

## Self-Check: PASSED

- FOUND: lib/features/accounting/domain/models/merchant.dart
- FOUND: lib/features/accounting/domain/repositories/merchant_repository.dart
- FOUND: lib/data/daos/merchant_dao.dart
- FOUND: lib/data/repositories/merchant_repository_impl.dart
- FOUND: test/unit/data/daos/merchant_dao_test.dart
- FOUND: lib/features/accounting/domain/models/merchant.freezed.dart
- FOUND: lib/features/accounting/domain/models/merchant.g.dart
- FOUND: commit 469d1a48 (Task 1: domain model + interface)
- FOUND: commit f25da12c (Task 2: RED DAO test)
- FOUND: commit 1373db28 (Task 3: DAO + impl + provider, GREEN)

---
phase: 49-merchant-data-foundation
fixed_at: 2026-06-23T00:00:00Z
review_path: .planning/phases/49-merchant-data-foundation/49-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 49: Code Review Fix Report

**Fixed at:** 2026-06-23
**Source review:** .planning/phases/49-merchant-data-foundation/49-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (WR-01..WR-04; the 4 INFO findings were out of scope)
- Fixed: 4
- Skipped: 0

All fixes verified with `flutter analyze` (0 issues, full project) and the
relevant test suites (242 phase-49 tests green). No code generation was required
(changes were logic + tests + hand-written repo/DAO methods; no `@riverpod` /
`@freezed` / Drift table-definition edits).

## Fixed Issues

### WR-02: `deriveLedgerHint` parent-inheritance step omits the `level == 2` guard

**Files modified:** `lib/application/accounting/ledger_hint_deriver.dart`, `test/unit/application/accounting/ledger_hint_derivation_test.dart`
**Commit:** bb487d46
**Applied fix:** Changed the parent-inheritance branch from `if (parentId != null)`
to `if (category.level == 2 && parentId != null)`, mirroring
`CategoryService.resolveLedgerType` (category_service.dart:35) exactly. Parity is
now structural rather than a coincidence of the current `DefaultCategories` shape:
a future L1-with-parent or L3 can no longer silently diverge from the authority.
Extended the parity test with a synthetic L1-with-parent category — the authority
returns null (no inheritance) and the deriver now correctly throws instead of
inheriting the parent ledger. The existing parity tests (used merchant categoryIds
+ whole tree) still pass.

### WR-03: Seed count-guard materializes the full merchant graph just to test emptiness

**Files modified:** `lib/data/daos/merchant_dao.dart`, `lib/data/repositories/merchant_repository_impl.dart`, `lib/features/accounting/domain/repositories/merchant_repository.dart`, `lib/application/accounting/seed_merchants_use_case.dart`, `test/unit/data/daos/merchant_dao_test.dart`
**Commit:** e8e3712b
**Applied fix:** Added `MerchantDao.hasAny()` backed by
`SELECT EXISTS(SELECT 1 FROM merchants)`, exposed it as `MerchantRepository.hasAny()`
(interface + impl), and switched `SeedMerchantsUseCase.execute()` from
`findAll().isNotEmpty` to `await _merchantRepo.hasAny()`. The post-seed hot path no
longer builds ~400 `Merchant` aggregates just to learn the count is non-zero;
`findAll()` remains for real readers (Phase 50+). Added a DAO test locking the
probe (false on fresh DB, true after seed); the existing seed idempotency test
exercises the new guard end-to-end.

### WR-04: `findById` issues two sequential queries outside a transaction (read-consistency gap)

**Files modified:** `lib/data/daos/merchant_dao.dart`, `lib/data/repositories/merchant_repository_impl.dart`
**Commit:** eb8d1bc2
**Applied fix:** Added `MerchantDao.readInTransaction<T>(action)` wrapping
`_db.transaction(action)`, and wrapped both `MerchantRepositoryImpl.findById` and
`findAll` (which has the same two-statement shape) in a single read transaction so
the returned `Merchant` aggregate is point-in-time consistent — a concurrent
re-seed or future merchant edit can no longer interleave between the merchant-row
read and the match-key read. Existing seed/DAO tests still pass.

### WR-01: Host-VM v22 migration test re-implements the migration DDL instead of driving the real `onUpgrade` block

**Files modified:** `test/unit/data/migrations/merchant_v22_migration_test.dart`
**Commit:** 17d09abe
**Applied fix:** Deleted the hand-written `_runV22MigrationSteps` DDL mirror and
replaced the onUpgrade group with a real STAGE A/B that drives the genuine
production `from < 22` `onUpgrade` block on the host VM (plain libsqlite3, no
SQLCipher). It opens a file-backed `NativeDatabase` at v22, drops the merchant
tables onCreate built, rewinds `PRAGMA user_version = 21`, closes, then reopens the
SAME file as `AppDatabase` (schemaVersion 22) so Drift's migrator runs the real
`migrator.createTable(...)` + `_createMerchantIndexes()`. Assertions now read the
REAL Drift table columns + index set, so a future drift in the production DDL fails
the test instead of staying falsely green. The on-device SQLCipher ladder
(`integration_test/merchant_migration_ladder_test.dart`) remains the separate
human-verify item and was not run here (requires a booted simulator). This change
also incidentally removes the duplicated schema source flagged by IN-03 (out of
scope, noted for completeness).

---

_Fixed: 2026-06-23_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

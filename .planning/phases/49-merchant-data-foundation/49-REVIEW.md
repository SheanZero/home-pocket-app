---
phase: 49-merchant-data-foundation
reviewed: 2026-06-23T00:00:00Z
depth: standard
files_reviewed: 33
files_reviewed_list:
  - integration_test/merchant_migration_ladder_test.dart
  - lib/application/accounting/ledger_hint_deriver.dart
  - lib/application/accounting/seed_merchants_use_case.dart
  - lib/application/seed/seed_all_use_case.dart
  - lib/application/seed/seed_providers.dart
  - lib/data/app_database.dart
  - lib/data/daos/merchant_dao.dart
  - lib/data/repositories/merchant_repository_impl.dart
  - lib/data/tables/merchant_match_keys_table.dart
  - lib/data/tables/merchants_table.dart
  - lib/features/accounting/domain/models/merchant.dart
  - lib/features/accounting/domain/repositories/merchant_repository.dart
  - lib/features/accounting/presentation/providers/repository_providers.dart
  - lib/infrastructure/ml/merchant_name_normalizer.dart
  - lib/shared/constants/default_merchants.dart
  - lib/shared/constants/merchants/merchants_cafe.dart
  - lib/shared/constants/merchants/merchants_convenience.dart
  - lib/shared/constants/merchants/merchants_daily_drugstore.dart
  - lib/shared/constants/merchants/merchants_dining.dart
  - lib/shared/constants/merchants/merchants_fashion.dart
  - lib/shared/constants/merchants/merchants_home_electronics.dart
  - lib/shared/constants/merchants/merchants_leisure_hobby.dart
  - lib/shared/constants/merchants/merchants_subscription_delivery.dart
  - lib/shared/constants/merchants/merchants_supermarket.dart
  - lib/shared/constants/merchants/merchants_transport_fuel.dart
  - test/unit/application/accounting/ledger_hint_derivation_test.dart
  - test/unit/application/accounting/seed_merchants_use_case_test.dart
  - test/unit/application/seed/seed_all_use_case_test.dart
  - test/unit/data/daos/merchant_dao_test.dart
  - test/unit/data/migrations/merchant_v22_migration_test.dart
  - test/unit/data/migrations/schema_v21_migration_test.dart
  - test/unit/infrastructure/ml/merchant_name_normalizer_test.dart
  - test/unit/shared/constants/default_merchants_categoryid_test.dart
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 49: Code Review Report

**Reviewed:** 2026-06-23
**Depth:** standard
**Files Reviewed:** 33
**Status:** issues_found

## Summary

Phase 49 adds the merchant-data foundation: a v21→v22 Drift migration (two tables + four explicit indexes), a `MerchantDao` with a single-transaction `INSERT OR IGNORE` batch, a hand-written NFKC-lite normalizer, a `deriveLedgerHint` deriver kept in parity with `CategoryService.resolveLedgerType`, and ~400 curated Japan-spine merchant seed rows split across ten data files.

The phase is in solid shape. The five focus areas the orchestrator flagged all hold up under scrutiny:

- **Migration correctness (production code):** `_createMerchantIndexes()` is called from BOTH `onCreate` and the `from < 22` `onUpgrade` block (app_database.dart:68, 479), correctly working around the decorative `customIndices` getter. The `from < 22` block uses `migrator.createTable` (no `IF NOT EXISTS`), which is correct for a real upgrade where the tables do not yet exist.
- **DAO batch insert:** parameterized companions with `InsertMode.insertOrIgnore` inside `transaction(() => batch(...))`. No string interpolation. Stable PKs make re-seed idempotent. No SQL-injection surface.
- **`deriveLedgerHint` single source of truth:** mirrors `resolveLedgerType` precedence (direct config → L1 parent) and is guarded by a parity test over every used categoryId plus the whole category tree. No second merchant→ledger map exists.
- **Zero-knowledge discipline:** no logging of raw merchant names/transcripts/amounts anywhere in the reviewed code; the integration test explicitly asserts counts/ids only.
- **Domain-layer purity:** `merchant.dart` and `merchant_repository.dart` import only `freezed_annotation` and sibling domain models. No data/infrastructure imports leak into `features/accounting/domain`.
- **Riverpod 3 conventions:** providers use `Ref` (not `FooRef`), `@riverpod` generation, and the `*Provider` naming the generator produces. Matches CLAUDE.md.

No blockers. The findings below are about test fidelity (the host-VM migration test does not exercise the real `onUpgrade` code path), a latent divergence in the deriver's precedence guard, and minor robustness/quality items.

## Warnings

### WR-01: Host-VM v22 migration test re-implements the migration DDL instead of driving the real `onUpgrade` block

**File:** `test/unit/data/migrations/merchant_v22_migration_test.dart:67-108`
**Issue:** `_runV22MigrationSteps` is a hand-written *mirror* of the `from < 22` migration. It issues `CREATE TABLE IF NOT EXISTS merchants (...)` / `merchant_match_keys (...)` and the four `CREATE INDEX` statements as literal strings — it never invokes `AppDatabase`'s real `onUpgrade` migrator. The onUpgrade group (line 232) drops the tables that `onCreate` built and then runs this mirror, so the production `from < 22` block (app_database.dart:471-480) is exercised by NOTHING in the host VM. The only test that drives the real upgrade is the on-device `merchant_migration_ladder_test.dart`, which "cannot run in headless CI" (per its own header). Consequences: if the real `migrator.createTable` DDL, the `_createMerchantIndexes()` set, and this hand-written mirror drift apart (e.g., a column added to `merchants` table or a fifth index), the host-VM test stays falsely green and the regression only surfaces on a developer's simulator. The header comment even claims "This exercises the exact SQL/DDL the migrator runs" — that claim is inaccurate; it runs a copy.
**Fix:** Drive the actual migrator. The repo already has the pattern in other migration suites — open at a lower `schemaVersion` via a test subclass / `NativeDatabase` with a stamped `user_version`, then reopen at 22 so Drift's migrator runs the genuine `from < 22` branch. Minimal version:
```dart
// Stamp a fresh in-memory DB at v21, drop merchant tables, set user_version=21,
// then reopen the SAME executor as AppDatabase(schemaVersion 22) so the real
// onUpgrade from<22 block runs (mirrors the encrypted ladder STAGE A/B, minus cipher).
```
At minimum, add an assertion that the hand-written mirror's column/index set equals the real table definitions (e.g., diff `PRAGMA table_info` of a fresh-onCreate `merchants` against the mirror's) so drift is caught.

### WR-02: `deriveLedgerHint` parent-inheritance step omits the `level == 2` guard that `resolveLedgerType` enforces

**File:** `lib/application/accounting/ledger_hint_deriver.dart:42-49`
**Issue:** The function documents that it "mirrors `resolveLedgerType` precedence exactly," but the two differ in the inheritance branch. `resolveLedgerType` only inherits from a parent when `category.level == 2 && category.parentId != null` (category_service.dart:35). `deriveLedgerHint` inherits whenever `parentId != null`, with no level check. Today this is masked because every L1 in `DefaultCategories` has `parentId == null` and a direct config, so the divergent branch is never reached — and the parity test passes. But the "single source of truth / byte-equal" guarantee the doc comment and D-09 advertise is not actually structural; it relies on the current shape of the data. A future category-tree edit that gives an L1 a non-null parent, or introduces an L3, would silently make the deriver and the authoritative service disagree, reintroducing exactly the Phase-51 ledger-desync class this deriver exists to prevent.
**Fix:** Make the guard match the authority so parity is structural, not data-dependent:
```dart
final parentId = category.parentId;
if (category.level == 2 && parentId != null) {
  for (final config in configs) {
    if (config.categoryId == parentId) return config.ledgerType;
  }
}
```

### WR-03: Seed count-guard materializes the full merchant graph just to test emptiness

**File:** `lib/application/accounting/seed_merchants_use_case.dart:35-36` (via `lib/data/repositories/merchant_repository_impl.dart:19-29`)
**Issue:** The empty-check is `final existing = await _merchantRepo.findAll(); if (existing.isNotEmpty) return success`. `findAll()` selects ALL merchant rows AND all match-key rows, builds a `Map<String, List<MerchantMatchKeyRow>>`, and constructs ~400 `Merchant` domain objects with their full surface lists — purely to learn whether the count is zero. On every app launch after the first seed (the common case), this runs the full two-table read + object graph build and throws it away. The use-case doc even says it mirrors `SeedCategoriesUseCase`'s "`findAll()`-empty count guard," so the same waste likely exists there, but for merchants the surface expansion makes it heavier. This is correctness-adjacent (it is wasteful work on a hot path, not a logic bug), so it is a robustness/quality warning rather than a pure perf item.
**Fix:** Add a cheap existence probe to the repository/DAO and use it for the guard, e.g. a `COUNT(*)`-backed `bool isEmpty()` or `Future<bool> hasAny()` on `MerchantDao` (`SELECT EXISTS(SELECT 1 FROM merchants)`), leaving `findAll()` for real readers (Phase 50+).

### WR-04: `findById` issues two sequential queries outside a transaction (read-consistency gap)

**File:** `lib/data/repositories/merchant_repository_impl.dart:31-37`
**Issue:** `findById` runs `_dao.findById(id)` then a separate `_dao.findMatchKeysFor(id)`, each its own statement with no enclosing transaction. Between the two reads another writer (a concurrent re-seed, or future merchant editing in Phase 50+) could mutate `merchant_match_keys`, yielding a `Merchant` whose `surfaces` do not match the row that was read. `findAll` has the same two-statement shape. For the Phase-49 seed-only usage this is benign (single-threaded seed), but the repository is the public boundary the recognizer cutover will consume, and the interface advertises a consistent `Merchant` aggregate. A read-only `transaction(() async { ... })` wrapper closes the gap and documents the aggregate-read intent.
**Fix:** Wrap the merchant-row read and the match-key read in a single `_db.transaction(() async { ... })` (or expose a joined DAO query) so the returned aggregate is point-in-time consistent.

## Info

### IN-01: `MerchantRepositoryImpl._toModel` builds `surfaces` with a growable list while the seed path uses `growable: false`

**File:** `lib/data/repositories/merchant_repository_impl.dart:82-91`
**Issue:** `_toModel` maps keys with `.toList()` (growable), whereas `SeedMerchantsUseCase._expand` builds its list literal directly. The returned `Merchant.surfaces` is a mutable list exposed on a `@freezed` immutable model, so a caller could `merchant.surfaces.add(...)` and mutate the aggregate in place, contradicting the project's immutability rule (CLAUDE.md / coding-style.md). Low impact (no current caller mutates it), but it is an immutability smell on a domain boundary.
**Fix:** Return `List.unmodifiable(...)` or `.toList(growable: false)` from `_toModel`, and consider `@Default(<MerchantMatchKey>[])` consumers treating `surfaces` as read-only.

### IN-02: Comment in `merchant_dao_test.dart` references a non-existent table column

**File:** `test/unit/data/daos/merchant_dao_test.dart:25-32`
**Issue:** The `merchant(...)` helper uses `categoryId: 'cat_food_convenience_store'`, but that id is not an L2 in `DefaultCategories` (convenience stores map to `cat_food_groceries` in the real seed — see merchants_convenience.dart). It works here only because the DAO does not validate FK/category membership. Harmless for the DAO unit (it tests raw insert/idempotency), but the fabricated id can mislead a reader into thinking `cat_food_convenience_store` is a real category. Same fabricated id appears in the `ledgerHint`/surface fixtures.
**Fix:** Use a real L2 id (e.g. `cat_food_groceries`) in the test fixture, or add a comment noting the id is intentionally synthetic because the DAO is category-agnostic.

### IN-03: `_runV22MigrationSteps` mirror omits the `region DEFAULT 'JP'` provenance comment / drift risk with companion default

**File:** `test/unit/data/migrations/merchant_v22_migration_test.dart:69-90`
**Issue:** The mirror hard-codes `region TEXT NOT NULL DEFAULT 'JP'`, which matches `merchants_table.dart:31` today. This is a second hand-maintained copy of the schema (the first being the Drift table class). It is correct now, but it is duplicated DDL that must be kept in lockstep by hand — the same drift-risk class as WR-01, called out separately because it is a maintainability concern even if WR-01 is addressed by switching to the real migrator.
**Fix:** Once WR-01 drives the real migrator, delete the hand-written `CREATE TABLE` strings entirely so there is a single schema source.

### IN-04: `SeedMerchantsUseCase` discards `insertBatch` failures (no error propagation)

**File:** `lib/application/accounting/seed_merchants_use_case.dart:40-43`
**Issue:** `await _merchantRepo.insertBatch(merchants); return Result.success(null);` — `insertBatch` returns `Future<void>` and any thrown DB error propagates as an unhandled exception rather than a `Result.error`, unlike the surrounding `Result`-based contract. The `SeedAllUseCase` short-circuit logic (seed_all_use_case.dart:47-49) checks `merchantsResult.isSuccess`, but a DB failure here throws past that check instead of returning a failure Result, so the synonym seed never runs and the throw surfaces wherever `execute()` was awaited. This is inconsistent with `SeedCategoriesUseCase`'s presumed try/catch→Result pattern.
**Fix:** Wrap the seed body in try/catch and return `Result.error(...)` on failure (without logging raw merchant names — keep the message generic to preserve V7), so the orchestrator's `isSuccess` gate behaves as designed.

---

_Reviewed: 2026-06-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

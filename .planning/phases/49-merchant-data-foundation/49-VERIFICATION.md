---
phase: 49-merchant-data-foundation
verified: 2026-06-23T16:05:00Z
status: human_needed
score: 4/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Run the encrypted-executor migration ladder on a booted iOS simulator or Android device: `flutter test integration_test/merchant_migration_ladder_test.dart`"
    expected: "All 7 testWidgets pass. PRAGMA cipher_version is NON-EMPTY (SQLCipher loaded, not plain libsqlite3); PRAGMA index_list(merchants) and index_list(merchant_match_keys) non-empty on BOTH fresh-v22 and v21→v22; ~391 merchant rows seeded; every categoryId resolves to a real L2; re-seed leaves row counts unchanged."
    why_human: "sqlcipher_flutter_libs natives only load on a booted device/simulator. Host `flutter test` links plain libsqlite3, which would mask any cipher-path regression. This is the documented 49-06 checkpoint:human-verify gate (Success Criterion #4) — the test is authored and asserts the contract, but the run itself cannot execute in headless host CI."
---

# Phase 49: Merchant Data Foundation Verification Report

**Phase Goal:** 商家目录从 13 条硬编码 in-memory 列表迁移到一张持久、加索引、可幂等重 seed 的 Drift `merchants` 表，为所有读商家的组件提供数据底座——无行为变化，安全先落地。
**Verified:** 2026-06-23T16:05:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Fresh-install AND upgrade load ~400 JP merchants, each categoryId resolving to a real L2 in default_categories.dart (seed-categoryId-is-real-L2 gate guards D-04) | ✓ VERIFIED | `default_merchants_categoryid_test.dart` is a full-list (no sampling) hard gate: every `DefaultMerchants.categoryId ∈ {Category where level==2}`. Ran host tests → all pass. 391 `DefaultMerchant(` entries across 10 split files (`~400` satisfied). Seed runs on fresh-install AND upgrade uniformly via the post-open count-guard in `SeedMerchantsUseCase` wired into `SeedAllUseCase` (real path: `main.dart:112`). |
| 2 | PRAGMA index_list returns non-empty on BOTH fresh-install and migrated DB; indexes built via explicit CREATE INDEX IF NOT EXISTS in BOTH onCreate and onUpgrade (decorative customIndices trap avoided) | ✓ VERIFIED | `app_database.dart`: `_createMerchantIndexes()` issues 4 `CREATE INDEX IF NOT EXISTS` (match_key, merchant, region, category); called from `onCreate` (line 68) AND the `from < 22` `onUpgrade` block (line 479). `merchant_v22_migration_test.dart` asserts all 4 indexes on fresh-install + a `_runV22MigrationSteps` mirror of the upgrade path — host tests pass. The `customIndices` getters on both table classes are explicitly documented as DECORATIVE and not relied upon. |
| 3 | Re-running seed converges, not doubles — stable string ids + INSERT OR IGNORE + single-transaction batch; row count unchanged after restart | ✓ VERIFIED | `merchant_dao.dart`: `_db.transaction(() => _db.batch(... mode: InsertMode.insertOrIgnore))` — single transaction, INSERT OR IGNORE, Drift companions (no string interpolation). Stable authored `mer_<slug>` ids (never generated from JP name; enforced by id-prefix + dup test). `seed_merchants_use_case_test.dart` "idempotency — re-seed converges, row counts unchanged" passes; `SeedMerchantsUseCase` short-circuits when `findAll()` is non-empty. |
| 4 | Full migration ladder (v3→v22, v17→v22, v21→v22, fresh v22) verified on the encrypted SQLCipher executor path (not just NativeDatabase.memory()) | ⏸ HUMAN VERIFICATION | `integration_test/merchant_migration_ladder_test.dart` (284 lines, 7 testWidgets) is fully authored: asserts `PRAGMA cipher_version` non-empty, index_list non-empty, seed populated, every categoryId L2, re-seed convergence, across fresh-v22 + v21→v22 groups on `createEncryptedExecutor`. Deep-history v3/v17 covered by the host-VM ladder. The on-device RUN is a documented blocking checkpoint (SQLCipher natives only load on a booted device) — 49-06 SUMMARY correctly marks `awaiting-human-verify` and does NOT claim green. Per phase instructions, classified as human_verification, NOT code-failed. |
| 5 | Schema includes region(JP) + multi-locale names + aliases + seed-time normalized match-key + L2 categoryId + non-authoritative ledger hint, 600-800 ceiling, reusable by regional expansion + MOD-005 OCR; names stored as Drift DATA, NOT ARB | ✓ VERIFIED | `merchants_table.dart`: id, nameJa(req), nameZh/nameEn(nullable), region(default 'JP'), categoryId, ledgerHint. `merchant_match_keys_table.dart`: surface, matchKey(indexed non-unique), kind. Domain `Merchant`/`MerchantMatchKey` mirror all dimensions. Aliases expand into match-key rows at seed time (`_surface(alias, 'alias')`). ARB leakage grep for merchant names → 0 hits (names are DATA). Schema docstrings cite the 600-800 ceiling + MERCH-V2-01 regional tail + MOD-005 OCR reuse. |

**Score:** 4/5 truths verified (1 routed to human verification — not failed)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/data/tables/merchants_table.dart` | Merchants Drift table | ✓ VERIFIED | All columns present, registered in @DriftDatabase (line 39) |
| `lib/data/tables/merchant_match_keys_table.dart` | MerchantMatchKeys table, non-unique match_key | ✓ VERIFIED | Registered (line 38); FK customConstraint to merchants(id); match_key NON-UNIQUE per design |
| `lib/data/app_database.dart` | schemaVersion 22, both tables, from<22 onUpgrade, _createMerchantIndexes | ✓ VERIFIED | v22; index helper called from onCreate + onUpgrade |
| `lib/infrastructure/ml/merchant_name_normalizer.dart` | normalizeMerchantKey (NFKC-lite + kana fold, zero deps) | ✓ VERIFIED | 219 lines, top-level fn + namespace wrapper; property test passes |
| `lib/application/accounting/ledger_hint_deriver.dart` | deriveLedgerHint(categoryId) → LedgerType | ✓ VERIFIED | Mirrors resolveLedgerType precedence; parity test passes |
| `lib/shared/constants/default_merchants.dart` (+ merchants/ split) | ~400 merchants, real L2 categoryId | ✓ VERIFIED | 391 entries; aggregator combines 10 group files |
| `lib/data/daos/merchant_dao.dart` | plain-class DAO, transactional batch insert | ✓ VERIFIED | transaction + batch + InsertMode.insertOrIgnore, companions |
| `lib/data/repositories/merchant_repository_impl.dart` | implements MerchantRepository | ✓ VERIFIED | findAll/findById/insertBatch, row→model mapping |
| `lib/features/accounting/domain/models/merchant.dart` | Merchant + MerchantMatchKey | ✓ VERIFIED | Freezed; no data/infra imports (layer clean) |
| `lib/application/accounting/seed_merchants_use_case.dart` | count-guarded idempotent seed | ✓ VERIFIED | mirrors SeedCategoriesUseCase |
| `lib/application/seed/seed_all_use_case.dart` | third leaf after categories | ✓ VERIFIED | short-circuits on prior failure; seedRunner no-op untouched |
| `integration_test/merchant_migration_ladder_test.dart` | encrypted ladder + cipher_version | ✓ AUTHORED (run = human) | 284 lines, substantive; run deferred to device |

### Key Link Verification

| From | To | Via | Status |
|------|-----|-----|--------|
| `SeedAllUseCase` | `SeedMerchantsUseCase` | constructor leaf, after categories, short-circuit | ✓ WIRED |
| `main.dart` | `SeedAllUseCase` | `ref.read(seedAllUseCaseProvider)` (real seed path, NOT seedRunner no-op) | ✓ WIRED |
| `SeedMerchantsUseCase` | `deriveLedgerHint` / `normalizeMerchantKey` | per-surface expansion | ✓ WIRED |
| `merchantRepository` provider | `MerchantDao` → `MerchantRepositoryImpl` | @riverpod, appDatabase | ✓ WIRED |
| `app_database` onCreate + onUpgrade | `_createMerchantIndexes()` | explicit calls both paths | ✓ WIRED |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| MERCH-01 | 49-03,04,05 | ✓ SATISFIED | merchants table + region/multi-locale/aliases/match-key/L2 categoryId/ledger hint; seed populates |
| MERCH-02 | 49-02,03 | ✓ SATISFIED | 391 JP merchants mapped to L2; normalizer (片↔平 fold, fullwidth/lowercase) authored + tested |
| MERCH-03 | 49-02 | ✓ SATISFIED (foundation) | Normalized match-key index built (the data底座 for anchored/normalized matching). Read-time scored matching is explicitly Phase 50 (this phase = data foundation, no consumer cutover) |
| MERCH-04 | 49-01,04,05,06 | ⏸ PARTIAL → human | Idempotent seed + explicit indexes VERIFIED on host; "full ladder under encrypted executor" = human-verify run (Crit #4) |
| MERCH-05 | 49-01,03 | ✓ SATISFIED | 600-800-ceiling schema, region, multi-locale DATA columns, OCR-reusable |

All 5 requirement IDs accounted for; no orphaned IDs.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| (none) | No TODO/FIXME/XXX/HACK/UnimplementedError in any phase-49 lib file | — | Clean |
| (none) | No merchant names in ARB (DATA discipline held) | — | Clean |

Advisory items from 49-REVIEW.md (0 blocker, 4 warning, 4 info) are non-blocking. Notable for follow-up:
- **WR-01** — `merchant_v22_migration_test.dart` re-implements the upgrade DDL (`_runV22MigrationSteps`) instead of driving the real `onUpgrade` migrator. The real encrypted onUpgrade is covered by the integration ladder (human-verify item #4). Host test proves the DDL contract, not the migrator invocation. Acceptable given the SQLCipher constraint; the integration test closes the gap on-device.
- **WR-02** — `deriveLedgerHint` parent-inheritance omits the `level==2` guard. Advisory; parity test currently passes for all 391 seeded categoryIds.

### Human Verification Required

**1. On-device encrypted migration ladder (Success Criterion #4 / MERCH-04 closure)**

- **Test:** Boot an iOS simulator (or attach Android device), then run `flutter test integration_test/merchant_migration_ladder_test.dart`
- **Expected:** All 7 testWidgets pass; `PRAGMA cipher_version` NON-EMPTY; index_list non-empty on fresh-v22 AND v21→v22; ~391 rows seeded; every categoryId L2; re-seed counts unchanged.
- **Why human:** SQLCipher natives load only on a booted device. Host CI links plain libsqlite3 (masks cipher regressions). Documented blocking checkpoint in 49-06; correctly not claimed green.

### Gaps Summary

No code gaps. The merchant directory is migrated from the 13-entry in-memory list to a persistent, indexed, idempotently re-seedable Drift `merchants` table with a normalized match-key index, multi-locale DATA columns, region tagging, and a derived non-authoritative ledger hint. 391 merchants seed via the real `SeedAllUseCase` path on both fresh-install and upgrade, behind a count-guard, in a single INSERT-OR-IGNORE transaction. All host-testable success criteria (#1, #2, #3, #5) are VERIFIED by passing tests. The single outstanding item (#4) is the on-device SQLCipher ladder RUN — a deliberate, documented human-verify checkpoint, not a code failure. "No behavior change, security first" holds: no existing MerchantDatabase consumer was cut over (cutover is Phase 50), and the encrypted executor path is the only seed/migration path.

---

_Verified: 2026-06-23T16:05:00Z_
_Verifier: Claude (gsd-verifier)_

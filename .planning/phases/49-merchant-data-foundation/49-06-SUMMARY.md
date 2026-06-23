---
phase: 49-merchant-data-foundation
plan: 06
subsystem: data/migrations
tags: [integration-test, sqlcipher, drift-migration, encrypted-executor, merchant-data]
requires:
  - "Plan 01 (v22 migration + _createMerchantIndexes + merchant tables)"
  - "Plan 05 (SeedMerchantsUseCase + DefaultMerchants + count-guarded seed)"
provides:
  - "integration_test/ directory + integration_test dev_dependency (Flutter SDK package)"
  - "encrypted-executor migration ladder proving fresh-v22 + v21->v22 on the SQLCipher path"
affects:
  - "/gsd-verify-work gate (final phase gate — Crit #4)"
tech-stack:
  added:
    - "integration_test (Flutter SDK package — on-device test driver)"
  patterns:
    - "IntegrationTestWidgetsFlutterBinding for on-device SQLCipher native loading"
    - "fixed-key MasterKeyRepository test double (no second key path — reuses createEncryptedExecutor)"
    - "drop-what-onCreate-built + user_version rewind to simulate v21 on the encrypted file"
key-files:
  created:
    - "integration_test/merchant_migration_ladder_test.dart"
  modified:
    - "pubspec.yaml (integration_test dev_dependency)"
    - "pubspec.lock (5 transitive integration_test deps)"
decisions:
  - "Reuse createEncryptedExecutor(keyRepo, inMemory: false) unchanged via a fixed-key MasterKeyRepository test double — satisfies V6 (no second key path) and exercises the production HKDF key-derivation path."
  - "SQL-layer test isolation (DELETE merchant rows / drop+user_version rewind) instead of file unlink — the executor's documents-dir path is not exposed for deletion, and reusing the same encrypted file is exactly the at-rest condition under test."
  - "Coverage split per RESEARCH: this integration test proves the SQLCipher path for fresh-v22 + v21->v22 (the only real v1.8-user upgrade); deep-history v3->v22/v17->v22 DDL assertions stay on the host-VM ladder merchant_v22_migration_test.dart."
metrics:
  duration: "~12m"
  completed: "2026-06-23"
  tasks_completed: 2
  tasks_total: 3
  files_created: 1
  files_modified: 2
status: awaiting-human-verify
---

# Phase 49 Plan 06: Encrypted Migration Ladder Summary

On-device encrypted-executor migration ladder authored — proves SQLCipher (not plain libsqlite3) actually applies the v22 merchant schema, indexes, and seed on both fresh-install and the real v21→v22 upgrade path; the device run itself is a blocking human-verify gate.

## What Was Built

**Task 1 — integration_test dev_dependency (commit 1e0cc19f)**
- Added `integration_test: { sdk: flutter }` to `dev_dependencies` (Flutter SDK package, no pub.dev fetch — T-49-SC supply-chain: no package-manager install).
- Created the `integration_test/` directory (did not exist before).
- `flutter pub get` resolved clean: 5 transitive deps added; the pinned trio (`file_picker` / `package_info_plus` / `share_plus`) and `win32 5.15.0` untouched; `drift` / `sqlcipher_flutter_libs` unchanged.
- `flutter analyze` 0 issues.

**Task 2 — encrypted migration ladder test (commit 29e8ecf6)**
- `integration_test/merchant_migration_ladder_test.dart` runs ONLY on a booted simulator/device where `sqlcipher_flutter_libs` natives load (host `flutter test` links plain libsqlite3 and would mask a cipher regression — Pitfall #2).
- Reuses `createEncryptedExecutor(keyRepo, inMemory: false)` unchanged, driven by a fixed-key `MasterKeyRepository` test double (deterministic 32-byte master key → production HKDF-SHA256 derivation). No second key path (V6). Never logs raw merchant names (V7).
- **FRESH v22** assertions: `PRAGMA cipher_version` NON-EMPTY; `schemaVersion == 22`; the four explicit indexes present (`idx_merchant_match_keys_match_key`, `idx_merchant_match_keys_merchant`, `idx_merchants_region`, `idx_merchants_category`) + `PRAGMA index_list` non-empty for both tables; `SeedMerchantsUseCase` populates merchants and **every `categoryId` resolves to a real L2** (count assertion); re-seed converges (idempotent).
- **v21→v22** (real v1.8-user upgrade) assertions: stamp the encrypted file at v21 (drop what onCreate built + `PRAGMA user_version = 21`), reopen as `AppDatabase` v22 so Drift's `from < 22` onUpgrade fires under SQLCipher; assert tables + four indexes rebuilt, `cipher_version` non-empty, and the seed populates the migrated encrypted DB with all categoryIds ∈ L2.

## Verification

- `flutter analyze integration_test/` → **No issues found**.
- `flutter analyze` (full project) → **No issues found**.
- `flutter test` (full host suite) → **3234 passed** (integration_test/ is not collected by the default `test/` path on host — correct; it is gated behind the on-device human-verify run).
- `grep cipher_version integration_test/merchant_migration_ladder_test.dart` → present.
- `grep 'PRAGMA index_list' integration_test/merchant_migration_ladder_test.dart` → present.

## Deviations from Plan

None — the two autonomous tasks executed as written. The on-device run (Task 3) is a `checkpoint:human-verify gate="blocking"` and CANNOT run in this headless orchestrator (no booted simulator); it is returned to the user as a structured checkpoint, not executed or claimed green here (honoring the prohibition: "MUST NOT mark the encrypted ladder green without a real cipher_version-non-empty assertion having run on a device/sim").

## Deep-History Coverage Note

Per RESEARCH's recommended split, deep-history `v3→v22` / `v17→v22` index/column assertions are covered by the host-VM ladder `test/unit/data/migrations/merchant_v22_migration_test.dart` (plain libsqlite3 is adequate for DDL-shape assertions). This integration test proves the SQLCipher boundary for the two paths where at-rest encryption of merchant data actually matters: fresh-v22 and v21→v22.

## Outstanding — Blocking Human-Verify (Task 3)

The encrypted ladder must be run on a booted simulator/device before this plan is fully green:

1. Boot an iOS simulator (or attach an Android device/emulator).
2. Run: `flutter test integration_test/merchant_migration_ladder_test.dart`
3. Confirm the run passes with `PRAGMA cipher_version` NON-EMPTY (SQLCipher loaded, not skipped).
4. Confirm fresh-v22 and v21→v22 both assert the four merchant indexes present + seeded rows + every categoryId ∈ L2.
5. D-08 spot-check (~10 rows): merchant list maps real chains to correct L2/region/names; confirm the expected Amazon / ヤマダ電機 derived-daily diffs (A4) are acceptable.

## Self-Check: PASSED

- FOUND: integration_test/merchant_migration_ladder_test.dart
- FOUND: pubspec.yaml (integration_test dev_dependency)
- FOUND commit: 1e0cc19f (Task 1)
- FOUND commit: 29e8ecf6 (Task 2)

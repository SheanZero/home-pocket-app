---
phase: 49-merchant-data-foundation
plan: 01
subsystem: data
status: complete
tags: [drift, migration, schema-v22, merchant, indexes]
requirements_completed: [MERCH-04, MERCH-05]
dependency_graph:
  requires: []
  provides:
    - "merchants Drift table (v22)"
    - "merchant_match_keys Drift table (v22)"
    - "_createMerchantIndexes() helper (onCreate + from<22)"
    - "schema v22 + v21→v22 migration step"
    - "four explicit indexes: idx_merchants_region, idx_merchants_category, idx_merchant_match_keys_match_key, idx_merchant_match_keys_merchant"
  affects:
    - "downstream merchant readers (Phase 50+) depend on this indexed schema"
tech_stack:
  added: []
  patterns:
    - "decorative customIndices + explicit CREATE INDEX IF NOT EXISTS in onCreate AND onUpgrade (CR-01 lesson)"
    - "stable string PK for idempotent re-seed (INSERT OR IGNORE)"
    - "companion-layer column default (region default JP)"
    - "raw-SQL FK via customConstraint('NOT NULL REFERENCES merchants(id)')"
    - "host-VM migration test: drop+rerun migration-step contract (category_v14 idiom)"
key_files:
  created:
    - lib/data/tables/merchants_table.dart
    - lib/data/tables/merchant_match_keys_table.dart
    - test/unit/data/migrations/merchant_v22_migration_test.dart
  modified:
    - lib/data/app_database.dart
    - lib/data/app_database.g.dart
    - test/unit/data/migrations/schema_v21_migration_test.dart
decisions:
  - "match_key index is NON-UNIQUE (cross-merchant collisions legal — RESEARCH #6); enforced by a regression test inserting two rows with the same match_key"
  - "region default is companion-layer (withDefault Constant JP), verified by an omitted-column insert test"
  - "ledger_hint kept as a stored non-authoritative hint column (D-09), not dropped"
  - "merchant_id FK declared via inline customConstraint('NOT NULL REFERENCES merchants(id)') rather than table-level customConstraints"
metrics:
  duration_min: 6
  tasks: 3
  files_created: 3
  files_modified: 3
  completed: 2026-06-23
---

# Phase 49 Plan 01: Merchant Schema Foundation (v22) Summary

Added the two-table merchant schema (`merchants` + `merchant_match_keys`) at Drift schema **v22** with explicit index creation in BOTH onCreate and the `from < 22` onUpgrade path, plus a host-VM migration unit test proving fresh-install columns/indexes and the v21→v22 upgrade contract. Schema only — no rows seeded (seed is Plan 05).

## What Was Built

- **`merchants` table** (`MerchantRow`): `id` PK (stable string), `name_ja` required, `name_zh`/`name_en` nullable, `region` (companion default `'JP'`), `category_id` (real L2), `ledger_hint` (stored non-authoritative hint). Merchant proper-nouns are DATA columns, not ARB keys (MERCH-05, D-01).
- **`merchant_match_keys` table** (`MerchantMatchKeyRow`): `id` PK, `merchant_id` FK → `merchants(id)`, `surface`, `match_key` (indexed, **non-unique**), `kind` (name|alias|locale).
- **`_createMerchantIndexes()`** helper emitting four `CREATE INDEX IF NOT EXISTS`, called from onCreate AND the `from < 22` block (the `customIndices`-is-decorative gotcha — MEMORY.md).
- **schemaVersion 21 → 22**; `from < 22` onUpgrade creates both tables then calls the index helper.
- **Migration test** with 9 assertions: fresh-install table/column existence, `PRAGMA index_list` non-empty on both tables, all four named indexes, `match_key` index `unique == 0`, a two-rows-share-a-match_key insert (must not throw), region-default insert, and a v21→v22 onUpgrade contract (drop tables, run the `_runV22MigrationSteps` mirror, re-assert).

## TDD Cycle

- **RED** (`e24dd8cb`): migration test authored first; failed because the merchant tables/indexes and v22 did not exist (8 fail / 1 pass — the onUpgrade-contract test builds its own tables and passed correctly).
- **GREEN** (`040dd7d9` tables, `4d530ba2` registration + migration + regen): tables defined, registered, schema bumped, indexes wired; all 9 assertions green.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated stale schema-version pin in pre-existing migration test**
- **Found during:** Task 3 (after bumping schemaVersion to 22)
- **Issue:** `test/unit/data/migrations/schema_v21_migration_test.dart` hard-pinned `schemaVersion == 21`, directly broken by the v22 bump (in-scope, caused by this plan's change).
- **Fix:** Changed the assertion to `greaterThanOrEqualTo(21)` — that suite's real concern is that v21 multi-currency columns/indexes persist; the exact-version pin now lives in the new `merchant_v22_migration_test.dart`. Future additive bumps no longer falsely fail it.
- **Files modified:** test/unit/data/migrations/schema_v21_migration_test.dart
- **Commit:** 4d530ba2

**2. [Rule 1 - Test authoring] Added missing `package:drift/drift.dart` import to RED test**
- **Found during:** Task 1 (RED run)
- **Issue:** `Variable<String>` is not re-exported through `app_database.dart`; the test failed to compile instead of failing for the intended reason.
- **Fix:** Added the direct drift import (matches the `category_v14_migration_test.dart` idiom). The test then failed correctly (missing tables/indexes).
- **Commit:** e24dd8cb

### Plan verify-command note (no code change)

The plan's Task-2 verify used `! grep -niE 'unique' ...`, which flags the documentation strings "NON-UNIQUE". That is a false positive: there is **no** real `UNIQUE` constraint (`grep -niE '\.unique\(|customConstraint.*UNIQUE'` returns nothing). The prohibition (no UNIQUE on `match_key`) is satisfied; only the verify regex is over-broad.

## Verification

- `flutter analyze` → **No issues found** (whole project, after build_runner).
- `flutter test test/unit/data/migrations/merchant_v22_migration_test.dart` → **9/9 passed**.
- `flutter test test/unit/data/migrations/` → **77/77 passed** (full migrations dir, incl. updated v21 test).
- `grep -c '_createMerchantIndexes' lib/data/app_database.dart` → **3** (def + onCreate call + from<22 call).
- No `UNIQUE` on `match_key`; `customIndices` documented decorative on both tables.

## Known Stubs

None — schema-only plan; no UI, no data rows. Seed rows are intentionally out of scope (Plan 05 per the plan's prohibitions).

## Threat Flags

None — no new security-relevant surface beyond the plan's threat model. Schema-only, no row data inserted, no key-path changes; indexes emitted via parameterless `customStatement` (no interpolation of data).

## Self-Check: PASSED

- FOUND: lib/data/tables/merchants_table.dart
- FOUND: lib/data/tables/merchant_match_keys_table.dart
- FOUND: test/unit/data/migrations/merchant_v22_migration_test.dart
- FOUND: commit e24dd8cb (RED test)
- FOUND: commit 040dd7d9 (tables)
- FOUND: commit 4d530ba2 (registration + migration + regen + Rule-1 fix)

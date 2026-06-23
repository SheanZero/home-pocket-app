---
phase: 49-merchant-data-foundation
plan: 05
subsystem: application/seed
tags: [seed, merchants, idempotency, riverpod, drift]
requires:
  - "normalizeMerchantKey (Plan 02)"
  - "DefaultMerchants.all + deriveLedgerHint (Plan 03)"
  - "MerchantRepository + merchantRepository provider (Plan 04)"
provides:
  - "SeedMerchantsUseCase — count-guarded idempotent merchant seed"
  - "seedMerchantsUseCase @riverpod provider"
  - "SeedAllUseCase third leaf (merchants after categories)"
affects:
  - "lib/application/accounting/seed_merchants_use_case.dart"
  - "lib/application/seed/seed_all_use_case.dart"
  - "lib/application/seed/seed_providers.dart"
  - "lib/features/accounting/presentation/providers/repository_providers.dart"
tech-stack:
  added: []
  patterns:
    - "Count-guarded idempotent seed (findAll() empty-guard + single-transaction batch), mirrors SeedCategoriesUseCase"
    - "Surface expansion: nameJa(name) + aliases(alias) + nameZh/nameEn(locale), matchKey = normalizeMerchantKey(surface)"
    - "Composition-leaf orchestration with short-circuit on prior failure"
key-files:
  created:
    - "lib/application/accounting/seed_merchants_use_case.dart"
    - "test/unit/application/accounting/seed_merchants_use_case_test.dart"
  modified:
    - "lib/application/seed/seed_all_use_case.dart"
    - "lib/application/seed/seed_providers.dart"
    - "lib/features/accounting/presentation/providers/repository_providers.dart"
    - "test/unit/application/seed/seed_all_use_case_test.dart"
decisions:
  - "ledgerHint stored as deriveLedgerHint(categoryId).name ('daily'|'joy') — LedgerType enum mapped to the String column via .name; single source of truth (D-09)"
  - "Merchant.region set to 'JP' at expansion (data-layer default per Merchant model + DefaultMerchants Japan spine)"
  - "Merchant seed placed AFTER categories and BEFORE voice synonyms in SeedAllUseCase (merchant categoryIds reference seeded L2s; short-circuits if categories fail)"
metrics:
  duration: "~3 min"
  completed: "2026-06-23"
  tasks: 3
  files_created: 2
  files_modified: 4
status: complete
---

# Phase 49 Plan 05: Merchant Seed Runtime Wiring Summary

Count-guarded idempotent `SeedMerchantsUseCase` that expands `DefaultMerchants.all` into merchant rows (derived `ledger_hint`) + normalized `merchant_match_keys` rows in one transaction, wired as the third leaf of the real `SeedAllUseCase` (after categories), leaving the AppInitializer `seedRunner` no-op untouched.

## What Was Built

- **`SeedMerchantsUseCase`** (`lib/application/accounting/seed_merchants_use_case.dart`): mirrors `SeedCategoriesUseCase` — `final existing = await _merchantRepo.findAll(); if (existing.isNotEmpty) return Result.success(null);` then expands each `DefaultMerchant` into a `Merchant` domain instance and calls `insertBatch` (one transaction, INSERT OR IGNORE in the DAO). Each merchant: `ledgerHint = deriveLedgerHint(categoryId).name`; surfaces = `nameJa` (kind `name`) + aliases (kind `alias`) + non-null `nameZh`/`nameEn` (kind `locale`), each with `matchKey = normalizeMerchantKey(surface)`. No logging of raw merchant names.
- **`seedMerchantsUseCase` provider** (`repository_providers.dart`): `@riverpod` wiring `merchantRepositoryProvider`.
- **`SeedAllUseCase` third leaf**: constructor now takes `SeedMerchantsUseCase seedMerchants`; `execute()` runs categories → merchants → voice synonyms, short-circuiting on categories OR merchants failure.
- **`seed_providers.dart`**: passes `seedMerchants: ref.watch(seedMerchantsUseCaseProvider)` into `SeedAllUseCase(...)`.
- **Tests**: `seed_merchants_use_case_test.dart` (4 tests — counts, ledger_hint parity, match_key parity, re-seed idempotency convergence against real `MerchantRepositoryImpl` + `AppDatabase.forTesting()`); extended `seed_all_use_case_test.dart` (+2 tests — merchant-after-categories ordering, merchant short-circuit when categories fail).

## How It Works

On fresh install AND upgrade, `HomePocketApp._initialize()` reads `seedAllUseCaseProvider` and calls `execute()`. The post-open count guard (`findAll()` empty) makes both paths uniform and idempotent: re-running leaves merchant + match-key row counts unchanged (stable composite PK `${id}__${matchKey}` + `INSERT OR IGNORE`; duplicate name==alias surfaces collapse to one row).

## Idempotency / Convergence (Crit #3)

Test `idempotency — re-seed converges` calls `execute()` twice and asserts both row counts unchanged. The second call short-circuits at the `findAll().isNotEmpty` guard; even if the guard were bypassed, the stable-PK + INSERT OR IGNORE path would still converge.

## Deviations from Plan

None — plan executed as written. Two implementation details worth noting (both anticipated by the read-first files, not deviations):
- `deriveLedgerHint` returns the `LedgerType` enum, while `Merchant.ledgerHint` is a `String` column; mapped via `.name` ('daily'|'joy').
- `Merchant.region` is `required`; set to `'JP'` (matches `DefaultMerchants` Japan spine + the repository impl's `region` default).

## Verification

- `flutter analyze` (whole project) → **No issues found** (after build_runner).
- `flutter test` seed_merchants + seed_all → **8/8 passed**.
- `grep -nE 'seedRunner' lib/main.dart` → `seedRunner: (_) async {}` untouched (Pitfall #1); merchant seed wired only via `SeedAllUseCase`.
- Re-seed convergence asserted (row counts unchanged on second `execute()`).

## Security (threat register)

- T-49-02 (SQL injection): expansion delegates to the Plan-04 DAO `insertSeed` companion path — parameterized, no string interpolation. ✓
- T-49-SEED (re-seed doubling): count guard + stable PK + INSERT OR IGNORE + single transaction; idempotency test asserts unchanged counts. ✓
- T-49-HOOK (seed never runs): wired into `SeedAllUseCase` real path; `seed_all_use_case_test.dart` asserts the third leaf executes. ✓
- T-49-LOG (raw-name disclosure): seed performs no logging (V7); `grep` confirms no `print`/`debugPrint`/`logger` in the use case. ✓

## Known Stubs

None.

## Self-Check: PASSED
- lib/application/accounting/seed_merchants_use_case.dart — FOUND
- test/unit/application/accounting/seed_merchants_use_case_test.dart — FOUND
- Commits 918054b2, 7b696a83, b79efe25 — present in git log

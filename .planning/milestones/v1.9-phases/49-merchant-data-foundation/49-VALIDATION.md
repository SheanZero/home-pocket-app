---
phase: 49
slug: merchant-data-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-23
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `49-RESEARCH.md` § Validation Architecture (2026-06-23).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (unit) + `integration_test` (device/sim — NEW for the encrypted-executor path) + `mocktail` for use-case mocks |
| **Config file** | `test/flutter_test_config.dart` (golden platform gate only — no SQLCipher setup) |
| **Quick run command** | `flutter test test/unit/data/migrations/merchant_v22_migration_test.dart test/unit/application/accounting/seed_merchants_use_case_test.dart` |
| **Full suite command** | `flutter test` (host) + `flutter test integration_test/` (on a booted simulator/device) |
| **Estimated runtime** | host unit ~60s; `integration_test/` ladder ~2-4 min on a booted sim |

---

## Sampling Rate

- **After every task commit:** Run the relevant unit test file(s) (`merchant_v22_migration_test.dart`, `seed_merchants_use_case_test.dart`, `merchant_name_normalizer_test.dart`, etc.)
- **After every plan wave:** Run full host `flutter test` + `flutter analyze` (0 issues). NOTE (MEMORY.md gotcha `gsd-post-merge-gate-flutter-mismatch`): GSD auto-gates sniff `xcodebuild`/`true` — the orchestrator must run `flutter analyze` + full `flutter test` manually.
- **Before `/gsd-verify-work`:** Full host suite green **and** `integration_test/` green on a booted simulator. If no simulator is available, a `checkpoint:human-verify` on the encrypted ladder is required.
- **Max feedback latency:** ~60s (host unit) per task; ~4 min at the phase gate (encrypted ladder).

---

## Per-Task Verification Map

> Task IDs bind at plan/execute time. Rows below are the criterion→test contract the planner must distribute across tasks (every row must land in some task's `<automated>` verify or a Wave 0 dependency).

| Req / Criterion | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-----------------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Crit #2/#5 fresh onCreate | 1 | MERCH-04, MERCH-05 | T-49-01 | indexes + columns built on fresh DB (PRAGMA) | unit (memory) | `flutter test test/unit/data/migrations/merchant_v22_migration_test.dart` | ❌ W0 | ⬜ pending |
| Crit #2 migrated onUpgrade | 1 | MERCH-04 | T-49-01 | same indexes non-empty after v21→v22 | unit (memory) | same file | ❌ W0 | ⬜ pending |
| D-03 normalizer | 1 | MERCH-02 | — | width/kana/case/combining fold per transform | unit (property-style) | `flutter test test/unit/infrastructure/ml/merchant_name_normalizer_test.dart` | ❌ W0 | ⬜ pending |
| Crit #1 categoryId guard | 1 | MERCH-01 | — | every `DefaultMerchants.categoryId` ∈ DefaultCategories L2 ids (hard gate) | unit | `flutter test test/unit/shared/constants/default_merchants_categoryid_test.dart` | ❌ W0 | ⬜ pending |
| Crit #1/#3 seed + idempotency | 2 | MERCH-01, MERCH-03 | T-49-02 | count guard; re-seed converges (row counts unchanged) | unit | `flutter test test/unit/application/accounting/seed_merchants_use_case_test.dart` | ❌ W0 | ⬜ pending |
| D-09 ledger_hint parity | 2 | MERCH-05 | — | derived hint == `CategoryService.resolveLedgerType` precedence for every seeded categoryId | unit | `flutter test test/unit/application/accounting/ledger_hint_derivation_test.dart` | ❌ W0 | ⬜ pending |
| Crit #4 encrypted ladder | 3 | MERCH-04 | T-49-03 | v3→v22 / v17→v22 / v21→v22 / fresh-v22 on SQLCipher executor; `cipher_version` non-empty | integration (device/sim) | `flutter test integration_test/merchant_migration_ladder_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/data/migrations/merchant_v22_migration_test.dart` — Crit #2, #5 (fresh-install onCreate; `PRAGMA index_list` + `table_info`)
- [ ] `test/unit/application/accounting/seed_merchants_use_case_test.dart` — Crit #1, #3 (count guard, idempotency)
- [ ] `test/unit/shared/constants/default_merchants_categoryid_test.dart` — Crit #1 hard gate (`categoryId` ∈ L2)
- [ ] `test/unit/infrastructure/ml/merchant_name_normalizer_test.dart` — D-03 transforms (property-style table)
- [ ] `test/unit/application/accounting/ledger_hint_derivation_test.dart` — D-09 parity with `resolveLedgerType`
- [ ] `integration_test/merchant_migration_ladder_test.dart` — Crit #4 (encrypted executor; NEW `integration_test/` dir)
- [ ] Verify `integration_test:` in `dev_dependencies` (Flutter SDK package); add if absent
- [ ] Update `test/unit/application/seed/seed_all_use_case_test.dart` for the new merchant seed leaf

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Encrypted migration ladder (Crit #4) when no simulator/device CI is available | MERCH-04 | Host `flutter test` links plain libsqlite3 — SQLCipher won't load; the ladder must run on a booted sim/device, which may not be wired into CI | Boot an iOS simulator, run `flutter test integration_test/merchant_migration_ladder_test.dart`, confirm `PRAGMA cipher_version` non-empty and index/seed assertions pass; record as `checkpoint:human-verify` |
| ~400-merchant categoryId spot-check (D-08) | MERCH-01 | Author-judgment that the curated list maps real chains to correct L2 categories beyond the automated `∈ L2` guard | Pre-commit: user samples merchant rows and confirms category/region/name accuracy |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s (host unit)
- [ ] Held-out flag honored: `merchant_name_normalizer_test.dart` is **property-style** (table of (input, expected) pairs across width/kana/case/combining), not a few examples
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

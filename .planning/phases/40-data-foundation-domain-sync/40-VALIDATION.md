---
phase: 40
slug: data-foundation-domain-sync
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-12
---

# Phase 40 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (bundled with Flutter 3.44.0) |
| **Config file** | `test/flutter_test_config.dart` (golden platform gate) |
| **Quick run command** | `flutter test test/unit/data/migrations/ test/unit/infrastructure/i18n/ test/unit/features/accounting/ test/unit/shared/ --no-pub` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | quick ~60s · full ~300s |

---

## Sampling Rate

- **After every task commit:** Run the quick run command above
- **After every plan wave:** Run `flutter test --no-pub` (full suite)
- **Before `/gsd-verify-work`:** Full suite green + `flutter analyze` 0 issues
- **Max feedback latency:** ~300 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | STORE-01 | — | v20→v21 migration adds 3 nullable columns + `exchange_rates` table, no data loss | unit/migration | `flutter test test/unit/data/migrations/schema_v21_migration_test.dart -x` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | STORE-01 | — | Fresh install reaches v21 in one pass with table + index | unit/migration | same file | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | STORE-01 | hash-chain integrity | `HashChainService.verifyChain` passes on mixed v20/v21 dataset | unit/migration | same file | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | STORE-01 | — | `ExchangeRateDao.findByDate` / `findLatest` correct | unit/dao | `flutter test test/unit/data/daos/exchange_rate_dao_test.dart -x` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | STORE-01 | analytics-SUM poisoning | `CreateTransactionUseCase` rejects partial-triple before DB write | unit | `flutter test test/unit/application/accounting/create_transaction_use_case_test.dart -x` | ✅ (new cases) | ⬜ pending |
| TBD | TBD | TBD | STORE-02 | — | `convertToJpy` preview == persist integer for 10 edge cases | unit | `flutter test test/unit/shared/currency_conversion_test.dart -x` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | STORE-03 | sync compat | `fromSyncMap` v1.6 payload → null fields, no exception; v1.7 round-trip lossless | unit | `flutter test test/unit/features/accounting/transaction_sync_mapper_test.dart -x` | ✅ (new cases) | ⬜ pending |
| TBD | TBD | TBD | STORE-04 | hash formula stability | ADR-021 recorded; `calculateTransactionHash` excludes currency fields | architecture + doc | `flutter test test/architecture/domain_import_rules_test.dart` + doc check | ✅ | ⬜ pending |
| TBD | TBD | TBD | STORE-05 | — | `formatCurrency('CNY')` → `CN¥`; `'KRW'` → `₩` 0 decimals; JPY unchanged | unit | `flutter test test/unit/infrastructure/i18n/formatters/number_formatter_test.dart -x` | ✅ (update) | ⬜ pending |
| TBD | TBD | TBD | STORE-05 | — | CNY golden baselines reflect `CN¥` | golden | `flutter test test/golden/amount_display_golden_test.dart --update-goldens` (macOS only) | ✅ (re-baseline) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/data/migrations/schema_v21_migration_test.dart` — stubs for STORE-01 migration contract
- [ ] `test/unit/data/daos/exchange_rate_dao_test.dart` — stubs for STORE-01 DAO behavior
- [ ] `test/unit/shared/currency_conversion_test.dart` — stubs for STORE-02 rounding utility
- [ ] `test/unit/features/accounting/transaction_sync_mapper_test.dart` — new currency round-trip cases for STORE-03 (file exists)
- [ ] Framework install: none needed — `flutter_test` already present

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Golden re-baseline correctness | STORE-05 | Goldens are macOS-baselined; CI cannot pixel-match (BaselineExistenceGoldenComparator off-macOS) | Run `--update-goldens` on macOS, visually inspect `amount_display_cny*.png` show `CN¥` |
| ADR content review | STORE-04 | ADR decision quality is a human judgment | Read ADR-020/021/022, confirm decisions match D-01..D-08 from CONTEXT.md |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---
phase: 40
slug: data-foundation-domain-sync
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-12
---

# Phase 40 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Sync wire → fromSyncMap | Adversarial peer may send payloads with partial currency triple (1 or 2 of 3 fields) | Transaction sync payloads (currency fields) |
| CreateTransactionUseCase | Validates partial-triple AND appliedRate validity BEFORE DB write — the domain tamper gate | Transaction input (originalCurrency / originalAmount / appliedRate) |
| DB migration → transactions rows | ALTER TABLE adds nullable columns to existing rows without touching their values | Schema v21 migration |
| ExchangeRateDao.upsert input | ExchangeRatesCompanion built internally; no user-supplied raw SQL in Phase 40 | Exchange rate cache rows |
| NumberFormatter input → output | currencyCode is an app-internal ISO string; not user-supplied in Phase 40 (no UI) | Currency display strings |
| ADR docs → implementation | ADRs constrain what code may do; no runtime trust surface | Documentation only |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-40-01 | Tampering | Test scaffolds (Wave 0) | accept | Test-only files; no production code modified; no new trust surface | closed |
| T-40-02 | Tampering | hash_chain_service.dart | mitigate | `calculateTransactionHash` takes exactly {transactionId, amount, timestamp, previousHash} (`hash_chain_service.dart:12-17`); zero currency-field references; signature pinned by architecture test `schema_v21_migration_test.dart:229-243` | closed |
| T-40-03 | Information Disclosure | ADR content | accept | ADR-020/021/022 document internal decisions only; no PII or credentials | closed |
| T-40-04 | Tampering | NumberFormatter._getCurrencySymbol | accept | currencyCode app-internal in Phase 40 (no UI input path); Phase 42 will validate ISO codes at entry | closed |
| T-40-05 | Information Disclosure | Golden image files | accept | Test assets with mock data; no real user data | closed |
| T-40-06 | Tampering | transactions table migration | mitigate | Three `ALTER TABLE ... ADD COLUMN` statements with no DEFAULT clause (`app_database.dart:455,458,461`); columns `.nullable()` in `transactions_table.dart:44,46,49`; no data written to existing rows | closed |
| T-40-07 | Tampering | exchange_rates table | mitigate | `ExchangeRates` registered in `@DriftDatabase` (`app_database.dart:32`); production DB built via `createEncryptedExecutor` (SQLCipher AES-256-CBC, `main.dart:57-58`, `encrypted_database.dart:21`) | closed |
| T-40-08 | Tampering | migration idempotency | mitigate | `_createExchangeRateIndexes` uses `CREATE INDEX IF NOT EXISTS` (`app_database.dart:501-503`); called from onCreate and the `from < 21` upgrade branch | closed |
| T-40-09 | Tampering | hash chain integrity across migration | mitigate | Hash formula unchanged (see T-40-02); STORE-04 test (`schema_v21_migration_test.dart:131-222`) runs `verifyChain` over mixed null/non-null currency rows and asserts pass | closed |
| T-40-10 | Tampering | ExchangeRateRepositoryImpl.upsert | accept | Verified: no production caller of `upsert` exists in `lib/` (only interface, DAO, impl); Phase 41 must validate ExchangeRate before first caller lands | closed |
| T-40-11 | Information Disclosure | ExchangeRate domain model | mitigate | Stored in SQLCipher-encrypted AppDatabase (same inheritance as T-40-07) | closed |
| T-40-12 | Tampering | convertToJpy double.parse | mitigate | `convertToJpy` guards `subunitToUnit <= 0`, `originalMinorUnits < 0`, uses `double.tryParse` (`currency_conversion.dart:21-36`); use case validates appliedRate first (`create_transaction_use_case.dart:118-121`) | closed |
| T-40-13 | Tampering | TransactionSyncMapper.fromSyncMap | mitigate | Type-checked null-safe reads (`is String ? x : null`) + triple-validity normalization (`transaction_sync_mapper.dart:58-69,84-86`); v1.6 payloads and wrong-typed adversarial values degrade to null — no exception. Implemented stronger than declared (`is`-checks vs `as T?`) | closed |
| T-40-14 | Tampering | partial-triple sync manipulation | mitigate | `hasCurrencyField && !hasAllCurrencyFields → Result.error` before any DB access (`create_transaction_use_case.dart:101-112`) | closed |
| T-40-15 | Tampering | appliedRate FormatException | mitigate | `validateAppliedRate` (`currency_conversion.dart:53-63`): plain-decimal regex pre-check makes `double.parse` unable to throw; 'NaN'/'-1.5'/'0'/infinite → error. Implemented stronger than declared (regex pre-validation vs try/catch) | closed |
| T-40-16 | Tampering | hash chain scope | mitigate | 4-parameter `calculateTransactionHash` signature excludes currency fields; architecture test (`schema_v21_migration_test.dart:229-243`) documents that adding them breaks compilation | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-40-01 | T-40-01 | Wave 0 scaffolds are test-only; no production trust surface | user (secure-phase gate) | 2026-06-12 |
| AR-40-02 | T-40-03 | ADRs document internal decisions; no secrets/PII | user (secure-phase gate) | 2026-06-12 |
| AR-40-03 | T-40-04 | currencyCode app-internal in Phase 40; **Phase 42 must validate ISO codes at UI entry** | user (secure-phase gate) | 2026-06-12 |
| AR-40-04 | T-40-05 | Golden images are mock test assets | user (secure-phase gate) | 2026-06-12 |
| AR-40-05 | T-40-10 | No upsert caller exists in Phase 40 (grep-verified); **Phase 41 must validate ExchangeRate before first caller lands** | user (secure-phase gate) | 2026-06-12 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-12 | 16 | 16 | 0 | gsd-security-auditor |

**Audit notes (2026-06-12):**
- Register authored at plan time across 6 plans (40-01 … 40-06); auditor verified mitigations only — no new-threat scan.
- All six SUMMARY threat-surface scans report no attack surface beyond the plan-time register.
- Two mitigations implemented stronger than declared (T-40-13, T-40-15) — no action needed.
- Defense-in-depth beyond register scope: use case also enforces ISO-4217 format, `originalAmount > 0`, and amount↔triple consistency via canonical `convertToJpy` (`create_transaction_use_case.dart:126-150`, review fixes WR-03/WR-04).

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-12

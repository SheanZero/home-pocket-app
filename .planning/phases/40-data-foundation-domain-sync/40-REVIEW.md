---
phase: 40-data-foundation-domain-sync
reviewed: 2026-06-12T11:12:41Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - docs/arch/03-adr/ADR-000_INDEX.md
  - docs/arch/03-adr/ADR-020_Exchange_Rate_Precision.md
  - docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md
  - docs/arch/03-adr/ADR-022_Edit_Semantics.md
  - lib/application/accounting/create_transaction_use_case.dart
  - lib/application/currency/repository_providers.dart
  - lib/data/app_database.dart
  - lib/data/daos/exchange_rate_dao.dart
  - lib/data/repositories/exchange_rate_repository_impl.dart
  - lib/data/tables/exchange_rates_table.dart
  - lib/data/tables/transactions_table.dart
  - lib/features/accounting/domain/models/transaction.dart
  - lib/features/accounting/domain/models/transaction_sync_mapper.dart
  - lib/features/currency/domain/models/exchange_rate.dart
  - lib/features/currency/domain/repositories/exchange_rate_repository.dart
  - lib/infrastructure/i18n/formatters/number_formatter.dart
  - lib/shared/utils/currency_conversion.dart
  - test/golden/amount_display_golden_test.dart
  - test/unit/application/accounting/create_transaction_use_case_test.dart
  - test/unit/data/daos/exchange_rate_dao_test.dart
  - test/unit/data/migrations/schema_v21_migration_test.dart
  - test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart
  - test/unit/infrastructure/i18n/formatters/number_formatter_test.dart
  - test/unit/shared/currency_conversion_test.dart
findings:
  critical: 1
  warning: 10
  info: 6
  total: 17
status: issues_found
---

# Phase 40: Code Review Report

**Reviewed:** 2026-06-12T11:12:41Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Phase 40 adds the multi-currency data foundation: schema v20→v21 (exchange_rates table + three nullable transaction columns), the string-typed ExchangeRate domain model (ADR-020), `convertToJpy()`, currency-symbol disambiguation (D-06/D-07/D-08), TransactionSyncMapper backward-compat, and the partial-triple invariant in CreateTransactionUseCase. ADR-020/021/022 were ratified and indexed.

The schema migration, hash-chain scope preservation (ADR-021, verified via the 4-parameter signature test and `verifyChain` with mixed null/non-null currency rows), layer separation (domain `ExchangeRate`/`ExchangeRateRepository` are Drift-free), and sync round-trip omit-when-null pattern are correctly implemented. The decorative-`customIndices` lesson (v1.6 CR-01) was correctly applied with explicit index creation on both onCreate and onUpgrade paths.

However, the review found one critical gap: the partial-triple invariant — which ADR-021 designates as the **sole integrity mechanism** for currency fields after excluding them from the hash chain — is enforced only on the local creation path. The sync ingestion path (`fromSyncMap` → `_transactionRepository.insert/update`) persists peer payloads with no triple validation and no appliedRate validity check, so the invariant ADR-021 depends on can be bypassed by any buggy or malicious peer. Several D-05 validation requirements (scientific-notation rejection, trim) are documented in the ratified ADR but not implemented, and the ADR-020-mandated migration-test assertions (applied_rate column type is TEXT; meaningful preview==persist boundary cases) are missing or vacuous.

## Critical Issues

### CR-01: Sync ingestion bypasses the partial-triple invariant and appliedRate validation

**File:** `lib/features/accounting/domain/models/transaction_sync_mapper.dart:61-63` (and consumer `lib/application/family_sync/apply_sync_operations_use_case.dart:143-148, 162-172`)
**Issue:** `fromSyncMap` blindly reads `originalCurrency`, `originalAmount`, `appliedRate` from the peer payload and the resulting `Transaction` is inserted/updated directly into the local ledger by `_handleCreate`/`_handleUpdate` with **no validation**. ADR-021 explicitly states the partial-triple domain invariant is the integrity guarantee that replaces hash-chain coverage for these fields ("partial-triple 领域不变量作为货币字段的完整性保证机制"), and CreateTransactionUseCase enforces it — but only for locally created transactions. A peer payload containing a partial triple (e.g., only `originalCurrency: 'USD'`), or an invalid rate (`'0'`, `'-1'`, `'abc'`, or a numeric JSON value that makes the `as String?` cast throw), is persisted as invalid domain state that the documented invariant promises cannot exist. Phase 42's edit UI (ADR-022 D-01: `originalCurrency != null` ⇒ render `convertToJpy(originalAmount, appliedRate, …)`) will then null-assert or `FormatException`-crash on such rows. Project security rules require validation of all external data at system boundaries; a P2P sync payload is exactly that boundary.
**Fix:** Enforce the invariant at sync ingestion. Either in `fromSyncMap` or in `_handleCreate`/`_handleUpdate` before persisting:
```dart
// In fromSyncMap, after extracting the three fields:
final oc = data['originalCurrency'] as String?;
final oa = data['originalAmount'] as int?;
final ar = data['appliedRate'] as String?;
final hasAny = oc != null || oa != null || ar != null;
final hasAll = oc != null && oa != null && ar != null;
// Degrade invalid triples to JPY-native rather than persisting invalid state
// (or reject the operation — pick one policy and document it):
final tripleValid = hasAll && _isValidRate(ar) && oa > 0 && oc.isNotEmpty;
...
originalCurrency: tripleValid ? oc : null,
originalAmount: tripleValid ? oa : null,
appliedRate: tripleValid ? ar : null,
```
Add mapper tests for partial-triple payloads and invalid-rate payloads from a peer.

## Warnings

### WR-01: `convertToJpy` — designated canonical site has zero input validation and two crash paths

**File:** `lib/shared/utils/currency_conversion.dart:15-22`
**Issue:** The function the whole codebase MUST route money math through (ADR-020) does not validate any input: (1) `double.parse(appliedRate)` throws an uncaught `FormatException` on a malformed stored string (reachable for sync-ingested rows per CR-01); (2) `subunitToUnit: 0` produces `Infinity`, and `Infinity.round()` throws `UnsupportedError`; (3) negative `appliedRate`/`originalMinorUnits` silently produce negative JPY. As a system-boundary utility consuming persisted strings, it should fail fast with clear errors per the project's error-handling rules.
**Fix:**
```dart
int convertToJpy({
  required int originalMinorUnits,
  required String appliedRate,
  required int subunitToUnit,
}) {
  if (subunitToUnit <= 0) {
    throw ArgumentError.value(subunitToUnit, 'subunitToUnit', 'must be > 0');
  }
  final rate = double.tryParse(appliedRate);
  if (rate == null || rate.isNaN || rate.isInfinite || rate <= 0) {
    throw FormatException('invalid appliedRate: "$appliedRate"');
  }
  return (originalMinorUnits / subunitToUnit * rate).round();
}
```

### WR-02: D-05 validation requirements not implemented — scientific notation and untrimmed input accepted

**File:** `lib/application/accounting/create_transaction_use_case.dart:110-120`
**Issue:** ADR-020 D-05 (ratified) requires rejecting 科学计数法 (scientific notation) and storing manual input "trim 后". The implemented check uses `double.parse`, which **accepts** `'1.493e2'` (= 149.3) and leading/trailing whitespace (`' 149.30 '`), so both pass validation and are persisted verbatim — including the whitespace, violating the trim requirement. Downstream numeric comparison (ADR-020 D-03/D-05) still parses these, but the stored literal violates the ratified save semantics and breaks the "human-readable audit" rationale.
**Fix:** Validate the literal's shape before parsing:
```dart
final raw = params.appliedRate!;
final trimmed = raw.trim();
final decimalLiteral = RegExp(r'^\d+(\.\d+)?$');
if (trimmed != raw || !decimalLiteral.hasMatch(trimmed)) {
  return Result.error('appliedRate must be a plain decimal literal');
}
final rate = double.parse(trimmed);
if (rate <= 0) return Result.error('appliedRate must be a positive number');
```
(Consider hosting this as `validateAppliedRate()` in `currency_conversion.dart` — see IN-04.)

### WR-03: `originalAmount` and `originalCurrency` are not validated

**File:** `lib/application/accounting/create_transaction_use_case.dart:96-120`
**Issue:** With a complete triple, `originalAmount: 0`, `originalAmount: -5000`, and `originalCurrency: ''` all pass validation and are persisted. The use case rejects `amount <= 0` but applies no equivalent check to the foreign-currency amount, and the currency code is not checked for emptiness or ISO 4217 shape (3 uppercase letters). An empty currency code defeats the `originalCurrency != null` ⇒ foreign-row discriminator that ADR-022 D-01 and the display layer rely on.
**Fix:** Inside the `hasAllCurrencyFields` branch:
```dart
if (params.originalAmount! <= 0) {
  return Result.error('originalAmount must be greater than 0');
}
if (!RegExp(r'^[A-Z]{3}$').hasMatch(params.originalCurrency!)) {
  return Result.error('originalCurrency must be a 3-letter ISO 4217 code');
}
```

### WR-04: No consistency check between `amount` and the currency triple

**File:** `lib/application/accounting/create_transaction_use_case.dart:182-201`
**Issue:** The use case accepts `amount` and the triple independently and never verifies `params.amount == convertToJpy(originalMinorUnits: params.originalAmount!, appliedRate: params.appliedRate!, subunitToUnit: …)`. A caller that computes the JPY amount with inline arithmetic (the exact divergence ADR-020 Pitfall 1 exists to prevent) persists a triple that contradicts the hashed `amount` — and since ADR-021 excludes the triple from the hash chain, nothing ever detects the contradiction. The use case also never calls `convertToJpy` at all, so the "single canonical conversion site" currently has zero production callers enforcing the derivation.
**Fix:** Either derive `amount` inside the use case from the triple (preferred — makes divergence impossible), or assert consistency and return `Result.error` on mismatch. Requires the currency's `subunitToUnit`, which suggests adding a minimal currency metadata source in this phase or deferring with an explicit `// Phase 41` marker plus a tracked requirement.

### WR-05: `fetchedAt`/`actualRateDate` round-trip as local time while documented as UTC

**File:** `lib/data/tables/exchange_rates_table.dart:47,54` (and `lib/features/currency/domain/models/exchange_rate.dart:30-43`)
**Issue:** `rateDate` got a dedicated `UtcEpochDateTimeConverter` precisely because Drift's default `dateTime()` returns **local** DateTimes — but `fetchedAt` and `actualRateDate` were left as plain `dateTime()`. Both are documented as "UTC timestamp" in the table and in the domain model. After a persistence round-trip, a `DateTime.utc(...)` value comes back as a local-zone DateTime: the instant is preserved, but `DateTime.==` requires matching `isUtc`, so a round-tripped `ExchangeRate` is not equal to the original Freezed value, and any future `fetchedAt.toIso8601String()` (sync/export/TTL logging) emits local-zone text on one side and UTC on the other.
**Fix:** Apply the same converter:
```dart
Column<int> get fetchedAt => integer().map(const UtcEpochDateTimeConverter())();
Column<int> get actualRateDate =>
    integer().map(const UtcEpochDateTimeConverter()).nullable()();
```
(Do this now, before Phase 41 writes real data — it changes the generated row type.)

### WR-06: `findByDate` requires exact epoch-second match with no UTC-midnight normalization

**File:** `lib/data/daos/exchange_rate_dao.dart:24-31` (and `lib/data/repositories/exchange_rate_repository_impl.dart:19-23`)
**Issue:** The composite key contract is "UTC midnight" (documented on the table and domain model), but neither DAO nor repository normalizes the input. A caller passing `DateTime(2026, 6, 12)` (local) or `DateTime.now()` produces a different epoch second than `DateTime.utc(2026, 6, 12)`, causing silent cache misses on lookup and near-duplicate rows on upsert (two "June 12" entries with different epoch keys). Nothing enforces the documented contract at the boundary.
**Fix:** Normalize in the repository (the domain-facing boundary):
```dart
DateTime _normalize(DateTime d) {
  final utc = d.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}
```
Apply to `findByDate` and to `rate.rateDate` in `upsert`. Add a DAO/repo test passing a non-midnight local DateTime.

### WR-07: schema_v21 test never exercises the v20→v21 upgrade path and omits the ADR-020-mandated TEXT-type assertion

**File:** `test/unit/data/migrations/schema_v21_migration_test.dart:40-109`
**Issue:** Two gaps: (1) The group is named "v20→v21 upgrade columns" but every test constructs `AppDatabase.forTesting()` — a fresh install at schema 21 that runs `onCreate`/`createAll()` only. The `from < 21` block in `onUpgrade` (the three `ALTER TABLE` statements and `_createExchangeRateIndexes()` on the upgrade path) is never executed by any test; the labels claim coverage that does not exist. This follows the repo's existing fresh-install convention, but the misleading group name should not survive review. (2) ADR-020 explicitly mandates: "`schema_v21_migration_test.dart` MUST 包含：`appliedRate` 在 transactions 表中的列类型为 TEXT（不为 REAL）". The tests read only the `name` field from `PRAGMA table_info` — the column type is never asserted, so a regression to `RealColumn` (the exact failure mode ADR-020 exists to prevent) would pass this suite.
**Fix:** Add the type assertion:
```dart
final cols = await db.customSelect('PRAGMA table_info(transactions)').get();
final applied = cols.firstWhere((r) => r.read<String>('name') == 'applied_rate');
expect(applied.read<String>('type'), equals('TEXT'));
final origAmount = cols.firstWhere((r) => r.read<String>('name') == 'original_amount');
expect(origAmount.read<String>('type'), equals('INTEGER'));
```
And rename the group (e.g., "v21 schema columns (fresh install)") or add a genuine upgrade test that builds a v20 database and reopens it at v21.

### WR-08: currency_conversion_test — tautological preview==persist test, wrong rounding claim, missing boundary cases

**File:** `test/unit/shared/currency_conversion_test.dart:8,88-101`
**Issue:** (1) The header comment claims the result uses "banker's rounding" — Dart's `.round()` is half-away-from-zero, not banker's; the comment documents behavior the code does not have, and no test pins the half-yen case (e.g., 750.5 → 751 vs 750) that distinguishes them. (2) The "preview and persist give same int" test calls the same pure function twice with identical arguments — it can never fail and provides zero evidence for the ADR-020 requirement of "≥10 boundary cases verifying preview == persisted value". (3) No tests for malformed rate (`'abc'` → currently uncaught FormatException, see WR-01), negative inputs, `subunitToUnit: 0`, or a classic float-precision stressor (e.g., rate `'0.1'` × large amount).
**Fix:** Delete or replace the tautological test with a half-yen boundary test pinning `.round()` semantics, fix the header comment, and add invalid-input tests once WR-01's validation lands.

### WR-09: ADR-021 documents `original_amount` as TEXT but the implementation is INTEGER minor units

**File:** `docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md:30` (vs `lib/data/tables/transactions_table.dart:46`, `lib/data/app_database.dart:457-459`)
**Issue:** ADR-021's 背景 section specifies `original_amount` (TEXT, nullable) — 原币金额字符串（如 "149.99"）. The implementation uses `IntColumn` (INTEGER, minor units: `5000` for $50.00), the Freezed field is `int?`, and `fromSyncMap` casts `data['originalAmount'] as int?`. A future implementer (Phase 41/42) or a peer following the ratified ADR's wire description and sending `"149.99"` as a string would crash the cast in `fromSyncMap`. The ADR is append-only post-ratification, so the contradiction will persist unless explicitly corrected.
**Fix:** Append an `## Update 2026-06-12: original_amount column type correction` section to ADR-021 recording that the implemented type is INTEGER (minor units) and that only `applied_rate` is TEXT, per the ADR's own append-only rule.

### WR-10: Golden tests baseline a wrong amount representation for 2-decimal currencies

**File:** `test/golden/amount_display_golden_test.dart:73-141`
**Issue:** The USD/CNY tests are titled "USD $1,235.00" / "CNY CN¥1,235.00" but pass `amount: '123500'` (minor units). `AmountDisplay._formatted` does no minor-unit conversion — it renders the raw string with comma grouping, so the goldens actually depict **"123,500"** next to a $/CN¥ badge, i.e., a value 100× the title's claim. The D-06 symbol disambiguation is therefore baselined against an amount display no real foreign-currency row should ever show, and decimal rendering ("1,235.00") for 2-decimal currencies is completely unverified.
**Fix:** Pass the major-unit display string the widget contract expects (`amount: '1235.00'`), re-baseline the four USD/CNY goldens on macOS (per the golden CI platform gate), and keep one test asserting the decimal part renders (`'1,235.00'`).

## Info

### IN-01: `idx_exchange_rates_currency_date` duplicates the composite primary key

**File:** `lib/data/tables/exchange_rates_table.dart:63-68`, `lib/data/app_database.dart:501-506`
**Issue:** The table's PRIMARY KEY is `(currency, rateDate)`; SQLite auto-creates a unique index for a non-rowid composite PK, so `idx_exchange_rates_currency_date (currency, rate_date)` is fully redundant — every query it could serve is served by the PK index, while every write maintains both.
**Fix:** Drop the custom index (and its migration/test references), or document why a duplicate is intentionally kept.

### IN-02: `expect(db.schemaVersion, equals(21))` breaks on the next schema bump

**File:** `test/unit/data/migrations/schema_v21_migration_test.dart:10`
**Issue:** Every other migration test in the directory uses `greaterThanOrEqualTo(_targetSchemaVersion)` so older tests survive future bumps. The strict `equals(21)` guarantees a spurious failure at v22.
**Fix:** `expect(db.schemaVersion, greaterThanOrEqualTo(21));`

### IN-03: ADR-000 INDEX statistics and review table not updated for the three new ADRs

**File:** `docs/arch/03-adr/ADR-000_INDEX.md:664-700`
**Issue:** The 决策统计 table says 已接受 16 / 总计 21, but the file lists 22 ADRs (001–022) with 17 accepted (001-005, 007-011, 015, 017-022) + 1 implemented (006) + 4 drafts (012-014, 016) = 22. Additionally, the 下次Review计划 table ends at ADR-019 — ADR-020/021/022 rows are missing even though each ADR body defines a review trigger.
**Fix:** Update counts to 17/1/4 = 22 and append three review-plan rows ("Phase 40 实施完成后" ×2, "Phase 42 实施完成后").

### IN-04: Inline `double.parse(appliedRate)` in the use case undercuts the "single parse site" claim

**File:** `lib/application/accounting/create_transaction_use_case.dart:113`
**Issue:** ADR-020 states the unique parse point is inside `convertToJpy()`, and `currency_conversion.dart` says "Do NOT call double.parse(appliedRate) inline". The use case's validation block parses inline. It's validation rather than arithmetic, so the spirit survives, but the letter of the constraint is already violated by the first consumer — future readers will cite this as precedent.
**Fix:** Export a `validateAppliedRate(String raw)` helper from `currency_conversion.dart` (combining with WR-02's shape check) and call it from the use case, keeping all `appliedRate` parsing in one file.

### IN-05: Noise comments and unused private constructor

**File:** `lib/infrastructure/i18n/formatters/number_formatter.dart:57-67`; `lib/features/currency/domain/models/exchange_rate.dart:16`
**Issue:** Comments like `return '¥'; // ¥` repeat the escape verbatim and add nothing — either write the literal character or drop the comment. `const ExchangeRate._();` exists with no custom members; the private constructor is only needed when adding getters/methods to a Freezed class.
**Fix:** Remove the redundant comments (or replace escapes with literal symbols plus one explanatory comment); remove `const ExchangeRate._();` until a member needs it.

### IN-06: Missing FormatException-path and empty-string tests for appliedRate validation

**File:** `test/unit/application/accounting/create_transaction_use_case_test.dart:481-543`
**Issue:** The D-05 group covers `'NaN'`, `'-1.5'`, `'0'`, `'0.001'` but never exercises the `on FormatException` branch (`'abc'` → "appliedRate is not a valid number") or the empty string `''`. One of the two error messages in the implementation is untested.
**Fix:** Add `appliedRate: 'abc'` and `appliedRate: ''` cases expecting `contains('not a valid number')`.

---

_Reviewed: 2026-06-12T11:12:41Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

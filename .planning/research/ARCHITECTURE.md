# Architecture Research — v1.7 Multi-Currency Integration

**Domain:** Multi-currency transaction entry on existing Home Pocket 5-layer Clean Architecture
**Researched:** 2026-06-12
**Confidence:** HIGH — all conclusions drawn from direct source-code inspection across all 7 integration surfaces

---

## Integration Map Overview

Seven integration surfaces. Five require code changes; two require zero changes and are confirmed safe.

```
NEW components (v1.7)                     EXISTING components (modified)
──────────────────────────────────────    ──────────────────────────────────────────────────
lib/infrastructure/
  exchange_rate/                           lib/data/tables/transactions_table.dart
    exchange_rate_api_client.dart            ← 3 nullable columns added (v20→v21)
    exchange_rate_cache_service.dart        lib/data/app_database.dart
                                              ← schemaVersion 20→21, new migration block
lib/data/
  tables/exchange_rates_table.dart         lib/features/accounting/domain/models/
  daos/exchange_rate_dao.dart                transaction.dart
  repositories/                              ← 3 optional nullable fields
    exchange_rate_repository_impl.dart       transaction_sync_mapper.dart
                                              ← conditional emit + null-safe read

lib/features/currency/domain/             lib/application/accounting/
  models/exchange_rate.dart                 create_transaction_use_case.dart
  repositories/                              ← 3 optional params in CreateTransactionParams
    exchange_rate_repository.dart

lib/application/currency/                 lib/application/voice/
  get_exchange_rate_use_case.dart            voice_text_parser.dart (minor: no direct change)
  resolve_rate_for_date_use_case.dart        parse_voice_input_use_case.dart
  repository_providers.dart                   ← _extractCurrencyCode + VoiceParseResult field
                                             lib/shared/constants/voice_currency_suffixes.dart
lib/features/accounting/presentation/       ← new tokens appended
  widgets/
    smart_keyboard.dart                    ZERO CHANGES:
      ← onCurrencyTap callback added        lib/data/daos/analytics_dao.dart
    currency_selector_sheet.dart (NEW)      lib/features/list/  (all list widgets/DAOs)
    transaction_details_form.dart           lib/application/analytics/ (all use cases)
      ← currency state + preview row        lib/core/initialization/app_initializer.dart
  screens/                                  lib/application/family_sync/
    manual_one_step_screen.dart               apply_sync_operations_use_case.dart
      ← passes onCurrencyTap                  transaction_change_tracker.dart
    voice_input_screen.dart
      ← passes initialCurrency from parse
```

---

## (a) Exchange-Rate Client and Rate Use Cases — Placement Decision

### Infrastructure layer: `lib/infrastructure/exchange_rate/`

Create a new `exchange_rate/` subdirectory inside `lib/infrastructure/`. Do NOT create a generic `network/` subdirectory.

**Rationale:**

`lib/infrastructure/sync/relay_api_client.dart` sets the precedent: a domain-specific subdirectory owns the HTTP client for that concern. The relay client is not in a generic `network/` folder; it is in `sync/`. Following the same convention keeps placement consistent.

The `http` package (`^1.6.0`) is already in `pubspec.yaml`. No new HTTP dependency is needed.

The `import_guard.yaml` for `lib/infrastructure/` (currently denying `features/**`, `application/**`, `data/**`) applies via `inherit: true` to any new subdirectory. No config change is required.

The API client carries no user data: it sends only a date string and a currency pair (privacy constraint documented in PROJECT.md §Key context). No `KeyManager` or `RequestSigner` is needed, making the client simpler than `relay_api_client.dart`.

**Two new files:**

`lib/infrastructure/exchange_rate/exchange_rate_api_client.dart` — wraps a single endpoint on `api.frankfurter.app` (free, no API key). The method signature:

```dart
Future<double> fetchRate({
  required String fromCurrency,
  required DateTime date,
}) async { ... }
// GET https://api.frankfurter.app/YYYY-MM-DD?amount=1&from={from}&to=JPY
// Returns: JPY per 1 unit of fromCurrency
```

Stateless. Injectable `http.Client` via constructor parameter — mirrors `RelayApiClient` exactly and enables unit testing with `MockClient`.

`lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart` — orchestrates cache-first logic: hit the `ExchangeRateDao`; on miss, call `ExchangeRateApiClient`; persist result; return rate. On network failure, return the most-recent cached rate for that currency (any date). Lives in infrastructure because it coordinates a platform capability (network) with a persistence operation. It is not a business use-case concern; use cases delegate rate resolution to this service.

### Application layer: `lib/application/currency/`

Create a new `currency/` subdirectory under `lib/application/`. Existing analogs: `accounting/`, `analytics/`, `voice/`.

`lib/application/currency/get_exchange_rate_use_case.dart` — receives `(DateTime date, String fromCurrency)`, calls `ExchangeRateCacheService`, returns `Result<ExchangeRate>`. On cache-miss + network failure, delegates to `ResolveRateForDateUseCase`.

`lib/application/currency/resolve_rate_for_date_use_case.dart` — encapsulates offline fallback + manual override merge. Returns a sealed `RateResult` with variants `RateResult.fetched` (fresh) and `RateResult.fallback({required DateTime cachedDate})` so the UI can display a "using cached rate from [date]" disclaimer.

`lib/application/currency/repository_providers.dart` — Riverpod wiring. ONE file per feature (Riverpod hygiene rule).

The `import_guard.yaml` for `lib/application/` (denying `data/tables/**`, `data/daos/**`, and `features/*/presentation/**`) constrains these use cases to go through the repository interface, not the DAO directly.

---

## (b) Rate Cache as a New Drift Table — Data Layer Placement

### Table: `lib/data/tables/exchange_rates_table.dart`

```dart
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  TextColumn get currency => text()();          // ISO 4217, e.g. 'USD'
  DateTimeColumn get rateDate => dateTime()();  // midnight UTC of the exchange day
  RealColumn get rate => real()();              // JPY per 1 unit of currency
  DateTimeColumn get fetchedAt => dateTime()(); // when the row was cached

  @override
  Set<Column> get primaryKey => {currency, rateDate};
}
```

The `(currency, rateDate)` composite primary key provides uniqueness and enables the "latest rate for currency X" fallback query:

```sql
SELECT * FROM exchange_rates WHERE currency = ? ORDER BY rate_date DESC LIMIT 1
```

**Explicit index** (per the v1.6 lesson — `customIndices` is decorative, `CREATE INDEX` must be emitted explicitly in `onCreate` and `onUpgrade`):

```sql
CREATE INDEX IF NOT EXISTS idx_exchange_rates_currency_date
  ON exchange_rates (currency, rate_date);
```

The composite-key lookup is already indexed by the primary key in SQLite. The explicit index on `(currency, rate_date)` additionally accelerates the "latest for currency" query via `ORDER BY rate_date DESC`.

### DAO: `lib/data/daos/exchange_rate_dao.dart`

Three methods, all `Future`-based (not streams — rates are fetched on-demand per save, not watched reactively):

- `Future<ExchangeRateRow?> findRate(String currency, DateTime date)` — exact date lookup
- `Future<ExchangeRateRow?> findLatestRate(String currency)` — most-recent cached fallback
- `Future<void> upsertRate(ExchangeRatesCompanion companion)` — insert-or-replace on composite PK conflict

### Repository interface: `lib/features/currency/domain/repositories/exchange_rate_repository.dart`

The "Thin Feature" rule: `lib/features/currency/domain/` holds only models and repository interfaces.

```dart
abstract interface class ExchangeRateRepository {
  Future<ExchangeRate?> findByDate(String currency, DateTime date);
  Future<ExchangeRate?> findLatest(String currency);
  Future<void> upsert(ExchangeRate rate);
}
```

### Repository implementation: `lib/data/repositories/exchange_rate_repository_impl.dart`

ALL repository implementations live in `lib/data/repositories/` per the "ALL tables in lib/data/" rule (CLAUDE.md). The impl maps `ExchangeRateRow` ↔ `ExchangeRate` Freezed model and delegates to `ExchangeRateDao`.

### Schema migration: v20 → v21

In `app_database.dart`, `onUpgrade` gains a `from < 21` block:

```dart
if (from < 21) {
  // New exchange_rates cache table
  await migrator.createTable(exchangeRates);
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_exchange_rates_currency_date '
    'ON exchange_rates (currency, rate_date)',
  );
  // New nullable columns on transactions (foreign-currency provenance)
  await customStatement('ALTER TABLE transactions ADD COLUMN original_currency TEXT');
  await customStatement('ALTER TABLE transactions ADD COLUMN original_amount REAL');
  await customStatement('ALTER TABLE transactions ADD COLUMN conversion_rate REAL');
}
```

Also added to `onCreate` (after `createAll()` + `_createShoppingItemIndexes()`) for fresh installs. This mirrors exactly the `_createShoppingItemIndexes()` helper pattern from v1.6 — a private method `_createExchangeRateIndexes()` keeps `onCreate` and `onUpgrade` in sync.

---

## (c) Transactions Table Migration v20→v21 — Nullability Decision and Sync Round-Trip

### New columns on `Transactions`

```dart
// All three nullable: JPY-native rows have NULL (amount IS already in JPY; no conversion).
// Non-null only when the original currency was not JPY.
TextColumn get originalCurrency => text().nullable()();  // ISO 4217, e.g. 'USD'
RealColumn get originalAmount => real().nullable()();    // user-entered in originalCurrency
RealColumn get conversionRate => real().nullable()();    // rate used: JPY per 1 unit
```

**Decision: all three columns nullable, no defaults.**

`NULL` correctly means "no conversion was performed; amount is already in JPY." A default string `'JPY'` on `originalCurrency` would contaminate the idiomatic null-check for "is this a foreign-currency row?" across query filters and UI display logic. A default `0.0` on `conversionRate` is semantically wrong (a zero rate is an error state, not an absent state). Nullable with no default is the correct choice.

The existing `amount` column (INT, NOT NULL) remains unchanged — it always stores the canonical JPY amount. All analytics, sorting, and list code touches only `amount`.

### Migration statement rationale

Use raw `customStatement` (not `migrator.addColumn`) for nullable columns without DEFAULT. The v17 `entry_source` migration used `customStatement` for the same reason (documented in `app_database.dart` line comment: "Cannot use migrator.addColumn here because table-level customConstraints are not applied by addColumn to existing rows"). For nullable columns the concern is slightly different (no CHECK to apply), but the pattern is established and consistent.

### Impact on `TransactionSyncMapper`

`toSyncMap` adds three conditional fields (matching the existing `if (x != null) 'field': x` pattern already used for `note`, `merchant`, `photoHash`):

```dart
if (transaction.originalCurrency != null)
  'originalCurrency': transaction.originalCurrency,
if (transaction.originalAmount != null)
  'originalAmount': transaction.originalAmount,
if (transaction.conversionRate != null)
  'conversionRate': transaction.conversionRate,
```

`fromSyncMap` adds three nullable reads with explicit null defaults:

```dart
originalCurrency: data['originalCurrency'] as String?,
originalAmount: (data['originalAmount'] as num?)?.toDouble(),
conversionRate: (data['conversionRate'] as num?)?.toDouble(),
```

### Sync round-trip compatibility

The sync payload is a JSON map. Extra keys in JSON are silently ignored by `fromSyncMap` because it only reads the keys it knows about. Absent keys read as `null` through the `as T?` cast. This gives clean bidirectional compatibility:

| Scenario | What happens |
|---|---|
| v1.7 sends transaction with `originalCurrency='USD'` to older client (v1.6) | Older `fromSyncMap` ignores unknown keys; stores `amount` (JPY). Correct. |
| v1.6 client sends JPY transaction to v1.7 | v1.7 `fromSyncMap` reads absent keys as `null`. All three fields null. Correct. |
| v1.7 sends JPY transaction (null fields) | `if (x != null)` guard omits the three keys from the payload. Wire is identical to pre-v1.7. |
| Manual rate override | `conversionRate` set by user, persisted verbatim; not re-fetched on receive. Correct. |

No version negotiation or wire versioning is needed.

### Impact on `TransactionChangeTracker` and `ApplySyncOperationsUseCase`

**TransactionChangeTracker:** no change. It receives pre-serialized `Map<String, dynamic>` from `TransactionSyncMapper.toCreateOperation` / `toUpdateOperation`. The mapper update above is the only edit.

**ApplySyncOperationsUseCase:** no change. The `_handleCreate` and `_handleUpdate` methods call `TransactionSyncMapper.fromSyncMap` directly. Backward-compat null defaults in the mapper handle field absence transparently.

### Impact on `Transaction` Freezed model and `CreateTransactionParams`

`Transaction` gains three nullable Freezed fields (declared with Dart null types, no `@Default` annotation needed — nullable fields default to null in Freezed):

```dart
String? originalCurrency,
double? originalAmount,
double? conversionRate,
```

`CreateTransactionParams` gains three optional constructor parameters:

```dart
final String? originalCurrency;
final double? originalAmount;
final double? conversionRate;
```

All existing call sites (manual, voice, OCR) omit these parameters and continue to work unchanged. Only the new multi-currency save path sets them.

---

## (d) SmartKeyboard and TransactionDetailsForm — Currency State Location

### SmartKeyboard: minimal change, new `onCurrencyTap` callback

The currency cell in the action row currently renders `currencyLabel` / `currencySymbol` as static display (a `_CurrencyKey` private widget). For v1.7, tapping this cell opens the currency selector.

The minimal change: add a nullable `onCurrencyTap` callback parameter. `_CurrencyKey` wraps its existing content in `GestureDetector` / `InkWell` when `onCurrencyTap != null`. `SmartKeyboard` remains a stateless `StatelessWidget` — no internal state added.

```dart
SmartKeyboard(
  ...
  currencyLabel: 'USD',    // updated by host when user picks a currency
  currencySymbol: '$',     // updated by host
  onCurrencyTap: () => _openCurrencySelector(), // NEW — null = display-only
)
```

### TransactionDetailsForm: local state fields (no new provider)

Currency selection and the converted-amount preview belong to the form's existing local state. The form already manages `_amount`, `_date`, `_ledgerType`, `_joyFullness` as `late` instance fields on `TransactionDetailsFormState`. Multi-currency state follows the same pattern.

New private fields added to `TransactionDetailsFormState`:

```dart
String? _originalCurrency;         // null = JPY (no conversion)
double? _originalAmount;            // user-entered value in originalCurrency
double? _conversionRate;            // rate fetched or manually overridden
bool _rateIsManualOverride = false; // distinguishes fetched vs user-typed rate
bool _rateFetchPending = false;     // drives loading indicator in preview row
```

No `StateNotifier`, `AsyncNotifier`, or separate Riverpod provider is needed. `setState(() {...})` drives all currency-state rebuilds — consistent with how `_date`, `_amount`, `_ledgerType` are already mutated.

**Converted-amount preview row** (visible when `_originalCurrency != null`):

```
USD  50  ×  148.30  =  ¥7,415   [edit rate]
```

"Edit rate" tap sets `_rateIsManualOverride = true` and opens a numeric input dialog. A loading spinner replaces the rate when `_rateFetchPending = true`.

**Rate fetch trigger:** when the user changes the form date OR changes the selected currency, the form calls `ref.read(getExchangeRateUseCaseProvider).execute(date, currency)` (a one-shot `Future` read, not a watch). The result updates `_conversionRate` via `setState`. If the fetch fails (network error or cache miss), `_conversionRate` retains its previous value and the preview shows "(using cached rate from [fallback date])".

**TransactionDetailsFormConfig extension:** `$new(...)` gains two new optional fields:

```dart
final String? initialCurrency;       // from voice parser or OCR
final double? initialOriginalAmount; // pre-filled original amount (OCR/voice)
```

These are null for the manual entry path, non-null when voice or OCR pre-detects a currency.

### Currency selector: new modal bottom sheet

```
lib/features/accounting/presentation/widgets/currency_selector_sheet.dart
```

Structure: segmented header (常用 common / 全部 full ISO / search tab), `ListView` of tappable currency rows (ISO code + symbol + localized name), returns `String?` (ISO 4217 code). Opens via `showModalBottomSheet` from `ManualOneStepScreen` (through `onCurrencyTap`) or from the voice/OCR host.

The full ISO currency list (170+ entries) is a static Dart constant — no network call needed for the list itself.

---

## (e) Voice Parser Extension for Currency Words

### State machines: unchanged

`ChineseNumeralStateMachine.normalize()` maps unrecognized characters to nothing (they are simply dropped from the token list — see the `// Step 5: everything else silently dropped` comment in the source). Currency words like `美元`, `ドル` are dropped, which is correct: the number extraction still works because currency words are not numeric tokens.

No changes to `ChineseNumeralStateMachine`, `JapaneseNumeralStateMachine`, or `NumeralStateMachine`.

### `VoiceCurrencySuffixes.all`: extend with multi-language currency words

Ordering rule: longer tokens first (existing invariant — `日元` before `元`, `块钱` before `块`).

New tokens to insert at the correct position (longest-first within their group):

```dart
// Multi-char zh (insert before bare single-char equivalents)
'人民币',  // CNY zh (3 chars — longest first)
'美元',    // USD zh
'欧元',    // EUR zh
'英镑',    // GBP zh
'港币',    // HKD zh
'澳元',    // AUD zh
'加元',    // CAD zh
'泰铢',    // THB zh
'韩元',    // KRW zh

// Multi-char ja (insert before 'ドル' which is already present)
'ユーロ',  // EUR ja (3 chars)
'ポンド',  // GBP ja (3 chars)
'ウォン',  // KRW ja (3 chars)
// 'ドル' already present (USD ja)
```

`regexAlternation` is auto-derived from `all`, so the `_extractArabicAmount` regex in `VoiceTextParser` expands automatically. No direct changes to `VoiceTextParser`.

### `ParseVoiceInputUseCase`: add `_extractCurrencyCode` + `VoiceParseResult` field

New private method on `ParseVoiceInputUseCase`:

```dart
/// Scans recognized text for a known currency word and returns the ISO 4217 code.
/// Returns null if no currency word is detected (= JPY, no conversion needed).
String? _extractCurrencyCode(String text) { ... }
```

Implementation: iterate `VoiceCurrencySuffixes.all`, check `text.contains(token)`, return the corresponding ISO code from a static `const Map<String, String> _currencyTokenToIso`.

`VoiceParseResult` Freezed model gains one new optional field:

```dart
final String? detectedCurrency; // null = JPY-native; 'USD', 'EUR', etc. otherwise
```

Freezed nullable fields with no `@Default` annotation implicitly default to `null` — no existing callsites need changes.

`VoiceInputScreen` reads `result.detectedCurrency` and passes it as `initialCurrency` in `TransactionDetailsFormConfig.$new(...)`.

---

## (f) Analytics and List Code Paths — Confirmed Zero Changes Required

All analytics queries operate on the `amount` column (SQLite INTEGER, the converted JPY value). Confirmed by direct inspection of `analytics_dao.dart`:

- `SUM(amount)` — expense totals, per-ledger totals, per-category totals
- `ORDER BY amount DESC` — largest expense, best joy moment
- `amount` field — joy contribution calculations (`Σ joy_contribution`)
- Calendar day totals — `SUM(amount)` per day

The v1.7 design principle is that `amount` always stores JPY. The three new nullable columns are additive and invisible to all query paths. Analytics and list use cases require **zero changes**.

**List tile decoration** for foreign-currency rows is purely additive: a conditional `Text` widget rendered when `transaction.originalCurrency != null`. This is a UI-only addition in `ListTransactionTile` — no DAO, repository, or use-case change.

**Detail view** (`TransactionDetailsForm` in edit mode): `initState` already seeds all fields from `seed` verbatim. The three new nullable fields on `Transaction` are naturally available via `seed.originalCurrency`, `seed.originalAmount`, `seed.conversionRate`. A read-only informational row is added to the build method when `_originalCurrency != null`.

---

## (g) AppInitializer — Confirmed No Impact

`AppInitializer` initializes `KeyManager → Database → other services`. Exchange-rate fetching is lazy: rates are fetched when the user selects a non-JPY currency during entry. No AppInitializer change is needed.

`ExchangeRateCacheService` and use cases are wired via Riverpod providers and instantiated on first `ref.read`. Boot time is unaffected.

---

## (h) Suggested Build Order

Phases ordered by dependency. Each phase completes before the next starts, except Phases E and F which are independent and can run in parallel.

### Phase A — Data Foundation (prerequisite for everything)

1. Add `exchange_rates_table.dart` to `lib/data/tables/`
2. Add `exchange_rate_dao.dart` to `lib/data/daos/`
3. Add `exchange_rate_repository_impl.dart` to `lib/data/repositories/`
4. Register `ExchangeRates` in `AppDatabase @DriftDatabase(tables:[...])`; bump `schemaVersion` to 21
5. Add v20→v21 migration block (exchange_rates table + index + three transactions columns)
6. Run `build_runner` — regenerates `app_database.g.dart`

Gate: migration tests — verify v20→v21 executes without error; verify v1→v21 clean install works; verify existing transactions gain three null columns without data loss.

### Phase B — Domain Models and Sync Protocol

7. Add three nullable fields to `Transaction` Freezed model
8. Add `ExchangeRate` Freezed model to `lib/features/currency/domain/models/`
9. Add `ExchangeRateRepository` interface to `lib/features/currency/domain/repositories/`
10. Update `TransactionSyncMapper.toSyncMap` (conditional emit) and `fromSyncMap` (null-safe read)
11. Add three optional fields to `CreateTransactionParams`
12. Run `build_runner` — regenerates Freezed + JSON serialization

Gate: sync round-trip unit tests — new-to-old wire (extra keys ignored), old-to-new wire (absent keys → null).

### Phase C — Infrastructure Client

13. Add `exchange_rate_api_client.dart` to `lib/infrastructure/exchange_rate/`
14. Add `exchange_rate_cache_service.dart` to `lib/infrastructure/exchange_rate/`

Gate: unit tests with injected `MockClient` — cache-hit path (no network call), cache-miss path (API called + DAO upserted + rate returned), offline-fallback path (API throws → latest cached row returned), privacy check (no device ID / user ID in HTTP request).

### Phase D — Application Use Cases

15. Add `get_exchange_rate_use_case.dart` to `lib/application/currency/`
16. Add `resolve_rate_for_date_use_case.dart` to `lib/application/currency/`
17. Add `repository_providers.dart` Riverpod wiring to `lib/application/currency/`

Gate: unit tests with mocked `ExchangeRateRepository` and `ExchangeRateCacheService` — fresh fetch, offline fallback with `RateResult.fallback`, manual override pass-through.

### Phase E — Voice Parser Extensions (parallel with F)

18. Extend `VoiceCurrencySuffixes.all` with new multi-language currency tokens
19. Add `_extractCurrencyCode` to `ParseVoiceInputUseCase`; add static `_currencyTokenToIso` map
20. Add `detectedCurrency` field to `VoiceParseResult` Freezed model; run `build_runner`
21. Wire `VoiceInputScreen` to pass `detectedCurrency` as `initialCurrency` in form config

Gate: extend voice corpus tests — `「50ドル」` → `{amount: 50, detectedCurrency: 'USD'}`, `「五十美元」` → `{amount: 50, detectedCurrency: 'USD'}`, `「1000円」` → `{amount: 1000, detectedCurrency: null}`.

### Phase F — Presentation (parallel with E, requires A-D)

22. Add `onCurrencyTap` callback to `SmartKeyboard`
23. Add `currency_selector_sheet.dart` (common + full ISO + search)
24. Add four currency state fields to `TransactionDetailsFormState`
25. Add converted-preview row to `TransactionDetailsForm.build`
26. Wire rate fetch on date-change and currency-change callbacks
27. Extend `TransactionDetailsFormConfig.$new` with `initialCurrency` / `initialOriginalAmount`
28. Update `ManualOneStepScreen` to pass `onCurrencyTap` and handle currency state
29. Add read-only currency info row to `TransactionDetailsForm` edit mode
30. Add foreign-currency annotation subtitle to `ListTransactionTile`

Gate: golden tests for keypad (tappable currency cell), form (converted-preview row in ja/zh/en × light/dark), list tile (annotation variant). Integration smoke test: manual flow saves USD 50 at rate 148.30, `amount = 7415`, `original_currency = 'USD'`, `original_amount = 50.0`, `conversion_rate = 148.30`.

---

## Component Boundaries Summary

| New Component | Layer | Communicates With |
|---|---|---|
| `ExchangeRateApiClient` | infrastructure/exchange_rate | `http.Client` (external), no app imports |
| `ExchangeRateCacheService` | infrastructure/exchange_rate | `ExchangeRateDao` (injected), `ExchangeRateApiClient` |
| `ExchangeRates` table | data/tables | `AppDatabase` |
| `ExchangeRateDao` | data/daos | `AppDatabase`, `ExchangeRates` table |
| `ExchangeRateRepositoryImpl` | data/repositories | `ExchangeRateDao`, `ExchangeRate` Freezed model |
| `ExchangeRate` Freezed model | features/currency/domain/models | (pure data, no imports) |
| `ExchangeRateRepository` interface | features/currency/domain/repositories | `ExchangeRate` model |
| `GetExchangeRateUseCase` | application/currency | `ExchangeRateCacheService` (injected), `ExchangeRateRepository` |
| `ResolveRateForDateUseCase` | application/currency | `ExchangeRateRepository` |
| `CurrencySelectorSheet` | features/accounting/presentation/widgets | static ISO list constant, `AppPalette` |

---

## Data Flow: Foreign-Currency Transaction Save

```
User taps currency cell on SmartKeyboard
  → SmartKeyboard.onCurrencyTap → ManualOneStepScreen._openCurrencySelector()
    → showModalBottomSheet(CurrencySelectorSheet)
    → returns 'USD'
  → form setState: _originalCurrency = 'USD'
  → form triggers GetExchangeRateUseCase.execute(date: _date, currency: 'USD')
      → ExchangeRateCacheService.getRate(date, 'USD')
          ├── ExchangeRateDao.findRate() → HIT → return cached ExchangeRate
          └── MISS → ExchangeRateApiClient.fetchRate() → ExchangeRateDao.upsertRate()
      → returns ExchangeRate(rate: 148.30)
  → form setState: _conversionRate = 148.30, _rateFetchPending = false
  → preview row renders: "USD  50  ×  148.30  =  ¥7,415"

User taps Save
  → TransactionDetailsFormState.submit()
  → jpyAmount = (_originalAmount × _conversionRate).round()  // 50 × 148.30 = 7415
  → CreateTransactionParams(
       amount: 7415,                // JPY canonical amount
       originalCurrency: 'USD',
       originalAmount: 50.0,
       conversionRate: 148.30,
       ...)
  → CreateTransactionUseCase.execute(params)
  → Transaction persisted: amount=7415, original_currency='USD',
      original_amount=50.0, conversion_rate=148.30
  → TransactionChangeTracker.trackCreate(TransactionSyncMapper.toCreateOperation(...))
      // toSyncMap emits 'originalCurrency', 'originalAmount', 'conversionRate'
      // because all three are non-null
  → SyncEngine.onTransactionChanged() → debounced push
```

---

## Architecture Constraints Verified

| Constraint | v1.7 Status |
|---|---|
| `import_guard`: infrastructure denies features/application/data | `exchange_rate/` inherits via `inherit: true` — compliant |
| `import_guard`: application denies `data/tables/**` and `data/daos/**` | Currency use cases go through repository interface only — compliant |
| `import_guard`: data denies application/presentation | `ExchangeRateRepositoryImpl` imports only DAO and domain model — compliant |
| "ALL tables in `lib/data/tables/`" rule | `ExchangeRates` in `lib/data/tables/` — compliant |
| "ALL DAOs in `lib/data/daos/`" rule | `ExchangeRateDao` in `lib/data/daos/` — compliant |
| "ALL repository impls in `lib/data/repositories/`" rule | `ExchangeRateRepositoryImpl` in `lib/data/repositories/` — compliant |
| "Thin Feature" rule: `features/` holds only domain models + repo interfaces + presentation | `lib/features/currency/domain/` has only model + interface — compliant |
| Riverpod: ONE `repository_providers.dart` per feature | `lib/application/currency/repository_providers.dart` is the single wiring point — compliant |
| Freezed immutability: always `copyWith`, never mutate | Three new `Transaction` fields are nullable Freezed fields — compliant |
| Privacy: no user data in outbound API calls | `ExchangeRateApiClient` sends only date string + currency code — compliant |
| AppInitializer: no eager initialization of optional services | Rate fetch is lazy, provider-driven — compliant |
| Schema migration pattern: explicit `CREATE INDEX` | Exchange_rates index emitted explicitly in `onCreate` + `onUpgrade` — compliant |
| Hash chain integrity: `amount` column is the canonical JPY value | `amount` untouched; three new columns are additive — compliant |

---

## Sources

All conclusions from direct source inspection (2026-06-12):

- `lib/data/tables/transactions_table.dart` — column types, nullability conventions, `customIndices` decorative (no-op), explicit `CREATE INDEX` required. HIGH confidence.
- `lib/data/app_database.dart` — `schemaVersion = 20`, migration pattern (`from < N` blocks), `customStatement` vs `migrator.addColumn` choice for columns with constraints. HIGH confidence.
- `lib/infrastructure/sync/relay_api_client.dart` — domain-specific subdirectory pattern, `http.Client` injectable constructor, `http ^1.6.0` already in pubspec. HIGH confidence.
- `lib/infrastructure/import_guard.yaml` — denies `features/**`, `application/**`, `data/**`; `inherit: true` propagates to new subdirectories. HIGH confidence.
- `lib/application/import_guard.yaml` — denies `data/tables/**`, `data/daos/**`, `features/*/presentation/**`. HIGH confidence.
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — `if (x != null)` conditional emit pattern, `as T?` null-safe reads, D-09 backward-compat `entrySource` fallback. HIGH confidence.
- `lib/features/accounting/domain/models/transaction.dart` — Freezed field list, nullable field conventions. HIGH confidence.
- `lib/application/accounting/create_transaction_use_case.dart` — `CreateTransactionParams` fields; `required this.entrySource` precedent for required-no-default pattern. HIGH confidence.
- `lib/application/family_sync/transaction_change_tracker.dart` — in-memory tracker, `flush()` returns-and-clears. No changes needed. HIGH confidence.
- `lib/application/family_sync/apply_sync_operations_use_case.dart` — `switch (entityType)` branching; `fromSyncMap` is the full mapper boundary; extra keys silently dropped. No changes needed. HIGH confidence.
- `lib/infrastructure/voice/chinese_numeral_state_machine.dart` + `numeral_state_machine.dart` — Step 5 drops unrecognized characters; currency words become `Skip` tokens. State machines unchanged. HIGH confidence.
- `lib/application/voice/voice_text_parser.dart` — `VoiceCurrencySuffixes.regexAlternation` drives `_extractArabicAmount`; extending the suffix list extends the regex automatically. HIGH confidence.
- `lib/shared/constants/voice_currency_suffixes.dart` — longest-first ordering invariant documented; extension point is well-defined. HIGH confidence.
- `lib/data/daos/analytics_dao.dart` — all SUM/ORDER BY queries use `amount` column only; three new columns are invisible to all analytics paths. HIGH confidence.
- `lib/features/accounting/presentation/widgets/smart_keyboard.dart` — `currencyLabel`/`currencySymbol` are static display params; `_CurrencyKey` is private widget; `onCurrencyTap` callback addition is minimal. HIGH confidence.
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` — local state pattern (`_amount`, `_date`, etc. as `late` instance fields + `setState`); `TransactionDetailsFormConfig.$new(...)` extensible. HIGH confidence.
- `lib/core/initialization/app_initializer.dart` — `KeyManager → Database → others`; no rate fetch at boot. HIGH confidence.

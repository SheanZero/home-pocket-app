# Phase 41: Exchange Rate Service - Pattern Map

**Mapped:** 2026-06-12
**Files analyzed:** 10 new/modified files
**Analogs found:** 10 / 10

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart` | service (infrastructure) | request-response | `lib/infrastructure/sync/relay_api_client.dart` | role-match (same HTTP client constructor pattern, same `kDebugMode` logging guard, same `http.Client` injection) |
| `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart` | service (infrastructure) | CRUD + event-driven | `lib/data/repositories/exchange_rate_repository_impl.dart` + `relay_api_client.dart` | role-match (composes repository + HTTP client; mirrors `_normalizeToUtcMidnight` pattern) |
| `lib/application/currency/get_exchange_rate_use_case.dart` | use case (application) | request-response | `lib/application/accounting/get_transactions_use_case.dart` | exact (params struct + `Result<T>` return + single repo dependency) |
| `lib/application/currency/rate_result.dart` | model (domain-adjacent) | — | `lib/shared/utils/result.dart` + Research sealed-class pattern | partial-match (sealed class instead of `Result<T>`; no existing sealed-class analog) |
| `lib/features/currency/domain/repositories/exchange_rate_repository.dart` | repository (domain interface) | CRUD | self (additive extension of existing Phase 40 file) | exact (same file, add 2 methods) |
| `lib/data/daos/exchange_rate_dao.dart` | DAO (data) | CRUD | self (additive extension of existing Phase 40 file) | exact (same file, add 2 Drift query methods) |
| `lib/data/repositories/exchange_rate_repository_impl.dart` | repository impl (data) | CRUD | self (additive extension of existing Phase 40 file) | exact (same file, add 2 delegation methods + `_normalizeToUtcMidnight` pattern) |
| `lib/features/settings/domain/models/backup_data.dart` | model (domain) | — | self (additive extension of Phase 40 `@freezed` model) | exact (same file, add `exchangeRates` field with `@Default`) |
| `lib/application/settings/export_backup_use_case.dart` | use case (application) | file-I/O | self (additive extension of Phase 40 use case) | exact (same file, add exchange-rate fetch + serialize step to existing pattern) |
| `lib/application/settings/import_backup_use_case.dart` | use case (application) | file-I/O | self (additive extension of Phase 40 use case) | exact (same file, add exchange-rate upsert loop to `_restoreData`) |

---

## Pattern Assignments

### `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart`
**Role:** infrastructure service — stateless HTTP wrapper
**Analog:** `lib/infrastructure/sync/relay_api_client.dart`

**Imports pattern** (lines 1–8 of relay_api_client.dart):
```dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
```
Note: No `KeyManager` or `crypto` imports needed — ExchangeRateApiClient is unauthenticated.

**Injectable client constructor pattern** (relay_api_client.dart lines 54–61):
```dart
class RelayApiClient {
  RelayApiClient({
    required this.baseUrl,
    required RequestSigner signer,
    http.Client? httpClient,
  }) : _signer = signer,
       _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
```
Copy this constructor shape exactly — `http.Client? httpClient` with `?? http.Client()` fallback. This is the injectable-for-testing pattern used throughout the project.

**kDebugMode logging guard pattern** (relay_api_client.dart lines 286–298):
```dart
void _logRequest(String method, String path, String body) {
  if (kDebugMode) {
    debugPrint('[RelayAPI] request prepared: $method');
  }
}

void _logResponse(String method, String path, http.Response response) {
  if (kDebugMode) {
    debugPrint(
      '[RelayAPI] response received: $method ${response.statusCode}',
    );
  }
}
```
Apply same guard for ExchangeRateApiClient. Per security requirement: log only `[RateCache] USD rate fetched` without the date in release mode; include date only under `kDebugMode`.

**HTTP GET + response parsing pattern** (relay_api_client.dart lines 300–318 and 385–410):
```dart
Future<http.Response> _get(String path, {bool authenticated = true}) async {
  _logRequest('GET', path, '');
  final url = Uri.parse('$baseUrl$path');
  final headers = <String, String>{'Content-Type': 'application/json'};
  final response = await _httpClient.get(url, headers: headers);
  _logResponse('GET', path, response);
  return response;
}

Map<String, dynamic> _parseResponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  // ... error path
}
```
ExchangeRateApiClient uses a simpler version: no auth headers, but same `Uri.parse`, same `jsonDecode`, same `statusCode` check. Timeout is applied via `http.get(...).timeout(const Duration(milliseconds: 1500))`.

**Error/exception class pattern** (relay_api_client.dart lines 414–432):
```dart
class RelayApiException implements Exception {
  const RelayApiException({
    required this.statusCode,
    required this.message,
    this.code,
  });
  final int statusCode;
  final String message;
  final String? code;
  bool get isNotFound => statusCode == 404;
  @override
  String toString() => 'RelayApiException($statusCode): $message';
}
```
Define an analogous `ExchangeRateApiException` in the same file — or reuse a simpler exception, since callers only care about "fetch failed" vs "currency not in this source (404)".

---

### `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart`
**Role:** infrastructure service — cache-first orchestration
**Analog:** `lib/data/repositories/exchange_rate_repository_impl.dart` (repository composition pattern) + `relay_api_client.dart` (HTTP client injection pattern)

**Constructor/dependency injection pattern** (exchange_rate_repository_impl.dart lines 13–16):
```dart
class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  ExchangeRateRepositoryImpl({required ExchangeRateDao dao}) : _dao = dao;
  final ExchangeRateDao _dao;
```
Mirror for cache service:
```dart
class ExchangeRateCacheService {
  ExchangeRateCacheService({
    required ExchangeRateRepository repository,
    required ExchangeRateApiClient apiClient,
    // connectivity_plus Connectivity instance — injectable for tests
    Connectivity? connectivity,
  }) : _repository = repository,
       _apiClient = apiClient,
       _connectivity = connectivity ?? Connectivity();
```

**`_normalizeToUtcMidnight` pattern** (exchange_rate_repository_impl.dart lines 51–55):
```dart
DateTime _normalizeToUtcMidnight(DateTime d) {
  final utc = d.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}
```
Copy verbatim into `ExchangeRateCacheService` — "today" is device local date, but all DB comparisons use UTC midnight (consistent with the existing repository contract).

**In-memory cooldown state pattern** (no direct analog — use simple field):
```dart
// D-06: in-memory only, no persistence needed
DateTime? _cooldownUntil;
bool get _inCooldown =>
    _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);
```

**D-03 correctable proxy guard** (see RESEARCH.md Pitfall 4):
```dart
bool _isCorrectableProxy(ExchangeRate row) {
  // Only re-fetch once per day: guard by fetchedAt < today
  final today = _normalizeToUtcMidnight(DateTime.now());
  return row.actualRateDate != null &&
      row.rateDate.isBefore(today) &&
      row.fetchedAt.isBefore(today);
}
```

---

### `lib/application/currency/get_exchange_rate_use_case.dart`
**Role:** application use case
**Analog:** `lib/application/accounting/get_transactions_use_case.dart`

**Params struct + use case constructor pattern** (get_transactions_use_case.dart lines 1–32):
```dart
class GetTransactionsParams {
  final String bookId;
  final LedgerType? ledgerType;
  // ...
  const GetTransactionsParams({required this.bookId, ...});
}

class GetTransactionsUseCase {
  GetTransactionsUseCase({required TransactionRepository transactionRepository})
    : _transactionRepo = transactionRepository;
  final TransactionRepository _transactionRepo;

  Future<Result<List<Transaction>>> execute(GetTransactionsParams params) async {
    if (params.bookId.isEmpty) {
      return Result.error('bookId must not be empty');
    }
    // ...
    return Result.success(transactions);
  }
}
```
Mirror for Phase 41 with `RateResult` as the return type instead of `Result<T>`:
```dart
class GetExchangeRateParams {
  final String currency;
  final DateTime date;
  final String? previousRate;      // for ADR-022 >1% delta check
  final bool wasManualOverride;    // ADR-022 D-02 guard
  const GetExchangeRateParams({
    required this.currency,
    required this.date,
    this.previousRate,
    this.wasManualOverride = false,
  });
}

class GetExchangeRateUseCase {
  GetExchangeRateUseCase({required ExchangeRateCacheService cacheService})
    : _cacheService = cacheService;
  final ExchangeRateCacheService _cacheService;

  Future<RateResult> execute(GetExchangeRateParams params) async { ... }
}
```

**Imports pattern** (get_transactions_use_case.dart lines 1–4):
```dart
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../shared/utils/result.dart';
```
For GetExchangeRateUseCase: import `exchange_rate_cache_service.dart` (infrastructure layer — the use case depends on the service interface, not the repository directly), plus `rate_result.dart`.

---

### `lib/application/currency/rate_result.dart`
**Role:** sealed class (domain-adjacent value object)
**Analog:** `lib/shared/utils/result.dart` (closest structural analog — simple discriminated union)

**`Result<T>` shape** (result.dart lines 1–19):
```dart
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({this.data, this.error, required this.isSuccess});
  factory Result.success(T? data) => Result._(data: data, isSuccess: true);
  factory Result.error(String message) => Result._(error: message, isSuccess: false);
  bool get isError => !isSuccess;
}
```
`RateResult` uses Dart `sealed` keyword instead of a single class with flags — this gives exhaustive `switch` pattern matching:
```dart
sealed class RateResult {
  const RateResult();
}
final class RateFetched extends RateResult { ... }
final class RateCached extends RateResult { ... }
final class RateFallback extends RateResult { ... }
final class RateManual extends RateResult { ... }
final class RateUnavailable extends RateResult { ... }
```
Do NOT use `@freezed` here — Freezed sealed union syntax is more complex and these are simple immutable value objects with `const` constructors. The `sealed` keyword + `final class` subclasses matches RESEARCH.md Pattern 2 exactly.

---

### `lib/features/currency/domain/repositories/exchange_rate_repository.dart` (extend)
**Role:** domain repository interface (additive extension)
**Analog:** self — same file pattern

**Existing interface** (exchange_rate_repository.dart lines 1–18, full file):
```dart
abstract class ExchangeRateRepository {
  Future<ExchangeRate?> findByDate(String currency, DateTime date);
  Future<ExchangeRate?> findLatest(String currency);
  Future<void> upsert(ExchangeRate rate);
}
```
Add two methods (RESEARCH.md §Repository Interface Extensions):
```dart
/// Return most-recent cached rate where source != 'manual', or null.
/// D-07: API-cached rows take priority over manual-override rows in fallback.
Future<ExchangeRate?> findLatestNonManual(String currency);

/// Delete all rows where rateDate is strictly before [cutoff].
/// Called on every upsert to enforce 2-year TTL (D-09).
Future<void> deleteOlderThan(DateTime cutoff);
```

---

### `lib/data/daos/exchange_rate_dao.dart` (extend)
**Role:** Drift DAO (additive extension)
**Analog:** self — same file; copy existing method structure

**Existing DAO method pattern** (exchange_rate_dao.dart lines 33–50):
```dart
Future<ExchangeRateRow?> findLatest(String currency) async {
  return (_db.select(_db.exchangeRates)
        ..where((t) => t.currency.equals(currency))
        ..orderBy([(t) => OrderingTerm.desc(t.rateDate)])
        ..limit(1))
      .getSingleOrNull();
}

Future<void> upsert(ExchangeRatesCompanion companion) async {
  await _db.into(_db.exchangeRates).insertOnConflictUpdate(companion);
}
```
Add two new methods following the same Drift query pattern:
```dart
/// D-07: exclude source='manual' rows to find latest API-cached rate.
Future<ExchangeRateRow?> findLatestNonManual(String currency) async {
  return (_db.select(_db.exchangeRates)
        ..where(
          (t) =>
              t.currency.equals(currency) &
              t.source.isNotValue('manual'),
        )
        ..orderBy([(t) => OrderingTerm.desc(t.rateDate)])
        ..limit(1))
      .getSingleOrNull();
}

/// D-09: delete rows where rateDate < cutoff (2-year TTL).
Future<void> deleteOlderThan(DateTime cutoff) async {
  await (_db.delete(_db.exchangeRates)
        ..where((t) => t.rateDate.isSmallerThanValue(cutoff)))
      .go();
}
```
Note: `equalsValue` is used for equality (TypeConverter-aware). For less-than comparison use `.isSmallerThanValue(cutoff)` — check Drift docs for the correct TypeConverter-aware comparator if needed.

---

### `lib/data/repositories/exchange_rate_repository_impl.dart` (extend)
**Role:** repository implementation (additive extension)
**Analog:** self — mirror existing delegation + `_normalizeToUtcMidnight` pattern

**Existing delegation pattern** (exchange_rate_repository_impl.dart lines 19–44):
```dart
@override
Future<ExchangeRate?> findByDate(String currency, DateTime date) async {
  final row = await _dao.findByDate(currency, _normalizeToUtcMidnight(date));
  if (row == null) return null;
  return _toModel(row);
}

@override
Future<void> upsert(ExchangeRate rate) async {
  await _dao.upsert(
    ExchangeRatesCompanion(
      currency: Value(rate.currency),
      rateDate: Value(_normalizeToUtcMidnight(rate.rateDate)),
      rate: Value(rate.rate),
      fetchedAt: Value(rate.fetchedAt),
      source: Value(rate.source),
      actualRateDate: Value(rate.actualRateDate),
    ),
  );
}
```
Add two new `@override` methods following the same delegation pattern:
```dart
@override
Future<ExchangeRate?> findLatestNonManual(String currency) async {
  final row = await _dao.findLatestNonManual(currency);
  if (row == null) return null;
  return _toModel(row);
}

@override
Future<void> deleteOlderThan(DateTime cutoff) async {
  await _dao.deleteOlderThan(_normalizeToUtcMidnight(cutoff));
}
```

---

### `lib/features/settings/domain/models/backup_data.dart` (extend)
**Role:** Freezed domain model (additive extension)
**Analog:** self — same `@freezed` pattern

**Existing `@freezed` factory pattern** (backup_data.dart lines 10–22):
```dart
@freezed
abstract class BackupData with _$BackupData {
  const factory BackupData({
    required BackupMetadata metadata,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> books,
    required Map<String, dynamic> settings,
  }) = _BackupData;

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);
}
```
Add one field using `@Default` for backward-compat (old `.hpb` files without the field deserialize to empty list):
```dart
@Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> exchangeRates,
```
After editing this file: run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `backup_data.freezed.dart` and `backup_data.g.dart`.

---

### `lib/application/settings/export_backup_use_case.dart` (extend)
**Role:** application use case (additive extension)
**Analog:** self — copy the existing pattern for collecting and serializing a repository's data

**Existing data collection + serialization pattern** (export_backup_use_case.dart lines 47–69):
```dart
// 1. Collect all data
final transactions = await _transactionRepo.findAllByBook(bookId);
final categories = await _categoryRepo.findAll();
final books = await _bookRepo.findAll(includeArchived: true, includeShadow: true);
final settings = await _settingsRepo.getSettings();

// 2. Build backup data structure
final backupData = BackupData(
  metadata: BackupMetadata(...),
  transactions: transactions.map((tx) => tx.toJson()).toList(),
  categories: categories.map((cat) => cat.toJson()).toList(),
  books: books.map((book) => book.toJson()).toList(),
  settings: settings.toJson(),
);
```
Add exchange-rate collection in step 1 and serialization in step 2 following the same `.map(...).toList()` shape:
```dart
// In step 1:
final exchangeRates = await _exchangeRateRepo.findAll();  // new findAll method needed on repo

// In step 2 (BackupData constructor):
exchangeRates: exchangeRates.map((er) => {
  'currency': er.currency,
  'rateDate': er.rateDate.millisecondsSinceEpoch ~/ 1000,
  'rate': er.rate,
  'fetchedAt': er.fetchedAt.millisecondsSinceEpoch ~/ 1000,
  'source': er.source,
  if (er.actualRateDate != null)
    'actualRateDate': er.actualRateDate!.millisecondsSinceEpoch ~/ 1000,
}).toList(),
```
Also add `ExchangeRateRepository exchangeRateRepo` to the constructor (same named-parameter pattern as existing repos).

Note: A `findAll()` method (no filter) is also needed on `ExchangeRateRepository` — or use the DAO directly. Prefer adding `Future<List<ExchangeRate>> findAll()` to the repository interface following the same additive extension pattern.

---

### `lib/application/settings/import_backup_use_case.dart` (extend)
**Role:** application use case (additive extension)
**Analog:** self — copy the existing per-entity restore loop pattern

**Existing restore loop pattern** (import_backup_use_case.dart lines 125–158):
```dart
Future<void> _restoreData(BackupData backupData) async {
  // Delete existing data first
  // ...

  // Import books
  for (final bookJson in backupData.books) {
    final book = Book.fromJson(bookJson);
    await _bookRepo.insert(book);
  }

  // Import categories
  for (final catJson in backupData.categories) {
    final category = Category.fromJson(catJson);
    await _categoryRepo.insert(category);
  }

  // Import transactions
  for (final txJson in backupData.transactions) {
    final transaction = Transaction.fromJson(txJson);
    await _transactionRepo.insert(transaction);
  }

  // Import settings
  final settings = AppSettings.fromJson(backupData.settings);
  await _settingsRepo.updateSettings(settings);
}
```
Add exchange-rate restore loop after settings import — use `upsert` (not `insert`) since exchange rates are idempotent by (currency, rateDate) composite key:
```dart
// Import exchange rates (D-10): upsert, not insert — idempotent by composite PK
for (final erJson in backupData.exchangeRates) {
  final er = ExchangeRate(
    currency: erJson['currency'] as String,
    rateDate: DateTime.fromMillisecondsSinceEpoch(
      (erJson['rateDate'] as int) * 1000, isUtc: true),
    rate: erJson['rate'] as String,
    fetchedAt: DateTime.fromMillisecondsSinceEpoch(
      (erJson['fetchedAt'] as int) * 1000, isUtc: true),
    source: erJson['source'] as String,
    actualRateDate: erJson['actualRateDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            (erJson['actualRateDate'] as int) * 1000, isUtc: true)
        : null,
  );
  await _exchangeRateRepo.upsert(er);
}
```
Also add `ExchangeRateRepository exchangeRateRepo` to constructor (same pattern as existing repo params).

---

## Shared Patterns

### Injectable `http.Client` for testing
**Source:** `lib/infrastructure/sync/relay_api_client.dart` lines 54–61
**Apply to:** `ExchangeRateApiClient`, `ExchangeRateCacheService` (via ApiClient injection)
```dart
// Constructor: optional httpClient defaults to real http.Client()
http.Client? httpClient,
// ...
_httpClient = httpClient ?? http.Client();
```
In tests, pass a `MockHttpClient` (mocktail mock of `http.Client`) — see `test/infrastructure/sync/relay_api_client_test.dart` line 14.

### `kDebugMode` logging guard
**Source:** `lib/infrastructure/sync/relay_api_client.dart` lines 286–298
**Apply to:** `ExchangeRateApiClient`, `ExchangeRateCacheService`
```dart
if (kDebugMode) {
  debugPrint('[RateCache] ...only non-sensitive info...');
}
```
Never log the full URL (contains date) in release builds — only log `[RateCache] {CURRENCY} rate fetched` in release, full URL detail only under `kDebugMode`.

### `Result<T>` error channel
**Source:** `lib/shared/utils/result.dart`
**Apply to:** `GetExchangeRateUseCase` — wraps the `RateResult` in a `Result` only for unexpected/fatal errors (connectivity layer, DB crash). The happy-path return is `RateResult` directly (not `Result<RateResult>`). Use `Result.error(...)` only in the outer try/catch of the use case.

### `_normalizeToUtcMidnight` helper
**Source:** `lib/data/repositories/exchange_rate_repository_impl.dart` lines 51–55
**Apply to:** `ExchangeRateCacheService` (for "today" comparison), `ExchangeRateRepositoryImpl` new methods
```dart
DateTime _normalizeToUtcMidnight(DateTime d) {
  final utc = d.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}
```

### Test: mocktail `Mock` class pattern
**Source:** `test/infrastructure/sync/relay_api_client_test.dart` lines 10–15, `test/unit/application/accounting/create_transaction_use_case_test.dart` lines 14–26
**Apply to:** All Phase 41 test files
```dart
class MockExchangeRateRepository extends Mock implements ExchangeRateRepository {}
class MockExchangeRateApiClient extends Mock implements ExchangeRateApiClient {}
class MockHttpClient extends Mock implements http.Client {}

// setUp pattern:
late MockExchangeRateRepository mockRepo;
late SomeUseCase useCase;
setUp(() {
  mockRepo = MockExchangeRateRepository();
  useCase = SomeUseCase(repository: mockRepo);
});
```

### Test: `http.Response` stubbing pattern
**Source:** `test/infrastructure/sync/relay_api_client_test.dart` lines 39–66
**Apply to:** `test/unit/infrastructure/exchange_rate/exchange_rate_api_client_test.dart`
```dart
when(
  () => httpClient.get(
    Uri.parse('https://api.frankfurter.dev/v1/2026-06-11?from=JPY&to=USD'),
    headers: any(named: 'headers'),
  ),
).thenAnswer(
  (_) async => http.Response(
    '{"amount":1.0,"base":"JPY","date":"2026-06-11","rates":{"USD":0.00623}}',
    200,
  ),
);
```

### Backup use case: constructor + `Result<T>` pattern
**Source:** `lib/application/settings/export_backup_use_case.dart` lines 20–45
**Apply to:** Both backup use case extensions
```dart
// Named-parameter constructor for all repositories
ExportBackupUseCase({
  required TransactionRepository transactionRepo,
  required CategoryRepository categoryRepo,
  required BookRepository bookRepo,
  required SettingsRepository settingsRepo,
  // Add:
  required ExchangeRateRepository exchangeRateRepo,
}) : ...

// execute returns Result<File> / Result<void>
Future<Result<File>> execute(...) async {
  try {
    // ...
    return Result.success(file);
  } catch (e) {
    return Result.error('Backup export failed: $e');
  }
}
```

---

## No Analog Found

All files have analogs. The sealed `RateResult` class has only a partial structural analog (`Result<T>`) since no existing sealed class exists in the codebase — use Dart `sealed` keyword per RESEARCH.md Pattern 2 rather than Freezed.

---

## Metadata

**Analog search scope:** `lib/infrastructure/sync/`, `lib/application/accounting/`, `lib/application/settings/`, `lib/data/daos/`, `lib/data/repositories/`, `lib/features/currency/`, `lib/features/settings/domain/models/`, `lib/shared/utils/`, `test/infrastructure/sync/`, `test/unit/application/`
**Files scanned:** 14 source files + 5 test files
**Pattern extraction date:** 2026-06-12

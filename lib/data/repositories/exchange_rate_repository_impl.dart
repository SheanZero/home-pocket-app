import '../app_database.dart';
import '../daos/exchange_rate_dao.dart';

// TODO(40-05): implements ExchangeRateRepository once interface lands
// import '../../features/currency/domain/repositories/exchange_rate_repository.dart';

// TODO(40-05): import ExchangeRate domain model once it lands
// import '../../features/currency/domain/models/exchange_rate.dart';

/// Stub implementation of the exchange rate repository.
///
/// This file is created in Wave 2 (Plan 40-04) to establish the class shape and
/// DAO wiring before the domain interface exists. The interface and Freezed model
/// arrive in Plan 40-05; the [ExchangeRateRepositoryImpl] is connected there.
///
/// **Important constraints for this wave:**
/// - No `implements ExchangeRateRepository` — the interface does not exist yet.
///   Adding it here would cause a compile error. TODO(40-05) marks the upgrade point.
/// - No `@riverpod` provider — providers are Plan 40-05's responsibility.
///   This class is not provider-registered so `provider_graph_hygiene_test.dart`
///   is not affected.
/// - [UnimplementedError] stubs are intentional per the plan spec. They do NOT
///   violate the CLAUDE.md "NEVER throw UnimplementedError in providers" rule
///   because this class is not registered as a Riverpod provider.
class ExchangeRateRepositoryImpl {
  ExchangeRateRepositoryImpl({required ExchangeRateDao dao}) : _dao = dao;

  final ExchangeRateDao _dao;

  // TODO(40-05): remove stub and implement with ExchangeRate Freezed model
  ExchangeRateRow? _toModel(ExchangeRateRow row) {
    throw UnimplementedError('wired in Plan 40-05');
  }

  // TODO(40-05): findByDate(String currency, DateTime date) → Result<ExchangeRate?>
  Future<ExchangeRateRow?> findByDate(String currency, DateTime date) async {
    final row = await _dao.findByDate(currency, date);
    return _toModel(row ?? (throw UnimplementedError('wired in Plan 40-05')));
  }

  // TODO(40-05): findLatest(String currency) → Result<ExchangeRate?>
  Future<ExchangeRateRow?> findLatest(String currency) async {
    final row = await _dao.findLatest(currency);
    return _toModel(row ?? (throw UnimplementedError('wired in Plan 40-05')));
  }

  // TODO(40-05): upsert(ExchangeRate rate) → Result<void>
  Future<void> upsert(ExchangeRatesCompanion companion) async {
    await _dao.upsert(companion);
    throw UnimplementedError('wired in Plan 40-05');
  }
}

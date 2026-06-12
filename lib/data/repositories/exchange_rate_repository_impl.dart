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
/// - Methods pass through to the DAO returning raw rows until the ExchangeRate
///   Freezed model lands in Plan 40-05 (HIGH-06 forbids UnimplementedError in lib/).
class ExchangeRateRepositoryImpl {
  ExchangeRateRepositoryImpl({required ExchangeRateDao dao}) : _dao = dao;

  final ExchangeRateDao _dao;

  // TODO(40-05): findByDate(String currency, DateTime date) → Result<ExchangeRate?>
  Future<ExchangeRateRow?> findByDate(String currency, DateTime date) =>
      _dao.findByDate(currency, date);

  // TODO(40-05): findLatest(String currency) → Result<ExchangeRate?>
  Future<ExchangeRateRow?> findLatest(String currency) =>
      _dao.findLatest(currency);

  // TODO(40-05): upsert(ExchangeRate rate) → Result<void>
  Future<void> upsert(ExchangeRatesCompanion companion) =>
      _dao.upsert(companion);
}

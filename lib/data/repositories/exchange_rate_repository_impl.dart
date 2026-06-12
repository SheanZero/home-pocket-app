import 'package:drift/drift.dart';

import '../app_database.dart';
import '../daos/exchange_rate_dao.dart';
import '../../features/currency/domain/models/exchange_rate.dart';
import '../../features/currency/domain/repositories/exchange_rate_repository.dart';

/// Concrete implementation of [ExchangeRateRepository].
///
/// Bridges the [ExchangeRateDao] (Drift row access) to the domain interface
/// (pure-Dart [ExchangeRate] model). All Drift types are contained here —
/// the domain layer never sees them.
class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  ExchangeRateRepositoryImpl({required ExchangeRateDao dao}) : _dao = dao;

  final ExchangeRateDao _dao;

  @override
  Future<ExchangeRate?> findByDate(String currency, DateTime date) async {
    final row = await _dao.findByDate(currency, date);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<ExchangeRate?> findLatest(String currency) async {
    final row = await _dao.findLatest(currency);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<void> upsert(ExchangeRate rate) async {
    await _dao.upsert(
      ExchangeRatesCompanion(
        currency: Value(rate.currency),
        rateDate: Value(rate.rateDate),
        rate: Value(rate.rate),
        fetchedAt: Value(rate.fetchedAt),
        source: Value(rate.source),
        actualRateDate: Value(rate.actualRateDate),
      ),
    );
  }

  /// Map an [ExchangeRateRow] (Drift) to an [ExchangeRate] domain model.
  ExchangeRate _toModel(ExchangeRateRow row) {
    return ExchangeRate(
      currency: row.currency,
      rateDate: row.rateDate,
      rate: row.rate,
      fetchedAt: row.fetchedAt,
      source: row.source,
      actualRateDate: row.actualRateDate,
    );
  }
}

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
    final row = await _dao.findByDate(currency, _normalizeToUtcMidnight(date));
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
        rateDate: Value(_normalizeToUtcMidnight(rate.rateDate)),
        rate: Value(rate.rate),
        fetchedAt: Value(rate.fetchedAt),
        source: Value(rate.source),
        actualRateDate: Value(rate.actualRateDate),
      ),
    );
  }

  @override
  Future<ExchangeRate?> findLatestNonManual(String currency) async {
    // No date normalization — this is a source-filtered latest lookup, not a
    // composite-key lookup (D-07).
    final row = await _dao.findLatestNonManual(currency);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<void> deleteOlderThan(DateTime cutoff) async {
    await _dao.deleteOlderThan(_normalizeToUtcMidnight(cutoff));
  }

  @override
  Future<List<ExchangeRate>> findAll() async {
    final rows = await _dao.findAll();
    return rows.map(_toModel).toList();
  }

  /// Normalizes [d] to the canonical composite-key date: its LOCAL calendar
  /// Y/M/D stamped as UTC midnight (WR-06). Without this, a local-zone or
  /// non-midnight DateTime produces a different epoch second than
  /// DateTime.utc(y, m, d), causing silent cache misses on lookup and
  /// near-duplicate rows on upsert.
  ///
  /// CR-02: uses local Y/M/D (NOT `d.toUtc()` first) so the key agrees with
  /// the API URL date and the transaction date picker — see
  /// ExchangeRateCacheService._normalizeToUtcMidnight.
  DateTime _normalizeToUtcMidnight(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);

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

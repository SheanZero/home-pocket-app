import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/exchange_rates_table.dart';

/// Data access object for the ExchangeRates table.
///
/// Provides findByDate (composite-key lookup), findLatest (most-recent row
/// per currency), and upsert (insertOnConflictUpdate) operations.
///
/// All arithmetic on the rate string must be done via double.parse() at
/// the call site — the rate field is TEXT (ADR-020 D-04) for full precision.
class ExchangeRateDao {
  ExchangeRateDao(this._db);

  final AppDatabase _db;

  /// Return the rate row for [currency] on [date], or null if not found.
  ///
  /// Composite key lookup: (currency, rateDate).
  ///
  /// Uses [GeneratedColumnWithTypeConverter.equalsValue] on [rateDate] because
  /// rateDate uses a TypeConverter (UtcEpochDateTimeConverter) and the plain
  /// [equals] method takes the SQL int type, not DateTime.
  Future<ExchangeRateRow?> findByDate(String currency, DateTime date) async {
    return (_db.select(_db.exchangeRates)
          ..where(
            (t) =>
                t.currency.equals(currency) & t.rateDate.equalsValue(date),
          ))
        .getSingleOrNull();
  }

  /// Return the most-recent row for [currency], or null if table is empty.
  ///
  /// Ordered by rateDate DESC, limit 1.
  Future<ExchangeRateRow?> findLatest(String currency) async {
    return (_db.select(_db.exchangeRates)
          ..where((t) => t.currency.equals(currency))
          ..orderBy([(t) => OrderingTerm.desc(t.rateDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Insert or update a row by composite primary key (currency, rateDate).
  ///
  /// On conflict (same currency + rateDate), all columns are overwritten
  /// with the new companion values (rate, fetchedAt, source, actualRateDate).
  Future<void> upsert(ExchangeRatesCompanion companion) async {
    await _db.into(_db.exchangeRates).insertOnConflictUpdate(companion);
  }

  /// Return the most-recent row for [currency] where source != 'manual',
  /// or null if no non-manual row exists.
  ///
  /// D-07: API-cached rows take priority over manual-override rows in the
  /// offline fallback path. Ordered by rateDate DESC, limit 1.
  Future<ExchangeRateRow?> findLatestNonManual(String currency) async {
    return (_db.select(_db.exchangeRates)
          ..where(
            (t) =>
                t.currency.equals(currency) & t.source.isNotValue('manual'),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.rateDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Delete all rows where rateDate is strictly before [cutoff].
  ///
  /// D-09: enforces the 2-year TTL. rateDate uses a TypeConverter
  /// (UtcEpochDateTimeConverter) so the column's comparison operators take the
  /// SQL int type, not DateTime — we convert the cutoff to its epoch-second
  /// representation with the same converter before comparing.
  Future<void> deleteOlderThan(DateTime cutoff) async {
    const converter = UtcEpochDateTimeConverter();
    final cutoffEpoch = converter.toSql(cutoff);
    await (_db.delete(_db.exchangeRates)
          ..where((t) => t.rateDate.isSmallerThanValue(cutoffEpoch)))
        .go();
  }

  /// Return all rows, unfiltered.
  ///
  /// D-10: used by the backup export to serialize the full rate cache.
  Future<List<ExchangeRateRow>> findAll() async {
    return _db.select(_db.exchangeRates).get();
  }
}

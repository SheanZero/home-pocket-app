import 'package:drift/drift.dart';

import '../app_database.dart';

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
}

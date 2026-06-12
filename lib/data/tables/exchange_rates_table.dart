import 'package:drift/drift.dart';

/// TypeConverter that stores DateTime as epoch seconds (INTEGER) and always
/// returns a UTC DateTime on read.
///
/// Drift's default DateTimeColumn uses epoch seconds but returns local DateTimes.
/// This converter ensures UTC round-trip so that DateTime.utc(...) comparisons
/// in tests and application code are correct (exchange_rate_dao_test.dart contract).
class UtcEpochDateTimeConverter extends TypeConverter<DateTime, int> {
  const UtcEpochDateTimeConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb * 1000, isUtc: true);

  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
}

/// Exchange rates cache table — stores fetched rates keyed by (currency, rateDate).
///
/// This table caches external API-fetched rates locally (per D-09). Rates are
/// stored as TEXT (TextColumn) throughout — including the `rate` field — for
/// consistent full-precision round-trip (ADR-020 stores rate strings in both the
/// cache table and transactions.applied_rate to avoid double/float precision drift).
///
/// NOTE: customIndices is DECORATIVE (v1.6 CR-01 lesson). Index created explicitly
/// via _createExchangeRateIndexes() in AppDatabase.
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  /// ISO 4217 currency code (e.g. "USD", "CNY").
  TextColumn get currency => text()();

  /// The date this rate applies to (UTC midnight).
  ///
  /// Stored as epoch seconds (INTEGER). Uses [UtcEpochDateTimeConverter] to
  /// return a UTC DateTime on read — Drift's default dateTime() returns local
  /// time from epoch seconds, but the DAO test contract uses DateTime.utc(...).
  Column<int> get rateDate =>
      integer().map(const UtcEpochDateTimeConverter())();

  /// Exchange rate as a string literal (e.g. "157.3421") — TextColumn for full
  /// precision (ADR-020 D-04). Use double.parse(rate) for arithmetic.
  TextColumn get rate => text()();

  /// UTC timestamp when this rate was fetched from the external API.
  DateTimeColumn get fetchedAt => dateTime()();

  /// Source identifier for the rate (e.g. "frankfurter", "manual").
  TextColumn get source => text()();

  /// The actual date the API reported for this rate (may differ from rateDate
  /// on weekends/holidays). Nullable — null means rateDate is the actual date.
  DateTimeColumn get actualRateDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {currency, rateDate};

  // Index declarations (no @override — CLAUDE.md pitfall #11). NOTE: Drift's
  // migrator does NOT consume this getter; the index is created explicitly in
  // AppDatabase._createExchangeRateIndexes() (onCreate + onUpgrade). Keep this
  // list and that method in sync.
  List<TableIndex> get customIndices => [
    TableIndex(
      name: 'idx_exchange_rates_currency_date',
      columns: {#currency, #rateDate},
    ),
  ];
}

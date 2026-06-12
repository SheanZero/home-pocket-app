import 'package:drift/drift.dart';

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

  /// The date this rate applies to (UTC, time component is midnight).
  DateTimeColumn get rateDate => dateTime()();

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

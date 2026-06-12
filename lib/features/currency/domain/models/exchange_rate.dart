import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_rate.freezed.dart';

/// Immutable domain model representing a cached exchange rate entry.
///
/// Fields mirror the v21 `exchange_rates` Drift table column set (D-09).
/// No Drift or Flutter imports — this is a pure domain type.
///
/// The [rate] field is stored as [String] throughout the stack (ADR-020 D-04)
/// to prevent float precision drift. All arithmetic goes through
/// [convertToJpy] in `lib/shared/utils/currency_conversion.dart`.
@freezed
abstract class ExchangeRate with _$ExchangeRate {
  const ExchangeRate._();

  const factory ExchangeRate({
    /// ISO 4217 currency code (e.g. "USD", "CNY", "EUR").
    required String currency,

    /// The date this rate applies to (UTC midnight).
    required DateTime rateDate,

    /// Exchange rate as a full-precision string (e.g. "157.3421" JPY per 1 unit).
    ///
    /// Stored and transmitted as a string literal to avoid double precision loss
    /// (ADR-020). Use [double.parse] only inside [convertToJpy].
    required String rate,

    /// UTC timestamp when this rate was fetched from the external API.
    required DateTime fetchedAt,

    /// Source identifier for the rate provider.
    ///
    /// Examples: "frankfurter", "fawazahmed0", "manual".
    required String source,

    /// The actual date the API reported for this rate.
    ///
    /// Non-null when the target date was a weekend or holiday and the API
    /// returned the nearest available rate from a different date.
    /// Null when [rateDate] is the actual date.
    DateTime? actualRateDate,
  }) = _ExchangeRate;
}

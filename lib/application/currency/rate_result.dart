/// Runtime-only discriminated union for all exchange-rate fetch/cache outcomes.
///
/// Uses Dart `sealed` + `final class` subclasses (not `@freezed`) — these are
/// simple immutable value objects with `const` constructors, and the sealed
/// keyword gives exhaustive `switch` pattern matching for the consuming
/// `GetExchangeRateUseCase` (Plan 04) and `ExchangeRateCacheService` (Plan 04).
///
/// Rate strings are full-precision (ADR-020): the rate is stored/passed as a
/// `String`, never a `double`, to prevent preview-vs-stored divergence.
///
/// Variant names follow RESEARCH.md Pattern 2.
library;

/// Base type for every exchange-rate outcome.
sealed class RateResult {
  const RateResult();
}

/// Fresh rate fetched from an external API.
final class RateFetched extends RateResult {
  const RateFetched({
    required this.rate,
    required this.currency,
    required this.rateDate,
    this.actualDate,
    required this.source,
  });

  /// Full-precision JPY-per-unit rate string (ADR-020).
  final String rate;

  /// ISO 4217 currency code.
  final String currency;

  /// The date the rate was requested for.
  final DateTime rateDate;

  /// Non-null when the API returned a rate for a different date than requested
  /// (weekend/holiday surfacing — RATE-05).
  final DateTime? actualDate;

  /// Originating source: 'frankfurter' | 'fawazahmed0'.
  final String source;
}

/// Exact-date cache hit (no network call required).
final class RateCached extends RateResult {
  const RateCached({
    required this.rate,
    required this.currency,
    required this.cachedDate,
    required this.source,
    this.isManualOverride = false,
  });

  /// Full-precision JPY-per-unit rate string (ADR-020).
  final String rate;

  /// ISO 4217 currency code.
  final String currency;

  /// The date the cached rate is keyed to.
  final DateTime cachedDate;

  /// Originating source of the cached row.
  final String source;

  /// True when this cache row is a user manual override (ADR-022 D-02).
  final bool isManualOverride;
}

/// Offline fallback — most-recent API-cached row when the requested date is
/// unavailable and no network is reachable.
final class RateFallback extends RateResult {
  const RateFallback({
    required this.rate,
    required this.currency,
    required this.cachedDate,
  });

  /// Full-precision JPY-per-unit rate string (ADR-020).
  final String rate;

  /// ISO 4217 currency code.
  final String currency;

  /// The date the fallback rate is keyed to — staleness indicator (RATE-03).
  final DateTime cachedDate;
}

/// Manual-only fallback (D-07 lowest priority) — the only available cached row
/// is a user manual override.
final class RateManual extends RateResult {
  const RateManual({
    required this.rate,
    required this.currency,
    required this.cachedDate,
  });

  /// Full-precision JPY-per-unit rate string (ADR-020).
  final String rate;

  /// ISO 4217 currency code.
  final String currency;

  /// The date the manual rate is keyed to.
  final DateTime cachedDate;
}

/// No rate available at all (D-08) — neither network nor cache produced a value.
final class RateUnavailable extends RateResult {
  const RateUnavailable({required this.currency});

  /// ISO 4217 currency code the lookup failed for.
  final String currency;
}

/// Base type for UI signals attached to a [RateResult] by the use case layer.
///
/// Kept separate from [RateResult] so the rate variants stay focused on the
/// rate value, while [GetExchangeRateUseCase] can attach ADR-022 signals via
/// [RateResultWithSignal].
sealed class RateSignal {
  const RateSignal();
}

/// Prompt the user to confirm a changed rate via a dialog (ADR-022 D-02).
final class RateSignalDialog extends RateSignal {
  const RateSignalDialog({
    required this.currency,
    required this.oldRate,
    required this.newRate,
  });

  /// ISO 4217 currency code.
  final String currency;

  /// The rate string the user previously had.
  final String oldRate;

  /// The freshly fetched rate string.
  final String newRate;
}

/// Surface a non-blocking toast about a >1% rate change (ADR-022 D-03).
///
/// WR-01: carries the actual full-precision RATE strings (ADR-020) and the
/// fractional change, NOT rounded int "JPY amounts". The previous design
/// rounded sub-1 rates (e.g. 0.0062) to 0, rendering a meaningless "0 → 0"
/// toast. Phase 42 computes the JPY-equivalent delta from these rates + the
/// transaction amount it owns; the use case does not receive the amount.
final class RateSignalToast extends RateSignal {
  const RateSignalToast({
    required this.oldRate,
    required this.newRate,
    required this.changeFraction,
  });

  /// The rate string the user previously had (JPY-per-unit, ADR-020).
  final String oldRate;

  /// The freshly resolved rate string (JPY-per-unit, ADR-020).
  final String newRate;

  /// Absolute fractional change `|new - old| / old` (e.g. 0.023 for +2.3%).
  /// Always > 0.01 when this signal is emitted (the D-03 threshold).
  final double changeFraction;
}

/// Wrapper pairing a [RateResult] with an optional [RateSignal].
///
/// Lets [GetExchangeRateUseCase] return a rate outcome together with any
/// ADR-022 UI signal without complicating the [RateResult] variants.
final class RateResultWithSignal {
  const RateResultWithSignal({required this.result, this.signal});

  /// The resolved rate outcome.
  final RateResult result;

  /// Optional UI signal (dialog/toast) to surface to the user.
  final RateSignal? signal;
}

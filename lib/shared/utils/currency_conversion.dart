/// Single canonical JPY conversion site per STORE-02 and ADR-020.
///
/// Formula: (originalMinorUnits / subunitToUnit * rate).round()
///
/// [originalMinorUnits]: amount in the currency's minor unit (e.g. cents for USD/EUR,
///   or the main unit for JPY/KRW which have no sub-unit).
/// [appliedRate]: exchange rate as a full-precision string (e.g. "157.3421"),
///   stored in transactions.applied_rate or exchange_rates.rate (TextColumn, ADR-020).
/// [subunitToUnit]: number of minor units per major unit.
///   100 for USD/EUR (cents to dollars/euros), 1 for JPY/KRW (no sub-unit).
///
/// All preview and persist callers MUST use this function.
/// Do NOT call double.parse(appliedRate) inline — that bypasses the single-parse-site
/// guarantee and risks preview/persist divergence (ADR-020 Pitfall 1).
///
/// Fails fast on invalid input (WR-01, Phase 40 review):
/// - throws [ArgumentError] if [subunitToUnit] <= 0 (would yield Infinity,
///   and Infinity.round() throws UnsupportedError) or [originalMinorUnits] < 0
///   (would silently yield a negative JPY amount).
/// - throws [FormatException] if [appliedRate] is not a finite positive number.
int convertToJpy({
  required int originalMinorUnits,
  required String appliedRate,
  required int subunitToUnit,
}) {
  if (subunitToUnit <= 0) {
    throw ArgumentError.value(subunitToUnit, 'subunitToUnit', 'must be > 0');
  }
  if (originalMinorUnits < 0) {
    throw ArgumentError.value(
      originalMinorUnits,
      'originalMinorUnits',
      'must be >= 0',
    );
  }
  final rate = double.tryParse(appliedRate);
  if (rate == null || rate.isNaN || rate.isInfinite || rate <= 0) {
    throw FormatException('invalid appliedRate: "$appliedRate"');
  }
  return (originalMinorUnits / subunitToUnit * rate).round();
}

/// Plain positive decimal literal per ADR-020 D-05: digits with optional
/// fraction — no sign, no exponent (scientific notation rejected), no
/// whitespace (manual input must arrive pre-trimmed).
final _plainDecimalLiteral = RegExp(r'^\d+(\.\d+)?$');

/// Validates [raw] as an appliedRate literal per ADR-020 D-05.
///
/// Returns a human-readable error message, or null when valid.
/// Hosted here so ALL appliedRate parsing stays in this one file
/// (single-parse-site guarantee — do not duplicate this check inline).
String? validateAppliedRate(String raw) {
  if (raw != raw.trim() || !_plainDecimalLiteral.hasMatch(raw)) {
    return 'appliedRate must be a positive number in plain decimal form '
        '(no sign, exponent, or whitespace; ADR-020 D-05)';
  }
  final rate = double.parse(raw);
  if (!rate.isFinite || rate <= 0) {
    return 'appliedRate must be a positive number';
  }
  return null;
}

/// Minor units per major unit for an ISO 4217 currency code.
///
/// JPY/KRW have no sub-unit (D-08); every other code the app handles uses
/// 2 decimals (mirrors NumberFormatter._getCurrencyDecimals). When Phase 41
/// introduces a richer currency metadata source, route this through it.
int subunitToUnitFor(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'JPY':
    case 'KRW':
      return 1;
    default:
      return 100;
  }
}

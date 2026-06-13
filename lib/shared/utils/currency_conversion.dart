import 'dart:math' as math;

import 'package:intl/number_symbols_data.dart' show currencyFractionDigits;

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

/// ISO 4217 minor-unit decimal count for [currencyCode] — the SINGLE
/// authoritative decimals source for the app (used by both the subunit math
/// below and `NumberFormatter._getCurrencyDecimals`).
///
/// Sourced from intl 0.20.2's `currencyFractionDigits` map (the canonical ISO
/// 4217 minor-unit table — e.g. BHD/JOD/KWD=3, JPY=0), with a literal default
/// of 2 only for codes the map omits (intl stores only deviations from 2).
///
/// KRW is kept as an explicit 0-decimal special case (T-42-03): the app's
/// display convention is 0 decimals for KRW, and routing it through the map
/// alone is intentionally not trusted given the documented subunit/ISO
/// mismatch noted in STATE. An unknown / malformed code never throws here —
/// it falls back to the safe default of 2 (T-42-02).
int currencyFractionDigitsFor(String currencyCode) {
  final code = currencyCode.toUpperCase();
  // KRW: locked 0-decimal display convention — do not trust intl for KRW.
  if (code == 'KRW') {
    return 0;
  }
  return currencyFractionDigits[code] ?? currencyFractionDigits['DEFAULT'] ?? 2;
}

/// Minor units per major unit for an ISO 4217 currency code.
///
/// `pow(10, fractionDigits)` from the single decimals source
/// [currencyFractionDigitsFor]: JPY/KRW (0 decimals) → 1, USD/EUR/CNY
/// (2 decimals) → 100, BHD/JOD/KWD (3 decimals) → 1000.
int subunitToUnitFor(String currencyCode) {
  return math.pow(10, currencyFractionDigitsFor(currencyCode)).toInt();
}

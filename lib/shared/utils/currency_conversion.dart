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

/// Formats a minor-unit amount in [currency] as its MAJOR-unit display string,
/// dropping a trailing all-zero fraction so whole foreign amounts read cleaner
/// (260614-dx1: "12,211.00 USD" → "12,211 USD"; the comma grouping is added by
/// the display widget downstream).
///
/// Returns '' for a non-positive amount (callers treat empty as "0").
///
/// Decimals/subunit come from the single decimals source
/// ([currencyFractionDigitsFor] / [subunitToUnitFor]) — no new decimal logic.
///
/// - decimals == 0 (JPY/KRW): integer string, UNCHANGED — never had a dot.
/// - decimals > 0: only an ENTIRELY-zero fraction is dropped (12.00 → "12");
///   real fractional digits stay (12.50 stays "12.50", 12.05 stays "12.05").
String formatMinorAsMajor(int minorUnits, String currency) {
  if (minorUnits <= 0) return '';
  final decimals = currencyFractionDigitsFor(currency);
  final subunit = subunitToUnitFor(currency);
  if (decimals == 0) return (minorUnits ~/ subunit).toString();
  final fixed = (minorUnits / subunit).toStringAsFixed(decimals);
  final dot = fixed.indexOf('.');
  if (dot < 0) return fixed;
  final fraction = fixed.substring(dot + 1);
  final isAllZero = fraction.split('').every((c) => c == '0');
  return isAllZero ? fixed.substring(0, dot) : fixed;
}

/// ISO 4217 currency code shape: exactly 3 uppercase ASCII letters.
final _iso4217 = RegExp(r'^[A-Z]{3}$');

/// Outcome of validating a foreign-currency triple (originalCurrency /
/// originalAmount / appliedRate).
///
/// Mutually exclusive: exactly one of [error] / [jpyAmount] is non-null per
/// instance, plus the [native] case where the row carries no currency fields.
///
/// - [CurrencyTripleResult.native]: no currency field set → JPY-native row.
/// - [CurrencyTripleResult.invalid]: a validation rule failed → [error] set.
/// - [CurrencyTripleResult.foreign]: full valid triple → [jpyAmount] is the
///   canonical [convertToJpy] result (the value the hashed `amount` MUST equal).
class CurrencyTripleResult {
  const CurrencyTripleResult._({
    this.error,
    this.jpyAmount,
    required this.isForeign,
  });

  /// No currency field present — JPY-native row.
  const CurrencyTripleResult.native() : this._(isForeign: false);

  /// A validation rule failed; [message] explains why.
  const CurrencyTripleResult.invalid(String message)
    : this._(error: message, isForeign: false);

  /// Full valid triple; [amount] is the canonical converted JPY value.
  const CurrencyTripleResult.foreign(int amount)
    : this._(jpyAmount: amount, isForeign: true);

  /// Non-null only on the invalid case.
  final String? error;

  /// Non-null only on the foreign case — the canonical [convertToJpy] result.
  final int? jpyAmount;

  /// True only on the foreign case (full valid triple present).
  final bool isForeign;
}

/// Validates a foreign-currency triple and computes its canonical JPY amount.
///
/// This is the SINGLE validation+conversion site shared by
/// `CreateTransactionUseCase` and `UpdateTransactionUseCase` (CLAUDE.md
/// many-small-files: do not duplicate this block inline). It enforces, in
/// order:
/// 1. Partial-triple invariant (STORE-04): all three fields, or none.
/// 2. [appliedRate] is a plain positive decimal literal (ADR-020 D-05).
/// 3. [originalAmount] > 0 and [originalCurrency] is a 3-letter ISO 4217 code
///    (Phase 40 review WR-03 — the foreign-row discriminator must be sound).
///
/// On a full valid triple it returns [CurrencyTripleResult.foreign] carrying
/// `convertToJpy(...)` — the value the row's hashed `amount` MUST equal
/// (ADR-020 Pitfall 1; inline arithmetic divergence is undetectable once
/// persisted because the triple is excluded from the hash chain, ADR-021).
CurrencyTripleResult validateCurrencyTriple({
  required String? originalCurrency,
  required int? originalAmount,
  required String? appliedRate,
}) {
  final hasAny =
      originalCurrency != null || originalAmount != null || appliedRate != null;
  final hasAll =
      originalCurrency != null && originalAmount != null && appliedRate != null;

  if (!hasAny) {
    return const CurrencyTripleResult.native();
  }
  if (!hasAll) {
    return const CurrencyTripleResult.invalid(
      'partial foreign-currency data: all three of originalCurrency, '
      'originalAmount, appliedRate must be non-null together',
    );
  }

  final rateError = validateAppliedRate(appliedRate);
  if (rateError != null) {
    return CurrencyTripleResult.invalid(rateError);
  }
  if (originalAmount <= 0) {
    return const CurrencyTripleResult.invalid(
      'originalAmount must be greater than 0',
    );
  }
  if (!_iso4217.hasMatch(originalCurrency)) {
    return const CurrencyTripleResult.invalid(
      'originalCurrency must be a 3-letter ISO 4217 code',
    );
  }

  final jpy = convertToJpy(
    originalMinorUnits: originalAmount,
    appliedRate: appliedRate,
    subunitToUnit: subunitToUnitFor(originalCurrency),
  );
  return CurrencyTripleResult.foreign(jpy);
}

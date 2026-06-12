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
int convertToJpy({
  required int originalMinorUnits,
  required String appliedRate,
  required int subunitToUnit,
}) {
  final rate = double.parse(appliedRate);
  return (originalMinorUnits / subunitToUnit * rate).round();
}

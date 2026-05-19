import 'package:intl/intl.dart';

/// Cumulative Joy PTVF base and display formatting helpers.
///
/// Currency code lookups are case-sensitive, matching Book.currency convention.
/// Unknown codes fall back to JPY semantics and never throw.
// D-20 names this map _PTVF_BASE_BY_CURRENCY; Dart style requires lower camel.
const Map<String, double> _ptvfBaseByCurrency = {
  'JPY': 500.0,
  'CNY': 25.0,
  'USD': 5.0,
};

/// PTVF base for [currencyCode], defaulting to JPY's 500.0 base.
double ptvfBaseFor(String currencyCode) =>
    _ptvfBaseByCurrency[currencyCode] ?? 500.0;

/// Formats Σ joy_contribution as an integer with grouped separators.
String formatJoyCumulative(double rawSum, String currencyCode) {
  // currencyCode is reserved for future locale-aware variants; cumulative Joy
  // has no currency-specific unit suffix.
  final intValue = rawSum.floor();
  return NumberFormat.decimalPattern().format(intValue);
}

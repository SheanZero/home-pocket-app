/// Joy density PTVF base and display formatting helpers.
///
/// HAPPY-02 / D-04 / D-19 / D-20: this file is the single source of
/// truth for both:
/// - PTVF base by currency, used by happiness formula math
/// - Display unit by currency, used by UI surfaces
///
/// Currency code lookups are case-sensitive, matching Book.currency convention.
/// Unknown codes fall back to JPY semantics and never throw.
// D-20 names this map _PTVF_BASE_BY_CURRENCY; Dart style requires lower camel.
const Map<String, double> _ptvfBaseByCurrency = {
  'JPY': 500.0,
  'CNY': 25.0,
  'USD': 5.0,
};

// D-20 names this map _DISPLAY_UNIT_BY_CURRENCY; Dart style requires lower camel.
const Map<String, ({double multiplier, String label})> _displayUnitByCurrency =
    {
      'JPY': (multiplier: 1000.0, label: '/ ¥1k'),
      'CNY': (multiplier: 100.0, label: '/ ¥100'),
      'USD': (multiplier: 1.0, label: r'/ $1'),
    };

/// PTVF base for [currencyCode], defaulting to JPY's 500.0 base.
double ptvfBaseFor(String currencyCode) =>
    _ptvfBaseByCurrency[currencyCode] ?? 500.0;

/// Formats a raw Joy-per-yen density with a currency-specific display unit.
String formatJoyDensity(double rawDensity, String currencyCode) {
  final unit =
      _displayUnitByCurrency[currencyCode] ?? _displayUnitByCurrency['JPY']!;
  final scaled = rawDensity * unit.multiplier;

  return '${scaled.toStringAsFixed(1)} ${unit.label}';
}

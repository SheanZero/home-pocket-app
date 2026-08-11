import 'package:flutter/material.dart';

/// Theme-aware category accents.
///
/// Category colors are persisted as light-theme identity colors. Dark mode
/// resolves them to lighter colors with the same hue so icons, borders, and
/// labels remain legible on the app's ink-green surfaces. Stored values are
/// intentionally left unchanged for sync and backwards compatibility.
abstract final class CategoryDisplayPalette {
  static const double minimumDarkContrast = 4.5;
  static const double _maximumTintAlpha = 0.15;

  static const Map<String, Color> _darkSystemColors = {
    '#FF5722': Color(0xFFFF8A65), // food
    '#00BCD4': Color(0xFF4DD0E1), // daily necessities
    '#7CB342': Color(0xFFAED581), // pets
    '#2196F3': Color(0xFF64B5F6), // transport
    '#9C27B0': Color(0xFFCE93D8), // hobbies
    '#E91E63': Color(0xFFF48FB1), // clothing
    '#FF9800': Color(0xFFFFB74D), // social
    '#F44336': Color(0xFFEF9A9A), // health
    '#3F51B5': Color(0xFF9FA8DA), // education
    '#FFC107': Color(0xFFFFD54F), // utilities
    '#00ACC1': Color(0xFF80DEEA), // communication
    '#795548': Color(0xFFBCAAA4), // housing
    '#455A64': Color(0xFFB0BEC5), // car
    '#5D4037': Color(0xFFC7A59A), // tax
    '#827717': Color(0xFFD4C957), // insurance
    '#AD1457': Color(0xFFF47FA5), // special expenses
    '#8D6E63': Color(0xFFD7CCC8), // allowance
    '#1B5E20': Color(0xFF81C784), // assets
    '#607D8B': Color(0xFFB0BEC5), // other
  };

  static Color parse(String colorHex) {
    final normalized = _normalize(colorHex);
    return Color(int.parse('FF${normalized.substring(1)}', radix: 16));
  }

  static Color resolve(
    String colorHex, {
    required Brightness brightness,
    required Color surface,
  }) {
    final normalized = _normalize(colorHex);
    final storedColor = parse(normalized);
    if (brightness == Brightness.light) return storedColor;

    final curated = _darkSystemColors[normalized];
    if (curated != null && _meetsDarkContrast(curated, surface)) {
      return curated;
    }
    return _liftForDarkSurface(curated ?? storedColor, surface);
  }

  static String _normalize(String colorHex) {
    final normalized = colorHex.trim().toUpperCase();
    final withHash = normalized.startsWith('#') ? normalized : '#$normalized';
    if (!RegExp(r'^#[0-9A-F]{6}$').hasMatch(withHash)) {
      throw FormatException('Expected a six-digit category color', colorHex);
    }
    return withHash;
  }

  static Color _liftForDarkSurface(Color color, Color surface) {
    if (_meetsDarkContrast(color, surface)) return color;

    final hsl = HSLColor.fromColor(color);
    var lower = hsl.lightness;
    var upper = 1.0;
    for (var i = 0; i < 16; i++) {
      final midpoint = (lower + upper) / 2;
      final candidate = hsl.withLightness(midpoint).toColor();
      if (_meetsDarkContrast(candidate, surface)) {
        upper = midpoint;
      } else {
        lower = midpoint;
      }
    }
    return hsl.withLightness(upper).toColor();
  }

  static bool _meetsDarkContrast(Color color, Color surface) {
    final tintedSurface = Color.alphaBlend(
      color.withValues(alpha: _maximumTintAlpha),
      surface,
    );
    return _contrastRatio(color, tintedSurface) >= minimumDarkContrast;
  }

  static double _contrastRatio(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    final lighter = foregroundLuminance > backgroundLuminance
        ? foregroundLuminance
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance
        ? backgroundLuminance
        : foregroundLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }
}

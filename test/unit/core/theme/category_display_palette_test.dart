import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/category_display_palette.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const darkCard = Color(0xFF222923);

  group('CategoryDisplayPalette', () {
    test('keeps stored colors unchanged in light mode', () {
      for (final category in DefaultCategories.all) {
        expect(
          CategoryDisplayPalette.resolve(
            category.color,
            brightness: Brightness.light,
            surface: const Color(0xFFFFFDF8),
          ),
          CategoryDisplayPalette.parse(category.color),
          reason: category.id,
        );
      }
    });

    test('all system categories remain readable on dark tinted surfaces', () {
      for (final category in DefaultCategories.all) {
        final displayColor = CategoryDisplayPalette.resolve(
          category.color,
          brightness: Brightness.dark,
          surface: darkCard,
        );
        final iconSurface = Color.alphaBlend(
          displayColor.withValues(alpha: 0.15),
          darkCard,
        );

        expect(
          _contrastRatio(displayColor, iconSurface),
          greaterThanOrEqualTo(4.5),
          reason: '${category.id} ${category.color}',
        );
      }
    });

    test('adapts an arbitrary dark custom color for dark mode', () {
      final displayColor = CategoryDisplayPalette.resolve(
        '#263238',
        brightness: Brightness.dark,
        surface: darkCard,
      );
      final tintedSurface = Color.alphaBlend(
        displayColor.withValues(alpha: 0.15),
        darkCard,
      );

      expect(displayColor, isNot(const Color(0xFF263238)));
      expect(
        _contrastRatio(displayColor, tintedSurface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('dark colors preserve their category hue family', () {
      for (final category in DefaultCategories.all) {
        final stored = HSLColor.fromColor(
          CategoryDisplayPalette.parse(category.color),
        );
        final display = HSLColor.fromColor(
          CategoryDisplayPalette.resolve(
            category.color,
            brightness: Brightness.dark,
            surface: darkCard,
          ),
        );
        final hueDistance = (stored.hue - display.hue).abs();

        expect(
          hueDistance > 180 ? 360 - hueDistance : hueDistance,
          lessThanOrEqualTo(8),
          reason: category.id,
        );
      }
    });
  });
}

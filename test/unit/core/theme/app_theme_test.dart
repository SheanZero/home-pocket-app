import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';
import 'package:home_pocket/core/theme/app_theme.dart';

void main() {
  void expectPaletteAwareTextTheme(ThemeData theme, AppPalette palette) {
    expect(theme.textTheme.displayLarge?.color, palette.textPrimary);
    expect(theme.textTheme.headlineLarge?.color, palette.textPrimary);
    expect(theme.textTheme.titleMedium?.color, palette.textPrimary);
    expect(theme.textTheme.bodyMedium?.color, palette.textPrimary);
    expect(theme.textTheme.labelLarge?.color, palette.textPrimary);

    expect(theme.textTheme.bodySmall?.color, palette.textSecondary);
    expect(theme.textTheme.labelMedium?.color, palette.textSecondary);
    expect(theme.textTheme.labelSmall?.color, palette.textSecondary);
  }

  group('AppTheme', () {
    test('light theme uses Material 3 and the V15 background', () {
      final theme = AppTheme.light;

      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, AppPalette.light.background);
    });

    test('light theme maps semantic typography and colors', () {
      final theme = AppTheme.light;

      expectPaletteAwareTextTheme(theme, AppPalette.light);
      expect(theme.textTheme.headlineLarge?.fontSize, AppTypography.pageTitle);
      expect(theme.textTheme.titleMedium?.fontSize, AppTypography.itemTitle);
      expect(theme.textTheme.bodyMedium?.fontSize, AppTypography.body);
      expect(theme.textTheme.bodySmall?.fontSize, AppTypography.supporting);
      expect(theme.textTheme.labelSmall?.fontSize, AppTypography.compact);
    });

    test('dark theme injects dark primary and secondary text colors', () {
      final theme = AppTheme.dark;

      expectPaletteAwareTextTheme(theme, AppPalette.dark);
      expect(theme.textTheme.bodyMedium?.color, AppPalette.dark.textPrimary);
      expect(theme.textTheme.bodySmall?.color, AppPalette.dark.textSecondary);
    });

    test('app bar titles use the global page-title style in both themes', () {
      final lightTitle = AppTheme.light.appBarTheme.titleTextStyle!;
      final darkTitle = AppTheme.dark.appBarTheme.titleTextStyle!;

      for (final style in [lightTitle, darkTitle]) {
        expect(style.fontSize, AppTypography.pageTitle);
        expect(
          style.fontSize! * style.height!,
          closeTo(AppTypography.pageTitleLineHeight, 0.000001),
        );
        expect(style.fontWeight, FontWeight.w700);
      }
      expect(lightTitle.color, AppPalette.light.textPrimary);
      expect(darkTitle.color, AppPalette.dark.textPrimary);
    });

    test('theme and app styles keep the platform Japanese font stack', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(
          theme.textTheme.bodyMedium?.fontFamily,
          isNot(contains('Outfit')),
        );
      }
      expect(AppTextStyles.body.fontFamily, isNull);
      expect(AppTextStyles.body.fontFamilyFallback, isNull);
    });
  });
}

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

    test(
      'theme routes all text roles through the numeral-only font family',
      () {
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          for (final style in [
            theme.textTheme.displayLarge,
            theme.textTheme.headlineLarge,
            theme.textTheme.titleMedium,
            theme.textTheme.bodyMedium,
            theme.textTheme.bodySmall,
            theme.textTheme.labelLarge,
            theme.primaryTextTheme.bodyMedium,
          ]) {
            expect(style?.fontFamily, AppTextStyles.numeralFontFamily);
            expect(
              style?.fontFeatures,
              contains(const FontFeature.tabularFigures()),
            );
            expect(style?.fontFeatures, contains(const FontFeature('zero')));
          }
        }
        expect(AppTextStyles.numeralFontFamily, 'RobotoMonoNumerals');
        expect(AppTextStyles.body.fontFamily, AppTextStyles.numeralFontFamily);
        expect(AppTextStyles.body.fontFamilyFallback, isNull);
      },
    );

    testWidgets('unstyled Text inherits the app-wide numeral font family', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Text('Version 2026年 · ¥1,234.50')),
        ),
      );

      final text = find.text('Version 2026年 · ¥1,234.50');
      final inherited = DefaultTextStyle.of(tester.element(text)).style;

      expect(inherited.fontFamily, AppTextStyles.numeralFontFamily);
      expect(
        inherited.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(inherited.fontFeatures, contains(const FontFeature('zero')));
    });
  });
}

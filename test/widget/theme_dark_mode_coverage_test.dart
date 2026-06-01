import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/core/theme/app_theme.dart';

/// Widget test: dark-mode theme resolution coverage (D-07 / THEME-V2-02).
///
/// Pumps minimal Builder widgets under ThemeMode.dark and asserts:
///   (a) no exception is thrown during build
///   (b) Theme.of(context).brightness == Brightness.dark
///   (c) `Theme.of(context).extension<AppPalette>()` is not null
///
/// This test is specifically checking ThemeExtension registration in
/// AppTheme.dark, not visual correctness (visual coverage = Phase 34 golden).
///
/// Expected state:
///   BEFORE Plan 33-02 registers AppPalette in AppTheme.dark → FAILS (compile error)
///   AFTER  Plan 33-02 lands                                  → PASSES
///
/// Run: flutter test test/widget/theme_dark_mode_coverage_test.dart

/// Wraps [child] in a MaterialApp with ThemeMode.dark and both light/dark themes.
/// Does not require localization delegates — tests here do not use localizations.
Widget _darkApp({required Widget child}) {
  return MaterialApp(
    themeMode: ThemeMode.dark,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: child,
  );
}

void main() {
  group('Dark-mode theme resolution (D-07 / THEME-V2-02)', () {
    testWidgets(
      'Builder under dark theme resolves Brightness.dark',
      (tester) async {
        Brightness? capturedBrightness;

        await tester.pumpWidget(
          _darkApp(
            child: Builder(
              builder: (context) {
                capturedBrightness = Theme.of(context).brightness;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(capturedBrightness, Brightness.dark);
      },
    );

    testWidgets(
      'AppPalette ThemeExtension resolves non-null under dark theme',
      (tester) async {
        AppPalette? capturedPalette;

        await tester.pumpWidget(
          _darkApp(
            child: Builder(
              builder: (context) {
                capturedPalette = Theme.of(context).extension<AppPalette>();
                return Container(
                  color: capturedPalette?.background ?? Colors.transparent,
                );
              },
            ),
          ),
        );

        expect(capturedPalette, isNotNull);
      },
    );

    testWidgets(
      'AppPalette.dark background resolves correct ADR-018 hex under dark theme',
      (tester) async {
        Color? capturedBackground;

        await tester.pumpWidget(
          _darkApp(
            child: Builder(
              builder: (context) {
                final palette = Theme.of(context).extension<AppPalette>();
                capturedBackground = palette?.background;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // ADR-018 dark background is #0C1719 (deep teal-black)
        expect(capturedBackground, const Color(0xFF0C1719));
      },
    );
  });
}

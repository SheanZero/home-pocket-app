@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Golden regression tests for SmartKeyboard — 6 baseline images.
///
/// Matrix: {ja, zh, en} * {light, dark} = 6 PNG files.
/// D-09 binding: file is located adjacent to widget tests at:
///   test/widget/features/accounting/presentation/widgets/
/// Goldens at:
///   test/widget/features/accounting/presentation/widgets/goldens/
///
/// The test uses vanilla matchesGoldenFile — no alchemist or golden_toolkit
/// dependencies added (project D-12 posture, RESEARCH "Don't Hand-Roll").
///
/// Captures SC-3 (KEYPAD-01 visual discriminability):
/// - backgroundMuted fill on digit keys
/// - coral gradient on Save key
/// - Uniform key heights (D-08)
/// - 6 dp total column gap + 12 dp row gap (D-07)
/// - Tabular figure digit glyphs (UI-SPEC Typography)
/// - CJK font fallback for ja/zh locales (RESEARCH pitfall 7)

/// Wraps [child] in a MaterialApp with full i18n + light/dark theme support.
///
/// The keyboard is positioned flush to the bottom of a 390 dp wide container
/// matching iPhone 14 width — so the responsive height calculation uses a
/// realistic screen height (844 dp) set via [tester.binding.setSurfaceSize].
Widget _wrap({
  required Locale locale,
  required ThemeMode themeMode,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: themeMode,
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(width: 390, child: child),
      ),
    ),
  );
}

void main() {
  group('SmartKeyboard golden — 6-image regression matrix (SC-3 / D-09)', () {
    for (final locale in const [Locale('ja'), Locale('zh'), Locale('en')]) {
      for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
        testWidgets(
          'SmartKeyboard — ${locale.languageCode} / ${mode.name}',
          (tester) async {
            // iPhone 14 surface size for stable golden output
            await tester.binding.setSurfaceSize(const Size(390, 844));
            addTearDown(() async => tester.binding.setSurfaceSize(null));

            await tester.pumpWidget(
              _wrap(
                locale: locale,
                themeMode: mode,
                child: SmartKeyboard(
                  onDigit: (_) {},
                  onDelete: () {},
                  onNext: () {},
                  onDoubleZero: () {},
                  onDot: () {},
                  // 'Record' is sufficient — exercises layout/typography/color.
                  // Locale only affects CJK font fallback selection.
                  actionLabel: 'Record',
                ),
              ),
            );
            await tester.pumpAndSettle();

            await expectLater(
              find.byType(SmartKeyboard),
              matchesGoldenFile(
                'goldens/smart_keyboard_${locale.languageCode}_${mode.name}.png',
              ),
            );
          },
        );
      }
    }
  });
}

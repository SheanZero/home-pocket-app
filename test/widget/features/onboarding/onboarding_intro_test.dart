import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_intro_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Widget _host({required VoidCallback onContinue}) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: OnboardingIntroScreen(onContinue: onContinue),
  );
}

void main() {
  group('OnboardingIntroScreen — D-02 / ONBOARD-02', () {
    testWidgets('renders the title and all four approved selling points', (
      tester,
    ) async {
      await tester.pumpWidget(_host(onContinue: () {}));
      await tester.pumpAndSettle();

      // Intro title.
      expect(find.text('まもる家計簿'), findsOneWidget);

      // The 4 approved selling-point titles (ja ARB from 54-02).
      expect(find.text('すべて端末内・暗号化'), findsOneWidget); // privacy/encryption
      expect(find.text('ローカルファースト'), findsOneWidget); // local-first
      expect(find.text('日常と悦己、ふたつの帳簿'), findsOneWidget); // dual-ledger
      expect(find.text('声でサッと記録'), findsOneWidget); // voice
    });

    testWidgets('tapping the continue button fires onContinue exactly once', (
      tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(_host(onContinue: () => count++));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'はじめる'));
      await tester.pumpAndSettle();

      expect(count, 1);
    });

    testWidgets('tapping the skip button also fires onContinue (skippable)', (
      tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(_host(onContinue: () => count++));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'スキップ'));
      await tester.pumpAndSettle();

      expect(count, 1);
    });
  });
}

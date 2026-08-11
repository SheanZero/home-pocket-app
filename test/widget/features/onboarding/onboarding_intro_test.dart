import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_intro_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Widget _host({
  required VoidCallback onContinue,
  Locale locale = const Locale('ja'),
}) {
  return MaterialApp(
    locale: locale,
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

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, '次へ'));
  await tester.pumpAndSettle();
}

void main() {
  group('OnboardingIntroScreen — V16 2-page PageView', () {
    testWidgets('page 1 renders badge, title, brand line, tagline, dots, '
        'value pills, 次へ and top-right スキップ', (tester) async {
      await tester.pumpWidget(_host(onContinue: () {}));
      await tester.pumpAndSettle();

      expect(find.text('たのしく、つづく家計簿'), findsOneWidget); // joy pill badge
      expect(find.text('Happy Pocket'), findsOneWidget); // title
      expect(find.text('ハピポケ家族家計簿'), findsOneWidget); // brand subtitle
      expect(
        find.text('記録するたびに、ちょっと、しあわせ。\nお金とのつきあいを、もっと前向きに。'),
        findsOneWidget,
      );
      expect(find.text('日々の帳'), findsOneWidget);
      expect(find.text('ときめき帳'), findsOneWidget);
      expect(find.text('満足度'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '次へ'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'スキップ'), findsOneWidget);
      // はじめる only appears on page 2.
      expect(find.text('はじめる'), findsNothing);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('brand subtitle matches the website in every locale', (
      tester,
    ) async {
      const subtitles = <(Locale, String)>[
        (Locale('ja'), 'ハピポケ家族家計簿'),
        (Locale('zh'), '家庭账本'),
        (Locale('en'), 'Family Budget'),
      ];

      for (final (locale, subtitle) in subtitles) {
        await tester.pumpWidget(_host(onContinue: () {}, locale: locale));
        await tester.pumpAndSettle();

        expect(find.text(subtitle), findsOneWidget);
      }
    });

    testWidgets('value area uses the warm three-capsule treatment', (
      tester,
    ) async {
      await tester.pumpWidget(_host(onContinue: () {}));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('onboarding-value-daily')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('onboarding-value-joy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('onboarding-value-satisfaction')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('onboarding-value-daily')),
          matching: find.byIcon(Icons.spa_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('onboarding-value-joy')),
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('warm value capsules fit a compact phone width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_host(onContinue: () {}));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('日々の帳'), findsOneWidget);
      expect(find.text('ときめき帳'), findsOneWidget);
      expect(find.text('満足度'), findsOneWidget);
    });

    testWidgets('prebuilds page 2 before the first transition', (tester) async {
      await tester.pumpWidget(_host(onContinue: () {}));
      await tester.pump();

      // The privacy page contains SVG, icon, layout, and animation resources.
      // Keeping it built offscreen prevents those one-time costs from landing
      // inside the first 300 ms page transition.
      final privacyTitle = find.text('データは、\nあなたの手の中に。', skipOffstage: false);
      expect(privacyTitle, findsOneWidget);
      expect(
        TickerMode.valuesOf(tester.element(privacyTitle)).enabled,
        isFalse,
      );
    });

    testWidgets('次へ moves 1 → 2; page 2 shows privacy promises and '
        'はじめる fires onContinue exactly once', (tester) async {
      var count = 0;
      await tester.pumpWidget(_host(onContinue: () => count++));
      await tester.pumpAndSettle();

      // Page 1 → 2.
      await _tapNext(tester);
      expect(count, 0); // 次へ never fires onContinue
      expect(find.text('データは、\nあなたの手の中に。'), findsOneWidget);
      expect(find.text('端末内に保存'), findsOneWidget);
      expect(find.text('エンドツーエンド暗号化'), findsOneWidget);
      expect(find.text('改ざん防止'), findsOneWidget);
      expect(find.text('LOCAL'), findsOneWidget);
      expect(find.text('E2EE'), findsOneWidget);
      expect(find.text('SAFE'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '戻る'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '次へ'), findsNothing);

      // Page 2 はじめる → onContinue exactly once.
      await tester.tap(find.widgetWithText(TextButton, 'はじめる'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('スキップ from page 1 fires onContinue exactly once', (
      tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(_host(onContinue: () => count++));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'スキップ'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('戻る on page 2 returns to page 1', (tester) async {
      await tester.pumpWidget(_host(onContinue: () {}));
      await tester.pumpAndSettle();

      await _tapNext(tester);
      await tester.tap(find.widgetWithText(TextButton, '戻る'));
      await tester.pumpAndSettle();

      expect(find.text('Happy Pocket'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '次へ'), findsOneWidget);
    });

    testWidgets('スキップ from page 2 fires onContinue exactly once', (
      tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(_host(onContinue: () => count++));
      await tester.pumpAndSettle();

      await _tapNext(tester);
      expect(find.widgetWithText(TextButton, 'スキップ'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'スキップ'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('PageView swipe also advances pages', (tester) async {
      await tester.pumpWidget(_host(onContinue: () {}));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(find.text('データは、\nあなたの手の中に。'), findsOneWidget);
    });
  });
}

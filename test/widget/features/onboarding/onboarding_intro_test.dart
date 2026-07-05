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

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, '次へ'));
  await tester.pumpAndSettle();
}

void main() {
  group('OnboardingIntroScreen — Welcome A 3-page PageView (WELA-01)', () {
    testWidgets('page 1 renders badge, title, brand line, tagline, dots, '
        '次へ and top-right スキップ', (tester) async {
      await tester.pumpWidget(_host(onContinue: () {}));
      await tester.pumpAndSettle();

      expect(find.text('たのしく、つづく家計簿'), findsOneWidget); // joy pill badge
      expect(find.text('まもる家計簿'), findsOneWidget); // title
      expect(find.text('HOME POCKET'), findsOneWidget); // brand line
      expect(
        find.text('記録するたびに、ちょっと、しあわせ。\nお金とのつきあいを、もっと前向きに。'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, '次へ'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'スキップ'), findsOneWidget);
      // はじめる only appears on page 3.
      expect(find.text('はじめる'), findsNothing);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('次へ pages 1 → 2 → 3; page 2 shows privacy cards, page 3 '
        'shows joy content; はじめる fires onContinue exactly once', (
      tester,
    ) async {
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

      // Page 2 → 3.
      await _tapNext(tester);
      expect(count, 0);
      expect(find.text('使ったお金に、“気持ち”を添えて。'), findsOneWidget);
      expect(find.text('満足度を、ワンタップで記録。'), findsOneWidget);
      expect(find.text('お金は、自分を満たすために。'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '次へ'), findsNothing);

      // Page 3 はじめる → onContinue exactly once.
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

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('データは、\nあなたの手の中に。'), findsOneWidget);
    });
  });
}

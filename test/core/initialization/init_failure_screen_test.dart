import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/initialization/init_failure_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Widget _wrap(
  InitFailureScreen screen, {
  Locale locale = const Locale('en'),
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
    home: screen,
  );
}

void main() {
  group('InitFailureScreen', () {
    testWidgets('shows English strings', (tester) async {
      await tester.pumpWidget(
        _wrap(
          InitFailureScreen(onRetry: () async {}),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Initialization failed'), findsOneWidget);
      expect(
        find.text(
          'Something went wrong while starting the app. Tap retry to try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows Japanese strings', (tester) async {
      await tester.pumpWidget(
        _wrap(
          InitFailureScreen(onRetry: () async {}),
          locale: const Locale('ja'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('初期化に失敗しました'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('shows Chinese strings', (tester) async {
      await tester.pumpWidget(
        _wrap(
          InitFailureScreen(onRetry: () async {}),
          locale: const Locale('zh'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('初始化失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('retry button calls onRetry callback', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(
          InitFailureScreen(onRetry: () async {
            called = true;
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('shows loading indicator while retrying', (tester) async {
      final completer = Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pumpWidget(
        _wrap(InitFailureScreen(onRetry: () => completer)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retry'), findsNothing);

      await tester.pumpAndSettle();
    });

    testWidgets('retry button is disabled while retrying', (tester) async {
      final completer = Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pumpWidget(
        _wrap(InitFailureScreen(onRetry: () => completer)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      await tester.pumpAndSettle();
    });

    testWidgets('renders error_outline icon', (tester) async {
      await tester.pumpWidget(
        _wrap(InitFailureScreen(onRetry: () async {})),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.error_outline,
        ),
        findsOneWidget,
      );
    });

    testWidgets('scaffold background is warm ivory (#FCFBF9)', (tester) async {
      await tester.pumpWidget(
        _wrap(InitFailureScreen(onRetry: () async {})),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFFFCFBF9)));
    });

    testWidgets('retry button re-enables after onRetry completes',
        (tester) async {
      var retryCount = 0;
      await tester.pumpWidget(
        _wrap(
          InitFailureScreen(onRetry: () async {
            retryCount++;
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Button should be re-enabled and showing text again
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
      expect(find.text('Retry'), findsOneWidget);
      expect(retryCount, equals(1));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_settings_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Widget _host({
  List<Override> overrides = const [],
  VoidCallback? onConfirmed,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: OnboardingSettingsScreen(
        bookId: 'book-1',
        onConfirmed: onConfirmed ?? () {},
      ),
    ),
  );
}

void main() {
  group('OnboardingSettingsScreen — D-14 nickname gate (Task 1)', () {
    testWidgets('start button is disabled until a nickname is set', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // The confirm button renders with the locked copy.
      final buttonFinder = find.widgetWithText(TextButton, 'この設定で始める');
      expect(buttonFinder, findsOneWidget);

      // Disabled while the nickname is empty (onPressed == null).
      final button = tester.widget<TextButton>(buttonFinder);
      expect(button.onPressed, isNull);

      // The nickname row shows the 未設定 placeholder.
      expect(find.text('未設定'), findsOneWidget);
    });

    testWidgets('start button enables once a non-empty nickname is entered', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Open the nickname editor and enter a name.
      await tester.tap(find.text('未設定'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'たけし');
      await tester.pumpAndSettle();

      // Confirm the dialog (its action carries the 変更 label, rendered last).
      await tester.tap(find.text('変更').last);
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(TextButton, 'この設定で始める');
      final button = tester.widget<TextButton>(buttonFinder);
      expect(button.onPressed, isNotNull);
      expect(find.text('たけし'), findsOneWidget);
    });

    testWidgets('renders all five unified rows with default current-values', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Section header.
      expect(find.text('基本設定'), findsOneWidget);
      // Row labels.
      expect(find.text('あなたの呼び名'), findsOneWidget); // nickname
      expect(find.text('言語'), findsOneWidget); // UI language
      expect(find.text('通貨'), findsOneWidget); // currency
      expect(find.text('音声入力の言語'), findsOneWidget); // voice
      // Five 変更 affordances (one per row).
      expect(find.text('変更'), findsNWidgets(5));
      // Currency default JPY visible.
      expect(find.textContaining('JPY'), findsOneWidget);
    });
  });
}

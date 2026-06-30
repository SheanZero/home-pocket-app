import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/applock/presentation/widgets/pin_keypad.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Widget _host(Widget child) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('PinKeypad — presentational 9-grid (D-12 / LOCK-06)', () {
    testWidgets('renders all digits 0-9 plus a backspace key', (tester) async {
      await tester.pumpWidget(
        _host(PinKeypad(onDigit: (_) {}, onBackspace: () {})),
      );
      await tester.pumpAndSettle();

      for (var d = 0; d <= 9; d++) {
        expect(
          find.text('$d'),
          findsOneWidget,
          reason: 'digit $d should be present exactly once',
        );
      }
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('tapping the 7 key invokes onDigit(7)', (tester) async {
      int? captured;
      await tester.pumpWidget(
        _host(PinKeypad(onDigit: (d) => captured = d, onBackspace: () {})),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();

      expect(captured, 7);
    });

    testWidgets('tapping backspace invokes onBackspace', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _host(PinKeypad(onDigit: (_) {}, onBackspace: () => pressed = true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/digit_code_display.dart';

void main() {
  testWidgets('DigitCodeDisplay renders each digit in its own box', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DigitCodeDisplay(code: '384729')),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('DigitCodeDisplay shows empty placeholders for short codes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DigitCodeDisplay(code: '38')),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.byType(Container), findsAtLeastNWidgets(6));
  });
}

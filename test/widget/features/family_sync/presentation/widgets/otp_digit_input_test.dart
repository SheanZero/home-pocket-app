import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/otp_digit_input.dart';

void main() {
  testWidgets('OtpDigitInput calls onCompleted with 6-digit code', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpDigitInput(
            onChanged: (_) {},
            onCompleted: (code) => result = code,
          ),
        ),
      ),
    );

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, '384729');
    await tester.pump();

    expect(result, '384729');
  });

  testWidgets('OtpDigitInput shows entered digits', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpDigitInput(onChanged: (_) {}, onCompleted: (_) {}),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '384');
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}

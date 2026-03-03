import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/pair_code_input.dart';

void main() {
  testWidgets(
    'PairCodeInput shows title, OTP input, join button, and scan button',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: PairCodeInput(onSubmit: (_) {}, onScanQr: () {}),
          ),
        ),
      );

      expect(find.text('家族に参加する'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('グループに参加'), findsOneWidget);
      expect(find.text('QRコードをスキャン'), findsOneWidget);
      expect(find.text('または'), findsOneWidget);
    },
  );
}

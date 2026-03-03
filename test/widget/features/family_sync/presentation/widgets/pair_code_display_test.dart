import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/pair_code_display.dart';

void main() {
  testWidgets('PairCodeDisplay shows digit boxes, buttons, and hint', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: PairCodeDisplay(
            inviteCode: '384729',
            qrData: 'hp://join/384729',
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            onRegenerate: () {},
            onShare: () {},
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('シェア'), findsOneWidget);
    expect(find.text('更新'), findsOneWidget);
    expect(find.textContaining('家族'), findsWidgets);
  });
}

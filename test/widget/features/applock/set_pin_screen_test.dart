import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/security/app_lock_service.dart';
import 'package:home_pocket/features/applock/presentation/screens/set_pin_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_localizations.dart';

class _MockAppLockService extends Mock implements AppLockService {}

void main() {
  late _MockAppLockService appLock;
  late int completedCount;

  setUp(() {
    appLock = _MockAppLockService();
    completedCount = 0;
    when(() => appLock.setPin(any())).thenAnswer((_) async {});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        SetPinScreen(onCompleted: () => completedCount++),
        locale: const Locale('ja'),
        overrides: [appLockServiceProvider.overrideWithValue(appLock)],
      ),
    );
    await tester.pumpAndSettle();
  }

  S l10nOf(WidgetTester tester) =>
      S.of(tester.element(find.byType(SetPinScreen)));

  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final c in pin.split('')) {
      await tester.tap(find.text(c));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('entering 4 digits advances to the confirm step', (tester) async {
    await pumpScreen(tester);

    expect(find.text(l10nOf(tester).appLockSetPinTitle), findsOneWidget);

    await enterPin(tester, '1234');

    // Step switched: confirm title shows, enter title gone.
    expect(find.text(l10nOf(tester).appLockConfirmPinTitle), findsOneWidget);
    verifyNever(() => appLock.setPin(any()));
  });

  testWidgets('matching re-entry calls setPin once and reports completion',
      (tester) async {
    await pumpScreen(tester);

    await enterPin(tester, '1234');
    await enterPin(tester, '1234');

    verify(() => appLock.setPin('1234')).called(1);
    expect(completedCount, 1);
  });

  testWidgets('mismatched re-entry shows the error, never calls setPin, and '
      'restarts at the enter step', (tester) async {
    await pumpScreen(tester);

    await enterPin(tester, '1234');
    await enterPin(tester, '9999');

    verifyNever(() => appLock.setPin(any()));
    expect(completedCount, 0);
    expect(find.text(l10nOf(tester).appLockPinMismatch), findsOneWidget);
    // Back to the enter step.
    expect(find.text(l10nOf(tester).appLockSetPinTitle), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/security/app_lock_service.dart';
import 'package:home_pocket/features/applock/presentation/screens/app_lock_screen.dart';
import 'package:home_pocket/features/applock/presentation/widgets/face_id_panel.dart';
import 'package:home_pocket/features/applock/presentation/widgets/pin_keypad.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/biometric_service.dart';
import 'package:home_pocket/infrastructure/security/models/auth_result.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_localizations.dart';

class _MockBiometricService extends Mock implements BiometricService {}

class _MockAppLockService extends Mock implements AppLockService {}

void main() {
  late _MockBiometricService biometric;
  late _MockAppLockService appLock;
  late int unlockCount;

  setUp(() {
    biometric = _MockBiometricService();
    appLock = _MockAppLockService();
    unlockCount = 0;
    // Default auto-trigger outcome: drop to PIN (never a dead end).
    when(() => biometric.authenticate(reason: any(named: 'reason')))
        .thenAnswer((_) async => const AuthResult.fallbackToPIN());
    when(() => appLock.verifyPin(any())).thenAnswer((_) async => false);
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool startOnPinPage = false,
  }) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        AppLockScreen(
          onUnlocked: () => unlockCount++,
          startOnPinPage: startOnPinPage,
        ),
        locale: const Locale('ja'),
        overrides: [
          biometricServiceProvider.overrideWithValue(biometric),
          appLockServiceProvider.overrideWithValue(appLock),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  S l10nOf(WidgetTester tester) =>
      S.of(tester.element(find.byType(AppLockScreen)));

  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final c in pin.split('')) {
      await tester.tap(find.text(c));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  group('AppLockScreen — Face ID auto-trigger -> PIN escape (D-09/LOCK-05)', () {
    testWidgets(
        'biometric fallbackToPIN keeps the Face ID page with the ghost escape',
        (tester) async {
      await pumpScreen(tester);

      // Auto-trigger ran and returned a non-success -> STAY on Face ID page.
      verify(() => biometric.authenticate(reason: any(named: 'reason')))
          .called(1);
      expect(find.byType(FaceIdPanel), findsOneWidget);
      expect(find.byType(PinKeypad), findsNothing);
      expect(unlockCount, 0);
      // The ghost passcode escape is present.
      expect(find.text(l10nOf(tester).appLockUsePasscode), findsOneWidget);
    });

    testWidgets('tapping パスコードを使用 switches to the PIN page',
        (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text(l10nOf(tester).appLockUsePasscode));
      await tester.pumpAndSettle();

      expect(find.byType(PinKeypad), findsOneWidget);
      expect(find.byType(FaceIdPanel), findsNothing);
    });

    testWidgets('biometric success unlocks without ever showing the PIN page',
        (tester) async {
      when(() => biometric.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => const AuthResult.success());

      await pumpScreen(tester);

      expect(unlockCount, 1);
      expect(find.byType(PinKeypad), findsNothing);
    });
  });

  group('AppLockScreen — PIN page instant verify (D-12/LOCK-06)', () {
    testWidgets('correct 4 digits call onUnlocked once on the 4th digit',
        (tester) async {
      when(() => appLock.verifyPin('1234')).thenAnswer((_) async => true);

      await pumpScreen(tester, startOnPinPage: true);
      expect(find.byType(PinKeypad), findsOneWidget);

      await enterPin(tester, '1234');

      verify(() => appLock.verifyPin('1234')).called(1);
      expect(unlockCount, 1);
    });

    testWidgets(
        'wrong PIN does NOT unlock, clears the dots, stays usable (no cooldown)',
        (tester) async {
      when(() => appLock.verifyPin(any())).thenAnswer((_) async => false);

      await pumpScreen(tester, startOnPinPage: true);
      await enterPin(tester, '9999');

      expect(unlockCount, 0);
      // Dots cleared back to empty after the shake.
      expect(find.byKey(const ValueKey('pin-dot-empty-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-dot-filled-0')), findsNothing);
      // Immediately retryable — no lockout text, keypad still present.
      expect(find.byType(PinKeypad), findsOneWidget);

      await enterPin(tester, '1234');
      expect(unlockCount, 0);
    });

    testWidgets('忘记 PIN? shows the no-recovery explanation copy (D-08/LOCK-09)',
        (tester) async {
      await pumpScreen(tester, startOnPinPage: true);

      await tester.tap(find.text(l10nOf(tester).appLockForgotPin));
      await tester.pumpAndSettle();

      expect(
        find.text(l10nOf(tester).appLockForgotPinExplanation),
        findsOneWidget,
      );
    });
  });
}

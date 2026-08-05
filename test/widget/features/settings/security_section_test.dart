import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/security/app_lock_service.dart';
import 'package:home_pocket/features/applock/presentation/screens/set_pin_screen.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/presentation/widgets/security_section.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/biometric_service.dart';
import 'package:home_pocket/infrastructure/security/models/auth_result.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/features/applock/presentation/providers/repository_providers.dart';
import 'package:home_pocket/shared/widgets/settings_section_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_localizations.dart';

class _MockAppLockService extends Mock implements AppLockService {}

class _MockBiometricService extends Mock implements BiometricService {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockAppLockService appLock;

  setUp(() {
    appLock = _MockAppLockService();
    when(() => appLock.setPin(any())).thenAnswer((_) async {});
    when(() => appLock.enableLock()).thenAnswer((_) async {});
    when(() => appLock.disableLock()).thenAnswer((_) async {});
    when(() => appLock.reauth()).thenAnswer((_) async => false);
    when(() => appLock.verifyPin(any())).thenAnswer((_) async => false);
  });

  Future<void> pump(
    WidgetTester tester, {
    required AppSettings settings,
    BiometricAvailability availability = BiometricAvailability.faceId,
    BiometricService? biometricService,
    SettingsRepository? settingsRepository,
  }) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: SingleChildScrollView(
            child: SecuritySection(settings: settings),
          ),
        ),
        locale: const Locale('ja'),
        overrides: [
          appLockServiceProvider.overrideWithValue(appLock),
          biometricAvailabilityProvider.overrideWith(
            (ref) async => availability,
          ),
          if (biometricService != null)
            biometricServiceProvider.overrideWithValue(biometricService),
          if (settingsRepository != null)
            settingsRepositoryProvider.overrideWithValue(settingsRepository),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  S l10nOf(WidgetTester tester) =>
      S.of(tester.element(find.byType(SecuritySection)));

  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final c in pin.split('')) {
      await tester.tap(find.text(c));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('master toggle renders; dormant notifications stay hidden', (
    tester,
  ) async {
    await pump(tester, settings: const AppSettings());

    final l = l10nOf(tester);
    expect(find.text(l.securityAppLock), findsOneWidget);
    expect(find.text(l.notifications), findsNothing);
    // Lock disabled -> no sub-items.
    expect(find.text(l.securityChangePin), findsNothing);
    expect(find.text(l.securityBiometricUnlock), findsNothing);
  });

  testWidgets(
    'enabling requires a PIN: only enables after SetPinScreen success',
    (tester) async {
      await pump(tester, settings: const AppSettings());

      await tester.tap(
        find.widgetWithText(SwitchListTile, l10nOf(tester).securityAppLock),
      );
      await tester.pumpAndSettle();

      // Pushes the double-entry set-PIN flow.
      expect(find.byType(SetPinScreen), findsOneWidget);

      await enterPin(tester, '1234');
      await enterPin(tester, '1234');

      verify(() => appLock.setPin('1234')).called(1);
      verify(() => appLock.enableLock()).called(1);
    },
  );

  testWidgets('cancelling set-PIN leaves the lock disabled (revert)', (
    tester,
  ) async {
    await pump(tester, settings: const AppSettings());

    await tester.tap(
      find.widgetWithText(SwitchListTile, l10nOf(tester).securityAppLock),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SetPinScreen), findsOneWidget);

    // Dismiss without setting a PIN.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    verifyNever(() => appLock.enableLock());
    verifyNever(() => appLock.setPin(any()));
  });

  testWidgets('disabling requires reauth: biometric success -> disableLock', (
    tester,
  ) async {
    when(() => appLock.reauth()).thenAnswer((_) async => true);

    await pump(
      tester,
      settings: const AppSettings(
        appLockEnabled: true,
        biometricUnlockEnabled: true,
      ),
    );

    await tester.tap(
      find.widgetWithText(SwitchListTile, l10nOf(tester).securityAppLock),
    );
    await tester.pumpAndSettle();

    verify(() => appLock.reauth()).called(1);
    verify(() => appLock.disableLock()).called(1);
  });

  testWidgets('disabling without biometric prompts current PIN then disables', (
    tester,
  ) async {
    when(() => appLock.reauth()).thenAnswer((_) async => false);
    when(() => appLock.verifyPin('4321')).thenAnswer((_) async => true);

    await pump(tester, settings: const AppSettings(appLockEnabled: true));

    await tester.tap(
      find.widgetWithText(SwitchListTile, l10nOf(tester).securityAppLock),
    );
    await tester.pumpAndSettle();

    // Biometric reauth failed -> a PIN verify surface is shown.
    expect(find.byType(SetPinScreen), findsNothing);
    verifyNever(() => appLock.disableLock());

    await enterPin(tester, '4321');

    verify(() => appLock.verifyPin('4321')).called(1);
    verify(() => appLock.disableLock()).called(1);
  });

  testWidgets('sub-items shown when enabled; biometric gated by availability', (
    tester,
  ) async {
    await pump(
      tester,
      settings: const AppSettings(appLockEnabled: true),
      availability: BiometricAvailability.faceId,
    );

    final l = l10nOf(tester);
    expect(find.text(l.securityChangePin), findsOneWidget);
    expect(find.text(l.securityBiometricUnlock), findsOneWidget);

    final switchTiles = find.byType(SwitchListTile);
    for (var index = 0; index < switchTiles.evaluate().length; index++) {
      expect(
        tester.getSize(switchTiles.at(index)).height,
        greaterThanOrEqualTo(72.0),
        reason: 'Security switches must use the shared settings row height',
      );
    }
    expect(
      tester.getSize(find.byType(SettingsActionTile)).height,
      greaterThanOrEqualTo(72.0),
      reason: 'The PIN action must align with adjacent security rows',
    );
  });

  testWidgets('biometric sub-toggle hidden when biometrics unavailable', (
    tester,
  ) async {
    await pump(
      tester,
      settings: const AppSettings(appLockEnabled: true),
      availability: BiometricAvailability.notSupported,
    );

    final l = l10nOf(tester);
    // Change-PIN still available; biometric sub-toggle gated out.
    expect(find.text(l.securityChangePin), findsOneWidget);
    expect(find.text(l.securityBiometricUnlock), findsNothing);
  });

  testWidgets(
    'enabling biometric unlock requests authorization before persisting',
    (tester) async {
      final biometric = _MockBiometricService();
      final settingsRepository = _MockSettingsRepository();
      when(
        () => biometric.authenticate(
          reason: any(named: 'reason'),
          biometricOnly: any(named: 'biometricOnly'),
        ),
      ).thenAnswer((_) async => const AuthResult.success());
      when(
        () => settingsRepository.setBiometricUnlockEnabled(true),
      ).thenAnswer((_) async {});

      await pump(
        tester,
        settings: const AppSettings(appLockEnabled: true),
        availability: BiometricAvailability.generic,
        biometricService: biometric,
        settingsRepository: settingsRepository,
      );

      await tester.tap(
        find.widgetWithText(
          SwitchListTile,
          l10nOf(tester).securityBiometricUnlock,
        ),
      );
      await tester.pumpAndSettle();

      verify(
        () => biometric.authenticate(
          reason: any(named: 'reason'),
          biometricOnly: true,
        ),
      ).called(1);
      verify(
        () => settingsRepository.setBiometricUnlockEnabled(true),
      ).called(1);
    },
  );

  testWidgets(
    'failed biometric authorization does not persist biometric unlock',
    (tester) async {
      final biometric = _MockBiometricService();
      final settingsRepository = _MockSettingsRepository();
      when(
        () => biometric.authenticate(
          reason: any(named: 'reason'),
          biometricOnly: any(named: 'biometricOnly'),
        ),
      ).thenAnswer((_) async => const AuthResult.fallbackToPIN());

      await pump(
        tester,
        settings: const AppSettings(appLockEnabled: true),
        availability: BiometricAvailability.generic,
        biometricService: biometric,
        settingsRepository: settingsRepository,
      );

      await tester.tap(
        find.widgetWithText(
          SwitchListTile,
          l10nOf(tester).securityBiometricUnlock,
        ),
      );
      await tester.pumpAndSettle();

      verifyNever(() => settingsRepository.setBiometricUnlockEnabled(true));
    },
  );
}

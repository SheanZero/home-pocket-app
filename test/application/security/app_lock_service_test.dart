import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/security/app_lock_service.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/infrastructure/security/biometric_service.dart';
import 'package:home_pocket/infrastructure/security/models/auth_result.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

class _MockBiometricService extends Mock implements BiometricService {}

void main() {
  late _MockSettingsRepository settings;
  late _MockSecureStorageService secure;
  late _MockBiometricService biometric;
  late AppLockService service;

  // In-memory pinHash slot so setPin/verifyPin round-trip uses the REAL
  // pin_kdf (Argon2id) end-to-end rather than a mocked compare.
  String? storedHash;

  setUp(() {
    settings = _MockSettingsRepository();
    secure = _MockSecureStorageService();
    biometric = _MockBiometricService();
    service = AppLockService(
      settingsRepository: settings,
      secureStorage: secure,
      biometricService: biometric,
    );

    storedHash = null;
    when(() => secure.getPinHash()).thenAnswer((_) async => storedHash);
    when(() => secure.setPinHash(any())).thenAnswer((invocation) async {
      storedHash = invocation.positionalArguments.first as String;
    });
    when(() => secure.deletePinHash()).thenAnswer((_) async {
      storedHash = null;
    });
    when(() => settings.setAppLockEnabled(any())).thenAnswer((_) async {});
  });

  void stubSettings({
    bool appLockEnabled = false,
    bool biometricUnlockEnabled = false,
  }) {
    when(() => settings.getSettings()).thenAnswer(
      (_) async => AppSettings(
        appLockEnabled: appLockEnabled,
        biometricUnlockEnabled: biometricUnlockEnabled,
      ),
    );
  }

  group('isLockEffective truth table (D-01 single source of truth)', () {
    test('appLockEnabled=false, pinHash=null -> false', () async {
      stubSettings(appLockEnabled: false);
      storedHash = null;
      expect(await service.isLockEffective(), isFalse);
    });

    test('appLockEnabled=true, pinHash=null -> false (no PIN never locks)',
        () async {
      stubSettings(appLockEnabled: true);
      storedHash = null;
      expect(await service.isLockEffective(), isFalse);
    });

    test('appLockEnabled=false, pinHash present -> false', () async {
      stubSettings(appLockEnabled: false);
      storedHash = 'argon2id\$v=19\$m=19456,t=2,p=1\$c2FsdA==\$aGFzaA==';
      expect(await service.isLockEffective(), isFalse);
    });

    test('appLockEnabled=true, pinHash present -> true', () async {
      stubSettings(appLockEnabled: true);
      storedHash = 'argon2id\$v=19\$m=19456,t=2,p=1\$c2FsdA==\$aGFzaA==';
      expect(await service.isLockEffective(), isTrue);
    });
  });

  group('setPin / verifyPin round-trip (LOCK-06, real pin_kdf)', () {
    test('setPin stores an argon2id PHC string', () async {
      await service.setPin('1234');
      verify(() => secure.setPinHash(any())).called(1);
      expect(storedHash, isNotNull);
      expect(storedHash, startsWith('argon2id\$'));
    });

    test('verifyPin true for correct PIN, false for wrong PIN', () async {
      await service.setPin('1234');
      expect(await service.verifyPin('1234'), isTrue);
      expect(await service.verifyPin('0000'), isFalse);
    });

    test('verifyPin false when no PIN stored', () async {
      storedHash = null;
      expect(await service.verifyPin('1234'), isFalse);
    });
  });

  group('reauth (D-05 biometric-or-PIN gate)', () {
    test('biometricUnlockEnabled && authenticate success -> true', () async {
      stubSettings(appLockEnabled: true, biometricUnlockEnabled: true);
      when(() => biometric.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => const AuthResult.success());
      expect(await service.reauth(), isTrue);
    });

    test('biometricUnlockEnabled && fallbackToPIN -> false (caller does PIN)',
        () async {
      stubSettings(appLockEnabled: true, biometricUnlockEnabled: true);
      when(() => biometric.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => const AuthResult.fallbackToPIN());
      expect(await service.reauth(), isFalse);
    });

    test('biometricUnlockEnabled=false -> false without calling biometric',
        () async {
      stubSettings(appLockEnabled: true, biometricUnlockEnabled: false);
      expect(await service.reauth(), isFalse);
      verifyNever(() => biometric.authenticate(reason: any(named: 'reason')));
    });
  });

  group('disableLock side-effects (T-55-16: no stale hash re-arms lock)', () {
    test('persists appLockEnabled=false AND deletes pinHash', () async {
      storedHash = 'argon2id\$v=19\$m=19456,t=2,p=1\$c2FsdA==\$aGFzaA==';
      await service.disableLock();
      verify(() => settings.setAppLockEnabled(false)).called(1);
      verify(() => secure.deletePinHash()).called(1);
      expect(storedHash, isNull);
    });
  });

  group('enableLock', () {
    test('persists appLockEnabled=true', () async {
      await service.enableLock();
      verify(() => settings.setAppLockEnabled(true)).called(1);
    });
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/security/biometric_service.dart';
import 'package:home_pocket/infrastructure/security/models/auth_result.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late MockLocalAuthentication mockAuth;
  late BiometricService service;

  setUpAll(() {
    registerFallbackValue(const AuthenticationOptions());
  });

  setUp(() {
    mockAuth = MockLocalAuthentication();
    service = BiometricService(localAuth: mockAuth);
  });

  group('checkAvailability', () {
    test('returns notSupported when canCheck and isSupported are both false',
        () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.notSupported);
    });

    test('returns notEnrolled when supported but no biometrics enrolled',
        () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => []);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.notEnrolled);
    });

    test('returns faceId when face biometric is available', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.face]);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.faceId);
    });

    test('returns fingerprint when fingerprint biometric is available',
        () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.fingerprint);
    });

    test('returns generic when only iris or other biometric is available',
        () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.iris]);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.generic);
    });

    test('prioritizes faceId when both face and fingerprint are available',
        () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.face, BiometricType.fingerprint]);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.faceId);
    });
  });

  group('authenticate', () {
    void setupAvailableBiometrics() {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
    }

    test('returns success when biometric passes', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => true);

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.success());
    });

    test('returns failed with attempt count on first failure', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => false);

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.failed(failedAttempts: 1));
    });

    test('returns tooManyAttempts after 3 consecutive failures', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => false);

      // Fail 3 times
      await service.authenticate(reason: 'test');
      await service.authenticate(reason: 'test');
      await service.authenticate(reason: 'test');

      // 4th attempt should be blocked
      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.tooManyAttempts());
    });

    test('resets failed count on success', () async {
      setupAvailableBiometrics();

      // Fail twice
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => false);
      await service.authenticate(reason: 'test');
      await service.authenticate(reason: 'test');

      // Then succeed
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => true);
      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.success());

      // Fail again — count should be reset to 1, not 3
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => false);
      final afterReset = await service.authenticate(reason: 'test');

      expect(afterReset, const AuthResult.failed(failedAttempts: 1));
    });

    test('returns fallbackToPIN when biometrics not supported', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.fallbackToPIN());
    });

    test('returns fallbackToPIN when biometrics not enrolled', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => []);

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.fallbackToPIN());
    });

    test('returns lockedOut on PlatformException with lockedOut code',
        () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenThrow(PlatformException(code: 'LockedOut'));

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.lockedOut());
    });

    test('returns lockedOut on permanentlyLockedOut', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenThrow(PlatformException(code: 'PermanentlyLockedOut'));

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.lockedOut());
    });

    test('returns fallbackToPIN on notAvailable exception', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenThrow(PlatformException(code: 'NotAvailable'));

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.fallbackToPIN());
    });

    test('returns error on unknown PlatformException', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
          PlatformException(code: 'UnknownError', message: 'something broke'));

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.error(message: 'something broke'));
    });
  });

  group('resetFailedAttempts', () {
    test('allows biometric retry after manual reset', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      // Fail 3 times
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => false);
      await service.authenticate(reason: 'test');
      await service.authenticate(reason: 'test');
      await service.authenticate(reason: 'test');

      // Verify locked out
      final locked = await service.authenticate(reason: 'test');
      expect(locked, const AuthResult.tooManyAttempts());

      // Reset and succeed
      service.resetFailedAttempts();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => true);

      final result = await service.authenticate(reason: 'test');
      expect(result, const AuthResult.success());
    });
  });
}

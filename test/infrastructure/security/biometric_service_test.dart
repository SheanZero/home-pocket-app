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

  setUp(() {
    mockAuth = MockLocalAuthentication();
    service = BiometricService(localAuth: mockAuth);
  });

  group('checkAvailability', () {
    test(
      'returns notSupported when canCheck and isSupported are both false',
      () async {
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

        final result = await service.checkAvailability();

        expect(result, BiometricAvailability.notSupported);
      },
    );

    test(
      'returns notEnrolled when supported but no biometrics enrolled',
      () async {
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => []);

        final result = await service.checkAvailability();

        expect(result, BiometricAvailability.notEnrolled);
      },
    );

    test('returns faceId when face biometric is available', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(
        () => mockAuth.getAvailableBiometrics(),
      ).thenAnswer((_) async => [BiometricType.face]);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.faceId);
    });

    test(
      'returns fingerprint when fingerprint biometric is available',
      () async {
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => [BiometricType.fingerprint]);

        final result = await service.checkAvailability();

        expect(result, BiometricAvailability.fingerprint);
      },
    );

    test(
      'returns generic when only iris or other biometric is available',
      () async {
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => [BiometricType.iris]);

        final result = await service.checkAvailability();

        expect(result, BiometricAvailability.generic);
      },
    );

    test(
      'prioritizes faceId when both face and fingerprint are available',
      () async {
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.face, BiometricType.fingerprint],
        );

        final result = await service.checkAvailability();

        expect(result, BiometricAvailability.faceId);
      },
    );
  });

  group('authenticate', () {
    void setupAvailableBiometrics() {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(
        () => mockAuth.getAvailableBiometrics(),
      ).thenAnswer((_) async => [BiometricType.fingerprint]);
    }

    test('returns success when biometric passes', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: any(named: 'biometricOnly'),
          sensitiveTransaction: any(named: 'sensitiveTransaction'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
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
          biometricOnly: any(named: 'biometricOnly'),
          sensitiveTransaction: any(named: 'sensitiveTransaction'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
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
          biometricOnly: any(named: 'biometricOnly'),
          sensitiveTransaction: any(named: 'sensitiveTransaction'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
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
          biometricOnly: any(named: 'biometricOnly'),
          sensitiveTransaction: any(named: 'sensitiveTransaction'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
        ),
      ).thenAnswer((_) async => false);
      await service.authenticate(reason: 'test');
      await service.authenticate(reason: 'test');

      // Then succeed
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: any(named: 'biometricOnly'),
          sensitiveTransaction: any(named: 'sensitiveTransaction'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
        ),
      ).thenAnswer((_) async => true);
      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.success());

      // Fail again — count should be reset to 1, not 3
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: any(named: 'biometricOnly'),
          sensitiveTransaction: any(named: 'sensitiveTransaction'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
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
      when(() => mockAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.fallbackToPIN());
    });

    // LOCK-05 / LOCK-10: local_auth 3.x throws LocalAuthException with a
    // LocalAuthExceptionCode enum (NOT a PlatformException with string codes).
    // EVERY one of the 14 codes — including the two lockout codes that the
    // legacy handler dead-ended at AuthResult.lockedOut() — MUST surface as a
    // PIN-fallback outcome so the user is never ejected from their own data.
    void whenAuthenticateThrows(Object error) {
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: any(named: 'biometricOnly'),
          sensitiveTransaction: any(named: 'sensitiveTransaction'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
        ),
      ).thenThrow(error);
    }

    // Exhaustive: all 14 LocalAuthExceptionCode values as of platform
    // interface 1.1.0. If a new code is added upstream the wildcard arm in
    // BiometricService keeps it on the PIN-fallback path.
    const allCodes = <LocalAuthExceptionCode>[
      LocalAuthExceptionCode.authInProgress,
      LocalAuthExceptionCode.uiUnavailable,
      LocalAuthExceptionCode.userCanceled,
      LocalAuthExceptionCode.timeout,
      LocalAuthExceptionCode.systemCanceled,
      LocalAuthExceptionCode.noCredentialsSet,
      LocalAuthExceptionCode.noBiometricsEnrolled,
      LocalAuthExceptionCode.noBiometricHardware,
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable,
      LocalAuthExceptionCode.temporaryLockout,
      LocalAuthExceptionCode.biometricLockout,
      LocalAuthExceptionCode.userRequestedFallback,
      LocalAuthExceptionCode.deviceError,
      LocalAuthExceptionCode.unknownError,
    ];

    for (final code in allCodes) {
      test(
        'LocalAuthException(${code.name}) -> fallbackToPIN (never ejects user)',
        () async {
          setupAvailableBiometrics();
          whenAuthenticateThrows(LocalAuthException(code: code));

          final result = await service.authenticate(reason: 'test');

          expect(result, const AuthResult.fallbackToPIN());
        },
      );
    }

    // Residual safety net: a stray PlatformException (legacy throw type) must
    // still resolve to PIN fallback, never an uncaught throw.
    test(
      'residual net: stray PlatformException -> fallbackToPIN',
      () async {
        setupAvailableBiometrics();
        whenAuthenticateThrows(
          PlatformException(code: 'LockedOut', message: 'legacy'),
        );

        final result = await service.authenticate(reason: 'test');

        expect(result, const AuthResult.fallbackToPIN());
      },
    );

    // Residual safety net: any other Exception type -> PIN fallback.
    test('residual net: generic Exception -> fallbackToPIN', () async {
      setupAvailableBiometrics();
      whenAuthenticateThrows(Exception('unexpected'));

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.fallbackToPIN());
    });
  });

  group('resetFailedAttempts', () {
    test('allows biometric retry after manual reset', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(
        () => mockAuth.getAvailableBiometrics(),
      ).thenAnswer((_) async => [BiometricType.fingerprint]);

      // Fail 3 times
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: any(named: 'biometricOnly'),
          sensitiveTransaction: any(named: 'sensitiveTransaction'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
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
          biometricOnly: any(named: 'biometricOnly'),
          sensitiveTransaction: any(named: 'sensitiveTransaction'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
        ),
      ).thenAnswer((_) async => true);

      final result = await service.authenticate(reason: 'test');
      expect(result, const AuthResult.success());
    });
  });
}

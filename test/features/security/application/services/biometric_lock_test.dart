import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';
import 'package:home_pocket/features/security/application/services/biometric_lock.dart';
import 'package:home_pocket/features/security/domain/models/auth_result.dart';

@GenerateMocks([LocalAuthentication])
import 'biometric_lock_test.mocks.dart';

void main() {
  group('BiometricLock', () {
    late BiometricLock biometricLock;
    late MockLocalAuthentication mockLocalAuth;

    setUp(() {
      mockLocalAuth = MockLocalAuthentication();
      biometricLock = BiometricLock(localAuth: mockLocalAuth);
    });

    group('checkAvailability', () {
      test('should return faceId when Face ID is available', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        // Act
        final availability = await biometricLock.checkAvailability();

        // Assert
        expect(availability, BiometricAvailability.faceId);
      });

      test('should return fingerprint when fingerprint is available', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.fingerprint]);

        // Act
        final availability = await biometricLock.checkAvailability();

        // Assert
        expect(availability, BiometricAvailability.fingerprint);
      });

      test('should return notSupported when hardware not supported', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final availability = await biometricLock.checkAvailability();

        // Assert
        expect(availability, BiometricAvailability.notSupported);
      });

      test('should return notEnrolled when no biometrics enrolled', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => []);

        // Act
        final availability = await biometricLock.checkAvailability();

        // Assert
        expect(availability, BiometricAvailability.notEnrolled);
      });
    });

    group('authenticate', () {
      test('should return success when authentication succeeds', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          authMessages: anyNamed('authMessages'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await biometricLock.authenticate(
          reason: 'Test authentication',
        );

        // Assert
        expect(
          result.when(
            success: () => true,
            failed: (_) => false,
            fallbackToPIN: () => false,
            tooManyAttempts: () => false,
            lockedOut: () => false,
            error: (_) => false,
          ),
          isTrue,
        );
      });

      test('should return failed and increment counter when auth fails', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          authMessages: anyNamed('authMessages'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => false);

        // Act
        final result = await biometricLock.authenticate(
          reason: 'Test authentication',
        );

        // Assert
        final isFailed = result.when(
          success: () => false,
          failed: (_) => true,
          fallbackToPIN: () => false,
          tooManyAttempts: () => false,
          lockedOut: () => false,
          error: (_) => false,
        );
        final attemptCount = result.when(
          success: () => null,
          failed: (failedAttempts) => failedAttempts,
          fallbackToPIN: () => null,
          tooManyAttempts: () => null,
          lockedOut: () => null,
          error: (_) => null,
        );
        expect(isFailed, isTrue);
        expect(attemptCount, 1);
      });

      test('should return tooManyAttempts after 3 failures', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          authMessages: anyNamed('authMessages'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => false);

        // Act: Fail 3 times, then 4th attempt should be blocked
        await biometricLock.authenticate(reason: 'Test'); // failure 1
        await biometricLock.authenticate(reason: 'Test'); // failure 2
        await biometricLock.authenticate(reason: 'Test'); // failure 3
        final result = await biometricLock.authenticate(reason: 'Test'); // 4th attempt - blocked

        // Assert
        expect(
          result.when(
            success: () => false,
            failed: (_) => false,
            fallbackToPIN: () => false,
            tooManyAttempts: () => true,
            lockedOut: () => false,
            error: (_) => false,
          ),
          isTrue,
        );
      });

      test('should return lockedOut when PlatformException LockedOut', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          authMessages: anyNamed('authMessages'),
          options: anyNamed('options'),
        )).thenThrow(PlatformException(code: auth_error.lockedOut));

        // Act
        final result = await biometricLock.authenticate(
          reason: 'Test authentication',
        );

        // Assert
        expect(
          result.when(
            success: () => false,
            failed: (_) => false,
            fallbackToPIN: () => false,
            tooManyAttempts: () => false,
            lockedOut: () => true,
            error: (_) => false,
          ),
          isTrue,
        );
      });

      test('should return fallbackToPIN when biometric not available', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final result = await biometricLock.authenticate(
          reason: 'Test authentication',
        );

        // Assert
        expect(
          result.when(
            success: () => false,
            failed: (_) => false,
            fallbackToPIN: () => true,
            tooManyAttempts: () => false,
            lockedOut: () => false,
            error: (_) => false,
          ),
          isTrue,
        );
      });
    });

    group('resetFailedAttempts', () {
      test('should reset failed attempts counter', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          authMessages: anyNamed('authMessages'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => false);

        // Act: Fail once
        await biometricLock.authenticate(reason: 'Test');

        // Reset
        biometricLock.resetFailedAttempts();

        // Try again
        final result = await biometricLock.authenticate(reason: 'Test');

        // Assert: Should be first failure again
        final attemptCount = result.when(
          success: () => null,
          failed: (failedAttempts) => failedAttempts,
          fallbackToPIN: () => null,
          tooManyAttempts: () => null,
          lockedOut: () => null,
          error: (_) => null,
        );
        expect(attemptCount, 1);
      });
    });
  });
}

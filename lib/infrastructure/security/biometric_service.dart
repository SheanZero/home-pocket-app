import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'models/auth_result.dart';

/// Biometric hardware availability status.
///
/// Android distinguishes between BIOMETRIC_STRONG (Class 3) and
/// BIOMETRIC_WEAK (Class 2). iOS Face ID and Touch ID are always strong.
enum BiometricAvailability {
  /// Face ID available (iOS) — always strong biometric.
  faceId,

  /// Fingerprint available (may be strong or weak on Android).
  fingerprint,

  /// Strong biometric available (Android Class 3).
  ///
  /// Class 3 biometrics meet the strictest security requirements:
  /// - Spoof acceptance rate < 7%
  /// - Must be hardware-backed
  strongBiometric,

  /// Weak biometric available (Android Class 2).
  ///
  /// Class 2 biometrics have relaxed security requirements.
  /// Use with caution for sensitive operations.
  weakBiometric,

  /// Generic biometric available (cannot determine specific type).
  generic,

  /// Device supports biometrics but user has not enrolled.
  notEnrolled,

  /// Device hardware does not support biometrics.
  notSupported,
}

/// Biometric authentication service wrapping platform APIs.
///
/// Encapsulates Face ID / Touch ID / Fingerprint authentication
/// with failure counting and lockout strategy.
class BiometricService {
  BiometricService({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;
  int _failedAttempts = 0;

  /// Maximum consecutive failures before forcing PIN fallback.
  static const int maxFailedAttempts = 3;

  /// Check current device biometric availability.
  Future<BiometricAvailability> checkAvailability() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();

    if (!canCheck && !isSupported) {
      return BiometricAvailability.notSupported;
    }

    final available = await _localAuth.getAvailableBiometrics();

    if (available.isEmpty) {
      return BiometricAvailability.notEnrolled;
    }

    if (available.contains(BiometricType.face)) {
      return BiometricAvailability.faceId;
    }
    if (available.contains(BiometricType.fingerprint)) {
      return BiometricAvailability.fingerprint;
    }
    return BiometricAvailability.generic;
  }

  /// Execute biometric authentication.
  ///
  /// [reason] is displayed in the system authentication dialog.
  /// [biometricOnly] prevents device PIN fallback if true.
  Future<AuthResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    final availability = await checkAvailability();
    if (availability == BiometricAvailability.notSupported ||
        availability == BiometricAvailability.notEnrolled) {
      return const AuthResult.fallbackToPIN();
    }

    if (_failedAttempts >= maxFailedAttempts) {
      return const AuthResult.tooManyAttempts();
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          sensitiveTransaction: true,
        ),
      );

      if (authenticated) {
        _failedAttempts = 0;
        return const AuthResult.success();
      } else {
        _failedAttempts++;
        return AuthResult.failed(failedAttempts: _failedAttempts);
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    }
  }

  /// Manually reset the failure counter (e.g. after successful PIN auth).
  void resetFailedAttempts() {
    _failedAttempts = 0;
  }

  AuthResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        return const AuthResult.lockedOut();
      case 'NotAvailable':
      case 'NotEnrolled':
        return const AuthResult.fallbackToPIN();
      default:
        return AuthResult.error(
          message: e.message ?? 'Unknown biometric error',
        );
    }
  }
}

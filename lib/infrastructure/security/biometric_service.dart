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
  ///
  /// [biometricOnly] defaults to `true` (secure-by-default, G2 / LOCK-05,06,10):
  /// this app's lock credential is its OWN 4-digit Argon2id PIN, so the iOS
  /// device passcode must NEVER satisfy app-lock auth. With `true`, `local_auth`
  /// selects a biometric-only LAPolicy and iOS never renders its
  /// "Enter iPhone passcode" sheet — every non-biometric outcome routes to the
  /// app's own PIN surface via [AuthResult.fallbackToPIN]. Passing `false` is an
  /// explicit opt-in to OS-passcode fallback; no caller in this app does so.
  Future<AuthResult> authenticate({
    required String reason,
    bool biometricOnly = true,
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
        biometricOnly: biometricOnly,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        _failedAttempts = 0;
        return const AuthResult.success();
      } else {
        _failedAttempts++;
        return AuthResult.failed(failedAttempts: _failedAttempts);
      }
    } on LocalAuthException catch (e) {
      // local_auth 3.x throws LocalAuthException with a LocalAuthExceptionCode
      // enum. EVERY classification maps to PIN fallback so the user is never
      // ejected from their own data (LOCK-05 / LOCK-10).
      //
      // The two lockout codes are named explicitly because the legacy handler
      // dead-ended them at AuthResult.lockedOut() (the T-55-06 bug): PIN is
      // exactly the "other auth" that recovers a biometric lockout, so they
      // MUST route to fallback, not a dead end. The reachable wildcard covers
      // the remaining current codes AND any future code the enum doc says may
      // be added non-breakingly — all on the same PIN-fallback path.
      return switch (e.code) {
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => const AuthResult.fallbackToPIN(),
        _ => const AuthResult.fallbackToPIN(),
      };
    } on PlatformException catch (_) {
      // Residual net: a legacy/stray PlatformException can never lock the user
      // out — route it to PIN fallback.
      return const AuthResult.fallbackToPIN();
    } catch (_) {
      // Belt-and-suspenders: no throw type of any kind escapes uncaught.
      return const AuthResult.fallbackToPIN();
    }
  }

  /// Manually reset the failure counter (e.g. after successful PIN auth).
  void resetFailedAttempts() {
    _failedAttempts = 0;
  }
}

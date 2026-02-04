import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import '../../domain/models/auth_result.dart';

part 'biometric_lock.g.dart';

enum BiometricAvailability {
  faceId,
  fingerprint,
  generic,
  notEnrolled,
  notSupported,
}

class BiometricLock {
  final LocalAuthentication _localAuth;
  int _failedAttempts = 0;
  static const int maxFailedAttempts = 3;

  BiometricLock({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// 检查设备是否支持生物识别
  Future<BiometricAvailability> checkAvailability() async {
    try {
      // 1. 检查设备硬件支持
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        return BiometricAvailability.notSupported;
      }

      // 2. 获取可用的生物识别类型
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return BiometricAvailability.notEnrolled;
      }

      // 3. 确定具体类型
      if (availableBiometrics.contains(BiometricType.face)) {
        return BiometricAvailability.faceId;
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return BiometricAvailability.fingerprint;
      } else if (availableBiometrics.contains(BiometricType.strong) ||
          availableBiometrics.contains(BiometricType.weak)) {
        return BiometricAvailability.generic;
      }

      return BiometricAvailability.notSupported;
    } catch (e) {
      return BiometricAvailability.notSupported;
    }
  }

  /// 执行生物识别认证
  Future<AuthResult> authenticate({
    required String reason,
    bool allowPINFallback = true,
  }) async {
    try {
      // 1. 检查可用性
      final availability = await checkAvailability();
      if (availability == BiometricAvailability.notSupported ||
          availability == BiometricAvailability.notEnrolled) {
        return AuthResult.fallbackToPIN();
      }

      // 2. 检查失败次数
      if (_failedAttempts >= maxFailedAttempts) {
        return AuthResult.tooManyAttempts();
      }

      // 3. 执行认证
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'Home Pocket 認証',
            cancelButton: 'キャンセル',
            biometricHint: '指紋または顔で認証',
          ),
          IOSAuthMessages(
            cancelButton: 'キャンセル',
            goToSettingsButton: '設定',
            goToSettingsDescription: '生体認証を設定してください',
            lockOut: '生体認証がロックされました',
          ),
        ],
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: !allowPINFallback,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      if (didAuthenticate) {
        _failedAttempts = 0;
        return AuthResult.success();
      } else {
        _failedAttempts++;
        return AuthResult.failed(failedAttempts: _failedAttempts);
      }
    } on PlatformException catch (e) {
      if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return AuthResult.lockedOut();
      } else if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled) {
        return AuthResult.fallbackToPIN();
      } else {
        _failedAttempts++;
        return AuthResult.error(message: e.message ?? '認証失敗');
      }
    } catch (e) {
      _failedAttempts++;
      return AuthResult.error(message: e.toString());
    }
  }

  /// 重置失败次数
  void resetFailedAttempts() {
    _failedAttempts = 0;
  }

  /// 获取当前失败次数
  int get failedAttempts => _failedAttempts;
}

@riverpod
BiometricLock biometricLock(BiometricLockRef ref) {
  return BiometricLock();
}

@riverpod
Future<BiometricAvailability> biometricAvailability(
  BiometricAvailabilityRef ref,
) async {
  final biometricLock = ref.watch(biometricLockProvider);
  return await biometricLock.checkAvailability();
}

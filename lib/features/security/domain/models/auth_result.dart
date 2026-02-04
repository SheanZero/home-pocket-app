import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_result.freezed.dart';

/// Authentication result with multiple variants using Freezed union type
@freezed
class AuthResult with _$AuthResult {
  /// Authentication succeeded
  const factory AuthResult.success() = AuthSuccess;

  /// Authentication failed with number of attempts
  const factory AuthResult.failed({
    required int failedAttempts,
  }) = AuthFailed;

  /// Device does not support biometric authentication, fallback to PIN required
  const factory AuthResult.fallbackToPIN() = AuthFallbackToPIN;

  /// Too many failed attempts, temporarily locked
  const factory AuthResult.tooManyAttempts() = AuthTooManyAttempts;

  /// Account locked out due to security policy
  const factory AuthResult.lockedOut() = AuthLockedOut;

  /// Authentication error occurred
  const factory AuthResult.error({
    required String message,
  }) = AuthError;
}

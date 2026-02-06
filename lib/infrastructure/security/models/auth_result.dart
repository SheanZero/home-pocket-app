import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_result.freezed.dart';

/// Authentication result union type.
///
/// Used by [BiometricService] to represent all possible
/// outcomes of an authentication attempt. Callers use `when`
/// to exhaustively handle every case.
@freezed
sealed class AuthResult with _$AuthResult {
  /// Authentication succeeded.
  const factory AuthResult.success() = AuthResultSuccess;

  /// Authentication failed. [failedAttempts] is the cumulative count.
  const factory AuthResult.failed({required int failedAttempts}) =
      AuthResultFailed;

  /// Biometric not available — fall back to PIN authentication.
  const factory AuthResult.fallbackToPIN() = AuthResultFallbackToPIN;

  /// Too many consecutive failures (>= 3). Force PIN authentication.
  const factory AuthResult.tooManyAttempts() = AuthResultTooManyAttempts;

  /// Device biometric is locked by the OS.
  const factory AuthResult.lockedOut() = AuthResultLockedOut;

  /// An unexpected platform error occurred.
  const factory AuthResult.error({required String message}) = AuthResultError;
}

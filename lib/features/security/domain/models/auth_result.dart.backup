import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_result.freezed.dart';

enum AuthStatus {
  success,
  failed,
  fallbackToPIN,
  tooManyAttempts,
  lockedOut,
  error,
}

@freezed
class AuthResult with _$AuthResult {
  const factory AuthResult({
    required AuthStatus status,
    String? message,
    int? failedAttempts,
  }) = _AuthResult;

  factory AuthResult.success() => const AuthResult(status: AuthStatus.success);

  factory AuthResult.failed(int attempts) => AuthResult(
        status: AuthStatus.failed,
        failedAttempts: attempts,
      );

  factory AuthResult.fallbackToPIN() => const AuthResult(
        status: AuthStatus.fallbackToPIN,
      );

  factory AuthResult.tooManyAttempts() => const AuthResult(
        status: AuthStatus.tooManyAttempts,
      );

  factory AuthResult.lockedOut() => const AuthResult(
        status: AuthStatus.lockedOut,
      );

  factory AuthResult.error(String message) => AuthResult(
        status: AuthStatus.error,
        message: message,
      );
}

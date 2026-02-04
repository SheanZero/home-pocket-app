import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/security/domain/models/auth_result.dart';

void main() {
  group('AuthResult', () {
    test('should create success result', () {
      final result = AuthResult.success();

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

    test('should create failed result with attempt count', () {
      final result = AuthResult.failed(failedAttempts: 2);

      final attempts = result.when(
        success: () => null,
        failed: (failedAttempts) => failedAttempts,
        fallbackToPIN: () => null,
        tooManyAttempts: () => null,
        lockedOut: () => null,
        error: (_) => null,
      );

      expect(attempts, 2);
    });

    test('should create fallback to PIN result', () {
      final result = AuthResult.fallbackToPIN();

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

    test('should create too many attempts result', () {
      final result = AuthResult.tooManyAttempts();

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

    test('should create locked out result', () {
      final result = AuthResult.lockedOut();

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

    test('should create error result with message', () {
      final result = AuthResult.error(message: 'Test error');

      final message = result.when(
        success: () => null,
        failed: (_) => null,
        fallbackToPIN: () => null,
        tooManyAttempts: () => null,
        lockedOut: () => null,
        error: (message) => message,
      );

      expect(message, 'Test error');
    });

    test('maybeWhen should work with orElse', () {
      final result = AuthResult.success();

      final isSuccess = result.maybeWhen(
        success: () => true,
        orElse: () => false,
      );

      expect(isSuccess, isTrue);
    });

    test('maybeWhen should use orElse for unhandled variants', () {
      final result = AuthResult.error(message: 'Test error');

      final isSuccess = result.maybeWhen(
        success: () => true,
        orElse: () => false,
      );

      expect(isSuccess, isFalse);
    });
  });
}

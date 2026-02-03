import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/security/domain/models/auth_result.dart';

void main() {
  group('AuthResult', () {
    test('should create success result', () {
      final result = AuthResult.success();

      expect(result.status, AuthStatus.success);
      expect(result.message, isNull);
      expect(result.failedAttempts, isNull);
    });

    test('should create failed result with attempt count', () {
      final result = AuthResult.failed(2);

      expect(result.status, AuthStatus.failed);
      expect(result.failedAttempts, 2);
    });

    test('should create fallback to PIN result', () {
      final result = AuthResult.fallbackToPIN();

      expect(result.status, AuthStatus.fallbackToPIN);
    });

    test('should create too many attempts result', () {
      final result = AuthResult.tooManyAttempts();

      expect(result.status, AuthStatus.tooManyAttempts);
    });

    test('should create locked out result', () {
      final result = AuthResult.lockedOut();

      expect(result.status, AuthStatus.lockedOut);
    });

    test('should create error result with message', () {
      final result = AuthResult.error('Test error');

      expect(result.status, AuthStatus.error);
      expect(result.message, 'Test error');
    });
  });
}

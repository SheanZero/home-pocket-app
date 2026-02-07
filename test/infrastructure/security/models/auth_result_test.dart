import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/security/models/auth_result.dart';

void main() {
  group('AuthResult', () {
    test('creates success variant', () {
      const result = AuthResult.success();
      result.when(
        success: () => expect(true, isTrue),
        failed: (_) => fail('should be success'),
        fallbackToPIN: () => fail('should be success'),
        tooManyAttempts: () => fail('should be success'),
        lockedOut: () => fail('should be success'),
        error: (_) => fail('should be success'),
      );
    });

    test('creates failed variant with attempt count', () {
      const result = AuthResult.failed(failedAttempts: 2);
      result.when(
        success: () => fail('should be failed'),
        failed: (attempts) => expect(attempts, 2),
        fallbackToPIN: () => fail('should be failed'),
        tooManyAttempts: () => fail('should be failed'),
        lockedOut: () => fail('should be failed'),
        error: (_) => fail('should be failed'),
      );
    });

    test('creates fallbackToPIN variant', () {
      const result = AuthResult.fallbackToPIN();
      result.when(
        success: () => fail('should be fallbackToPIN'),
        failed: (_) => fail('should be fallbackToPIN'),
        fallbackToPIN: () => expect(true, isTrue),
        tooManyAttempts: () => fail('should be fallbackToPIN'),
        lockedOut: () => fail('should be fallbackToPIN'),
        error: (_) => fail('should be fallbackToPIN'),
      );
    });

    test('creates tooManyAttempts variant', () {
      const result = AuthResult.tooManyAttempts();
      result.when(
        success: () => fail('should be tooManyAttempts'),
        failed: (_) => fail('should be tooManyAttempts'),
        fallbackToPIN: () => fail('should be tooManyAttempts'),
        tooManyAttempts: () => expect(true, isTrue),
        lockedOut: () => fail('should be tooManyAttempts'),
        error: (_) => fail('should be tooManyAttempts'),
      );
    });

    test('creates lockedOut variant', () {
      const result = AuthResult.lockedOut();
      result.when(
        success: () => fail('should be lockedOut'),
        failed: (_) => fail('should be lockedOut'),
        fallbackToPIN: () => fail('should be lockedOut'),
        tooManyAttempts: () => fail('should be lockedOut'),
        lockedOut: () => expect(true, isTrue),
        error: (_) => fail('should be lockedOut'),
      );
    });

    test('creates error variant with message', () {
      const result = AuthResult.error(message: 'Unknown biometric error');
      result.when(
        success: () => fail('should be error'),
        failed: (_) => fail('should be error'),
        fallbackToPIN: () => fail('should be error'),
        tooManyAttempts: () => fail('should be error'),
        lockedOut: () => fail('should be error'),
        error: (msg) => expect(msg, 'Unknown biometric error'),
      );
    });

    test('supports equality comparison', () {
      expect(const AuthResult.success(), const AuthResult.success());
      expect(
        const AuthResult.failed(failedAttempts: 1),
        const AuthResult.failed(failedAttempts: 1),
      );
      expect(const AuthResult.success(), isNot(const AuthResult.lockedOut()));
    });
  });
}

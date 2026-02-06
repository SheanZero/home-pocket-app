import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/utils/result.dart';

void main() {
  group('Result', () {
    test('success creates a success result with data', () {
      final result = Result.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
      expect(result.data, 42);
      expect(result.error, isNull);
    });

    test('error creates an error result with message', () {
      final result = Result<int>.error('Something failed');

      expect(result.isError, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.error, 'Something failed');
      expect(result.data, isNull);
    });

    test('success with null data', () {
      final result = Result<String>.success(null);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });
  });
}

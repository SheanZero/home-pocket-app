import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/initialization/init_result.dart';

void main() {
  group('InitResult', () {
    test('InitSuccess carries container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const result = InitResult.success;
      final success = result(container: container);

      expect(success, isA<InitSuccess>());
      expect((success as InitSuccess).container, same(container));
    });

    test('InitFailure carries type, error, and optional stackTrace', () {
      final error = Exception('db error');
      final st = StackTrace.current;

      const result = InitResult.failure;
      final failure = result(
        type: InitFailureType.database,
        error: error,
        stackTrace: st,
      );

      expect(failure, isA<InitFailure>());
      final f = failure as InitFailure;
      expect(f.type, equals(InitFailureType.database));
      expect(f.error, same(error));
      expect(f.stackTrace, same(st));
    });

    test('InitFailure stackTrace defaults to null', () {
      final failure = InitResult.failure(
        type: InitFailureType.unknown,
        error: 'oops',
      );
      expect((failure as InitFailure).stackTrace, isNull);
    });

    test('InitFailureType has 4 variants', () {
      expect(InitFailureType.values, hasLength(4));
      expect(InitFailureType.values, containsAll([
        InitFailureType.masterKey,
        InitFailureType.database,
        InitFailureType.seed,
        InitFailureType.unknown,
      ]));
    });

    test('sealed class pattern matching on success', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = InitResult.success(container: container);

      final matched = switch (result) {
        InitSuccess(:final container) => 'success:${container.runtimeType}',
        InitFailure() => 'failure',
      };
      expect(matched, startsWith('success:'));
    });

    test('sealed class pattern matching on failure', () {
      final result = InitResult.failure(
        type: InitFailureType.masterKey,
        error: 'key error',
      );

      final matched = switch (result) {
        InitSuccess() => 'success',
        InitFailure(:final type) => 'failure:$type',
      };
      expect(matched, equals('failure:InitFailureType.masterKey'));
    });

    test('two InitSuccess with same container are equal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = InitResult.success(container: container);
      final b = InitResult.success(container: container);

      expect(a, equals(b));
    });

    test('two InitFailure with same values are equal', () {
      final error = Exception('x');
      final a = InitResult.failure(type: InitFailureType.seed, error: error);
      final b = InitResult.failure(type: InitFailureType.seed, error: error);

      expect(a, equals(b));
    });
  });
}

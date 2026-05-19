import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/_time_window_validation.dart';

void main() {
  group('TimeWindowValidation.assertValid', () {
    test('allows a valid one-month range', () {
      expect(
        () => TimeWindowValidation.assertValid(
          DateTime(2026, 4),
          DateTime(2026, 4, 30, 23, 59, 59),
        ),
        returnsNormally,
      );
    });

    test('allows a day-exact twelve-month range', () {
      expect(
        () => TimeWindowValidation.assertValid(
          DateTime(2025, 5, 15),
          DateTime(2026, 5, 15, 23, 59, 59),
        ),
        returnsNormally,
      );
    });

    test('rejects twelve months plus one day', () {
      expect(
        () => TimeWindowValidation.assertValid(
          DateTime(2025, 5, 15),
          DateTime(2026, 5, 16, 23, 59, 59),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects thirteen calendar months', () {
      expect(
        () => TimeWindowValidation.assertValid(
          DateTime(2025, 5, 15),
          DateTime(2026, 6, 14, 23, 59, 59),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects inverted ranges with startDate message', () {
      expect(
        () => TimeWindowValidation.assertValid(
          DateTime(2026, 5, 31, 23, 59, 59),
          DateTime(2026, 5),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('startDate must be <= endDate'),
          ),
        ),
      );
    });

    test('allows leap-year cross when end day is before start day', () {
      expect(
        () => TimeWindowValidation.assertValid(
          DateTime(2024, 2, 29),
          DateTime(2025, 2, 28, 23, 59, 59),
        ),
        returnsNormally,
      );
    });

    test('rejects leap-year range that crosses into a thirteenth month', () {
      expect(
        () => TimeWindowValidation.assertValid(
          DateTime(2024, 2, 29),
          DateTime(2025, 3, 1, 23, 59, 59),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects future end with future-end message', () {
      expect(
        () => TimeWindowValidation.assertValid(
          DateTime.now().subtract(const Duration(days: 1)),
          DateTime.now().add(const Duration(days: 2)),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('endDate must not be in the future'),
          ),
        ),
      );
    });

    test('allows end dates just before now', () {
      expect(
        () => TimeWindowValidation.assertValid(
          DateTime.now().subtract(const Duration(hours: 1)),
          DateTime.now().subtract(const Duration(seconds: 1)),
        ),
        returnsNormally,
      );
    });

    test('exposes only static validation through a private constructor', () {
      expect(
        TimeWindowValidation.assertValid,
        isA<void Function(DateTime, DateTime)>(),
      );
    });
  });
}

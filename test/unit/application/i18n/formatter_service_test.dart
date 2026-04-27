import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/i18n/formatter_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  group('FormatterService', () {
    late FormatterService service;

    setUpAll(() async {
      // intl requires locale data to be initialized before use in tests.
      await initializeDateFormatting('ja', null);
      await initializeDateFormatting('zh', null);
      await initializeDateFormatting('en', null);
    });

    setUp(() {
      service = const FormatterService();
    });

    group('formatDate', () {
      test('formats date in Japanese locale', () {
        final result = service.formatDate(
          DateTime(2026, 4, 26),
          const Locale('ja'),
        );
        expect(result, '2026/04/26');
      });

      test('formats date in Chinese locale', () {
        final result = service.formatDate(
          DateTime(2026, 4, 26),
          const Locale('zh'),
        );
        expect(result, '2026年04月26日');
      });

      test('formats date in English locale', () {
        final result = service.formatDate(
          DateTime(2026, 4, 26),
          const Locale('en'),
        );
        expect(result, '04/26/2026');
      });
    });

    group('formatCurrency', () {
      test('formats JPY with no decimals', () {
        final result = service.formatCurrency(1234, 'JPY', const Locale('ja'));
        expect(result, '¥1,234');
      });

      test('formats USD with 2 decimals', () {
        final result = service.formatCurrency(
          1234.5,
          'USD',
          const Locale('en'),
        );
        expect(result, '\$1,234.50');
      });
    });

    group('formatterServiceProvider', () {
      test('returns a FormatterService instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final instance = container.read(formatterServiceProvider);
        expect(instance, isA<FormatterService>());
      });

      test('returns the same instance across two reads (const)', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final a = container.read(formatterServiceProvider);
        final b = container.read(formatterServiceProvider);
        expect(identical(a, b), isTrue);
      });
    });

    group('delegation smoke tests', () {
      test('formatRelative returns today for DateTime.now()', () {
        final result = service.formatRelative(
          DateTime.now(),
          const Locale('ja'),
        );
        expect(result, '今日');
      });

      test('formatMonthYear returns expected format for Japanese', () {
        final result = service.formatMonthYear(
          DateTime(2026, 4, 1),
          const Locale('ja'),
        );
        expect(result, contains('2026'));
        expect(result, contains('4'));
      });

      test('formatNumber delegates correctly', () {
        final result = service.formatNumber(
          1234.56,
          const Locale('en'),
          decimals: 2,
        );
        expect(result, contains('1,234'));
      });

      test('formatDateTime delegates correctly', () {
        final result = service.formatDateTime(
          DateTime(2026, 4, 26, 10, 30),
          const Locale('ja'),
        );
        expect(result, contains('2026/04/26'));
        expect(result, contains('10:30'));
      });

      test('formatPercentage delegates correctly', () {
        final result = service.formatPercentage(0.5, const Locale('en'));
        expect(result, contains('50'));
        expect(result, contains('%'));
      });

      test('formatCompact delegates correctly for large numbers', () {
        final result = service.formatCompact(12000, const Locale('ja'));
        // 12000 / 10000 = 1.2 万
        expect(result, contains('万'));
      });
    });
  });
}

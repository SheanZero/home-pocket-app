import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/utils/formatters/date_formatter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  // Initialize date formatting for all supported locales
  setUpAll(() async {
    await initializeDateFormatting('ja', null);
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('zh', null);
  });

  group('DateFormatter', () {
    final testDate = DateTime(2026, 2, 3, 14, 30, 45);

    test('should format date in Japanese locale (YYYY/MM/DD)', () {
      // Act
      final result = DateFormatter.formatDate(testDate, const Locale('ja'));

      // Assert
      expect(result, '2026/02/03');
    });

    test('should format date in English locale (MM/DD/YYYY)', () {
      // Act
      final result = DateFormatter.formatDate(testDate, const Locale('en'));

      // Assert
      expect(result, '02/03/2026');
    });

    test('should format date in Chinese locale (YYYY年MM月DD日)', () {
      // Act
      final result = DateFormatter.formatDate(testDate, const Locale('zh'));

      // Assert
      expect(result, '2026年02月03日');
    });

    test('should format datetime with time in Japanese', () {
      // Act
      final result = DateFormatter.formatDateTime(testDate, const Locale('ja'));

      // Assert
      expect(result, '2026/02/03 14:30');
    });

    test('should format datetime with time in English', () {
      // Act
      final result = DateFormatter.formatDateTime(testDate, const Locale('en'));

      // Assert
      expect(result, '02/03/2026 2:30 PM');
    });

    test('should format relative time', () {
      // Arrange
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      // Act & Assert (relative times in Japanese)
      expect(
        DateFormatter.formatRelative(now, const Locale('ja')),
        contains('今'),
      );
      expect(
        DateFormatter.formatRelative(yesterday, const Locale('ja')),
        contains('昨日'),
      );
    });

    test('should format month and year', () {
      // Act
      final resultJa =
          DateFormatter.formatMonthYear(testDate, const Locale('ja'));
      final resultEn =
          DateFormatter.formatMonthYear(testDate, const Locale('en'));
      final resultZh =
          DateFormatter.formatMonthYear(testDate, const Locale('zh'));

      // Assert
      expect(resultJa, '2026年2月');
      expect(resultEn, 'February 2026');
      expect(resultZh, '2026年2月');
    });
  });
}

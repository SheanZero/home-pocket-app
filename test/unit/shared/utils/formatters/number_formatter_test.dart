import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/utils/formatters/number_formatter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  // Initialize number formatting for all supported locales
  setUpAll(() async {
    await initializeDateFormatting('ja', null);
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('zh', null);
  });

  group('NumberFormatter', () {
    test('should format number with thousand separators for Japanese', () {
      // Act
      final result =
          NumberFormatter.formatNumber(1234567.89, const Locale('ja'));

      // Assert
      expect(result, '1,234,567.89');
    });

    test('should format number with thousand separators for English', () {
      // Act
      final result =
          NumberFormatter.formatNumber(1234567.89, const Locale('en'));

      // Assert
      expect(result, '1,234,567.89');
    });

    test('should format number with thousand separators for Chinese', () {
      // Act
      final result =
          NumberFormatter.formatNumber(1234567.89, const Locale('zh'));

      // Assert
      expect(result, '1,234,567.89');
    });

    test('should format integer without decimals', () {
      // Act
      final resultJa =
          NumberFormatter.formatNumber(1234, const Locale('ja'), decimals: 0);
      final resultEn =
          NumberFormatter.formatNumber(1234, const Locale('en'), decimals: 0);

      // Assert
      expect(resultJa, '1,234');
      expect(resultEn, '1,234');
    });

    test('should format currency in JPY', () {
      // Act
      final result =
          NumberFormatter.formatCurrency(1234.5, 'JPY', const Locale('ja'));

      // Assert
      expect(result, '¥1,235'); // JPY rounds to integer
    });

    test('should format currency in CNY', () {
      // Act
      final result =
          NumberFormatter.formatCurrency(1234.56, 'CNY', const Locale('zh'));

      // Assert
      expect(result, '¥1,234.56');
    });

    test('should format currency in USD', () {
      // Act
      final result =
          NumberFormatter.formatCurrency(1234.56, 'USD', const Locale('en'));

      // Assert
      expect(result, r'$1,234.56');
    });

    test('should format percentage', () {
      // Act
      final resultJa =
          NumberFormatter.formatPercentage(0.8523, const Locale('ja'));
      final resultEn =
          NumberFormatter.formatPercentage(0.8523, const Locale('en'));

      // Assert
      expect(resultJa, '85.23%');
      expect(resultEn, '85.23%');
    });

    test('should format compact numbers', () {
      // Act
      final resultJa =
          NumberFormatter.formatCompact(1234567, const Locale('ja'));
      final resultEn =
          NumberFormatter.formatCompact(1234567, const Locale('en'));

      // Assert
      expect(resultJa, '123万'); // Japanese uses 万 (10,000)
      expect(resultEn, '1.23M'); // English compact format
    });
  });
}

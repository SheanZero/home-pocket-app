import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Locale-aware number and currency formatting utility
///
/// Provides consistent number, currency, and percentage formatting across the app
/// with support for:
/// - Japanese (JPY ¥, comma separators)
/// - Chinese (CNY ¥, comma separators)
/// - English (USD $, comma separators)
class NumberFormatter {
  NumberFormatter._(); // Private constructor - utility class

  /// Format number with thousand separators and decimals
  ///
  /// Examples:
  /// - 1234567.89 → "1,234,567.89"
  /// - 1234 (decimals: 0) → "1,234"
  static String formatNumber(
    num number,
    Locale locale, {
    int decimals = 2,
  }) {
    final formatter = NumberFormat.decimalPattern(locale.toString());
    formatter.minimumFractionDigits = decimals;
    formatter.maximumFractionDigits = decimals;
    return formatter.format(number);
  }

  /// Format currency with symbol and locale-specific formatting
  ///
  /// Supports JPY (¥, no decimals), CNY (¥), USD ($), EUR (€), GBP (£)
  ///
  /// Examples:
  /// - 1234.5 JPY → "¥1,235"
  /// - 1234.56 USD → "$1,234.56"
  static String formatCurrency(
    num amount,
    String currencyCode,
    Locale locale,
  ) {
    final formatter = NumberFormat.currency(
      locale: locale.toString(),
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: _getCurrencyDecimals(currencyCode),
    );
    return formatter.format(amount);
  }

  /// Format percentage
  ///
  /// Example: 0.8523 → "85.23%"
  static String formatPercentage(
    double value,
    Locale locale, {
    int decimals = 2,
  }) {
    final percentage = value * 100;
    final formatter = NumberFormat.decimalPattern(locale.toString());
    formatter.minimumFractionDigits = decimals;
    formatter.maximumFractionDigits = decimals;
    return '${formatter.format(percentage)}%';
  }

  /// Format compact numbers (1.2M for English, 123万 for Japanese/Chinese)
  ///
  /// Japanese/Chinese use 万 (10,000) as the unit
  /// English uses K, M, B
  ///
  /// Examples:
  /// - 1234567 (ja) → "123万"
  /// - 1234567 (en) → "1.2M"
  static String formatCompact(num number, Locale locale) {
    if (locale.languageCode == 'ja' || locale.languageCode == 'zh') {
      // Japanese/Chinese use 万 (10,000) as unit
      if (number >= 10000) {
        final manValue = number / 10000;
        return '${formatNumber(manValue, locale, decimals: manValue >= 100 ? 0 : 1)}万';
      }
    }

    // English uses K, M, B
    final formatter = NumberFormat.compact(locale: locale.toString());
    return formatter.format(number);
  }

  /// Get currency symbol for currency code
  static String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'JPY':
      case 'CNY':
        return '¥';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currencyCode;
    }
  }

  /// Get decimal places for currency
  static int _getCurrencyDecimals(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'JPY': // Japanese Yen has no decimals
        return 0;
      default:
        return 2;
    }
  }
}

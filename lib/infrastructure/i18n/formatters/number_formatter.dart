import 'dart:ui';

import 'package:intl/intl.dart';

class NumberFormatter {
  NumberFormatter._();

  static String formatNumber(num number, Locale locale, {int decimals = 2}) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale.toString(),
      decimalDigits: decimals,
    );
    return formatter.format(number);
  }

  static String formatCurrency(num amount, String currencyCode, Locale locale) {
    final formatter = NumberFormat.currency(
      locale: locale.toString(),
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: _getCurrencyDecimals(currencyCode),
    );
    return formatter.format(amount);
  }

  static String formatPercentage(
    double value,
    Locale locale, {
    int decimals = 2,
  }) {
    final percentage = value * 100;
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale.toString(),
      decimalDigits: decimals,
    );
    return '${formatter.format(percentage)}%';
  }

  static String formatCompact(num number, Locale locale) {
    if (locale.languageCode == 'ja' || locale.languageCode == 'zh') {
      if (number >= 10000) {
        final manValue = number / 10000;
        final formatted = formatNumber(
          manValue,
          locale,
          decimals: manValue >= 100 ? 0 : 1,
        );
        return '$formatted\u4e07';
      }
    }
    final formatter = NumberFormat.compact(locale: locale.toString());
    return formatter.format(number);
  }

  static String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'JPY':
        return '\u00a5'; // \u00a5
      case 'CNY':
        return 'CN\u00a5'; // CN\u00a5 \u2014 disambiguated from JPY (D-06)
      case 'KRW':
        return '\u20a9'; // \u20a9
      case 'USD':
        return r'$';
      case 'EUR':
        return '\u20ac'; // \u20ac
      case 'GBP':
        return '\u00a3'; // \u00a3
      case 'HKD':
        return 'HK\$'; // D-06
      case 'AUD':
        return 'A\$'; // D-06
      case 'CAD':
        return 'C\$'; // D-06
      case 'TWD':
        return 'NT\$'; // D-06
      case 'SGD':
        return 'S\$'; // D-06
      default:
        return currencyCode; // ISO code prefix fallback (D-07)
    }
  }

  static int _getCurrencyDecimals(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'JPY':
      case 'KRW': // D-08: KRW uses 0 decimal places
        return 0;
      default:
        return 2;
    }
  }
}

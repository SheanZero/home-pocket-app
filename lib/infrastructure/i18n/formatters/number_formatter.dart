import 'dart:ui';

import 'package:intl/intl.dart';

import '../../../shared/utils/currency_conversion.dart'
    show currencyFractionDigitsFor;

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
      // Long-tail currencies with recognized glyphs (260613-ote).
      // Non-ASCII glyphs written as \uXXXX escapes (matches the '¥' style
      // above); readable symbol noted in the trailing comment.
      case 'THB':
        return '\u0e3f'; // ฿
      case 'INR':
        return '\u20b9'; // ₹
      case 'IDR':
        return 'Rp';
      case 'MYR':
        return 'RM';
      case 'PHP':
        return '\u20b1'; // ₱
      case 'VND':
        return '\u20ab'; // ₫
      case 'NZD':
        return 'NZ\$'; // D-06 style
      case 'BRL':
        return 'R\$';
      case 'RUB':
        return '\u20bd'; // ₽
      case 'ZAR':
        return 'R';
      case 'SEK':
        return 'kr';
      case 'NOK':
        return 'kr';
      case 'DKK':
        return 'kr';
      case 'MXN':
        return 'MX\$'; // D-06 style
      case 'TRY':
        return '\u20ba'; // ₺
      case 'PLN':
        return 'z\u0142'; // zł
      // CHF / AED / SAR intentionally have no case: their conventional "symbol"
      // is the ISO code itself (no common single glyph) — they fall through to
      // the default ISO-code fallback below (D-07).
      default:
        return currencyCode; // ISO code prefix fallback (D-07)
    }
  }

  /// ISO 4217 minor-unit decimals, sourced from intl's `currencyFractionDigits`
  /// via the single shared helper [currencyFractionDigitsFor] (JPY/KRW=0,
  /// USD/EUR/CNY=2, BHD/JOD/KWD=3). KRW stays an explicit 0-decimal case inside
  /// the helper; unknown codes fall back to 2 there — never a hardcoded default
  /// here (keeps decimals + subunit consistent with currency_conversion.dart).
  static int _getCurrencyDecimals(String currencyCode) =>
      currencyFractionDigitsFor(currencyCode);
}

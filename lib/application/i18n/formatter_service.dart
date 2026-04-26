import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../infrastructure/i18n/formatters/number_formatter.dart';

part 'formatter_service.g.dart';

/// Application-layer injectable wrapper around the infrastructure formatters.
///
/// Delegates to [DateFormatter] and [NumberFormatter] static implementations
/// so feature presentation never imports infrastructure/ directly (HIGH-02).
///
/// `const` constructor — no instance state; const semantics ensure a single
/// canonical instance is returned by [formatterServiceProvider].
class FormatterService {
  const FormatterService();

  // ── Date formatting ──────────────────────────────────────────────────────

  /// Format a [date] to a locale-appropriate date string.
  ///
  /// ja: 2026/04/26 · zh: 2026年04月26日 · en: 04/26/2026
  String formatDate(DateTime date, Locale locale) =>
      DateFormatter.formatDate(date, locale);

  /// Format a [date] with time component.
  ///
  /// ja: 2026/04/26 10:30 · en: 04/26/2026 10:30 AM
  String formatDateTime(DateTime date, Locale locale) =>
      DateFormatter.formatDateTime(date, locale);

  /// Format a [date] as month-year string.
  ///
  /// ja/zh: 2026年4月 · en: April 2026
  String formatMonthYear(DateTime date, Locale locale) =>
      DateFormatter.formatMonthYear(date, locale);

  /// Format [date] as a relative label (today/yesterday/N days ago) or date.
  ///
  /// ja: 今日, 昨日, N日前 · zh: 今天, 昨天, N天前 · en: Today, Yesterday, N days ago
  String formatRelative(DateTime date, Locale locale) =>
      DateFormatter.formatRelative(date, locale);

  // ── Number / currency formatting ─────────────────────────────────────────

  /// Format [number] with [decimals] decimal places.
  String formatNumber(num number, Locale locale, {int decimals = 2}) =>
      NumberFormatter.formatNumber(number, locale, decimals: decimals);

  /// Format [amount] as a currency string for [currencyCode].
  ///
  /// JPY: ¥1,234 (0 decimals) · USD/EUR/GBP: 2 decimals
  String formatCurrency(num amount, String currencyCode, Locale locale) =>
      NumberFormatter.formatCurrency(amount, currencyCode, locale);

  /// Format [value] as a percentage with [decimals] decimal places.
  ///
  /// 0.5 → "50.00%"
  String formatPercentage(double value, Locale locale, {int decimals = 2}) =>
      NumberFormatter.formatPercentage(value, locale, decimals: decimals);

  /// Format [number] in compact notation.
  ///
  /// ja/zh: 1.2万 for 12,000 · en: 12K
  String formatCompact(num number, Locale locale) =>
      NumberFormatter.formatCompact(number, locale);
}

/// Application-layer provider for [FormatterService].
///
/// No `app` prefix needed — FormatterService has no infrastructure-side analog
/// provider; this is the single canonical name.
@riverpod
FormatterService formatterService(Ref ref) => const FormatterService();

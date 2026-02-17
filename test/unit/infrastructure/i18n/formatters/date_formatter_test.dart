import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/i18n/formatters/date_formatter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  group('DateFormatter', () {
    final testDate = DateTime(2026, 2, 6, 14, 30);
    const ja = Locale('ja');
    const en = Locale('en');
    const zh = Locale('zh');

    setUpAll(() async {
      await initializeDateFormatting('ja');
      await initializeDateFormatting('en');
      await initializeDateFormatting('zh');
    });

    group('formatDate', () {
      test('formats Japanese date as yyyy/MM/dd', () {
        expect(DateFormatter.formatDate(testDate, ja), '2026/02/06');
      });

      test('formats English date as MM/dd/yyyy', () {
        expect(DateFormatter.formatDate(testDate, en), '02/06/2026');
      });

      test('formats Chinese date with year/month/day characters', () {
        expect(DateFormatter.formatDate(testDate, zh), '2026年02月06日');
      });

      test('falls back to English format for unknown locale', () {
        const ko = Locale('ko');
        expect(DateFormatter.formatDate(testDate, ko), '02/06/2026');
      });
    });

    group('formatDateTime', () {
      test('formats Japanese datetime with 24h time', () {
        expect(DateFormatter.formatDateTime(testDate, ja), '2026/02/06 14:30');
      });

      test('formats English datetime with 12h AM/PM', () {
        expect(
            DateFormatter.formatDateTime(testDate, en), '02/06/2026 2:30 PM');
      });

      test('formats Chinese datetime with 24h time', () {
        expect(
            DateFormatter.formatDateTime(testDate, zh), '2026年02月06日 14:30');
      });
    });

    group('formatMonthYear', () {
      test('formats Japanese month-year', () {
        expect(DateFormatter.formatMonthYear(testDate, ja), '2026年2月');
      });

      test('formats English month-year', () {
        expect(DateFormatter.formatMonthYear(testDate, en), 'February 2026');
      });

      test('formats Chinese month-year', () {
        expect(DateFormatter.formatMonthYear(testDate, zh), '2026年2月');
      });
    });

    group('formatRelative', () {
      test('returns today label for same day', () {
        final now = DateTime.now();
        expect(DateFormatter.formatRelative(now, ja), '今日');
        expect(DateFormatter.formatRelative(now, en), 'Today');
        expect(DateFormatter.formatRelative(now, zh), '今天');
      });

      test('returns yesterday label for 1 day ago', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateFormatter.formatRelative(yesterday, ja), '昨日');
        expect(DateFormatter.formatRelative(yesterday, en), 'Yesterday');
        expect(DateFormatter.formatRelative(yesterday, zh), '昨天');
      });

      test('returns N days ago for 2-6 days', () {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        expect(DateFormatter.formatRelative(threeDaysAgo, ja), '3日前');
        expect(DateFormatter.formatRelative(threeDaysAgo, en), '3 days ago');
        expect(DateFormatter.formatRelative(threeDaysAgo, zh), '3天前');
      });

      test('falls back to formatDate for 7+ days', () {
        final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
        final result = DateFormatter.formatRelative(twoWeeksAgo, ja);
        expect(result, contains('/'));
      });
    });
  });
}

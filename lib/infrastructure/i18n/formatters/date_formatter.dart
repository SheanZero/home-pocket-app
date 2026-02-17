import 'dart:ui';

import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime date, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return DateFormat('yyyy/MM/dd', locale.toString()).format(date);
      case 'zh':
        return DateFormat('yyyy年MM月dd日', locale.toString()).format(date);
      case 'en':
      default:
        return DateFormat('MM/dd/yyyy', locale.toString()).format(date);
    }
  }

  static String formatDateTime(DateTime date, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return DateFormat('yyyy/MM/dd HH:mm', locale.toString()).format(date);
      case 'zh':
        return DateFormat('yyyy年MM月dd日 HH:mm', locale.toString()).format(date);
      case 'en':
      default:
        return DateFormat('MM/dd/yyyy h:mm a', locale.toString()).format(date);
    }
  }

  static String formatMonthYear(DateTime date, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
      case 'zh':
        return DateFormat('yyyy年M月', locale.toString()).format(date);
      case 'en':
      default:
        return DateFormat('MMMM yyyy', locale.toString()).format(date);
    }
  }

  static String formatRelative(DateTime date, Locale locale) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return _getRelativeToday(locale);
    } else if (difference == 1) {
      return _getRelativeYesterday(locale);
    } else if (difference < 7) {
      return _getRelativeDaysAgo(difference, locale);
    } else {
      return formatDate(date, locale);
    }
  }

  static String _getRelativeToday(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return '今日';
      case 'zh':
        return '今天';
      case 'en':
      default:
        return 'Today';
    }
  }

  static String _getRelativeYesterday(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return '昨日';
      case 'zh':
        return '昨天';
      case 'en':
      default:
        return 'Yesterday';
    }
  }

  static String _getRelativeDaysAgo(int days, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return '$days日前';
      case 'zh':
        return '$days天前';
      case 'en':
      default:
        return '$days days ago';
    }
  }
}

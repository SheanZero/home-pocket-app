import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Locale-aware date formatting utility
///
/// Provides consistent date/time formatting across the app with support for:
/// - Japanese (YYYY/MM/DD, 24-hour time)
/// - Chinese (YYYY年MM月DD日, 24-hour time)
/// - English (MM/DD/YYYY, 12-hour time with AM/PM)
class DateFormatter {
  DateFormatter._(); // Private constructor - utility class

  /// Format date only (no time) according to locale
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

  /// Format date with time according to locale
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

  /// Format relative time (e.g., "今日", "昨日", "1週間前")
  ///
  /// Returns relative strings for recent dates (today, yesterday, days ago)
  /// Falls back to absolute date formatting for older dates
  static String formatRelative(DateTime date, Locale locale) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return _getRelativeToday(locale);
    } else if (difference.inDays == 1) {
      return _getRelativeYesterday(locale);
    } else if (difference.inDays < 7) {
      return _getRelativeDaysAgo(difference.inDays, locale);
    } else {
      return formatDate(date, locale);
    }
  }

  /// Format month and year
  static String formatMonthYear(DateTime date, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return DateFormat('yyyy年M月', locale.toString()).format(date);
      case 'zh':
        return DateFormat('yyyy年M月', locale.toString()).format(date);
      case 'en':
      default:
        return DateFormat('MMMM yyyy', locale.toString()).format(date);
    }
  }

  // Helper methods for relative time strings
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

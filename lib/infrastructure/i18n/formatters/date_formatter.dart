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

  static String formatShortMonthDay(DateTime date, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
      case 'zh':
        return DateFormat('M月d日', locale.toString()).format(date);
      case 'en':
      default:
        return DateFormat('MMM d', locale.toString()).format(date);
    }
  }

  /// Full CJK-form date for day-group headers (ja/zh `2026年7月10日`, en
  /// `Jul 10, 2026`). Distinct from [formatDate] (which renders the numeric
  /// `yyyy/MM/dd` form) so existing callers keep their format.
  static String formatFullDateCjk(DateTime date, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
      case 'zh':
        return DateFormat('yyyy年M月d日', locale.toString()).format(date);
      case 'en':
      default:
        return DateFormat('MMM d, yyyy', locale.toString()).format(date);
    }
  }

  /// Compact `M/D` slash form (e.g. `7/10`) used as a row date prefix in the
  /// amount-sort flat list. Locale-stable digits, no CJK affix — kept separate
  /// from [formatShortMonthDay] so its `M月d日` callers are unaffected.
  static String formatSlashMonthDay(DateTime date, Locale locale) {
    return DateFormat('M/d', locale.toString()).format(date);
  }

  /// Day-of-month axis tick label (ja/zh `7日`, en plain `7`).
  ///
  /// Used by within-month chart X-axis markers. The `日` glyph is a CJK date
  /// affix (same family as the 年/月/日 patterns above), kept here in the
  /// whitelisted formatter rather than leaked into a UI widget literal.
  static String formatDayOfMonthAxis(int day, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
      case 'zh':
        return '$day日';
      case 'en':
      default:
        return '$day';
    }
  }

  /// Short localized weekday label (ja 月, zh 周一, en Mon) — matches the labels
  /// table_calendar renders in its days-of-week row.
  static String formatShortWeekday(DateTime date, Locale locale) {
    return DateFormat.E(locale.toString()).format(date);
  }

  /// Month-only band label for the Best Joy calendar tile (quick 260602-u5x):
  /// ja/zh render the "M月" form, every other locale the abbreviated month
  /// ("MMM"). Kept here so the CJK pattern lives in the i18n formatter rather
  /// than a UI widget.
  static String formatCalendarMonth(DateTime date, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
      case 'zh':
        return DateFormat('M月', locale.toString()).format(date);
      case 'en':
      default:
        return DateFormat('MMM', locale.toString()).format(date);
    }
  }

  /// Day-of-month numeral for the Best Joy calendar tile (locale-stable digits).
  static String formatCalendarDay(DateTime date, Locale locale) {
    return DateFormat('d', locale.toString()).format(date);
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

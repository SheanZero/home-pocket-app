import '../../infrastructure/ml/merchant_database.dart';
import '../../infrastructure/voice/chinese_numeral_state_machine.dart';
import '../../infrastructure/voice/japanese_numeral_state_machine.dart';

/// NLP text parser for voice input.
///
/// Extracts structured data (amounts, merchants) from natural language text.
/// Supports Japanese, Chinese, and English input.
///
/// Amount extraction is a thin transfer station:
/// 1. Arabic-numeral path (_extractArabicAmount) always wins priority.
/// 2. Kanji/kana parsing is delegated to locale-specific state machines
///    (ChineseNumeralStateMachine / JapaneseNumeralStateMachine).
class VoiceTextParser {
  final ChineseNumeralStateMachine _zhMachine;
  final JapaneseNumeralStateMachine _jaMachine;

  VoiceTextParser({
    ChineseNumeralStateMachine? zhMachine,
    JapaneseNumeralStateMachine? jaMachine,
  }) : _zhMachine = zhMachine ?? const ChineseNumeralStateMachine(),
       _jaMachine = jaMachine ?? JapaneseNumeralStateMachine();

  /// Fast guard: contains at least one kanji numeral OR a multi-char kana numeral
  /// sequence that unambiguously signals a number context.
  ///
  /// Used by the null-locale fallback to prevent false positives from
  /// single-character hiragana digits (e.g. `ご`=5 in 「ごはん」) appearing in
  /// ordinary Japanese prose.
  static final _numeralHintPattern = RegExp(
    r'[一二三四五六七八九十百千万萬零〇壱弐参壹贰叁伍仟]|'
    r'(?:いち|ひと|ふた|さん|よん|ろく|なな|しち|はち|きゅう|せん|ひゃく|じゅう|まん|'
    r'いっせん|さんぜん|はっせん|さんびゃく|ろっぴゃく|はっぴゃく|いちまん)',
  );

  /// Extracts the monetary amount from a text string.
  ///
  /// Supports:
  /// 1. Arabic numerals: 「680円」「¥1280」「1,280」 — always tried first.
  /// 2. Locale-routed kanji/kana state machines:
  ///    - localeId starts with 'ja' → JapaneseNumeralStateMachine
  ///    - localeId starts with 'zh' → ChineseNumeralStateMachine
  ///    - null or other localeId → try ja then zh as defensive fallback
  ///
  /// Returns null if no amount is found.
  int? extractAmount(String text, {String? localeId}) {
    // Priority 1: Arabic numerals (locale-independent)
    final arabicAmount = _extractArabicAmount(text);
    if (arabicAmount != null) return arabicAmount;

    // Priority 2: locale-routed numeral state machines
    if (localeId != null && localeId.startsWith('ja')) {
      return _jaMachine.parse(text);
    }
    if (localeId != null && localeId.startsWith('zh')) {
      return _zhMachine.parse(text);
    }
    // Fallback (null locale or unsupported) — only route to ja/zh if text
    // contains a recognizable numeral hint (kanji or multi-char kana unit).
    // Single-char hiragana like 'ご' can appear in common words (e.g. ごはん)
    // and must not trigger a false positive amount extraction.
    if (_numeralHintPattern.hasMatch(text)) {
      return _jaMachine.parse(text) ?? _zhMachine.parse(text);
    }
    return null;
  }

  /// Extracts Arabic numeral amounts from text.
  int? _extractArabicAmount(String text) {
    final patterns = [
      // ¥1,280 / ￥1280
      RegExp(r'[¥￥]\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)'),
      // 1,280円 / 1280円 / 1280yen / 480块 / 480元
      RegExp(
        r'(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)\s*(?:円|えん|yen|元|块|塊)',
        caseSensitive: false,
      ),
      // Standalone numbers (3+ digits, likely amount)
      RegExp(r'(?<!\d)(\d{3,7}(?:\.\d{1,2})?)(?!\d)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0 && amount < 10000000) {
          return amount.round();
        }
      }
    }

    return null;
  }

  /// Extracts a date from voice-recognized text.
  ///
  /// Supports relative expressions (yesterday, last week) and absolute dates
  /// (2月20日, 2/20) in Japanese, Chinese, and English.
  ///
  /// Returns null if no date expression is found (caller defaults to today).
  DateTime? extractDate(String text) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Priority 1: Relative date keywords (yesterday, today, last week)
    final relativeDate = _extractRelativeDate(text, today);
    if (relativeDate != null) return relativeDate;

    // Priority 2: "N days/weeks/months ago" patterns
    final nAgoDate = _extractNAgoDate(text, today);
    if (nAgoDate != null) return nAgoDate;

    // Priority 3: Composite "month ref + day" (上个月15号, 今月10日)
    final compositeDate = _extractCompositeMonthDay(text, today);
    if (compositeDate != null) return compositeDate;

    // Priority 4: Bare day only (15号, 10日, the 15th) → current month
    final bareDayDate = _extractBareDay(text, today);
    if (bareDayDate != null) return bareDayDate;

    // Priority 5: Absolute date patterns (M月D日, M/D)
    final absoluteDate = _extractAbsoluteDate(text, today);
    if (absoluteDate != null) return absoluteDate;

    return null;
  }

  /// Matches relative date keywords across 3 languages.
  DateTime? _extractRelativeDate(String text, DateTime today) {
    final lowerText = text.toLowerCase();

    // Map of keywords to day offsets (negative = past)
    const relativeKeywords = <String, int>{
      // Japanese
      '一昨日': -2,
      'おととい': -2,
      '昨日': -1,
      'きのう': -1,
      '今日': 0,
      'きょう': 0,
      // Chinese
      '前天': -2,
      '昨天': -1,
      '今天': 0,
      // English (checked via lowered text)
    };

    // Check Japanese/Chinese keywords (case-sensitive)
    for (final entry in relativeKeywords.entries) {
      if (text.contains(entry.key)) {
        return today.add(Duration(days: entry.value));
      }
    }

    // Check English keywords (case-insensitive)
    const englishKeywords = <String, int>{
      'day before yesterday': -2,
      'yesterday': -1,
      'today': 0,
    };

    for (final entry in englishKeywords.entries) {
      if (lowerText.contains(entry.key)) {
        return today.add(Duration(days: entry.value));
      }
    }

    // "Last week" / "Last month" keywords
    const lastWeekKeywords = ['先週', '上周', '上個星期', '上个星期'];
    for (final kw in lastWeekKeywords) {
      if (text.contains(kw)) {
        return today.subtract(const Duration(days: 7));
      }
    }
    if (lowerText.contains('last week')) {
      return today.subtract(const Duration(days: 7));
    }

    // "Last month" — only match when NOT followed by a specific day number.
    // When followed by a day (e.g. 上个月15号), let composite matcher handle it.
    final dayFollowsPattern = RegExp(r'\d{1,2}\s*[日号號]');
    const lastMonthKeywords = ['先月', '上个月', '上個月'];
    for (final kw in lastMonthKeywords) {
      final kwIndex = text.indexOf(kw);
      if (kwIndex >= 0) {
        final afterKw = text.substring(kwIndex + kw.length);
        if (!dayFollowsPattern.hasMatch(afterKw)) {
          return DateTime(today.year, today.month - 1, today.day);
        }
      }
    }
    if (lowerText.contains('last month')) {
      final kwIndex = lowerText.indexOf('last month');
      final afterKw = lowerText.substring(kwIndex + 'last month'.length);
      final enDayFollows = RegExp(r'\s*\d{1,2}\s*(?:st|nd|rd|th)\b');
      if (!enDayFollows.hasMatch(afterKw)) {
        return DateTime(today.year, today.month - 1, today.day);
      }
    }

    return null;
  }

  /// Matches "N days/weeks/months ago" patterns.
  DateTime? _extractNAgoDate(String text, DateTime today) {
    final lowerText = text.toLowerCase();

    // Days ago: N日前, N天前, N days ago
    final daysAgoPatterns = [
      RegExp(r'(\d+)\s*日前'),
      RegExp(r'(\d+)\s*天前'),
      RegExp(r'(\d+)\s*days?\s*ago', caseSensitive: false),
    ];

    for (final pattern in daysAgoPatterns) {
      final match = pattern.firstMatch(lowerText) ?? pattern.firstMatch(text);
      if (match != null) {
        final n = int.tryParse(match.group(1)!);
        if (n != null && n > 0 && n <= 365) {
          return today.subtract(Duration(days: n));
        }
      }
    }

    // Weeks ago: N週間前, N周前, N weeks ago
    final weeksAgoPatterns = [
      RegExp(r'(\d+)\s*週間前'),
      RegExp(r'(\d+)\s*周前'),
      RegExp(r'(\d+)\s*weeks?\s*ago', caseSensitive: false),
    ];

    for (final pattern in weeksAgoPatterns) {
      final match = pattern.firstMatch(lowerText) ?? pattern.firstMatch(text);
      if (match != null) {
        final n = int.tryParse(match.group(1)!);
        if (n != null && n > 0 && n <= 52) {
          return today.subtract(Duration(days: n * 7));
        }
      }
    }

    // Months ago: Nヶ月前, Nか月前, N个月前, N個月前, N months ago
    final monthsAgoPatterns = [
      RegExp(r'(\d+)\s*[ヶか]月前'),
      RegExp(r'(\d+)\s*[个個]月前'),
      RegExp(r'(\d+)\s*months?\s*ago', caseSensitive: false),
    ];

    for (final pattern in monthsAgoPatterns) {
      final match = pattern.firstMatch(lowerText) ?? pattern.firstMatch(text);
      if (match != null) {
        final n = int.tryParse(match.group(1)!);
        if (n != null && n > 0 && n <= 12) {
          return DateTime(today.year, today.month - n, today.day);
        }
      }
    }

    return null;
  }

  /// Matches composite "relative month + specific day" patterns.
  ///
  /// Examples: 上个月15号 → last month day 15, 今月10日 → this month day 10
  DateTime? _extractCompositeMonthDay(String text, DateTime today) {
    final lowerText = text.toLowerCase();

    // Last month + day patterns
    final lastMonthDayPatterns = [
      // Chinese: 上个月/上個月 + D号/日/號
      RegExp(r'(?:上个月|上個月)\s*(\d{1,2})\s*[日号號]'),
      // Japanese: 先月 + D日
      RegExp(r'先月\s*(\d{1,2})\s*日'),
    ];

    for (final pattern in lastMonthDayPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final day = int.tryParse(match.group(1)!);
        if (day != null && day >= 1 && day <= 31) {
          return DateTime(today.year, today.month - 1, day);
        }
      }
    }

    // English: last month + D(st|nd|rd|th)
    final enLastMonthDay = RegExp(
      r'last\s+month\s+(\d{1,2})\s*(?:st|nd|rd|th)?',
      caseSensitive: false,
    );
    final enLastMatch = enLastMonthDay.firstMatch(lowerText);
    if (enLastMatch != null) {
      final day = int.tryParse(enLastMatch.group(1)!);
      if (day != null && day >= 1 && day <= 31) {
        return DateTime(today.year, today.month - 1, day);
      }
    }

    // This month + day patterns
    final thisMonthDayPatterns = [
      // Chinese: 这个月/這個月 + D号/日/號
      RegExp(r'(?:这个月|這個月)\s*(\d{1,2})\s*[日号號]'),
      // Japanese: 今月 + D日
      RegExp(r'今月\s*(\d{1,2})\s*日'),
    ];

    for (final pattern in thisMonthDayPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final day = int.tryParse(match.group(1)!);
        if (day != null && day >= 1 && day <= 31) {
          return DateTime(today.year, today.month, day);
        }
      }
    }

    // English: this month + D(st|nd|rd|th)
    final enThisMonthDay = RegExp(
      r'this\s+month\s+(\d{1,2})\s*(?:st|nd|rd|th)?',
      caseSensitive: false,
    );
    final enThisMatch = enThisMonthDay.firstMatch(lowerText);
    if (enThisMatch != null) {
      final day = int.tryParse(enThisMatch.group(1)!);
      if (day != null && day >= 1 && day <= 31) {
        return DateTime(today.year, today.month, day);
      }
    }

    return null;
  }

  /// Matches bare day patterns (15号, 10日, the 15th) without a month context.
  ///
  /// Always assumes the current month.
  DateTime? _extractBareDay(String text, DateTime today) {
    final lowerText = text.toLowerCase();

    // Chinese/Japanese: D号/號 (bare, not preceded by 月 or a digit that looks like a month)
    final bareDayZhPattern = RegExp(r'(?<!\d月\s*)(?<!\d)(\d{1,2})\s*[号號]');
    final zhMatch = bareDayZhPattern.firstMatch(text);
    if (zhMatch != null) {
      final day = int.tryParse(zhMatch.group(1)!);
      if (day != null && day >= 1 && day <= 31) {
        return DateTime(today.year, today.month, day);
      }
    }

    // Japanese: D日 (bare, not preceded by a month number like 2月)
    // Must not be preceded by \d月 or by relative month keywords
    final bareDayJaPattern = RegExp(r'(?<!\d\s*月\s*)(?<!\d)(\d{1,2})\s*日(?!前)');
    final jaMatch = bareDayJaPattern.firstMatch(text);
    if (jaMatch != null) {
      // Make sure it's not part of a N日前 pattern or M月D日 pattern
      final day = int.tryParse(jaMatch.group(1)!);
      if (day != null && day >= 1 && day <= 31) {
        return DateTime(today.year, today.month, day);
      }
    }

    // English: the Dth/Dst/Dnd/Drd
    final bareDayEnPattern = RegExp(
      r'\bthe\s+(\d{1,2})\s*(?:st|nd|rd|th)\b',
      caseSensitive: false,
    );
    final enMatch = bareDayEnPattern.firstMatch(lowerText);
    if (enMatch != null) {
      final day = int.tryParse(enMatch.group(1)!);
      if (day != null && day >= 1 && day <= 31) {
        return DateTime(today.year, today.month, day);
      }
    }

    return null;
  }

  /// Matches absolute date patterns (M月D日, M/D).
  ///
  /// If the resulting date is in the future, assumes previous year.
  DateTime? _extractAbsoluteDate(String text, DateTime today) {
    final patterns = [
      // M月D日 (ja/zh)
      RegExp(r'(\d{1,2})\s*月\s*(\d{1,2})\s*[日号號]?'),
      // M/D (universal, but avoid matching times like 1/1/2025)
      RegExp(r'(?<!\d)(\d{1,2})/(\d{1,2})(?!\d|/)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final month = int.tryParse(match.group(1)!);
        final day = int.tryParse(match.group(2)!);
        if (month != null &&
            day != null &&
            month >= 1 &&
            month <= 12 &&
            day >= 1 &&
            day <= 31) {
          var year = today.year;
          final candidate = DateTime(year, month, day);
          // If the date is in the future, assume previous year
          if (candidate.isAfter(today)) {
            year -= 1;
          }
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  /// Extracts merchant names from text and matches against [merchantDB].
  ///
  /// Returns the best [MerchantMatch] found, or null if no merchant matched.
  MerchantMatch? extractAndMatchMerchant(
    String text,
    MerchantDatabase merchantDB,
  ) {
    final words = _extractPotentialMerchantNames(text);

    for (final word in words) {
      final match = merchantDB.findMerchant(word);
      if (match != null) return match;
    }

    return null;
  }

  /// Extracts candidate merchant name segments from text.
  List<String> _extractPotentialMerchantNames(String text) {
    final results = <String>[];

    // Remove amounts and common verbs, leaving potential merchant name words
    var cleaned = text
        .replaceAll(RegExp(r'[¥￥]\s*\d[\d,.]*'), '')
        .replaceAll(RegExp(r'\d[\d,.]*\s*(?:円|元|块|yen)'), '')
        .replaceAll(RegExp(r'[でにをがはのとへからまで]|した|って|ました|だった|です'), ' ')
        .replaceAll(RegExp(r'[在了花买吃用去到]'), ' ')
        .replaceAll(RegExp(r'\b(?:at|for|in|on|spent|paid|bought)\b'), ' ')
        .trim();

    // Split into candidate segments
    final segments = cleaned
        .split(RegExp(r'[\s,、。，]+'))
        .where((s) => s.length >= 2 && s.length <= 20)
        .toList();

    // Prefer longer segments (more likely to be complete merchant names)
    segments.sort((a, b) => b.length.compareTo(a.length));
    results.addAll(segments);

    // Also try raw substrings of varying lengths
    for (var len = 10; len >= 2; len--) {
      for (var i = 0; i <= text.length - len; i++) {
        final sub = text.substring(i, i + len).trim();
        if (sub.isNotEmpty && !results.contains(sub)) {
          results.add(sub);
        }
      }
    }

    return results;
  }
}

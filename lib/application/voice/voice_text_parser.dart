import '../../infrastructure/ml/merchant_database.dart';

/// NLP text parser for voice input.
///
/// Extracts structured data (amounts, merchants) from natural language text.
/// Supports Japanese, Chinese, and English input.
class VoiceTextParser {
  /// Extracts the monetary amount from a text string.
  ///
  /// Supports three formats:
  /// 1. Arabic numerals: 「680円」「¥1280」「1,280」
  /// 2. Japanese kanji numbers: 「六百八十円」「千二百円」
  /// 3. Chinese numbers: 「六百八十块」「一千二百元」
  ///
  /// Returns null if no amount is found.
  int? extractAmount(String text) {
    // Priority 1: Arabic numeral amounts
    final arabicAmount = _extractArabicAmount(text);
    if (arabicAmount != null) return arabicAmount;

    // Priority 2: Japanese/Chinese kanji numeral amounts
    final kanjiAmount = _extractKanjiAmount(text);
    if (kanjiAmount != null) return kanjiAmount;

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

  /// Extracts Japanese/Chinese kanji numeral amounts from text.
  ///
  /// Examples: 「六百八十」→ 680、「千二百」→ 1200、「三万五千」→ 35000
  int? _extractKanjiAmount(String text) {
    const kanjiDigits = {
      '零': 0,
      '〇': 0,
      '一': 1,
      '壱': 1,
      '壹': 1,
      '二': 2,
      '弐': 2,
      '贰': 2,
      '三': 3,
      '参': 3,
      '叁': 3,
      '四': 4,
      '五': 5,
      '伍': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };

    const kanjiUnits = {
      '十': 10,
      '百': 100,
      '千': 1000,
      '仟': 1000,
      '万': 10000,
      '萬': 10000,
    };

    // Find the text region that may contain a kanji number
    final amountPattern = RegExp(
      r'[零〇一壱壹二弐贰三参叁四五伍六七八九十百千仟万萬]+'
      r'(?:\s*(?:円|えん|yen|元|块|塊))?',
    );

    final match = amountPattern.firstMatch(text);
    if (match == null) return null;

    final kanjiText =
        match.group(0)!.replaceAll(RegExp(r'[\s円えんyen元块塊]'), '');

    if (kanjiText.isEmpty) return null;

    // Parse kanji numbers
    var result = 0;
    var currentSection = 0;
    var currentDigit = 1; // default multiplier for units without preceding digit

    for (var i = 0; i < kanjiText.length; i++) {
      final char = kanjiText[i];

      if (kanjiDigits.containsKey(char)) {
        currentDigit = kanjiDigits[char]!;
      } else if (kanjiUnits.containsKey(char)) {
        final unit = kanjiUnits[char]!;
        if (unit == 10000) {
          // 「万」: multiply current section by 10000
          final sectionValue =
              currentSection == 0 ? currentDigit : currentSection + currentDigit;
          result += sectionValue * 10000;
          currentSection = 0;
          currentDigit = 1;
        } else {
          currentSection += currentDigit * unit;
          currentDigit = 1;
        }
      }
    }

    // Add remaining digits at the end
    final lastChar = kanjiText[kanjiText.length - 1];
    if (!kanjiUnits.containsKey(lastChar) && currentDigit < 10) {
      currentSection += currentDigit;
    }

    result += currentSection;

    return result > 0 ? result : null;
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
    final enLastMonthDay =
        RegExp(r'last\s+month\s+(\d{1,2})\s*(?:st|nd|rd|th)?', caseSensitive: false);
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
    final enThisMonthDay =
        RegExp(r'this\s+month\s+(\d{1,2})\s*(?:st|nd|rd|th)?', caseSensitive: false);
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
        .replaceAll(
          RegExp(r'[でにをがはのとへからまで]|した|って|ました|だった|です'),
          ' ',
        )
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

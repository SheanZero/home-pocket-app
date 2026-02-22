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

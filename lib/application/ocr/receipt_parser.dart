/// Parsed data extracted from a receipt OCR text.
class ParsedReceiptData {
  final int? amount;
  final DateTime? date;
  final String? merchant;

  const ParsedReceiptData({this.amount, this.date, this.merchant});
}

/// Extracts structured data (amount, date, merchant) from raw OCR text.
class ReceiptParser {
  // Lines containing these keywords are excluded from yen-amount fallback.
  static final _excludedAmountKeywords = RegExp(
    r'(お釣り|釣銭|税\s|消費税|内税|外税)',
  );

  ParsedReceiptData parse(String text) {
    return ParsedReceiptData(
      amount: _extractAmount(text),
      date: null, // Task 3
      merchant: null, // Task 4
    );
  }

  /// Amount extraction priority:
  /// 1. Keyword-adjacent (税込合計 > 合計 > 小計 > TOTAL > 円 suffix)
  /// 2. Largest ¥-prefixed number (excluding change/tax lines)
  /// 3. null
  int? _extractAmount(String text) {
    // Phase 1: keyword-adjacent amounts (return first match by priority)
    final keywordPatterns = [
      RegExp(r'税込\s*合[計计]\s*[¥￥]?\s*([\d,]+)'),
      RegExp(r'合[計计]\s*[¥￥]?\s*([\d,]+)'),
      RegExp(r'小[計计]\s*[¥￥]?\s*([\d,]+)'),
      RegExp(r'TOTAL\s*[¥￥]?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'([\d,]+)\s*円'),
    ];

    for (final pattern in keywordPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final parsed = _parseNumber(match.group(1)!);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // Phase 2: fallback — largest ¥-prefixed number, excluding change/tax lines
    final yenPattern = RegExp(r'[¥￥]\s*([\d,]+)');
    int? largest;

    for (final line in text.split('\n')) {
      if (_excludedAmountKeywords.hasMatch(line)) continue;
      for (final match in yenPattern.allMatches(line)) {
        final parsed = _parseNumber(match.group(1)!);
        if (parsed != null && parsed > 0) {
          if (largest == null || parsed > largest) largest = parsed;
        }
      }
    }

    return largest;
  }

  int? _parseNumber(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    return int.tryParse(cleaned);
  }
}

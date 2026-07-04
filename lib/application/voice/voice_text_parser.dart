import '../../infrastructure/voice/chinese_numeral_state_machine.dart';
import '../../infrastructure/voice/japanese_numeral_state_machine.dart';
import '../../shared/constants/voice_currency_suffixes.dart';
import 'english_number_words.dart';

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
    r'[一二两三四五六七八九十百千万萬零〇壱弐参壹贰叁伍仟]|'
    r'(?:いち|ひと|ふた|さん|よん|ろく|なな|しち|はち|きゅう|せん|ひゃく|じゅう|まん|'
    r'いっせん|さんぜん|はっせん|さんびゃく|ろっぴゃく|はっぴゃく|いちまん)',
  );

  /// Extracts the monetary amount from a text string.
  ///
  /// Routing:
  /// 1. If text contains kanji/kana numerals, try the locale-routed state
  ///    machine FIRST (mixed forms like 「2千304元」 must read as 2304, not 304
  ///    — the arabic regex would otherwise short-circuit on `304元`).
  /// 2. Otherwise, try the arabic regex (「680円」「¥1280」「1,280」).
  /// 3. As a last resort, fall through to the other path.
  /// 260622-nhs R6 (BUG 2): a comma-grouped Arabic number (e.g. 「99,999」,
  /// 「1,234,567」, full-width 「12，450」). The state-machine scanner drops the
  /// comma and splits the run into two Digits — keeping only the trailing group
  /// (99,999 → 999). The Arabic regex parses comma grouping correctly, so when a
  /// comma-grouped number is present it is AUTHORITATIVE over the state machine.
  static final _commaGroupedPattern = RegExp(r'\d[,，]\d');

  /// 260703 BUG-1: spaced ITN-split signature — a "round" Arabic group (ends
  /// in ≥1 zero: 「两千五百」→"2500", and the 十-terminated 「五千三百一十」→
  /// "5310" reported on-device 260704) followed by a short 1–2 digit tail that
  /// is itself followed by a currency suffix or end-of-string. Such pairs are
  /// ONE spoken number split by the recognizer's inverse text normalization
  /// and must route through the state machine's positional merge ("2500 46元"
  /// → 2546, "5310 2元" → 5312); the Arabic regex would keep only the tail.
  /// The machine enforces the exact tail-fits-trailing-zeros check, so this
  /// gate only needs the cheap shape. The suffix/end anchor keeps date-shaped
  /// tails (「1200 15号」) on the Arabic path — misrouting those would corrupt
  /// a correct amount.
  static final _spacedRoundGroupPattern = RegExp(
    r'(?<!\d)\d+0[\s　]+\d{1,2}\s*(?:' +
        VoiceCurrencySuffixes.regexAlternation +
        r'|$)',
    caseSensitive: false,
  );

  /// Money-context gate for the en number-word fallback (VEN-02 / D-14):
  /// a recognized currency token (via [VoiceCurrencySuffixes]), a `$` symbol,
  /// or a `dollar`/`dollars` word. Without this gate「five fifty」would be the
  /// ambiguous 550-vs-5.50 case, so the X.50 idiom must never fire bare.
  static final _enMoneyContextPattern = RegExp(r'\$|\bdollars?\b');

  bool _hasEnMoneyContext(String text) {
    if (_enMoneyContextPattern.hasMatch(text.toLowerCase())) return true;
    final lower = text.toLowerCase();
    return VoiceCurrencySuffixes.all.any(
      (token) => lower.contains(token.toLowerCase()),
    );
  }

  int? extractAmount(String text, {String? localeId}) {
    // VEN-02 / D-14: the en locale routes ENTIRELY around the CJK numeral state
    // machines (isolation; guards the v1.8 WR-04 regression class). Arabic STT
    // digits always win first; only on an Arabic miss, in money context, do we
    // consult the bounded English number-word fallback. The en branch NEVER
    // reaches _runStateMachine, so an English (or stray CJK) utterance under
    // en-US can never leak into _jaMachine/_zhMachine.
    if (localeId != null && localeId.startsWith('en')) {
      final fromArabic = _extractArabicAmount(text);
      if (fromArabic != null) return fromArabic;
      if (_hasEnMoneyContext(text)) {
        return parseEnglishNumberWords(text, moneyContext: true);
      }
      return null;
    }

    // 260622-nhs R6 (BUG 2): a comma-grouped Arabic amount is unambiguous and
    // the scanner cannot read it (it drops the comma and keeps only the last
    // group). Prefer the Arabic regex when one is present, even if a stray kanji
    // numeral (e.g. 一 in 一共) would otherwise trip the state-machine hint.
    if (_commaGroupedPattern.hasMatch(text)) {
      final fromArabic = _extractArabicAmount(text);
      if (fromArabic != null) return fromArabic;
    }

    final hasNumeralHint = _numeralHintPattern.hasMatch(text);

    // Mixed kanji+arabic strings (e.g. 「2千304元」) must NOT fall through to
    // the arabic regex — it would partial-match the trailing 「304元」 and
    // return 304, masking the correct 2304 reading. State machine is
    // authoritative when any numeral hint is present.
    //
    // Fallthrough (260526-n7b): hint detection has false positives on CJK
    // day-of-week / month names where 二/三/四 etc. are NOT numbers (e.g.
    // 「上周二交公交卡用了¥5240」 → 周二 trips the hint, machine fails on the
    // non-numeric context, arabic regex would correctly match ¥5240). When
    // the state machine yields null, try the arabic path instead of giving up.
    // 260703 BUG-1: a spaced round-group pair ("2500 46元") is an ITN-split
    // single number — the machine's positional merge is the only reader that
    // reassembles it correctly. Comma-grouped inputs never reach here (the
    // comma-authoritative gate above already returned), and en locales are
    // fully isolated in the branch at the top.
    if (hasNumeralHint || _spacedRoundGroupPattern.hasMatch(text)) {
      final fromMachine = _runStateMachine(text, localeId);
      if (fromMachine != null) return fromMachine;
    }
    return _extractArabicAmount(text);
  }

  /// 260703 BUG-1: detects the UNSPACED ITN concatenation signature in a pure
  /// digit string and returns the positional-repair candidate, or null.
  ///
  /// iOS zh ITN can normalize 「两千五百四十六」 as two segments "2500"+"46" and
  /// join them without a delimiter → "250046". The signature: S = head ++ tail
  /// where the head ends in ≥1 zero (a round ITN group — includes the
  /// 十-terminated single-zero shape 「五千三百一十」→"5310"+"2"→"53102",
  /// reported on-device 260704), the tail is 1–2 digits with no leading zero,
  /// and the tail fits inside the head's trailing zeros. Repair = head + tail
  /// (250046 → 2546, 53102 → 5312).
  ///
  /// Guardrails (precision over recall — a false rewrite is worse than a miss):
  /// - length floor 5: 「3005」(三千零五) is a normal amount, never flagged;
  /// - all-zero / zero-led tails rejected: 「250000」 is a legit round amount;
  /// - longest-head split wins when several fit ("2500046" → 25000+46).
  ///
  /// This NEVER rewrites anything by itself — callers surface the candidate
  /// for user confirmation, or auto-adopt it only when an alternate transcript
  /// independently parses to the same value (ParseVoiceInputUseCase).
  static int? detectConcatRepairCandidate(String digits) {
    if (digits.length < 5 || digits.length > 9) return null;
    if (!RegExp(r'^\d+$').hasMatch(digits)) return null;
    // Shortest tail first == longest head wins.
    for (var tailLen = 1; tailLen <= 2; tailLen++) {
      final splitAt = digits.length - tailLen;
      if (splitAt < 3) continue; // head must be ≥ 100 (three digits)
      final head = digits.substring(0, splitAt);
      final tail = digits.substring(splitAt);
      if (tail.startsWith('0')) continue;
      final trailingZeros =
          head.length - head.replaceAll(RegExp(r'0+$'), '').length;
      if (trailingZeros < 1 || tailLen > trailingZeros) continue;
      return int.parse(head) + int.parse(tail);
    }
    return null;
  }

  int? _runStateMachine(String text, String? localeId) {
    if (localeId != null && localeId.startsWith('ja')) {
      return _jaMachine.parse(text);
    }
    if (localeId != null && localeId.startsWith('zh')) {
      return _zhMachine.parse(text);
    }
    return _jaMachine.parse(text) ?? _zhMachine.parse(text);
  }

  /// Extracts Arabic numeral amounts from text.
  ///
  /// Quick task 260526-l0o (Issue 1): pattern set extended to handle
  /// `12,450日元` and full-width-comma variants (`12，450日元`). The suffix
  /// alternation is sourced from [VoiceCurrencySuffixes.regexAlternation] so
  /// `日元` is recognized in the same place merchant stripping is. The bare
  /// comma-separated standalone pattern (third entry) covers utterances
  /// without any currency suffix, and the upper digit cap is bumped 7 → 9
  /// to cover million-plus integer amounts (the post-parse range check at
  /// line bottom still guards against >10M).
  int? _extractArabicAmount(String text) {
    final suffixGroup = VoiceCurrencySuffixes.regexAlternation;
    final patterns = [
      // ¥1,280 / ￥1280 / ¥5240 — alternation mirrors the suffix pattern
      // below so 4-9 digit non-comma amounts are not truncated to 3 chars.
      // (?!\d) trailing anchor forces backtracking from \d{1,3} (which would
      // otherwise greedily match "524" out of "5240") to the \d{4,9} branch.
      RegExp(
        r'[¥￥]\s*(\d{1,3}(?:[,，]\d{3})*(?:\.\d{1,2})?|\d{4,9}(?:\.\d{1,2})?)(?!\d)',
      ),
      // 1,280円 / 12,450日元 / 1280円 / 1280yen / 480块 / 480元
      // (?<!\d) anchors capture at a non-digit boundary so 「1280块」 does not
      // partial-match to 「280块」 and return 280. Full-width comma (，) is
      // tolerated for CJK keyboards. Suffix list is centralized so `日元`
      // is recognized identically here and in keyword extraction.
      RegExp(
        r'(?<!\d)(\d{1,3}(?:[,，]\d{3})*(?:\.\d{1,2})?|\d{4,9}(?:\.\d{1,2})?)\s*(?:' +
            suffixGroup +
            r')',
        caseSensitive: false,
      ),
      // Comma-separated standalone (no currency suffix): `12,450` → 12450.
      // Requires at least one comma group so we don't compete with the
      // last-resort 3-7-digit fallback below.
      RegExp(r'(?<!\d)(\d{1,3}(?:[,，]\d{3})+)(?!\d)'),
      // Standalone numbers (3+ digits, likely amount)
      RegExp(r'(?<!\d)(\d{3,7}(?:\.\d{1,2})?)(?!\d)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        final amountStr = match.group(1)!.replaceAll(RegExp(r'[,，]'), '');
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
  ///
  /// Quick task 260526-k92 (Item 4): LAST-wins rule — when an utterance
  /// mentions multiple keywords (e.g. "昨天今天都没记账"), the keyword whose
  /// rightmost occurrence has the largest `text.lastIndexOf` wins. Replaces
  /// the prior first-match-wins iteration so contradictory phrases resolve
  /// to the speaker's final intent.
  DateTime? _extractRelativeDate(String text, DateTime today) {
    final lowerText = text.toLowerCase();

    // Map of keywords to day offsets (negative = past, positive = future)
    const relativeKeywords = <String, int>{
      // Japanese — past
      '一昨日': -2,
      'おととい': -2,
      '昨日': -1,
      'きのう': -1,
      '今日': 0,
      'きょう': 0,
      // Japanese — future (Item 4, 260526-k92)
      '明日': 1,
      'あした': 1,
      'あす': 1,
      '明後日': 2,
      'あさって': 2,
      // Chinese — past
      '大前天': -3,
      '前天': -2,
      '昨天': -1,
      '今天': 0,
      // Chinese — future (Item 4, 260526-k92)
      '明天': 1,
      '后天': 2,
      // English (checked via lowered text)
    };

    // Item 4: LAST-wins — pick the keyword whose rightmost match ENDS
    // furthest right in the utterance. Ties broken by longer keyword (so
    // 一昨日 wins over the 昨日 substring it contains, and 大前天 wins over 前天).
    String? bestKey;
    int bestEnd = -1;
    int bestLen = -1;
    for (final entry in relativeKeywords.entries) {
      final idx = text.lastIndexOf(entry.key);
      if (idx < 0) continue;
      final end = idx + entry.key.length;
      if (end > bestEnd || (end == bestEnd && entry.key.length > bestLen)) {
        bestEnd = end;
        bestLen = entry.key.length;
        bestKey = entry.key;
      }
    }
    if (bestKey != null) {
      return today.add(Duration(days: relativeKeywords[bestKey]!));
    }

    // Check English keywords (case-insensitive) — same end-position rule with
    // length tiebreaker (so "day before yesterday" wins over the "yesterday"
    // substring it contains).
    const englishKeywords = <String, int>{
      'day before yesterday': -2,
      'yesterday': -1,
      'today': 0,
    };

    String? bestEnKey;
    int bestEnEnd = -1;
    int bestEnLen = -1;
    for (final entry in englishKeywords.entries) {
      final idx = lowerText.lastIndexOf(entry.key);
      if (idx < 0) continue;
      final end = idx + entry.key.length;
      if (end > bestEnEnd ||
          (end == bestEnEnd && entry.key.length > bestEnLen)) {
        bestEnEnd = end;
        bestEnLen = entry.key.length;
        bestEnKey = entry.key;
      }
    }
    if (bestEnKey != null) {
      return today.add(Duration(days: englishKeywords[bestEnKey]!));
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
}

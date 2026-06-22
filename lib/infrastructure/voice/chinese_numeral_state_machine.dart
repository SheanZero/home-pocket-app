/// Chinese numeral state machine — kanji/arabic → int amount.
///
/// Stateless functional API per D-03. Algorithm: normalize() produces a
/// List&lt;NumeralToken&gt;; inherited scan() runs the section-accumulator
/// (Pattern 1 in RESEARCH.md).
///
/// Per D-08: kanji-only — no pinyin fallback. Chinese speech recognizers
/// return native script reliably; defensive pinyin tables add maintenance burden.
///
/// Layer direction: imports only sibling file.
/// No imports from lib/features/, lib/application/, or lib/data/.
library;

import 'numeral_state_machine.dart';

/// Concrete stateless parser for Chinese numeral text.
///
/// Handles compound numbers including 零-placeholder semantics (PATTERNS.md §Pattern 1).
/// Supports kanji digits (一–九 + variants) and arabic digits (0–9) in the same input.
///
/// Usage:
/// ```dart
/// const machine = ChineseNumeralStateMachine();
/// final amount = machine.parse('2千2百零4元'); // → 2204
/// ```
class ChineseNumeralStateMachine extends NumeralStateMachine {
  const ChineseNumeralStateMachine();

  static const _kanjiDigits = <String, int>{
    '零': 0,
    '〇': 0,
    '一': 1,
    '壱': 1,
    '壹': 1,
    '二': 2,
    '两': 2,
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

  static const _kanjiUnits = <String, int>{
    '十': 10,
    '百': 100,
    '千': 1000,
    '仟': 1000,
    '万': 10000,
    '萬': 10000,
  };

  @override
  int? parse(String text) => scan(normalize(text));

  /// Tokenizes [text] into a canonical [NumeralToken] stream.
  ///
  /// Dispatch precedence (PATTERNS.md §Pattern Assignments for zh):
  /// 1. 零/〇 → ZeroPlaceholder (MUST win before _kanjiDigits lookup — this is the
  ///    key fix: legacy code mapped '零':0 in kanjiDigits, which silently set
  ///    currentDigit=0 and then the Unit branch applied the digit==0?1:digit
  ///    fallback, double-counting. Explicit ZeroPlaceholder dispatch avoids this.)
  /// 2. Other kanji digits → Digit(value)
  /// 3. Kanji units → Unit(power)
  /// 4. ASCII arabic digits (0–9) → Digit(value)
  /// 5. Anything else (currency suffix, whitespace, random text) → silently dropped
  @override
  List<NumeralToken> normalize(String text) {
    final tokens = <NumeralToken>[];
    // 260622-nhs R6 (BUG 2): buffer consecutive Arabic digits so a multi-digit
    // run like "99999" or the "304" tail of 「2千304」 reads as ONE positional
    // Digit(99999) / Digit(304) instead of the scanner overwriting digit on
    // each rune and keeping only the last (the 「99999→9」 / 「2千304→2004」
    // regression). A non-Arabic rune (unit, kanji digit, or any dropped char)
    // flushes the run — so a stray kanji 一 (in 一共) separated from "99999" by
    // text does NOT merge into it, and comma grouping (handled at the parser
    // layer) is unaffected.
    final arabicRun = StringBuffer();
    void flushArabicRun() {
      if (arabicRun.isEmpty) return;
      tokens.add(Digit(int.parse(arabicRun.toString())));
      arabicRun.clear();
    }

    // Chinese kanji are all in the BMP; runes iteration is grapheme-safe here.
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (RegExp(r'^[0-9]$').hasMatch(ch)) {
        // Step 4: arabic digit — accumulate the run; flush on the next
        // non-Arabic rune. Mixed "2千" inputs still tokenize per D-07 because
        // the 千 below flushes the leading "2" first.
        arabicRun.write(ch);
        continue;
      }
      flushArabicRun();
      // Step 1: explicit ZeroPlaceholder dispatch — MUST precede _kanjiDigits lookup
      if (ch == '零' || ch == '〇') {
        tokens.add(const ZeroPlaceholder());
      } else if (_kanjiDigits.containsKey(ch)) {
        // Step 2: non-zero kanji digit
        tokens.add(Digit(_kanjiDigits[ch]!));
      } else if (_kanjiUnits.containsKey(ch)) {
        // Step 3: positional unit
        tokens.add(Unit(_kanjiUnits[ch]!));
      }
      // Step 5: everything else silently dropped — _skipPattern chars and
      // any random text that the speech recognizer may have emitted.
      //
      // Phase 42 (VOICE-CUR-01): currency tokens (美元/欧元/英镑/港币/澳元/加元
      // and the bare 元 terminator) are among the runes dropped here so the
      // integer amount stays clean (T-42-07). Their DETECTION is handled
      // separately by the inherited [detectCurrencyToken], which runs a
      // longest-first scan over [VoiceCurrencySuffixes.all]; the use-case layer
      // then maps the token → ISO (bare 元 → CNY in zh locale per D-08 locked).
    }
    flushArabicRun();
    return tokens;
  }
}

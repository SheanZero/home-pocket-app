/// Japanese numeral state machine — hiragana/katakana/kanji/arabic → int amount.
///
/// Stateless functional API per D-03. Tokenizer: greedy longest-match against
/// `japaneseNumeralDictionary` (D-06). Scanner: inherited section-accumulator
/// (Pattern 1 in RESEARCH.md).
///
/// Handles full multi-reading coverage (D-05): なな/しち→7, よん/し→4, etc.
/// Voicing/sokuon variants (はっぴゃく/ろっぴゃく/さんびゃく/さんぜん/はっせん) are
/// direct dictionary entries — no rule engine needed.
///
/// Layer direction: imports only sibling infrastructure files.
/// No imports from lib/features/, lib/application/, or lib/data/.
library;

import 'numeral_state_machine.dart';
import 'japanese_numeral_dictionary.dart';

/// Concrete stateless parser for Japanese numeral text.
///
/// Uses a greedy longest-match tokenizer over [japaneseNumeralDictionary] with
/// a one-time descending-length sort ([_sortedKeys]) so multi-char entries like
/// `はっぴゃく` (5 chars) always beat single-char prefixes like `は`.
///
/// Falls back to kanji digit/unit and arabic digit character-level lookup after
/// dictionary miss.
///
/// Usage:
/// ```dart
/// final machine = JapaneseNumeralStateMachine();
/// final amount = machine.parse('にせんにひゃくよん'); // → 2204
/// ```
class JapaneseNumeralStateMachine extends NumeralStateMachine {
  JapaneseNumeralStateMachine();
  // Note: NOT const, because _sortedKeys is initialized non-const (static final).

  /// One-time sort, descending by key length — longest first so greedy match
  /// finds はっぴゃく (5 chars) before はち (2 chars) before は (1 char).
  static final List<String> _sortedKeys = japaneseNumeralDictionary.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  /// Kanji single-char digit fallback (covers `一万二千` → tokens [Digit(1), Unit(10000), Digit(2), Unit(1000)]).
  static const _kanjiDigits = <String, int>{
    '一': 1,
    '二': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
    '零': 0,
    '〇': 0,
  };

  /// Kanji single-char unit fallback.
  static const _kanjiUnits = <String, int>{
    '十': 10,
    '百': 100,
    '千': 1000,
    '万': 10000,
    '萬': 10000,
  };

  /// Characters that are currency/whitespace suffixes — emitted as Skip.
  static final _skipPattern = RegExp(r'[\s¥￥円えんyen]');

  @override
  int? parse(String text) => scan(normalize(text));

  /// Tokenizes [text] into a canonical [NumeralToken] stream via greedy
  /// longest-match over the Japanese numeral dictionary.
  ///
  /// Algorithm:
  /// 1. Try every key in [_sortedKeys] (longest first) at position [i].
  /// 2. On miss: try arabic digit → kanji digit → kanji unit → skip.
  /// 3. [Skip] tokens are consumed silently (not added to output).
  ///
  /// Note: Japanese hiragana/katakana are BMP (U+3040-30FF) — `text[i]` and
  /// `text.substring(i, i+k)` are safe without surrogate-pair concerns.
  @override
  List<NumeralToken> normalize(String text) {
    final tokens = <NumeralToken>[];
    var i = 0;
    while (i < text.length) {
      NumeralToken? matched;
      int? matchLen;

      // Step 1: Greedy longest-match against dictionary
      for (final key in _sortedKeys) {
        if (i + key.length > text.length) continue;
        if (text.substring(i, i + key.length) == key) {
          matched = japaneseNumeralDictionary[key];
          matchLen = key.length;
          break;
        }
      }

      // Step 2: Character-level fallback — arabic / kanji digit / kanji unit / skip
      if (matched == null) {
        final ch = text[i];
        if (RegExp(r'^[0-9]$').hasMatch(ch)) {
          matched = Digit(int.parse(ch));
          matchLen = 1;
        } else if (_kanjiDigits.containsKey(ch)) {
          matched = Digit(_kanjiDigits[ch]!);
          matchLen = 1;
        } else if (_kanjiUnits.containsKey(ch)) {
          matched = Unit(_kanjiUnits[ch]!);
          matchLen = 1;
        } else if (_skipPattern.hasMatch(ch)) {
          // Currency/whitespace suffix — skip silently
          matched = const Skip();
          matchLen = 1;
        } else {
          // Unrecognised character — advance 1 char without emitting a token
          matched = const Skip();
          matchLen = 1;
        }
      }

      if (matched is! Skip) {
        tokens.add(matched);
      }
      i += matchLen!;
    }
    return tokens;
  }
}

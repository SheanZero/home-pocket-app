/// Magnitude-word ↔ digit-count guard (quick task 260706-kzr).
///
/// A pure function that derives the digit count a spoken magnitude word pins
/// onto the utterance's monetary amount:
///   - 千/仟 (zh), 千/せん/ぜん (ja), thousand (en) → multiplier digits + 3
///   - 万/萬 (zh), 万/まん (ja)                     → multiplier digits + 4
///     (en has no ten-thousand word — not applicable)
///
/// Consumers use the expectation to arbitrate between conflicting amount
/// readings (ITN-poisoned digit runs vs. state-machine/alternate re-reads):
/// 「3千5百16元」 pins 4 digits, so a 6-digit "350016" reading violates the
/// speaker's own magnitude word.
///
/// Precision over recall (mirrors `VoiceTextParser._spacedRoundGroupPattern`'s
/// philosophy): idioms (千万别/万一/成千上万), non-monetary tails (1万步),
/// decimal multipliers (3.5千), bare zh 千 without a multiplier, and any
/// ambiguity (conflicting anchored expressions) all return null — the guard
/// refuses to validate rather than risk a wrong expectation. A false
/// expectation could flip a CORRECT amount; a missed one merely skips a check.
///
/// D-14-style isolation: the en branch never touches the CJK numeral state
/// machines; the zh/ja branch never consults English number words.
library;

import '../../infrastructure/voice/chinese_numeral_state_machine.dart';
import '../../infrastructure/voice/japanese_numeral_state_machine.dart';
import '../../shared/constants/voice_currency_suffixes.dart';
import 'english_number_words.dart';

// Private machine singletons — mirrors ParseVoiceInputUseCase's statics
// (ChineseNumeralStateMachine is const; the Japanese machine is not, because
// its dictionary key sort is a non-const static final).
const ChineseNumeralStateMachine _zhMachine = ChineseNumeralStateMachine();
final JapaneseNumeralStateMachine _jaMachine = JapaneseNumeralStateMachine();

/// Magnitude anchor tokens → power (10^power). Highest anchor within one
/// expression wins (千 inside a 万 expression is residue, not an anchor).
const Map<String, int> _magnitudeTokens = {
  '万': 4, '萬': 4, 'まん': 4,
  '千': 3, '仟': 3, 'せん': 3, 'ぜん': 3,
};

/// Characters allowed in a kanji/arabic multiplier run or low-order residue.
/// Units strictly BELOW the anchor power are added per call site.
const String _cjkDigitChars = '0123456789〇零一壱壹二两弐贰三参叁四五伍六七八九';

/// Kana numeral fragments (digit readings + sub-anchor units) used to
/// validate kana multipliers/residues by full greedy tokenization — a
/// substring is numeric ONLY if every char belongs to a known numeral token
/// (prevents swallowing prose like ごはん).
const List<String> _kanaDigitKeys = [
  'いち', 'ひと', 'に', 'ふた', 'さん', 'よん', 'し', 'ご', 'ろく', 'なな',
  'しち', 'はち', 'きゅう', 'く', 'ゼロ', 'れい', 'まる',
];
const List<String> _kanaSubThousandUnitKeys = [
  'じゅう', 'ひゃく', 'さんびゃく', 'ろっぴゃく', 'はっぴゃく',
];
const List<String> _kanaThousandKeys = [
  'せん', 'ぜん', 'いっせん', 'さんぜん', 'はっせん',
];

final List<String> _kanaKeysBelowSen = [
  ..._kanaDigitKeys,
  ..._kanaSubThousandUnitKeys,
]..sort((a, b) => b.length.compareTo(a.length));

final List<String> _kanaKeysBelowMan = [
  ..._kanaDigitKeys,
  ..._kanaSubThousandUnitKeys,
  ..._kanaThousandKeys,
]..sort((a, b) => b.length.compareTo(a.length));

/// Longest-first currency-suffix alternation anchored at position 0, used to
/// check that a money expression terminates in a currency token.
final RegExp _currencyPrefixPattern = RegExp(
  '^(?:${VoiceCurrencySuffixes.regexAlternation})',
  caseSensitive: false,
);

/// English number words accepted in a thousand-multiplier or residue run.
/// Local mirror of the english_number_words.dart lexicon (its maps are
/// library-private); 'thousand' itself is excluded — it is the anchor.
const Set<String> _enNumberWords = {
  'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
  'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
  'sixteen', 'seventeen', 'eighteen', 'nineteen', 'a', 'an',
  'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty',
  'ninety', 'hundred',
};

/// Returns the digit count the utterance's magnitude word implies for its
/// monetary amount, or null when no unambiguous magnitude-anchored money
/// expression exists (precision over recall — null means "do not validate").
///
/// [localeId] routes like `VoiceTextParser.extractAmount`: an en locale uses
/// the isolated English branch; zh/ja/null use the CJK branch (multiplier
/// parsing falls back ja-then-zh when the locale is null).
int? expectedDigitCountForAmount(String text, {String? localeId}) {
  if (text.isEmpty) return null;
  final lower = (localeId ?? '').toLowerCase();
  if (lower.startsWith('en')) {
    return _enExpectedDigitCount(text);
  }
  return _cjkExpectedDigitCount(text, localeId);
}

// ── zh/ja branch ─────────────────────────────────────────────────────────────

int? _cjkExpectedDigitCount(String text, String? localeId) {
  final anchors = <({int start, int end, int power})>[];
  _magnitudeTokens.forEach((token, power) {
    var idx = text.indexOf(token);
    while (idx >= 0) {
      anchors.add((start: idx, end: idx + token.length, power: power));
      idx = text.indexOf(token, idx + 1);
    }
  });
  if (anchors.isEmpty) return null;

  // 万 expressions first; a 千 that falls inside a committed 万 expression
  // span (its multiplier or residue — e.g. the 二千 in 一万二千円) is NOT an
  // independent anchor.
  final spans = <({int start, int end})>[];
  final expectations = <int>[];
  for (final pass in const [4, 3]) {
    for (final anchor in anchors) {
      if (anchor.power != pass) continue;
      final consumed = spans.any(
        (s) => anchor.start >= s.start && anchor.start < s.end,
      );
      if (consumed) continue;
      final expr = _evaluateCjkExpression(
        text,
        anchorStart: anchor.start,
        anchorEnd: anchor.end,
        power: anchor.power,
        localeId: localeId,
      );
      if (expr == null) continue;
      spans.add((start: expr.start, end: expr.end));
      expectations.add(expr.expected);
    }
  }

  if (expectations.isEmpty) return null;
  final first = expectations.first;
  for (final expected in expectations) {
    // Mutually exclusive expectations → ambiguous → refuse to validate.
    if (expected != first) return null;
  }
  return first;
}

({int start, int end, int expected})? _evaluateCjkExpression(
  String text, {
  required int anchorStart,
  required int anchorEnd,
  required int power,
  required String? localeId,
}) {
  final kanaKeys = power == 4 ? _kanaKeysBelowMan : _kanaKeysBelowSen;

  // Multiplier run: the longest contiguous numeric substring immediately
  // before the anchor — kanji/arabic char walk first, kana tokenization as
  // fallback. 万 admits 千/仟 in its multiplier (三千万 shapes); those parse
  // above the 1–999 bound and are rejected, which doubles as the 千万别
  // idiom guard.
  var run = _kanjiMultiplierRun(text, anchorStart, power);
  if (run.isEmpty) {
    run = _kanaMultiplierRun(text, anchorStart, kanaKeys);
  }
  final runStart = anchorStart - run.length;

  // Decimal multipliers (3.5千 / 三点五千) are real-amount shapes this integer
  // guard must never constrain.
  final guardIdx = runStart - 1;
  if (guardIdx >= 0 && '.．点'.contains(text[guardIdx])) return null;

  int? multiplier;
  if (run.isNotEmpty) {
    multiplier = _parseMultiplier(run, localeId);
    if (multiplier == null || multiplier < 1 || multiplier > 999) return null;
  }

  // Low-order residue after the anchor: only numeral content is allowed;
  // any other rune (万步的步) breaks the expression.
  final residueEnd = _consumeResidue(text, anchorEnd, power, kanaKeys);
  final atEnd = residueEnd >= text.length;
  final hasCurrency =
      !atEnd && _currencyPrefixPattern.hasMatch(text.substring(residueEnd));
  if (!atEnd && !hasCurrency) return null;

  if (multiplier == null) {
    // Bare-anchor default (千円→1000): Japanese only, and only when the
    // expression is explicitly currency-anchored. zh (and null locale) yield
    // null — 千万别-class idioms must never validate.
    final isJa = (localeId ?? '').toLowerCase().startsWith('ja');
    if (!isJa || !hasCurrency) return null;
    multiplier = 1;
  }

  return (
    start: runStart,
    end: residueEnd,
    expected: multiplier.toString().length + power,
  );
}

String _kanjiMultiplierRun(String text, int anchorStart, int power) {
  final allowed = _cjkDigitChars + (power == 4 ? '十百千仟' : '十百');
  var start = anchorStart;
  while (start > 0 && allowed.contains(text[start - 1])) {
    start--;
  }
  return text.substring(start, anchorStart);
}

String _kanaMultiplierRun(String text, int anchorStart, List<String> keys) {
  var best = '';
  final maxLen = anchorStart < 12 ? anchorStart : 12;
  for (var len = 1; len <= maxLen; len++) {
    final candidate = text.substring(anchorStart - len, anchorStart);
    if (_fullyKanaNumeric(candidate, keys)) best = candidate;
  }
  return best;
}

bool _fullyKanaNumeric(String s, List<String> keys) {
  if (s.isEmpty) return false;
  var i = 0;
  outer:
  while (i < s.length) {
    for (final key in keys) {
      if (s.startsWith(key, i)) {
        i += key.length;
        continue outer;
      }
    }
    return false;
  }
  return true;
}

int? _parseMultiplier(String run, String? localeId) {
  if (RegExp(r'^\d+$').hasMatch(run)) return int.tryParse(run);
  final lower = (localeId ?? '').toLowerCase();
  if (lower.startsWith('zh')) return _zhMachine.parse(run);
  if (lower.startsWith('ja')) return _jaMachine.parse(run);
  // Null locale: mirror VoiceTextParser._runStateMachine's ja-then-zh fallback.
  return _jaMachine.parse(run) ?? _zhMachine.parse(run);
}

int _consumeResidue(String text, int pos, int power, List<String> kanaKeys) {
  final allowed = _cjkDigitChars + (power == 4 ? '十百千仟' : '十百');
  var p = pos;
  outer:
  while (p < text.length) {
    final ch = text[p];
    if (ch == ' ' || ch == '　') {
      p++;
      continue;
    }
    if (allowed.contains(ch)) {
      p++;
      continue;
    }
    for (final key in kanaKeys) {
      if (text.startsWith(key, p)) {
        p += key.length;
        continue outer;
      }
    }
    break;
  }
  return p;
}

// ── en branch (isolated — never touches the CJK machines) ───────────────────

int? _enExpectedDigitCount(String text) {
  final lower = text.toLowerCase();
  // \b keeps 'thousands' (of people) from matching; more than one anchor is
  // ambiguous → refuse.
  final anchors = RegExp(r'\bthousand\b').allMatches(lower).toList();
  if (anchors.length != 1) return null;
  final anchor = anchors.single;

  // Multiplier: trailing arabic run, else trailing number-word phrase fed to
  // the bounded English number-word parser (a/an → 1).
  final before = lower.substring(0, anchor.start);
  int? multiplier;
  final arabicTail = RegExp(r'(\d+)\s*$').firstMatch(before);
  if (arabicTail != null) {
    final runStart = arabicTail.start;
    if (runStart > 0 && before[runStart - 1] == '.') return null;
    multiplier = int.tryParse(arabicTail.group(1)!);
  } else {
    final words = before.trim().split(RegExp(r'\s+'));
    final phrase = <String>[];
    for (var i = words.length - 1; i >= 0; i--) {
      final word = words[i];
      if (word.isEmpty || !_enNumberWords.contains(word)) break;
      phrase.insert(0, word);
    }
    if (phrase.isNotEmpty) {
      multiplier = parseEnglishNumberWords(
        phrase.join(' '),
        moneyContext: true,
      );
    }
  }
  if (multiplier == null || multiplier < 1 || multiplier > 999) return null;

  // Low-order residue: number words / digit runs after 'thousand'.
  var rest = lower.substring(anchor.end).trimLeft();
  while (rest.isNotEmpty) {
    final wordMatch = RegExp(r'^([a-z]+|\d+)').firstMatch(rest);
    if (wordMatch == null) break;
    final word = wordMatch.group(1)!;
    final isNumeric =
        _enNumberWords.contains(word) || RegExp(r'^\d+$').hasMatch(word);
    if (!isNumeric) break;
    rest = rest.substring(wordMatch.end).trimLeft();
  }

  // Money anchor: end-of-string after the residue, or a money token
  // ($ / dollar(s) / any VoiceCurrencySuffixes token) right after it.
  final anchored =
      rest.isEmpty ||
      rest.startsWith(r'$') ||
      RegExp(r'^dollars?\b').hasMatch(rest) ||
      _currencyPrefixPattern.hasMatch(rest);
  if (!anchored) return null;

  return multiplier.toString().length + 3;
}

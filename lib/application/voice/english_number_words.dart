/// Bounded English number-word parser (VEN-02 / D-14).
///
/// A pure, ~30-line fallback for English STT amounts that the Arabic regex in
/// [VoiceTextParser._extractArabicAmount] misses (e.g. 「fifty dollars」 where
/// the engine returned words, not digits). It handles units zero…nineteen,
/// tens twenty…ninety, scales hundred/thousand, and `a`/`an`→1, plus the
/// 「X fifty」→X.50 money idiom.
///
/// D-14 isolation (guards the v1.8 WR-04 regression class): this function NEVER
/// imports or calls the ja/zh numeral state machines. The English fallback must
/// route entirely AROUND the CJK numeral path.
///
/// Security (T-52-10): output is clamped to the same `0 < amount < 10_000_000`
/// bound the Arabic path uses — no unbounded amount can leak through.
library;

const Map<String, int> _units = {
  'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6,
  'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11, 'twelve': 12,
  'thirteen': 13, 'fourteen': 14, 'fifteen': 15, 'sixteen': 16,
  'seventeen': 17, 'eighteen': 18, 'nineteen': 19, 'a': 1, 'an': 1,
};

const Map<String, int> _tens = {
  'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60,
  'seventy': 70, 'eighty': 80, 'ninety': 90,
};

/// Parses an English number-word amount, or returns null if none / out of range.
///
/// The 「X fifty」→X.50 idiom (e.g. 「five fifty」→550 minor units) fires ONLY
/// when [moneyContext] is true (otherwise 「five fifty」 is the ambiguous 550 we
/// refuse to guess). Clamped to `0 < result < 10_000_000`.
int? parseEnglishNumberWords(String text, {required bool moneyContext}) {
  final tokens = text
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((t) => t.isNotEmpty && (_units.containsKey(t) || _tens.containsKey(t) || t == 'hundred' || t == 'thousand'))
      .toList();
  if (tokens.isEmpty) return null;

  // 「X fifty」 idiom shape: a unit/teen immediately followed by a tens-word.
  // Unit-then-tens is NOT a valid spoken composite for any plain integer, so:
  //  - in money context it reads as X.50 (e.g. 「five fifty」→ 550 minor units);
  //  - outside money context it is the ambiguous 550-vs-5.50 case we refuse to
  //    guess (return null) rather than fall through to a bogus 55.
  if (tokens.length == 2 &&
      _units.containsKey(tokens[0]) &&
      _units[tokens[0]]! >= 1 &&
      _units[tokens[0]]! <= 19 &&
      _tens.containsKey(tokens[1])) {
    if (!moneyContext) return null;
    final result = _units[tokens[0]]! * 100 + _tens[tokens[1]]!;
    return _clamp(result);
  }

  // Plain numeric reading (units + tens + hundred/thousand scales).
  var total = 0;
  var current = 0;
  for (final token in tokens) {
    if (_units.containsKey(token)) {
      current += _units[token]!;
    } else if (_tens.containsKey(token)) {
      current += _tens[token]!;
    } else if (token == 'hundred') {
      current = (current == 0 ? 1 : current) * 100;
    } else if (token == 'thousand') {
      total += (current == 0 ? 1 : current) * 1000;
      current = 0;
    }
  }
  return _clamp(total + current);
}

int? _clamp(int amount) =>
    (amount > 0 && amount < 10000000) ? amount : null;

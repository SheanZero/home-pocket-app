/// Currency suffix tokens recognized by the voice pipeline.
///
/// Centralized in WR-07 because two functions in the voice path
/// (`VoiceTextParser._extractPotentialMerchantNames` and
/// `ParseVoiceInputUseCase._extractKeyword`) had drifted to slightly
/// different sets — '5块钱' would have its amount stripped but '块'
/// left behind as a corrupt keyword, depending on which function ran.
///
/// Keep this list narrow — every entry is a voice-recognized currency
/// marker, not a generic Asian-language noun.
class VoiceCurrencySuffixes {
  VoiceCurrencySuffixes._();

  /// All recognized suffix tokens, in regex-alternation order.
  ///
  /// Ordering matters: longer tokens come first so that a regex constructed
  /// from `regexAlternation` matches the longest possible suffix at any
  /// given position (e.g. `5块钱` matches `5块钱`, not `5块` with `钱` left
  /// behind in the keyword stream).
  ///
  /// Used to construct extraction regexes — see `regexAlternation`.
  static const List<String> all = <String>[
    // Quick task 260526-l0o (Issue 1): '日元' (zh — "Japanese yen") MUST come
    // before the bare '元' so the longer two-char token wins the regex
    // alternation. Without it, `12,450日元` partial-matches `,450` and drops
    // the thousands group.
    '日元',
    '块钱',
    'えん',
    'yen',
    '円',
    '元',
    '块',
    '塊',
    'ドル',
  ];

  /// Regex-alternation fragment for use inside a larger pattern, e.g.
  /// `RegExp(r'\d+\s*(?:' + VoiceCurrencySuffixes.regexAlternation + r')')`.
  static String get regexAlternation => all.join('|');
}

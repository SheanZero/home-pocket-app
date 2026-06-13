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
    // Phase 42 (VOICE-CUR-01/02): multi-char foreign-currency tokens come
    // FIRST so the longest-first alternation invariant holds — `香港ドル`
    // (HKD) must beat the bare `ドル` (USD) suffix, and `美元`/`欧元`/`澳元`/
    // `加元` (3rd char counts) must beat the bare `元` terminator.
    '香港ドル',
    '美元',
    '欧元',
    '澳元',
    '加元',
    'ユーロ',
    'ポンド',
    '豪ドル',
    '英镑',
    '港币',
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

  /// Maps each voice-recognized currency token to its ISO 4217 code.
  ///
  /// Phase 42 (VOICE-CUR-01/02/03): the voice pipeline now DETECTS a spoken
  /// foreign-currency token (not just strips it). The numeral state machines
  /// look up the longest matching token here and carry the ISO code out on
  /// `VoiceParseResult.detectedCurrency`, which the shared form uses to trigger
  /// the normal rate-fetch flow.
  ///
  /// Ordering inside [all] (longest-first) is the matching invariant; this map
  /// is the value lookup once a token has been matched.
  ///
  /// Bare-native tokens (`元`/`円`/`日元`/`块`/`塊`/`块钱`/`えん`/`yen`) are NOT
  /// in this map: `元`'s ISO is locale-dependent (zh→CNY, ja→JPY per D-08) and
  /// is resolved at the use-case layer, while `円`/`日元`/yen are JPY-native and
  /// surface as null `detectedCurrency` (no foreign conversion). English tokens
  /// are deliberately absent — voice currency is deferred to v2 for English.
  static const Map<String, String> tokenToIso = <String, String>{
    // zh foreign-currency tokens (VOICE-CUR-01)
    '美元': 'USD',
    '欧元': 'EUR',
    '英镑': 'GBP',
    '港币': 'HKD',
    '澳元': 'AUD',
    '加元': 'CAD',
    // ja foreign-currency tokens (VOICE-CUR-02)
    '香港ドル': 'HKD',
    '豪ドル': 'AUD',
    'ユーロ': 'EUR',
    'ポンド': 'GBP',
    'ドル': 'USD', // bare ドル → USD (default, D-08 locked)
  };

  /// Regex-alternation fragment for use inside a larger pattern, e.g.
  /// `RegExp(r'\d+\s*(?:' + VoiceCurrencySuffixes.regexAlternation + r')')`.
  static String get regexAlternation => all.join('|');
}

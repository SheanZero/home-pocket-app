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

  /// All recognized suffix tokens.
  ///
  /// Detection (`detectCurrencyToken`) is order-robust: it tiers explicit-
  /// foreign over bare-native and breaks ties leftmost-wins, so containment
  /// (`香港ドル ⊃ ドル`, `canadian dollar ⊃ dollar`) is resolved by index, not
  /// list position. The regex consumers go through [regexAlternation], which
  /// sorts longest-first at build time — so the list itself only needs to be
  /// COMPLETE here, not perfectly length-ordered. Grouped by currency for
  /// readability; bare single-token terminators (`元`/`円`/`块`/`ドル`) live at
  /// the end.
  ///
  /// Quick task 260614-goh: expanded to cover EVERY app-supported currency
  /// (USD/EUR/CNY/HKD/GBP/KRW/TWD/AUD/CAD/SGD) in zh / ja / en spoken forms.
  /// English tokens are stored lowercase; detection and the amount regex are
  /// case-insensitive so STT capitalization ("Dollars") still matches.
  static const List<String> all = <String>[
    // ── USD ──
    '美元', '美金', // zh
    'アメリカドル', '米国ドル', '米ドル', 'ドル', // ja (bare ドル → USD, D-08)
    'american dollar', 'us dollar', 'dollars', 'dollar', // en
    // ── EUR ──
    '欧元', // zh
    'ユーロ', // ja
    'euros', 'euro', // en
    // ── GBP ──
    '英镑', // zh
    '英ポンド', 'ポンド', // ja
    'british pound', 'sterling', 'pounds', 'pound', // en
    // ── CNY ── (bare 元 stays locale-resolved: zh→CNY / ja→JPY, see below)
    '人民币', '人民幣', // zh
    '人民元', '中国元', // ja
    'chinese yuan', 'renminbi', 'yuan', 'rmb', // en
    // ── HKD ──
    '港币', '港元', // zh
    '香港ドル', // ja
    'hong kong dollar', // en
    // ── AUD ──
    '澳元', '澳币', // zh
    'オーストラリアドル', '豪ドル', // ja
    'australian dollar', 'aussie dollar', // en
    // ── CAD ──
    '加元', '加币', // zh
    'カナダドル', '加ドル', // ja
    'canadian dollar', // en
    // ── KRW ──
    '韩元', '韩币', '韩圆', // zh
    '韓国ウォン', 'ウォン', // ja
    'korean won', 'korea won', // en
    // ── TWD ──
    '新台币', '新台幣', '台币', '台幣', '台元', // zh
    '新台湾ドル', '台湾ドル', // ja
    'new taiwan dollar', 'taiwan dollar', // en
    // ── SGD ──
    '新加坡元', '新元', // zh
    'シンガポールドル', // ja
    'singapore dollar', // en
    // ── JPY-native (NOT in tokenToIso → resolve to null, no conversion) ──
    // '日元' (zh) MUST precede the bare '元' so `12,450日元` is not split.
    '日元', '块钱', 'えん', 'japanese yen', 'yen', 'jpy',
    // ── Bare locale-ambiguous / native terminators (kept LAST) ──
    '円', '元', '块', '塊',
  ];

  /// Maps each voice-recognized currency token to its ISO 4217 code.
  ///
  /// Phase 42 (VOICE-CUR-01/02/03): the voice pipeline DETECTS a spoken
  /// foreign-currency token (not just strips it). [tokenToIso] is the value
  /// lookup once `detectCurrencyToken` has matched a token; the ISO code is
  /// carried out on `VoiceParseResult.detectedCurrency`, which the shared form
  /// uses to trigger the normal rate-fetch flow.
  ///
  /// Bare-native tokens (`元`/`円`/`日元`/`块`/`块钱`/`えん`/`yen`/`jpy`/
  /// `japanese yen`) are NOT in this map: `元`'s ISO is locale-dependent
  /// (zh→CNY, ja→JPY per D-08) and is resolved at the use-case layer, while the
  /// rest are JPY-native and surface as null `detectedCurrency`.
  ///
  /// Quick task 260614-goh: English tokens (lowercase) and the full supported
  /// currency set added. Every key here MUST also appear in [all].
  static const Map<String, String> tokenToIso = <String, String>{
    // USD
    '美元': 'USD', '美金': 'USD',
    'アメリカドル': 'USD', '米国ドル': 'USD', '米ドル': 'USD', 'ドル': 'USD',
    'american dollar': 'USD', 'us dollar': 'USD',
    'dollars': 'USD', 'dollar': 'USD',
    // EUR
    '欧元': 'EUR', 'ユーロ': 'EUR', 'euros': 'EUR', 'euro': 'EUR',
    // GBP
    '英镑': 'GBP', '英ポンド': 'GBP', 'ポンド': 'GBP',
    'british pound': 'GBP', 'sterling': 'GBP', 'pounds': 'GBP', 'pound': 'GBP',
    // CNY (explicit words only; bare 元 resolved by locale, see bareYuanToken)
    '人民币': 'CNY', '人民幣': 'CNY', '人民元': 'CNY', '中国元': 'CNY',
    'chinese yuan': 'CNY', 'renminbi': 'CNY', 'yuan': 'CNY', 'rmb': 'CNY',
    // HKD
    '港币': 'HKD', '港元': 'HKD', '香港ドル': 'HKD', 'hong kong dollar': 'HKD',
    // AUD
    '澳元': 'AUD', '澳币': 'AUD', 'オーストラリアドル': 'AUD', '豪ドル': 'AUD',
    'australian dollar': 'AUD', 'aussie dollar': 'AUD',
    // CAD
    '加元': 'CAD', '加币': 'CAD', 'カナダドル': 'CAD', '加ドル': 'CAD',
    'canadian dollar': 'CAD',
    // KRW
    '韩元': 'KRW', '韩币': 'KRW', '韩圆': 'KRW', '韓国ウォン': 'KRW', 'ウォン': 'KRW',
    'korean won': 'KRW', 'korea won': 'KRW',
    // TWD
    '新台币': 'TWD', '新台幣': 'TWD', '台币': 'TWD', '台幣': 'TWD', '台元': 'TWD',
    '新台湾ドル': 'TWD', '台湾ドル': 'TWD',
    'new taiwan dollar': 'TWD', 'taiwan dollar': 'TWD',
    // SGD
    '新加坡元': 'SGD', '新元': 'SGD', 'シンガポールドル': 'SGD',
    'singapore dollar': 'SGD',
  };

  /// The bare locale-ambiguous Chinese yuan / Japanese yen token (`元`).
  ///
  /// D-08 (locked): in zh locale this resolves to CNY; in ja locale it is
  /// JPY-native (no foreign conversion). Exposed as a named constant so the
  /// use-case layer can resolve the ambiguity WITHOUT embedding a raw CJK
  /// literal (keeps `ParseVoiceInputUseCase` out of the hardcoded-CJK scan).
  static const String bareYuanToken = '元';

  /// Tokens ordered longest-first — the matching invariant for the regexes.
  ///
  /// Longer tokens win at any given position so a multi-word / compound token
  /// (`canadian dollar`, `香港ドル`, `12,450日元`) is consumed whole instead of
  /// having a shorter substring (`dollar`, `ドル`, `元`) match first and leave a
  /// corrupt remainder. Sorting here (not hand-ordering [all]) keeps [all]
  /// readable while guaranteeing the invariant.
  static final List<String> _longestFirst =
      List<String>.of(all)..sort((a, b) => b.length.compareTo(a.length));

  /// Regex-alternation fragment for use inside a larger pattern, e.g.
  /// `RegExp(r'\d+\s*(?:' + VoiceCurrencySuffixes.regexAlternation + r')')`.
  ///
  /// Built from [_longestFirst] so the alternation matches the longest token
  /// at any position. Tokens are regex-escaped (English tokens contain spaces
  /// only today, but escaping is future-proof against metacharacters).
  static String get regexAlternation =>
      _longestFirst.map(RegExp.escape).join('|');
}

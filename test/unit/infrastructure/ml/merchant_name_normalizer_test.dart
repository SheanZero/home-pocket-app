import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/ml/merchant_name_normalizer.dart';

/// Property-style held-out test for [normalizeMerchantKey] (MERCH-02, D-03).
///
/// This is the seed-time AND (future Phase 50) query-time match-key function.
/// It folds:
///   - fullwidth ASCII (U+FF01..FF5E) → halfwidth; ideographic space U+3000 → ' '
///   - katakana (U+30A1..30F6) → hiragana; half-width katakana (U+FF61..FF9F)
///     → standard katakana → hiragana (incl. combining ﾞ/ﾟ markers)
///   - combining dakuten/handakuten (U+3099/309A) composed so か+◌゙ == が
///   - lowercase; 中黒 ・ and whitespace stripped from the key
/// It KEEPS 長音符 ー (U+30FC) and small kana ァィゥェォッ (meaningful — RESEARCH Open Q #3).
void main() {
  // (input, expected) pairs covering EVERY case in the plan behavior block.
  // Built table-style so each transform is exercised in isolation and in combination.
  const expectedPairs = <(String, String)>[
    // --- Fullwidth ASCII → halfwidth, then lowercase ---
    ('ＳＴＡＲＢＵＣＫＳ', 'starbucks'),
    ('７', '7'),
    ('ＭｃＤｏｎａｌｄ', 'mcdonald'),
    ('ＡＢＣ１２３', 'abc123'),

    // --- Fullwidth/ideographic space stripped ---
    ('Ａ　Ｂ', 'ab'), // U+3000 ideographic space between fullwidth A/B

    // --- Katakana → hiragana ---
    ('マック', 'まっく'),
    ('セブン', 'せぶん'),
    ('スタバ', 'すたば'),
    ('スターバックス', 'すたーばっくす'),
    ('マクドナルド', 'まくどなるど'),
    ('ヨシノヤ', 'よしのや'),

    // --- Half-width katakana → standard → hiragana ---
    ('ｾﾌﾞﾝ', 'せぶん'), // ｾ ﾌ +ﾞ ﾝ  (ﾞ combines onto ﾌ → ぶ)
    ('ﾏｯｸ', 'まっく'), // ﾏ ｯ(small tsu) ｸ
    ('ﾊﾟﾝ', 'ぱん'), // ﾊ +ﾟ(handakuten) ﾝ → ぱん
    ('ｶﾞ', 'が'), // ｶ +ﾞ → が

    // --- Combining dakuten / handakuten compose (standard kana base) ---
    ('が', 'が'), // か + combining dakuten == precomposed が
    ('ぱ', 'ぱ'), // は + combining handakuten == precomposed ぱ
    ('ガ', 'が'), // katakana カ + combining dakuten → fold to が

    // --- Case folding ---
    ('McDonald', 'mcdonald'),
    ('UNIQLO', 'uniqlo'),
    ('Starbucks', 'starbucks'),

    // --- KEEP 長音符 ー (do NOT over-merge コーヒー → こひ) ---
    ('コーヒー', 'こーひー'),
    ('ラーメン', 'らーめん'),

    // --- KEEP small kana (マック keeps っ; ファミマ keeps ァ) ---
    ('ファミマ', 'ふぁみま'),

    // --- Strip 中黒 ・ and whitespace ---
    ('7・11', '711'),
    ('セブン イレブン', 'せぶんいれぶん'),
    ('7-Eleven', '7-eleven'), // ASCII hyphen kept (not 中黒, not whitespace)
    ('セブン・イレブン', 'せぶんいれぶん'),
    ('  spaced  out  ', 'spacedout'),

    // --- Combined real-world surfaces ---
    ('ＵＮＩＱＬＯ', 'uniqlo'), // fullwidth → halfwidth → lower
    ('スターバックス コーヒー', 'すたーばっくすこーひー'), // kana fold + ー kept + space strip

    // --- Empty / passthrough ---
    ('', ''),
    ('lawson', 'lawson'),
  ];

  group('normalizeMerchantKey — property table', () {
    for (final (input, expected) in expectedPairs) {
      test('normalize(${_label(input)}) == ${_label(expected)}', () {
        expect(normalizeMerchantKey(input), expected);
      });
    }
  });

  group('normalizeMerchantKey — idempotency invariant', () {
    for (final (input, _) in expectedPairs) {
      test('idempotent for ${_label(input)}', () {
        final once = normalizeMerchantKey(input);
        final twice = normalizeMerchantKey(once);
        expect(twice, once);
      });
    }
  });
}

/// Render control/wide characters readably in test names.
String _label(String s) => s.isEmpty ? '<empty>' : s;

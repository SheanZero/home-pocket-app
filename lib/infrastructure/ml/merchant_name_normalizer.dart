/// Computes the canonical match-key for a merchant surface form.
///
/// This is the SINGLE shared normalizer for merchant matching: it is used at
/// seed time (Plan 05 `SeedMerchantsUseCase` precomputes `merchant_match_keys`)
/// AND, unchanged, at query time in Phase 50 (`MerchantRecognizer`). It is a
/// hand-written NFKC-lite + kana fold with ZERO new dependencies (D-03), scoped
/// to merchant match-keys rather than full linguistic Unicode normalization.
///
/// Pipeline (over `input.runes`):
///   1. Fullwidth ASCII (U+FF01..FF5E) → halfwidth (offset −0xFEE0);
///      ideographic space (U+3000) → ASCII space.
///   2. Half-width katakana (U+FF61..FF9F) → standard katakana, composing the
///      trailing half-width dakuten (ﾞ U+FF9E) / handakuten (ﾟ U+FF9F) onto the
///      preceding base kana when a voiced/semi-voiced form exists.
///   3. Katakana (U+30A1..U+30F6) → hiragana (offset −0x60). 長音符 ー (U+30FC)
///      is KEPT (stripping over-merges コーヒー/コヒー — RESEARCH Open Q #3).
///   4. Combining dakuten (U+3099) / handakuten (U+309A) following a base
///      hiragana are composed so か+◌゙ == precomposed が.
/// After the rune pass: `.toLowerCase()`, then strip 中黒 ・ (U+30FB) and all
/// whitespace from the key. Small kana ァィゥェォッ are KEPT (meaningful).
///
/// The function is idempotent: `normalizeMerchantKey(normalizeMerchantKey(x))`
/// equals `normalizeMerchantKey(x)` for all inputs.
String normalizeMerchantKey(String input) {
  // Pass 1: fold each rune to a hiragana/halfwidth codepoint, expanding
  // half-width katakana and composing combining/voicing marks as we go.
  final folded = <int>[];
  final runes = input.runes.toList(growable: false);

  for (var i = 0; i < runes.length; i++) {
    final r = runes[i];

    // --- Fullwidth ASCII → halfwidth ---
    if (r >= 0xFF01 && r <= 0xFF5E) {
      folded.add(r - 0xFEE0);
      continue;
    }

    // --- Ideographic space → ASCII space (stripped later) ---
    if (r == 0x3000) {
      folded.add(0x20);
      continue;
    }

    // --- Half-width katakana (U+FF61..FF9F) → standard katakana → hiragana ---
    if (r >= 0xFF61 && r <= 0xFF9F) {
      final base = _halfwidthKatakanaToHiragana[r];
      if (base == null) {
        // Standalone half-width voicing mark with no base (rare); drop it so it
        // cannot corrupt the key. (Composed marks are consumed below.)
        continue;
      }
      // Look ahead for a half-width dakuten/handakuten and compose if possible.
      if (i + 1 < runes.length) {
        final next = runes[i + 1];
        if (next == 0xFF9E) {
          final voiced = _composeDakuten[base];
          if (voiced != null) {
            folded.add(voiced);
            i++; // consume the mark
            continue;
          }
        } else if (next == 0xFF9F) {
          final semi = _composeHandakuten[base];
          if (semi != null) {
            folded.add(semi);
            i++; // consume the mark
            continue;
          }
        }
      }
      folded.add(base);
      continue;
    }

    // --- Katakana (U+30A1..U+30F6) → hiragana. Keep 長音符 ー (U+30FC). ---
    if (r >= 0x30A1 && r <= 0x30F6) {
      folded.add(r - 0x60);
      continue;
    }

    // --- Combining dakuten/handakuten after a base hiragana → compose ---
    if (r == 0x3099 || r == 0x309A) {
      if (folded.isNotEmpty) {
        final base = folded.last;
        final composed = (r == 0x3099)
            ? _composeDakuten[base]
            : _composeHandakuten[base];
        if (composed != null) {
          folded[folded.length - 1] = composed;
          continue;
        }
      }
      // No composable base: drop the orphan combining mark.
      continue;
    }

    folded.add(r);
  }

  final lowered = String.fromCharCodes(folded).toLowerCase();
  // Strip 中黒 ・ and all whitespace from the match-key.
  return lowered.replaceAll('・', '').replaceAll(RegExp(r'\s+'), '');
}

/// Convenience namespace wrapper around [normalizeMerchantKey] for callers that
/// prefer a typed entry point. The top-level function remains the canonical API.
abstract final class MerchantNameNormalizer {
  const MerchantNameNormalizer._();

  /// See [normalizeMerchantKey].
  static String key(String input) => normalizeMerchantKey(input);
}

// ---------------------------------------------------------------------------
// Lookup tables (const). All values are HIRAGANA codepoints so half-width
// katakana lands directly in the hiragana namespace alongside steps 3/4.
// ---------------------------------------------------------------------------

/// Half-width katakana (U+FF61..FF9F) → base hiragana codepoint.
/// Voicing marks ﾞ (U+FF9E) / ﾟ (U+FF9F) are handled separately (composed).
const Map<int, int> _halfwidthKatakanaToHiragana = {
  0xFF61: 0x3002, // 。 ideographic full stop
  0xFF62: 0x300C, // 「
  0xFF63: 0x300D, // 」
  0xFF64: 0x3001, // 、
  0xFF65: 0x30FB, // ・ (stripped later)
  0xFF66: 0x3092, // ｦ → を
  0xFF67: 0x3041, // ｧ → ぁ
  0xFF68: 0x3043, // ｨ → ぃ
  0xFF69: 0x3045, // ｩ → ぅ
  0xFF6A: 0x3047, // ｪ → ぇ
  0xFF6B: 0x3049, // ｫ → ぉ
  0xFF6C: 0x3083, // ｬ → ゃ
  0xFF6D: 0x3085, // ｭ → ゅ
  0xFF6E: 0x3087, // ｮ → ょ
  0xFF6F: 0x3063, // ｯ → っ
  0xFF70: 0x30FC, // ｰ → ー (長音符 kept)
  0xFF71: 0x3042, // ｱ → あ
  0xFF72: 0x3044, // ｲ → い
  0xFF73: 0x3046, // ｳ → う
  0xFF74: 0x3048, // ｴ → え
  0xFF75: 0x304A, // ｵ → お
  0xFF76: 0x304B, // ｶ → か
  0xFF77: 0x304D, // ｷ → き
  0xFF78: 0x304F, // ｸ → く
  0xFF79: 0x3051, // ｹ → け
  0xFF7A: 0x3053, // ｺ → こ
  0xFF7B: 0x3055, // ｻ → さ
  0xFF7C: 0x3057, // ｼ → し
  0xFF7D: 0x3059, // ｽ → す
  0xFF7E: 0x305B, // ｾ → せ
  0xFF7F: 0x305D, // ｿ → そ
  0xFF80: 0x305F, // ﾀ → た
  0xFF81: 0x3061, // ﾁ → ち
  0xFF82: 0x3064, // ﾂ → つ
  0xFF83: 0x3066, // ﾃ → て
  0xFF84: 0x3068, // ﾄ → と
  0xFF85: 0x306A, // ﾅ → な
  0xFF86: 0x306B, // ﾆ → に
  0xFF87: 0x306C, // ﾇ → ぬ
  0xFF88: 0x306D, // ﾈ → ね
  0xFF89: 0x306E, // ﾉ → の
  0xFF8A: 0x306F, // ﾊ → は
  0xFF8B: 0x3072, // ﾋ → ひ
  0xFF8C: 0x3075, // ﾌ → ふ
  0xFF8D: 0x3078, // ﾍ → へ
  0xFF8E: 0x307B, // ﾎ → ほ
  0xFF8F: 0x307E, // ﾏ → ま
  0xFF90: 0x307F, // ﾐ → み
  0xFF91: 0x3080, // ﾑ → む
  0xFF92: 0x3081, // ﾒ → め
  0xFF93: 0x3082, // ﾓ → も
  0xFF94: 0x3084, // ﾔ → や
  0xFF95: 0x3086, // ﾕ → ゆ
  0xFF96: 0x3088, // ﾖ → よ
  0xFF97: 0x3089, // ﾗ → ら
  0xFF98: 0x308A, // ﾘ → り
  0xFF99: 0x308B, // ﾙ → る
  0xFF9A: 0x308C, // ﾚ → れ
  0xFF9B: 0x308D, // ﾛ → ろ
  0xFF9C: 0x308F, // ﾜ → わ
  0xFF9D: 0x3093, // ﾝ → ん
};

/// Base hiragana → voiced (dakuten) hiragana. Used to compose か+◌゙ → が,
/// half-width ｶ+ﾞ → が, etc.
const Map<int, int> _composeDakuten = {
  0x304B: 0x304C, // か → が
  0x304D: 0x304E, // き → ぎ
  0x304F: 0x3050, // く → ぐ
  0x3051: 0x3052, // け → げ
  0x3053: 0x3054, // こ → ご
  0x3055: 0x3056, // さ → ざ
  0x3057: 0x3058, // し → じ
  0x3059: 0x305A, // す → ず
  0x305B: 0x305C, // せ → ぜ
  0x305D: 0x305E, // そ → ぞ
  0x305F: 0x3060, // た → だ
  0x3061: 0x3062, // ち → ぢ
  0x3064: 0x3065, // つ → づ
  0x3066: 0x3067, // て → で
  0x3068: 0x3069, // と → ど
  0x306F: 0x3070, // は → ば
  0x3072: 0x3073, // ひ → び
  0x3075: 0x3076, // ふ → ぶ
  0x3078: 0x3079, // へ → べ
  0x307B: 0x307C, // ほ → ぼ
  0x3046: 0x3094, // う → ゔ
};

/// Base hiragana → semi-voiced (handakuten) hiragana. Used to compose は+◌゚ → ぱ.
const Map<int, int> _composeHandakuten = {
  0x306F: 0x3071, // は → ぱ
  0x3072: 0x3074, // ひ → ぴ
  0x3075: 0x3077, // ふ → ぷ
  0x3078: 0x307A, // へ → ぺ
  0x307B: 0x307D, // ほ → ぽ
};

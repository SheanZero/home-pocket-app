import '../../../features/accounting/domain/models/merchant_candidate.dart';
import '../../../features/accounting/domain/models/merchant_match_entry.dart';
import '../../../features/accounting/domain/repositories/merchant_repository.dart';
import '../../../infrastructure/ml/merchant_name_normalizer.dart';

/// Anchored normalized scorer over Phase-49's `merchant_match_keys` (DECOUP-03).
///
/// This is the ONLY genuinely new logic in Phase 50: a pure-Dart recall-first
/// ranker that replaces the retired bidirectional-substring lookup in
/// `merchant_database.dart` (`:158-159`). It returns ranked [MerchantCandidate]s
/// for a transcript fragment; the orchestrator (Plan 05) applies the D-03 0.85
/// auto-fill floor — the engine itself stays floor-agnostic and surfaces every
/// scored candidate (recall-first, D-01).
///
/// Construction independence (DECOUP-01): this engine takes ONLY a
/// [MerchantRepository]. It never imports or holds the keyword/category
/// recognizer — the two recognizers run independently and are merged only in
/// the orchestrator (Plan 05).
///
/// No-log discipline (V7): never `print`/log the raw query or candidate names.
/// The user utterance is sensitive; the seed list is public non-sensitive data.
class MerchantRecognizer {
  MerchantRecognizer({required MerchantRepository merchantRepository})
    : _merchantRepository = merchantRepository;

  final MerchantRepository _merchantRepository;

  /// Warm cache of every match-key surface (~391+ rows), loaded once via
  /// [MerchantRepository.loadAllForMatching] and never invalidated — the seed is
  /// immutable per app version (research A5, mirrors `_seedCache ??=`).
  List<MerchantMatchEntry>? _cache;

  // ── Anchored scoring tiers (RESEARCH Pattern 1) ──
  static const double _scoreExact = 1.00;
  static const double _scoreAnchoredPrefix = 0.85;
  static const double _scoreContainment = 0.60;
  static const double _scoreReverseContainment = 0.55;

  // ── Per-script min-length floors (Assumptions A1/A2) for the weak
  // containment tiers. Kanji-containing fragments carry more signal per rune,
  // so a 2-rune floor suffices; pure kana/latin needs >= 3 to avoid the
  // generic-substring false positives the bidirectional matcher produced. ──
  static const int _kanjiMinRunes = 2;
  static const int _kanaLatinMinRunes = 3;

  /// Recognize merchants in [query], returning candidates ranked recall-first
  /// (score DESC, then longer matchKey first), one per `merchantId`.
  ///
  /// Normalizes [query] with the SAME [normalizeMerchantKey] used at seed time
  /// (Pitfall 1) so the query key and the stored match keys live in one space.
  /// Returns an empty list for an empty/blank query (a blank key would otherwise
  /// prefix-match every row via `startsWith('')`).
  Future<List<MerchantCandidate>> recognize(String query) async {
    final nq = normalizeMerchantKey(query);
    if (nq.isEmpty) return const <MerchantCandidate>[];

    final entries = _cache ??= await _merchantRepository.loadAllForMatching();

    // Best-scoring surface per merchant. We keep the winning entry so ranking
    // can break score ties by matchKey length deterministically.
    final bestByMerchant = <String, _Scored>{};
    for (final entry in entries) {
      final score = _scoreOf(nq, entry.matchKey);
      if (score == null) continue;
      final existing = bestByMerchant[entry.merchantId];
      if (existing == null ||
          score > existing.score ||
          (score == existing.score &&
              entry.matchKey.length > existing.entry.matchKey.length)) {
        bestByMerchant[entry.merchantId] = _Scored(score, entry);
      }
    }

    final ranked = bestByMerchant.values.toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        // Longer matchKey wins ties (more specific surface — mirrors the
        // resolver's longest-key-wins ranking).
        return b.entry.matchKey.length.compareTo(a.entry.matchKey.length);
      });

    return ranked
        .map(
          (s) => MerchantCandidate(
            merchantId: s.entry.merchantId,
            displayName: s.entry.displayName,
            score: s.score,
            categoryId: s.entry.categoryId,
            ledgerHint: s.entry.ledgerHint,
          ),
        )
        .toList(growable: false);
  }

  /// Score a normalized query [nq] against a stored match key [mk], or null when
  /// no tier matches (so the caller skips the entry entirely).
  ///
  /// Tiers (anchored — there is no bidirectional `contains||contains`):
  ///   - exact          `nq == mk`                              → 1.00
  ///   - anchored prefix either is a prefix of the other, with
  ///                    min-length on the SHORTER string        → 0.85
  ///   - containment    `mk.contains(nq)`, min-length nq        → 0.60
  ///   - reverse        `nq.contains(mk)`, min-length mk        → 0.55
  ///
  /// Every NON-exact tier is gated by [_passesScriptMinLength] on the SHORTER
  /// (contained / prefixing) string — the source of false positives at scale.
  /// Crucially the prefix tier is guarded too: a bare single kanji like 「米」
  /// is a prefix of a long chain name (米屋本舗) but must NOT auto-fill (SC2).
  ///
  /// The prefix tier carries an ADDITIONAL coverage guard: the shorter (prefix)
  /// string must cover STRICTLY MORE than half the longer string's runes. A
  /// generic word or place name that prefixes a longer brand surface
  /// (「the」⊂「thebig」 3/6, 「大阪」⊂「大阪王将」 2/4, 「cafe」⊂「caferenoir」 4/10)
  /// is a weak signal and must NOT auto-fill (SC2); a substantial prefix
  /// (「まくどな」⊂「まくどなるど」 4/6) is a strong one. Only an EXACT key equality
  /// (an explicitly seeded short alias, e.g. スタバ) bypasses both guards.
  double? _scoreOf(String nq, String mk) {
    if (nq == mk) return _scoreExact;
    if (mk.startsWith(nq) || nq.startsWith(mk)) {
      // The shorter string is the prefix; guard IT on script-min-length AND on
      // coverage (>= half the longer string).
      final shorterRunes = nq.runes.length <= mk.runes.length
          ? nq.runes.length
          : mk.runes.length;
      final longerRunes = nq.runes.length >= mk.runes.length
          ? nq.runes.length
          : mk.runes.length;
      final shorter = nq.length <= mk.length ? nq : mk;
      if (!_passesScriptMinLength(shorter)) return null;
      if (shorterRunes * 2 <= longerRunes) return null; // must cover > 50%
      return _scoreAnchoredPrefix;
    }
    if (mk.contains(nq) && _passesScriptMinLength(nq)) return _scoreContainment;
    if (nq.contains(mk) && _passesScriptMinLength(mk)) {
      return _scoreReverseContainment;
    }
    return null;
  }

  /// True when [s] is long enough to be a trustworthy containment match:
  /// kanji-containing strings need >= [_kanjiMinRunes] runes, pure kana/latin
  /// need >= [_kanaLatinMinRunes] (A2). Length is counted in RUNES, not UTF-16
  /// code units, so surrogate-pair / combining cases count correctly.
  bool _passesScriptMinLength(String s) {
    final runeCount = s.runes.length;
    final min = _containsKanji(s) ? _kanjiMinRunes : _kanaLatinMinRunes;
    return runeCount >= min;
  }

  /// True if [s] contains at least one CJK unified ideograph (kanji). Covers the
  /// BMP block (U+4E00..U+9FFF) and Extension A (U+3400..U+4DBF), which together
  /// span the kanji used in merchant surfaces.
  bool _containsKanji(String s) {
    for (final r in s.runes) {
      if ((r >= 0x4E00 && r <= 0x9FFF) || (r >= 0x3400 && r <= 0x4DBF)) {
        return true;
      }
    }
    return false;
  }
}

/// A scored match entry — the winning surface for one merchant before ranking.
class _Scored {
  const _Scored(this.score, this.entry);
  final double score;
  final MerchantMatchEntry entry;
}

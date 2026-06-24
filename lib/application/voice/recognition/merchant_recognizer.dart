import '../../../features/voice/domain/models/merchant_candidate.dart';
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
  /// [MerchantRepository.loadAllForMatching] — the seed is immutable per app
  /// version (research A5, mirrors `_seedCache ??=`).
  ///
  /// WR-02: we cache the in-flight FUTURE (not the resolved value) so two
  /// concurrent first-calls share ONE load instead of both issuing the
  /// (transactional) DB read.
  ///
  /// WR-01: an EMPTY first load is NOT latched. If `recognize()` runs before
  /// merchant seeding has completed (e.g. a seed retried after an init failure),
  /// the cached future is cleared so a later call re-loads the now-populated
  /// table — an empty seed never poisons the whole app session.
  Future<List<MerchantMatchEntry>>? _cacheFuture;

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

    // WR-02: share one in-flight load across concurrent first-callers.
    final entries = await (_cacheFuture ??=
        _merchantRepository.loadAllForMatching());
    // WR-01: do not latch an empty seed — clear the cached future so a later
    // call re-loads once seeding has populated the table.
    if (entries.isEmpty) _cacheFuture = null;

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
  ///   - exact            `nq == mk`                            → 1.00
  ///   - alias-at-start   seeded alias [mk] is a prefix of the
  ///                      (stripped) utterance [nq], min-length mk → 0.85
  ///   - anchored prefix  query [nq] prefixes a longer brand [mk],
  ///                      min-length nq AND > 50% coverage       → 0.85
  ///   - containment      `mk.contains(nq)`, min-length nq       → 0.60
  ///   - reverse          `nq.contains(mk)`, min-length mk       → 0.55
  ///
  /// CR-01 / WR-03: the two prefix directions are NOT symmetric and must be
  /// scored separately (the pre-fix code collapsed both into one coverage-guarded
  /// branch that `return null`ed on failure, silently dropping the dominant
  /// "merchant-then-words" utterance):
  ///
  ///   • `nq.startsWith(mk)` — the seeded alias [mk] is a prefix of the longer
  ///     (amount/particle-stripped) utterance [nq], e.g. すたば ⊂ すたばこーひー
  ///     (「スタバでコーヒー」), まくど ⊂ まくどぽてと…. This is a STRONG signal: the
  ///     user spoke the merchant name first. It resolves at the anchored tier
  ///     gated ONLY by [_passesScriptMinLength] on the alias — NO coverage guard
  ///     (the trailing words shrink coverage but carry no counter-evidence). A
  ///     bare single-kanji / 2-kana alias is still rejected by the min-length
  ///     floor, so 「米…」 cannot prefix-fill a 米-chain (SC2).
  ///
  ///   • `mk.startsWith(nq)` — the query [nq] is a prefix of a longer BRAND
  ///     surface [mk], e.g. 大阪 ⊂ 大阪王将, the ⊂ thebig, cafe ⊂ caferenoir. A
  ///     short generic prefix of a long brand is a WEAK signal and keeps the
  ///     `> 50%` coverage guard so it does NOT auto-fill (SC2); a substantial
  ///     prefix (まくどな ⊂ まくどなるど 4/6) still clears it.
  ///
  /// A failed guard in EITHER prefix branch falls THROUGH to the containment
  /// tiers instead of returning null, so an embedded (non-prefix) match can
  /// still surface recall-first (IN-03).
  double? _scoreOf(String nq, String mk) {
    if (nq == mk) return _scoreExact;

    // Direction A — seeded alias [mk] anchored at the START of the utterance
    // [nq]. Min-length on the alias keeps generic short fragments out (SC2);
    // no coverage guard (the utterance is legitimately longer than the alias).
    if (nq.startsWith(mk) && _passesScriptMinLength(mk)) {
      return _scoreAnchoredPrefix;
    }

    // Direction B — query [nq] is a prefix of a longer BRAND [mk]. Keep the
    // min-length + > 50% coverage guard so a short generic word does not
    // auto-fill on a long brand surface (SC2).
    if (mk.startsWith(nq) && _passesScriptMinLength(nq)) {
      final nqRunes = nq.runes.length;
      final mkRunes = mk.runes.length;
      if (nqRunes * 2 > mkRunes) return _scoreAnchoredPrefix; // covers > 50%
      // else: weak prefix — fall through to containment instead of dropping.
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

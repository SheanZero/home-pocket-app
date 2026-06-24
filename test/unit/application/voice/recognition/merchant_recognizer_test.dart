import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/recognition/merchant_recognizer.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_candidate.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_match_entry.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_repository.dart';
import 'package:home_pocket/infrastructure/ml/merchant_name_normalizer.dart';
import 'package:mocktail/mocktail.dart';

// Phase 50 Plan 03 (DECOUP-03 / SC3): MerchantRecognizer is a pure-Dart anchored
// scorer over the seed-normalized merchant_match_keys. These tests pin the four
// scoring tiers (exact 1.00 / anchored-prefix 0.85 / containment 0.60 / reverse
// 0.55), the per-script min-length guard, ranking + per-merchantId dedupe, the
// four real surface forms at >= 0.85, and the normalize-equality invariant
// (query is normalized with the SAME normalizeMerchantKey used at seed time —
// Pitfall 1). The recognizer takes ONLY a MerchantRepository: it is
// constructionally independent of CategoryRecognizer (DECOUP-01).

class _MockMerchantRepository extends Mock implements MerchantRepository {}

/// Build a [MerchantMatchEntry] whose [matchKey] is derived from [surface] with
/// the production normalizer — exactly as the Phase-49 seed does. This makes the
/// fixture a faithful stand-in for the real `merchant_match_keys` rows.
MerchantMatchEntry _entry(
  String surface, {
  required String merchantId,
  required String displayName,
  required String categoryId,
  String ledgerHint = 'daily',
}) {
  return MerchantMatchEntry(
    matchKey: normalizeMerchantKey(surface),
    surface: surface,
    merchantId: merchantId,
    displayName: displayName,
    categoryId: categoryId,
    ledgerHint: ledgerHint,
  );
}

/// A small fixed match-entry set mirroring the real seed surfaces the four SC3
/// utterances must resolve against, plus a 米-bearing chain and a generic-word
/// collider used to exercise the containment + min-length tiers.
List<MerchantMatchEntry> _fixtureEntries() => <MerchantMatchEntry>[
  // Starbucks — name + the bare-スタバ alias + romaji + zh locale.
  _entry(
    'スターバックス',
    merchantId: 'mer_starbucks',
    displayName: 'スターバックス',
    categoryId: 'cat_food_cafe',
  ),
  _entry(
    'スタバ',
    merchantId: 'mer_starbucks',
    displayName: 'スターバックス',
    categoryId: 'cat_food_cafe',
  ),
  _entry(
    'Starbucks',
    merchantId: 'mer_starbucks',
    displayName: 'スターバックス',
    categoryId: 'cat_food_cafe',
  ),
  _entry(
    '星巴克',
    merchantId: 'mer_starbucks',
    displayName: 'スターバックス',
    categoryId: 'cat_food_cafe',
  ),
  // McDonald's — name + Kansai マクド alias + マック alias.
  _entry(
    'マクドナルド',
    merchantId: 'mer_mcdonalds',
    displayName: 'マクドナルド',
    categoryId: 'cat_food_dining_out',
  ),
  _entry(
    'マクド',
    merchantId: 'mer_mcdonalds',
    displayName: 'マクドナルド',
    categoryId: 'cat_food_dining_out',
  ),
  _entry(
    'マック',
    merchantId: 'mer_mcdonalds',
    displayName: 'マクドナルド',
    categoryId: 'cat_food_dining_out',
  ),
  // MOS Burger — only the full name + short モス alias seeded; lets us test the
  // anchored-prefix tier (モス ⊂ モスバーガー) AND that bare 2-char generic
  // queries do not over-fill.
  _entry(
    'モスバーガー',
    merchantId: 'mer_mos_burger',
    displayName: 'モスバーガー',
    categoryId: 'cat_food_dining_out',
  ),
  // A 米-bearing chain whose ONLY surface is a longer name; bare お米/米 must
  // stay below floor via the containment min-length guard.
  _entry(
    '米屋本舗',
    merchantId: 'mer_komeya',
    displayName: '米屋本舗',
    categoryId: 'cat_food_groceries',
  ),
];

MerchantRecognizer _recognizer(List<MerchantMatchEntry> entries) {
  final repo = _MockMerchantRepository();
  when(repo.loadAllForMatching).thenAnswer((_) async => entries);
  return MerchantRecognizer(merchantRepository: repo);
}

double? _bestScoreFor(List<MerchantCandidate> cands, String merchantId) {
  for (final c in cands) {
    if (c.merchantId == merchantId) return c.score;
  }
  return null;
}

void main() {
  group('normalize-equality invariant (Pitfall 1)', () {
    test('normalizeMerchantKey(スタバ) equals the seeded スタバ matchKey', () {
      // The recognizer MUST reuse this same function on the query side; if it
      // declared its own normalizer the keys would silently diverge.
      final seededKey = normalizeMerchantKey('スタバ');
      expect(seededKey, 'すたば');
      final entry = _entry(
        'スタバ',
        merchantId: 'mer_starbucks',
        displayName: 'スターバックス',
        categoryId: 'cat_food_cafe',
      );
      expect(entry.matchKey, seededKey);
    });
  });

  group('scoring tiers', () {
    test('exact normalized match scores 1.00', () async {
      final r = _recognizer(_fixtureEntries());
      final cands = await r.recognize('スタバ');
      expect(_bestScoreFor(cands, 'mer_starbucks'), 1.00);
    });

    test('anchored prefix (まくどな ⊂ マクドナルド) scores 0.85', () async {
      // まくどな (4 kana, passes the >= 3 kana guard) is a genuine prefix of
      // まくどなるど but NOT an exact key — so it lands in the anchored-prefix
      // tier, not the exact tier. There is no seeded まくどな alias.
      final r = _recognizer(_fixtureEntries());
      final cands = await r.recognize('まくどな');
      expect(_bestScoreFor(cands, 'mer_mcdonalds'), 0.85);
    });

    test('short kana prefix below the guard does NOT prefix-fill', () async {
      // モス -> もす is only 2 kana; it is a prefix of もすばーがー but must be
      // guarded OUT (< 3 kana) so generic 2-char fragments never auto-fill.
      final r = _recognizer(_fixtureEntries());
      final cands = await r.recognize('モス');
      final score = _bestScoreFor(cands, 'mer_mos_burger');
      expect(score == null || score < 0.85, isTrue);
    });

    test(
      'containment with sufficient script length scores in the weak band',
      () async {
        // A query that is a substring of a longer matchKey but is NOT a prefix
        // — exercises the 0.60 containment tier. ばー is inside もすばーがー but
        // is only 2 kana runes, so it must be guarded OUT (< 3 kana). Use a
        // 3-rune kana substring instead: すばー is not present, so build a
        // dedicated entry.
        final entries = <MerchantMatchEntry>[
          _entry(
            'あいすばーがー',
            merchantId: 'mer_test_contain',
            displayName: 'アイスバーガー',
            categoryId: 'cat_food_dining_out',
          ),
        ];
        final r = _recognizer(entries);
        // すばーが is a 4-rune kana substring in the middle (not a prefix).
        final cands = await r.recognize('すばーが');
        final score = _bestScoreFor(cands, 'mer_test_contain');
        expect(score, isNotNull);
        expect(score! < 0.85, isTrue);
        expect(score >= 0.55, isTrue);
      },
    );

    test(
      'below script-min-length on containment yields no candidate',
      () async {
        // お米 normalizes to お米 (2 runes, kanji-containing → min 2, OK as kanji)
        // — but 'パ' style 1-rune kana must be guarded out. Use a 2-rune kana
        // fragment 'ばー' which is inside もすばーがー but below the 3-kana floor.
        final entries = <MerchantMatchEntry>[
          _entry(
            'もすばーがー',
            merchantId: 'mer_mos2',
            displayName: 'モスバーガー',
            categoryId: 'cat_food_dining_out',
          ),
        ];
        final r = _recognizer(entries);
        final cands = await r.recognize('ばー'); // 2 kana runes, contained
        expect(cands.where((c) => c.merchantId == 'mer_mos2'), isEmpty);
      },
    );
  });

  group('four real surface forms resolve at >= 0.85 (SC3)', () {
    test('bare スタバ resolves to Starbucks', () async {
      final r = _recognizer(_fixtureEntries());
      final cands = await r.recognize('スタバ');
      final score = _bestScoreFor(cands, 'mer_starbucks');
      expect(score, isNotNull);
      expect(score! >= 0.85, isTrue);
    });

    test('half-width ｽﾀﾊﾞ resolves to Starbucks', () async {
      final r = _recognizer(_fixtureEntries());
      final cands = await r.recognize('ｽﾀﾊﾞ');
      final score = _bestScoreFor(cands, 'mer_starbucks');
      expect(score, isNotNull);
      expect(score! >= 0.85, isTrue);
    });

    test('Kansai マクド resolves to McDonald\'s', () async {
      final r = _recognizer(_fixtureEntries());
      final cands = await r.recognize('マクド');
      final score = _bestScoreFor(cands, 'mer_mcdonalds');
      expect(score, isNotNull);
      expect(score! >= 0.85, isTrue);
    });

    test('romaji Starbucks resolves to Starbucks', () async {
      final r = _recognizer(_fixtureEntries());
      final cands = await r.recognize('Starbucks');
      final score = _bestScoreFor(cands, 'mer_starbucks');
      expect(score, isNotNull);
      expect(score! >= 0.85, isTrue);
    });
  });

  group('ranking and dedupe', () {
    test('one candidate per merchantId (keep best-scoring surface)', () async {
      final r = _recognizer(_fixtureEntries());
      final cands = await r.recognize('スタバ');
      final ids = cands.map((c) => c.merchantId).toList();
      expect(ids.toSet().length, ids.length, reason: 'no duplicate merchantId');
    });

    test('candidates are ranked score-DESC', () async {
      final r = _recognizer(_fixtureEntries());
      final cands = await r.recognize('スタバ');
      for (var i = 1; i < cands.length; i++) {
        expect(cands[i - 1].score >= cands[i].score, isTrue);
      }
      // The exact Starbucks hit must be the top candidate.
      expect(cands.first.merchantId, 'mer_starbucks');
    });

    test('candidate carries the parent categoryId + ledgerHint', () async {
      final r = _recognizer(_fixtureEntries());
      final cands = await r.recognize('スタバ');
      final star = cands.firstWhere((c) => c.merchantId == 'mer_starbucks');
      expect(star.categoryId, 'cat_food_cafe');
      expect(star.ledgerHint, 'daily');
      expect(star.displayName, 'スターバックス');
    });
  });

  group('empty / no-match', () {
    test('empty query yields no candidates', () async {
      final r = _recognizer(_fixtureEntries());
      expect(await r.recognize(''), isEmpty);
    });

    test('whitespace-only query yields no candidates', () async {
      final r = _recognizer(_fixtureEntries());
      expect(await r.recognize('   '), isEmpty);
    });

    test('お米 / 米 do not auto-fill the 米屋 chain at the floor', () async {
      final r = _recognizer(_fixtureEntries());
      for (final q in ['お米', '米']) {
        final cands = await r.recognize(q);
        final best = cands.isEmpty ? null : cands.first.score;
        expect(
          best == null || best < 0.85,
          isTrue,
          reason: '"$q" must not auto-fill at the floor',
        );
      }
    });
  });

  group('cache hardening (WR-01 / WR-02)', () {
    test(
      'WR-01: an empty first load does NOT poison a later non-empty load',
      () async {
        final repo = _MockMerchantRepository();
        var call = 0;
        when(repo.loadAllForMatching).thenAnswer((_) async {
          call++;
          // First load returns empty (seeding not yet done); later loads are
          // populated. The empty result must NOT latch.
          return call == 1
              ? const <MerchantMatchEntry>[]
              : _fixtureEntries();
        });
        final r = MerchantRecognizer(merchantRepository: repo);

        // First call hits the empty seed → no candidate.
        expect(await r.recognize('スタバ'), isEmpty);
        // Second call must re-load (cache not poisoned) and resolve.
        final cands = await r.recognize('スタバ');
        expect(_bestScoreFor(cands, 'mer_starbucks'), 1.00);
        expect(call, greaterThanOrEqualTo(2), reason: 'empty load re-tried');
      },
    );

    test('WR-01: a non-empty load IS cached (loaded once)', () async {
      final repo = _MockMerchantRepository();
      var call = 0;
      when(repo.loadAllForMatching).thenAnswer((_) async {
        call++;
        return _fixtureEntries();
      });
      final r = MerchantRecognizer(merchantRepository: repo);

      await r.recognize('スタバ');
      await r.recognize('マクド');
      await r.recognize('Starbucks');
      expect(call, 1, reason: 'a populated seed is loaded exactly once');
    });

    test(
      'WR-02: concurrent first-calls share ONE in-flight load',
      () async {
        final repo = _MockMerchantRepository();
        var call = 0;
        when(repo.loadAllForMatching).thenAnswer((_) async {
          call++;
          // Yield so both racing callers observe the null cache before either
          // assigns — without the shared-future guard this double-loads.
          await Future<void>.delayed(Duration.zero);
          return _fixtureEntries();
        });
        final r = MerchantRecognizer(merchantRepository: repo);

        await Future.wait([r.recognize('スタバ'), r.recognize('マクド')]);
        expect(call, 1, reason: 'concurrent first-calls share one load (WR-02)');
      },
    );
  });
}

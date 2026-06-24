import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/recognition/merchant_recognizer.dart';
import 'package:home_pocket/features/voice/domain/models/merchant_candidate.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_match_entry.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_repository.dart';
import 'package:home_pocket/infrastructure/ml/merchant_name_normalizer.dart';
import 'package:mocktail/mocktail.dart';

// Phase 50 CR-01 regression (covers IN-03 / IN-04): the REAL MerchantRecognizer
// must resolve the merchant for the DOMINANT "merchant-then-words" utterance
// shape (「スタバでコーヒー」「マクドで昼」「スタバで500円」) at the >= 0.85 auto-fill
// floor (SC3), not silently drop it.
//
// Before the fix, an alias spoken at the START of a longer utterance entered
// the prefix branch and was rejected by the >50% coverage guard, returning NO
// candidate. This test drives the real scorer over a faithful seed fixture with
// the SAME particle/amount-stripped surface the orchestrator now feeds the
// recognizer (WR-03) — so this class of false-negative cannot ship green again.

class _MockMerchantRepository extends Mock implements MerchantRepository {}

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

List<MerchantMatchEntry> _fixtureEntries() => <MerchantMatchEntry>[
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
  group('CR-01: compound merchant-then-words utterances auto-fill (SC3)', () {
    // The orchestrator strips amount / particles before calling recognize(),
    // so the recognizer sees the fused surface (で removed). These are the
    // exact post-strip surfaces for the headline utterances.
    const cases = <String, String>{
      // raw utterance (after orchestrator strip) -> merchant that must resolve
      'スタバコーヒー': 'mer_starbucks', // 「スタバでコーヒー」 - で stripped
      'スタバ': 'mer_starbucks', // 「スタバで500円」 - amount+で stripped
      'スタバ行った': 'mer_starbucks', // 「スタバに行った」 - に stripped
      'マクドポテト食べた': 'mer_mcdonalds', // 「マクドでポテト食べた」
      'マクド昼': 'mer_mcdonalds', // 「マクドで昼」
    };

    cases.forEach((stripped, merchantId) {
      test('"$stripped" resolves $merchantId at >= 0.85', () async {
        final r = _recognizer(_fixtureEntries());
        final cands = await r.recognize(stripped);
        final score = _bestScoreFor(cands, merchantId);
        expect(
          score,
          isNotNull,
          reason: '"$stripped" must surface $merchantId (CR-01)',
        );
        expect(
          score! >= 0.85,
          isTrue,
          reason: '"$stripped" must auto-fill $merchantId (SC3); got $score',
        );
      });
    });

    test('the bare alias still resolves exactly (no regression)', () async {
      final r = _recognizer(_fixtureEntries());
      expect(_bestScoreFor(await r.recognize('スタバ'), 'mer_starbucks'), 1.00);
      expect(_bestScoreFor(await r.recognize('マクド'), 'mer_mcdonalds'), 1.00);
    });
  });
}

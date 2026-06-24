import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/voice/domain/models/merchant_candidate.dart';
import 'package:home_pocket/features/voice/domain/models/recognition_outcome.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/voice/domain/services/recognition_reconciler.dart';

// Phase 51 Plan 02 (XVAL-01 / XVAL-02) — the LOAD-BEARING 3×3 truth-table spec
// for the pure RecognitionReconciler. Written FIRST (research flag): each of the
// 9 keyword×merchant cells is a named test, plus the 4 carried boundary cases.
//
// Per-engine banding (RESEARCH §XVAL-01):
//   keyword: source==learning -> strong | source==keyword -> weak | null -> none
//   merchant: best score >=0.85 -> strong | [0.55,0.85) -> weak | empty -> none
//
// Selection rule: keyword always wins when present (keyword-priority). band =
// strong if keyword is learning, else medium; D-06 boosts to strong when a
// strong-keyword/strong-merchant pair agree on the EXACT L2 id. keyword=none
// falls back to merchant (auto-fill >=floor band=medium; below-floor best-guess
// band=weak; both-none -> null/weak).

/// Strong (user-validated learning) keyword verdict on [categoryId].
CategoryMatchResult _strongKw(String categoryId) => CategoryMatchResult(
  categoryId: categoryId,
  confidence: 0.90,
  source: MatchSource.learning,
);

/// Weak (seed) keyword verdict on [categoryId].
CategoryMatchResult _weakKw(String categoryId) => CategoryMatchResult(
  categoryId: categoryId,
  confidence: 0.85,
  source: MatchSource.keyword,
);

/// Merchant candidate at a given score on [categoryId].
MerchantCandidate _merchant(
  String categoryId, {
  required double score,
  String merchantId = 'mer_x',
  String displayName = 'Merchant X',
  String ledgerHint = 'daily',
}) => MerchantCandidate(
  merchantId: merchantId,
  displayName: displayName,
  score: score,
  categoryId: categoryId,
  ledgerHint: ledgerHint,
);

void main() {
  const reconciler = RecognitionReconciler();

  // L2 id literals (reconciler compares ids as plain strings; no normalizeToL2).
  const kShopping = 'cat_shopping_general';
  const kCafe = 'cat_food_cafe';
  const kFuel = 'cat_car_fuel';

  group('3×3 truth table — keyword=strong (learning)', () {
    test('strong × merchant=none -> KW.l2, band=strong, alts=[]', () {
      final outcome = reconciler.reconcile(_strongKw(kShopping), const []);

      expect(outcome.selectedCategoryId, kShopping);
      expect(outcome.band, ConfidenceBand.strong);
      expect(outcome.alternates, isEmpty);
      expect(outcome.keywordMerchantConflict, isFalse);
    });

    test('strong × merchant=weak -> KW.l2, band=strong, alts=[merchant.l2]', () {
      final outcome = reconciler.reconcile(
        _strongKw(kShopping),
        [_merchant(kCafe, score: 0.60)],
      );

      expect(outcome.selectedCategoryId, kShopping);
      expect(outcome.band, ConfidenceBand.strong);
      expect(outcome.alternates.map((a) => a.categoryId), [kCafe]);
      // Merchant is weak (below floor) -> not a "strong merchant override",
      // so no conflict flag.
      expect(outcome.keywordMerchantConflict, isFalse);
    });

    test(
      'strong × merchant=strong (differ) -> KW wins, merchant->alt, '
      'conflict=true, band=strong',
      () {
        final outcome = reconciler.reconcile(
          _strongKw(kShopping),
          [_merchant(kCafe, score: 1.0)],
        );

        expect(outcome.selectedCategoryId, kShopping);
        expect(outcome.band, ConfidenceBand.strong);
        expect(outcome.alternates.map((a) => a.categoryId), [kCafe]);
        expect(outcome.keywordMerchantConflict, isTrue);
      },
    );
  });

  group('3×3 truth table — keyword=weak (seed)', () {
    test('weak × merchant=none -> KW.l2, band=medium, alts=[]', () {
      final outcome = reconciler.reconcile(_weakKw(kShopping), const []);

      expect(outcome.selectedCategoryId, kShopping);
      expect(outcome.band, ConfidenceBand.medium);
      expect(outcome.alternates, isEmpty);
      expect(outcome.keywordMerchantConflict, isFalse);
    });

    test(
      'weak × merchant=weak -> KW wins (not vetoed), band=medium, '
      'alts=[merchant.l2]',
      () {
        final outcome = reconciler.reconcile(
          _weakKw(kShopping),
          [_merchant(kCafe, score: 0.60)],
        );

        expect(outcome.selectedCategoryId, kShopping);
        expect(outcome.band, ConfidenceBand.medium);
        expect(outcome.alternates.map((a) => a.categoryId), [kCafe]);
        expect(outcome.keywordMerchantConflict, isFalse);
      },
    );

    test(
      'weak × merchant=strong (differ) -> KW wins, band=medium, '
      'conflict=true, alts=[merchant.l2]',
      () {
        final outcome = reconciler.reconcile(
          _weakKw(kShopping),
          [_merchant(kCafe, score: 0.90)],
        );

        expect(outcome.selectedCategoryId, kShopping);
        expect(outcome.band, ConfidenceBand.medium);
        expect(outcome.alternates.map((a) => a.categoryId), [kCafe]);
        expect(outcome.keywordMerchantConflict, isTrue);
      },
    );
  });

  group('3×3 truth table — keyword=none', () {
    test('none × merchant=none -> selected=null, band=weak, alts=[]', () {
      final outcome = reconciler.reconcile(null, const []);

      expect(outcome.selectedCategoryId, isNull);
      expect(outcome.band, ConfidenceBand.weak);
      expect(outcome.alternates, isEmpty);
      expect(outcome.keywordMerchantConflict, isFalse);
    });

    test(
      'none × merchant=weak -> best-guess selected=merchant.l2, band=weak '
      '(D-05), alts=ranked merchants',
      () {
        final outcome = reconciler.reconcile(null, [
          _merchant(kCafe, score: 0.60, merchantId: 'mer_a'),
          _merchant(kShopping, score: 0.55, merchantId: 'mer_b'),
        ]);

        expect(outcome.selectedCategoryId, kCafe);
        expect(outcome.band, ConfidenceBand.weak);
        expect(outcome.alternates.map((a) => a.categoryId), [kCafe, kShopping]);
        expect(outcome.keywordMerchantConflict, isFalse);
      },
    );

    test(
      'none × merchant=strong -> auto-fill selected=merchant.l2, band=medium, '
      'alts=other merchants',
      () {
        final outcome = reconciler.reconcile(null, [
          _merchant(kCafe, score: 1.0, merchantId: 'mer_a'),
          _merchant(kShopping, score: 0.60, merchantId: 'mer_b'),
        ]);

        expect(outcome.selectedCategoryId, kCafe);
        expect(outcome.band, ConfidenceBand.medium);
        expect(outcome.alternates.map((a) => a.categoryId), [kCafe, kShopping]);
        expect(outcome.keywordMerchantConflict, isFalse);
      },
    );
  });

  group('D-06 exact-L2-agreement boost', () {
    test('strong-kw + strong-merchant SAME L2 -> band=strong (boosted), '
        'no conflict', () {
      // Same L2 id on both engines; merchant >= 0.85.
      final outcome = reconciler.reconcile(
        _strongKw(kCafe),
        [_merchant(kCafe, score: 0.90)],
      );

      expect(outcome.selectedCategoryId, kCafe);
      expect(outcome.band, ConfidenceBand.strong);
      // Agreement -> not a conflict; merchant collapses into the same id, so no
      // distinct alternate.
      expect(outcome.keywordMerchantConflict, isFalse);
      expect(outcome.alternates, isEmpty);
    });

    test('weak-kw + strong-merchant SAME L2 -> band=strong (boosted), '
        'no conflict', () {
      final outcome = reconciler.reconcile(
        _weakKw(kCafe),
        [_merchant(kCafe, score: 0.90)],
      );

      expect(outcome.selectedCategoryId, kCafe);
      // Weak keyword agreeing with a strong merchant on the EXACT L2 -> boost.
      expect(outcome.band, ConfidenceBand.strong);
      expect(outcome.keywordMerchantConflict, isFalse);
      expect(outcome.alternates, isEmpty);
    });

    test('counter-case: strong-merchant DIFFERENT L2 -> NO boost', () {
      // weak keyword, strong merchant, but DIFFERENT L2 -> stays at keyword's
      // own band (medium), not boosted to strong.
      final outcome = reconciler.reconcile(
        _weakKw(kShopping),
        [_merchant(kCafe, score: 0.90)],
      );

      expect(outcome.selectedCategoryId, kShopping);
      expect(outcome.band, ConfidenceBand.medium);
    });

    test('counter-case: agreeing merchant BELOW floor -> NO boost', () {
      // Same L2 but merchant < 0.85 -> not a strong merchant -> weak keyword
      // stays medium (the boost requires score >= 0.85).
      final outcome = reconciler.reconcile(
        _weakKw(kCafe),
        [_merchant(kCafe, score: 0.60)],
      );

      expect(outcome.selectedCategoryId, kCafe);
      expect(outcome.band, ConfidenceBand.medium);
    });
  });

  group('deterministic tie-break + alternates', () {
    test('keyword always wins ties vs merchant', () {
      // Equal-ish signals: keyword wins regardless of merchant strength.
      final outcome = reconciler.reconcile(
        _strongKw(kShopping),
        [_merchant(kCafe, score: 1.0)],
      );
      expect(outcome.selectedCategoryId, kShopping);
    });

    test('merchant candidates consumed in pre-sorted order', () {
      // keyword=none -> best (first, pre-sorted) merchant is selected.
      final outcome = reconciler.reconcile(null, [
        _merchant(kCafe, score: 1.0, merchantId: 'mer_a'),
        _merchant(kShopping, score: 0.90, merchantId: 'mer_b'),
        _merchant(kFuel, score: 0.86, merchantId: 'mer_c'),
      ]);
      expect(outcome.selectedCategoryId, kCafe);
      expect(outcome.alternates.map((a) => a.categoryId), [
        kCafe,
        kShopping,
        kFuel,
      ]);
    });

    test('alternates de-duplicated by L2 id', () {
      // Two merchants on the SAME L2 -> appears once in alternates.
      final outcome = reconciler.reconcile(_strongKw(kShopping), [
        _merchant(kCafe, score: 0.90, merchantId: 'mer_a'),
        _merchant(kCafe, score: 0.60, merchantId: 'mer_b'),
      ]);
      expect(outcome.selectedCategoryId, kShopping);
      expect(
        outcome.alternates.where((a) => a.categoryId == kCafe).length,
        1,
      );
    });
  });

  group('resolvedKeyword threading (D-13 learning-key identity)', () {
    test('resolvedKeyword threads through verbatim', () {
      final outcome = reconciler.reconcile(
        _strongKw(kShopping),
        const [],
        resolvedKeyword: '杯子',
      );
      expect(outcome.resolvedKeyword, '杯子');
    });

    test('resolvedKeyword null when not provided', () {
      final outcome = reconciler.reconcile(_strongKw(kShopping), const []);
      expect(outcome.resolvedKeyword, isNull);
    });
  });

  group('4 carried boundary cases (verbatim utterance intent)', () {
    test('「在星巴克买杯子」-> 购物 (KW wins, スタバ cafe demoted to alt, '
        'conflict=true)', () {
      // keyword 买/杯子 -> shopping; merchant スタバ -> cafe at >=0.85.
      final outcome = reconciler.reconcile(
        _strongKw(kShopping),
        [_merchant(kCafe, score: 1.0, displayName: 'スターバックス')],
        resolvedKeyword: '买杯子',
      );

      expect(outcome.selectedCategoryId, kShopping);
      expect(outcome.alternates.map((a) => a.categoryId), [kCafe]);
      expect(outcome.keywordMerchantConflict, isTrue);
      expect(outcome.band, ConfidenceBand.strong);
    });

    test('bare 「スタバ」-> 咖啡 (keyword null, merchant auto-fill, band=medium)',
        () {
      final outcome = reconciler.reconcile(
        null,
        [_merchant(kCafe, score: 1.0, displayName: 'スターバックス')],
      );

      expect(outcome.selectedCategoryId, kCafe);
      expect(outcome.band, ConfidenceBand.medium);
      expect(outcome.keywordMerchantConflict, isFalse);
    });

    test('「加油用了400块」-> 燃料 (category-only, merchant=none)', () {
      final outcome = reconciler.reconcile(
        _weakKw(kFuel),
        const [],
        resolvedKeyword: '加油',
      );

      expect(outcome.selectedCategoryId, kFuel);
      expect(outcome.band, ConfidenceBand.medium);
      expect(outcome.alternates, isEmpty);
    });

    test('both-weak -> best-guess filled + band=weak (D-05)', () {
      // keyword none + below-floor merchant -> best-guess fill, weak band.
      final outcome = reconciler.reconcile(
        null,
        [_merchant(kCafe, score: 0.60)],
      );

      expect(outcome.selectedCategoryId, kCafe);
      expect(outcome.band, ConfidenceBand.weak);
    });
  });
}

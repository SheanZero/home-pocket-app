import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/recognition/category_recognizer.dart';
import 'package:home_pocket/application/voice/recognition/merchant_recognizer.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_candidate.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_match_entry.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_repository.dart';
import 'package:home_pocket/infrastructure/ml/merchant_name_normalizer.dart';
import 'package:mocktail/mocktail.dart';

// Phase 50 (DECOUP-01/02/03) — ParseVoiceInputUseCase runs two INDEPENDENT
// engines and applies one thin keyword-priority merge with the 0.85 auto-fill
// floor (D-02 / D-03). This is the PHASE ACCEPTANCE GATE: the four-quadrant
// regression (merchant × keyword), the ledger invariant (ledger == a pure
// function of the final category, LEDGER-01), and the learning-key identity
// (resolvedKeyword == the canonical key the recognizer read, 260526-pg6).
//
// Both engines are mocked so each quadrant is exercised in isolation — the
// real engines have their own unit + corpus coverage (category_recognizer_test,
// merchant_recognizer_test, voice_category_corpus_{zh,ja,en}_test).

class _MockCategoryRecognizer extends Mock implements CategoryRecognizer {}

class _MockMerchantRecognizer extends Mock implements MerchantRecognizer {}

class _MockVoiceTextParser extends Mock implements VoiceTextParser {}

class _MockMerchantRepository extends Mock implements MerchantRepository {}

/// Faithful match entry for the de-mocked (IN-04) end-to-end quadrant: matchKey
/// derived with the production normalizer, exactly as the Phase-49 seed does.
MerchantMatchEntry _matchEntry(
  String surface, {
  required String merchantId,
  required String displayName,
  required String categoryId,
}) {
  return MerchantMatchEntry(
    matchKey: normalizeMerchantKey(surface),
    surface: surface,
    merchantId: merchantId,
    displayName: displayName,
    categoryId: categoryId,
    ledgerHint: 'daily',
  );
}

/// Builds a merchant candidate at a given score (default at/above floor).
MerchantCandidate _candidate({
  String merchantId = 'm_starbucks',
  String displayName = 'スターバックス',
  double score = 0.95,
  String categoryId = 'cat_food_cafe',
  String ledgerHint = 'soul', // deliberately NON-daily to prove ledger never
  // derives from the hint (LEDGER-01).
}) {
  return MerchantCandidate(
    merchantId: merchantId,
    displayName: displayName,
    score: score,
    categoryId: categoryId,
    ledgerHint: ledgerHint,
  );
}

void main() {
  late _MockCategoryRecognizer mockCategory;
  late _MockMerchantRecognizer mockMerchant;
  late VoiceTextParser parser;
  late ParseVoiceInputUseCase useCase;

  setUp(() {
    mockCategory = _MockCategoryRecognizer();
    mockMerchant = _MockMerchantRecognizer();
    parser = VoiceTextParser();
    useCase = ParseVoiceInputUseCase(
      textParser: parser,
      categoryRecognizer: mockCategory,
      merchantRecognizer: mockMerchant,
    );

    // Sensible defaults — each test overrides only what it exercises.
    when(
      () => mockCategory.resolve(any()),
    ).thenAnswer((_) async => null);
    when(
      () => mockMerchant.recognize(any()),
    ).thenAnswer((_) async => const <MerchantCandidate>[]);
    when(
      () => mockCategory.resolveLedgerType(any()),
    ).thenAnswer((_) async => LedgerType.daily);
    when(
      () => mockCategory.normalizeToL2(any()),
    ).thenAnswer((inv) async => inv.positionalArguments.first as String);
  });

  // ─── Pre-merge plumbing: both fields still flow (amount/raw/currency) ───
  group('ParseVoiceInputUseCase — basic extraction still flows', () {
    test('parses amount correctly from text with 円', () async {
      when(() => mockCategory.resolve(any())).thenAnswer(
        (_) async => const CategoryMatchResult(
          categoryId: 'cat_food_dining_out',
          confidence: 0.9,
          source: MatchSource.keyword,
        ),
      );

      final result = await useCase.execute('昼ごはんに680円', localeId: 'ja-JP');

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.data!.amount, equals(680));
      expect(result.data!.rawText, equals('昼ごはんに680円'));
    });

    test(
      'returns success with nulls when no engine produces a match',
      () async {
        final result = await useCase.execute('test');

        expect(result.isSuccess, isTrue);
        expect(result.data!.amount, isNull);
        expect(result.data!.merchantName, isNull);
        expect(result.data!.categoryMatch, isNull);
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════
  // FOUR-QUADRANT REGRESSION (merchant × keyword) — phase acceptance gate.
  // ════════════════════════════════════════════════════════════════════════
  group('Four-quadrant merge (D-02 keyword-priority + D-03 0.85 floor)', () {
    // ── Quadrant 1: merchant✓ keyword✓ → KEYWORD WINS (XVAL-02) ──
    // 「在星巴克买杯子」: Starbucks matches (merchant✓) AND 买杯子→购物 (keyword✓).
    // The category MUST be the keyword's 购物 (shopping), NOT the merchant's
    // 咖啡 default. resolveLedgerType is consulted on the keyword's categoryId.
    test(
      'merchant✓keyword✓ "在星巴克买杯子" → 购物 (keyword wins, NOT 咖啡)',
      () async {
        when(() => mockCategory.resolve(any())).thenAnswer(
          (_) async => const CategoryMatchResult(
            categoryId: 'cat_shopping_daily',
            confidence: 0.9,
            source: MatchSource.keyword,
          ),
        );
        when(() => mockMerchant.recognize(any())).thenAnswer(
          (_) async => [_candidate(displayName: '星巴克')],
        );
        // The 购物 category resolves to the daily ledger.
        when(
          () => mockCategory.resolveLedgerType('cat_shopping_daily'),
        ).thenAnswer((_) async => LedgerType.daily);

        final result = await useCase.execute('在星巴克买杯子', localeId: 'zh-CN');

        expect(result.isSuccess, isTrue, reason: result.error);
        final data = result.data!;
        // Keyword wins — category is 购物, source keyword, NOT merchant 咖啡.
        expect(data.categoryMatch!.categoryId, equals('cat_shopping_daily'));
        expect(data.categoryMatch!.source, equals(MatchSource.keyword));
        expect(
          data.categoryMatch!.categoryId,
          isNot('cat_food_cafe'),
          reason: 'keyword 购物 must win over the merchant 咖啡 default',
        );
        // Merchant primitives still surface (best candidate for form pre-fill).
        expect(data.merchantName, equals('星巴克'));
        expect(data.merchantCandidates, isNotEmpty);
        // normalizeToL2 is NOT consulted on the keyword branch.
        verifyNever(() => mockCategory.normalizeToL2(any()));
      },
    );

    // ── Quadrant 2: merchant✓ keyword✗ → MERCHANT AUTO-FILL at >= 0.85 ──
    // bare 「スタバ」: no keyword, Starbucks candidate at 0.95 (>= floor) →
    // auto-fill 咖啡 via normalizeToL2. (SC3)
    test(
      'merchant✓keyword✗ bare スタバ → 咖啡 via the >= 0.85 auto-fill floor',
      () async {
        when(() => mockCategory.resolve(any())).thenAnswer((_) async => null);
        when(() => mockMerchant.recognize(any())).thenAnswer(
          (_) async => [_candidate(score: 0.95, categoryId: 'cat_food_cafe')],
        );
        when(
          () => mockCategory.normalizeToL2('cat_food_cafe'),
        ).thenAnswer((_) async => 'cat_food_cafe');
        when(
          () => mockCategory.resolveLedgerType('cat_food_cafe'),
        ).thenAnswer((_) async => LedgerType.daily);

        final result = await useCase.execute('スタバ', localeId: 'ja-JP');

        expect(result.isSuccess, isTrue, reason: result.error);
        final data = result.data!;
        expect(data.categoryMatch, isNotNull);
        expect(data.categoryMatch!.categoryId, equals('cat_food_cafe'));
        expect(data.categoryMatch!.source, equals(MatchSource.merchant));
        // Auto-fill confidence is the candidate's raw score.
        expect(data.categoryMatch!.confidence, equals(0.95));
      },
    );

    // Surface-form variants where the floor logic still applies. Each is a
    // merchant✓keyword✗ case at-or-above the floor and must auto-fill.
    for (final variant in const ['ｽﾀﾊﾞ', 'マクド', 'Starbucks']) {
      test(
        'merchant✓keyword✗ variant "$variant" auto-fills at the >= 0.85 floor',
        () async {
          when(() => mockCategory.resolve(any())).thenAnswer((_) async => null);
          when(() => mockMerchant.recognize(any())).thenAnswer(
            (_) async =>
                [_candidate(score: 0.85, categoryId: 'cat_food_cafe')],
          );
          when(
            () => mockCategory.normalizeToL2('cat_food_cafe'),
          ).thenAnswer((_) async => 'cat_food_cafe');
          when(
            () => mockCategory.resolveLedgerType('cat_food_cafe'),
          ).thenAnswer((_) async => LedgerType.daily);

          final result = await useCase.execute(variant, localeId: 'ja-JP');

          expect(result.isSuccess, isTrue, reason: result.error);
          expect(
            result.data!.categoryMatch!.categoryId,
            equals('cat_food_cafe'),
          );
          expect(
            result.data!.categoryMatch!.source,
            equals(MatchSource.merchant),
          );
        },
      );
    }

    // ── Quadrant 3: merchant✗ keyword✓ → KEYWORD ONLY, no merchant fill ──
    // 「加油用了400块」: no merchant, 加油→cat_car_fuel keyword (SC4 / DECOUP-02
    // Case B). The category is the keyword's; no merchant primitives.
    test(
      'merchant✗keyword✓ "加油用了400块" → cat_car_fuel (no merchant auto-fill)',
      () async {
        when(() => mockCategory.resolve(any())).thenAnswer(
          (_) async => const CategoryMatchResult(
            categoryId: 'cat_car_fuel',
            confidence: 0.85,
            source: MatchSource.keyword,
          ),
        );
        when(
          () => mockMerchant.recognize(any()),
        ).thenAnswer((_) async => const <MerchantCandidate>[]);
        when(
          () => mockCategory.resolveLedgerType('cat_car_fuel'),
        ).thenAnswer((_) async => LedgerType.daily);

        final result = await useCase.execute('加油用了400块', localeId: 'zh-CN');

        expect(result.isSuccess, isTrue, reason: result.error);
        final data = result.data!;
        expect(data.categoryMatch!.categoryId, equals('cat_car_fuel'));
        expect(data.categoryMatch!.source, equals(MatchSource.keyword));
        // No merchant candidate — no merchant pre-fill.
        expect(data.merchantName, isNull);
        expect(data.merchantCandidates, isEmpty);
        verifyNever(() => mockCategory.normalizeToL2(any()));
      },
    );

    // ── Quadrant 4: merchant✗ keyword✗ → finalCategory null, no auto-fill ──
    // Plus: a BELOW-floor candidate must NOT auto-fill, yet still surfaces on
    // the result (recall-first for Phase-52 chips).
    test(
      'merchant✗keyword✗ → finalCategory null; candidates still surfaced',
      () async {
        when(() => mockCategory.resolve(any())).thenAnswer((_) async => null);
        // A weak (below-floor) candidate exists but must NOT auto-fill.
        final weak = _candidate(score: 0.60, categoryId: 'cat_food_cafe');
        when(
          () => mockMerchant.recognize(any()),
        ).thenAnswer((_) async => [weak]);

        final result = await useCase.execute('なにか適当な発話', localeId: 'ja-JP');

        expect(result.isSuccess, isTrue, reason: result.error);
        final data = result.data!;
        // No auto-fill below the floor.
        expect(data.categoryMatch, isNull, reason: 'below 0.85 → no auto-fill');
        // But the ranked candidate is still surfaced.
        expect(data.merchantCandidates, isNotEmpty);
        expect(data.merchantCandidates.first.score, equals(0.60));
        expect(data.ledgerType, isNull);
        verifyNever(() => mockCategory.normalizeToL2(any()));
      },
    );

    // ── WR-04: a null normalizeToL2 result must NOT auto-fill the raw,
    // possibly-non-L2 merchant categoryId — leave the category null and surface
    // the candidate for a manual pick instead. ──
    test(
      'merchant✓keyword✗ but normalizeToL2 null → no auto-fill (WR-04)',
      () async {
        when(() => mockCategory.resolve(any())).thenAnswer((_) async => null);
        when(() => mockMerchant.recognize(any())).thenAnswer(
          (_) async =>
              [_candidate(score: 0.95, categoryId: 'cat_food_l1_only')],
        );
        // The merchant categoryId does not normalize to an L2 (e.g. an L1 id
        // with no resolvable child).
        when(
          () => mockCategory.normalizeToL2('cat_food_l1_only'),
        ).thenAnswer((_) async => null);

        final result = await useCase.execute('スタバ', localeId: 'ja-JP');

        expect(result.isSuccess, isTrue, reason: result.error);
        final data = result.data!;
        // No auto-fill: the un-normalized id must never be stamped.
        expect(
          data.categoryMatch,
          isNull,
          reason: 'null normalizeToL2 → no auto-fill (WR-04)',
        );
        expect(data.ledgerType, isNull);
        // resolveLedgerType is NOT consulted when there is no final category.
        verifyNever(() => mockCategory.resolveLedgerType(any()));
        // The candidate still surfaces for a manual pick (recall-first).
        expect(data.merchantCandidates, isNotEmpty);
      },
    );

    test(
      'exactly-at-floor (0.85) candidate auto-fills (>= is inclusive)',
      () async {
        when(() => mockCategory.resolve(any())).thenAnswer((_) async => null);
        when(() => mockMerchant.recognize(any())).thenAnswer(
          (_) async => [_candidate(score: kMerchantAutoFillFloor)],
        );

        final result = await useCase.execute('スタバ', localeId: 'ja-JP');

        expect(result.data!.categoryMatch, isNotNull);
        expect(
          result.data!.categoryMatch!.source,
          equals(MatchSource.merchant),
        );
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════
  // LEDGER INVARIANT (LEDGER-01) — ledger is a pure function of the final
  // category, derived via resolveLedgerType; NEVER the merchant ledger hint.
  // ════════════════════════════════════════════════════════════════════════
  group('Ledger invariant — ledger == resolveLedgerType(finalCategoryId)', () {
    test(
      'keyword branch: ledger derived from the keyword category, NOT the hint',
      () async {
        when(() => mockCategory.resolve(any())).thenAnswer(
          (_) async => const CategoryMatchResult(
            categoryId: 'cat_shopping_daily',
            confidence: 0.9,
            source: MatchSource.keyword,
          ),
        );
        // Merchant candidate carries a SOUL ledger hint — must be ignored.
        when(() => mockMerchant.recognize(any())).thenAnswer(
          (_) async => [_candidate(ledgerHint: 'soul')],
        );
        when(
          () => mockCategory.resolveLedgerType('cat_shopping_daily'),
        ).thenAnswer((_) async => LedgerType.daily);

        final result = await useCase.execute('在星巴克买杯子', localeId: 'zh-CN');

        // 购物 → daily ledger, NOT the candidate's soul hint.
        expect(result.data!.ledgerType, equals(LedgerType.daily));
        verify(
          () => mockCategory.resolveLedgerType('cat_shopping_daily'),
        ).called(1);
      },
    );

    test(
      'merchant auto-fill branch: ledger derived from the auto-filled L2, '
      'NOT the candidate ledgerHint',
      () async {
        when(() => mockCategory.resolve(any())).thenAnswer((_) async => null);
        when(() => mockMerchant.recognize(any())).thenAnswer(
          // ledgerHint deliberately 'soul' — the final ledger must come from
          // resolveLedgerType(cat_food_cafe), which we stub to daily.
          (_) async => [
            _candidate(
              score: 0.95,
              categoryId: 'cat_food_cafe',
              ledgerHint: 'soul',
            ),
          ],
        );
        when(
          () => mockCategory.normalizeToL2('cat_food_cafe'),
        ).thenAnswer((_) async => 'cat_food_cafe');
        when(
          () => mockCategory.resolveLedgerType('cat_food_cafe'),
        ).thenAnswer((_) async => LedgerType.daily);

        final result = await useCase.execute('スタバ', localeId: 'ja-JP');

        // Ledger is the resolved daily, NOT the 'soul' hint.
        expect(result.data!.ledgerType, equals(LedgerType.daily));
        verify(
          () => mockCategory.resolveLedgerType('cat_food_cafe'),
        ).called(1);
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════
  // LEARNING-KEY IDENTITY (260526-pg6) — resolvedKeyword on the result equals
  // the exact canonical key the CategoryRecognizer.resolve() received.
  // ════════════════════════════════════════════════════════════════════════
  group('Learning-key identity (260526-pg6)', () {
    test(
      'resolvedKeyword equals the post-strip key the recognizer read (zh)',
      () async {
        String? recognizerSaw;
        when(() => mockCategory.resolve(any())).thenAnswer((inv) async {
          recognizerSaw = inv.positionalArguments.first as String;
          return null;
        });

        // 「去外食12,450日元」zh: amount + 日元 suffix stripped, 去外食 stays intact.
        final result = await useCase.execute('去外食12,450日元', localeId: 'zh-CN');

        expect(result.isSuccess, isTrue, reason: result.error);
        expect(recognizerSaw, equals('去外食'));
        expect(result.data!.resolvedKeyword, equals('去外食'));
        // Pin: the write-key IS the read-key (single canonical source).
        expect(result.data!.resolvedKeyword, equals(recognizerSaw));
      },
    );

    test(
      'resolvedKeyword is populated even on the merchant auto-fill branch',
      () async {
        when(() => mockCategory.resolve(any())).thenAnswer((_) async => null);
        when(() => mockMerchant.recognize(any())).thenAnswer(
          (_) async => [_candidate(score: 0.95)],
        );
        when(
          () => mockCategory.normalizeToL2(any()),
        ).thenAnswer((inv) async => inv.positionalArguments.first as String);

        final result = await useCase.execute('去星巴克喝咖啡', localeId: 'zh-CN');

        expect(result.isSuccess, isTrue, reason: result.error);
        // The post-strip keyword is still surfaced for a future correction.
        expect(result.data!.resolvedKeyword, isNotNull);
        expect(result.data!.resolvedKeyword!.isNotEmpty, isTrue);
      },
    );

    test('amount-only utterance yields null resolvedKeyword', () async {
      final result = await useCase.execute('500日元', localeId: 'zh-CN');

      expect(result.isSuccess, isTrue);
      expect(
        result.data!.resolvedKeyword,
        isNull,
        reason: 'amount-only utterance → null resolvedKeyword (explicit guard)',
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // IN-04 / CR-01: REAL MerchantRecognizer end-to-end. The four-quadrant gate
  // above mocks the recognizer (0.95 for any() input), so it cannot catch a
  // scorer regression. This group wires the REAL MerchantRecognizer over a tiny
  // in-memory seed through the REAL ParseVoiceInputUseCase, asserting compound
  // "merchant-then-words" utterances auto-fill via the real anchored scorer —
  // the structural reason CR-01 shipped green is closed here.
  // ════════════════════════════════════════════════════════════════════════
  group('IN-04 — real MerchantRecognizer over a tiny seed (CR-01 e2e)', () {
    late ParseVoiceInputUseCase realMerchantUseCase;

    setUp(() {
      final repo = _MockMerchantRepository();
      when(repo.loadAllForMatching).thenAnswer(
        (_) async => <MerchantMatchEntry>[
          _matchEntry(
            'スターバックス',
            merchantId: 'mer_starbucks',
            displayName: 'スターバックス',
            categoryId: 'cat_food_cafe',
          ),
          _matchEntry(
            'スタバ',
            merchantId: 'mer_starbucks',
            displayName: 'スターバックス',
            categoryId: 'cat_food_cafe',
          ),
          _matchEntry(
            'マクドナルド',
            merchantId: 'mer_mcdonalds',
            displayName: 'マクドナルド',
            categoryId: 'cat_food_dining_out',
          ),
          _matchEntry(
            'マクド',
            merchantId: 'mer_mcdonalds',
            displayName: 'マクドナルド',
            categoryId: 'cat_food_dining_out',
          ),
        ],
      );
      final realMerchant = MerchantRecognizer(merchantRepository: repo);
      // Category recognizer stays mocked: it returns null so the merchant
      // auto-fill branch is exercised; the L2/ledger steps pass through.
      realMerchantUseCase = ParseVoiceInputUseCase(
        textParser: parser,
        categoryRecognizer: mockCategory,
        merchantRecognizer: realMerchant,
      );
      when(() => mockCategory.resolve(any())).thenAnswer((_) async => null);
    });

    for (final c in const <String, String>{
      'スタバでコーヒー': 'cat_food_cafe',
      'スタバで500円': 'cat_food_cafe',
      'スタバに行った': 'cat_food_cafe',
      'マクドでポテト食べた': 'cat_food_dining_out',
      'マクドで昼': 'cat_food_dining_out',
    }.entries) {
      test(
        'compound "${c.key}" auto-fills ${c.value} via the real scorer',
        () async {
          final result = await realMerchantUseCase.execute(
            c.key,
            localeId: 'ja-JP',
          );

          expect(result.isSuccess, isTrue, reason: result.error);
          final data = result.data!;
          expect(
            data.merchantCandidates,
            isNotEmpty,
            reason: '"${c.key}" must surface a merchant candidate (CR-01)',
          );
          expect(
            data.categoryMatch,
            isNotNull,
            reason: '"${c.key}" must auto-fill (>= 0.85 floor)',
          );
          expect(data.categoryMatch!.categoryId, equals(c.value));
          expect(data.categoryMatch!.source, equals(MatchSource.merchant));
          expect(data.categoryMatch!.confidence >= 0.85, isTrue);
        },
      );
    }
  });

  // ─── localeId routing (preserved from the pre-Phase-50 test) ───
  group('localeId routing', () {
    late _MockVoiceTextParser mockTextParser;
    late ParseVoiceInputUseCase useCaseWithMockParser;

    setUp(() {
      mockTextParser = _MockVoiceTextParser();
      useCaseWithMockParser = ParseVoiceInputUseCase(
        textParser: mockTextParser,
        categoryRecognizer: mockCategory,
        merchantRecognizer: mockMerchant,
      );
      when(
        () => mockTextParser.extractAmount(
          any(),
          localeId: any(named: 'localeId'),
        ),
      ).thenReturn(2204);
      when(() => mockTextParser.extractDate(any())).thenReturn(null);
    });

    test(
      'execute(text, localeId: x) forwards localeId to textParser.extractAmount',
      () async {
        await useCaseWithMockParser.execute('test text', localeId: 'ja-JP');

        verify(
          () => mockTextParser.extractAmount('test text', localeId: 'ja-JP'),
        ).called(1);
      },
    );
  });

  // ─── WR-04 regression: currency-suffix residue must not pollute keyword ───
  group('WR-04 — currency-suffix residue stripped from category keyword', () {
    test('"5块钱拉面" → keyword 拉面 (no 块/钱 residue)', () async {
      String? seen;
      when(() => mockCategory.resolve(any())).thenAnswer((inv) async {
        seen = inv.positionalArguments.first as String?;
        return const CategoryMatchResult(
          categoryId: 'cat_food_dining_out',
          confidence: 0.5,
          source: MatchSource.keyword,
        );
      });

      final result = await useCase.execute('5块钱拉面', localeId: 'zh-CN');
      expect(result.isSuccess, isTrue, reason: result.error);
      expect(seen, equals('拉面'));
      expect(result.data!.resolvedKeyword, equals('拉面'));
    });

    test('"50美元咖啡" → keyword 咖啡 (no 美元 residue)', () async {
      String? seen;
      when(() => mockCategory.resolve(any())).thenAnswer((inv) async {
        seen = inv.positionalArguments.first as String?;
        return const CategoryMatchResult(
          categoryId: 'cat_food_dining_out',
          confidence: 0.5,
          source: MatchSource.keyword,
        );
      });

      final result = await useCase.execute('50美元咖啡', localeId: 'zh-CN');
      expect(result.isSuccess, isTrue, reason: result.error);
      expect(seen, equals('咖啡'));
      expect(result.data!.resolvedKeyword, equals('咖啡'));
    });
  });
}

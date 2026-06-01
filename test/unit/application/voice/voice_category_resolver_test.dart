import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/voice/voice_category_resolver.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_keyword_preference.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';
import 'package:mocktail/mocktail.dart';

// VOICE-06 structural verification (Phase 21 D-07): each pipeline data source
// is independently mockable. Every group below stubs ONLY the source it
// exercises — earlier steps are stubbed to no-op so the test isolates the
// behavior under examination.

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockCategoryKeywordPreferenceRepository extends Mock
    implements CategoryKeywordPreferenceRepository {}

class _MockCategoryService extends Mock implements CategoryService {}

class _MockMerchantDatabase extends Mock implements MerchantDatabase {}

Category _makeCategory(String id, {int level = 2, String? parentId}) {
  return Category(
    id: id,
    name: id,
    icon: 'icon',
    color: '#000000',
    level: level,
    parentId: parentId,
    createdAt: DateTime(2026),
  );
}

CategoryKeywordPreference _pref(
  String keyword,
  String categoryId, {
  int hitCount = 0,
}) {
  return CategoryKeywordPreference(
    keyword: keyword,
    categoryId: categoryId,
    hitCount: hitCount,
    lastUsed: DateTime(2026),
  );
}

void main() {
  late _MockCategoryRepository mockCategoryRepo;
  late _MockCategoryKeywordPreferenceRepository mockPrefRepo;
  late _MockCategoryService mockCategoryService;
  late _MockMerchantDatabase mockMerchantDb;
  late VoiceCategoryResolver resolver;

  setUp(() {
    mockCategoryRepo = _MockCategoryRepository();
    mockPrefRepo = _MockCategoryKeywordPreferenceRepository();
    mockCategoryService = _MockCategoryService();
    mockMerchantDb = _MockMerchantDatabase();
    resolver = VoiceCategoryResolver(
      categoryRepository: mockCategoryRepo,
      preferenceRepository: mockPrefRepo,
      categoryService: mockCategoryService,
      merchantDatabase: mockMerchantDb,
    );
    // 260526-l0o (Issue 2): step 2.5 substring fallback consults the seed
    // cache via findAllSeedRows. Default to empty so tests not exercising the
    // fallback are unaffected; per-test stubs can override.
    when(() => mockPrefRepo.findAllSeedRows()).thenAnswer((_) async => []);
    // Quick task 260526-pg6 (Option F — Task 3): step 2.5 also consults
    // learned rows at-or-above kLearnedPromotionThreshold. Default to empty
    // so seed-only tests are unaffected.
    when(
      () => mockPrefRepo.findLearnedRowsAtOrAbove(any()),
    ).thenAnswer((_) async => []);
  });

  group('Step 1: MerchantDatabase', () {
    test('L2 hit returns categoryId with source=merchant and merchant confidence', () async {
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(
        const MerchantMatch(
          merchantName: 'スターバックス',
          categoryId: 'cat_food_cafe',
          confidence: 0.90,
          ledgerType: LedgerType.daily,
        ),
      );
      when(() => mockCategoryRepo.findById('cat_food_cafe')).thenAnswer(
        (_) async => _makeCategory('cat_food_cafe', parentId: 'cat_food'),
      );

      final result = await resolver.resolve('スタバ');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food_cafe');
      expect(result.source, MatchSource.merchant);
      expect(result.confidence, 0.90);
      // Preference repo MUST NOT be consulted when step 1 hits.
      verifyNever(() => mockPrefRepo.findByKeyword(any()));
    });

    test('L1 result is routed through _ensureL2 to \${l1Id}_other', () async {
      // Defensive — verifies the resolver does not trust merchantDb to always
      // return L2 (despite Plan 04's enforcement).
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(
        const MerchantMatch(
          merchantName: 'マクドナルド',
          categoryId: 'cat_food', // L1 — must be demoted.
          confidence: 0.90,
          ledgerType: LedgerType.daily,
        ),
      );
      when(() => mockCategoryRepo.findById('cat_food')).thenAnswer(
        (_) async => _makeCategory('cat_food', level: 1),
      );
      when(() => mockCategoryRepo.findById('cat_food_other')).thenAnswer(
        (_) async => _makeCategory('cat_food_other', parentId: 'cat_food'),
      );

      final result = await resolver.resolve('マクドナルド');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food_other');
      expect(result.source, MatchSource.merchant);
    });
  });

  group('WR-02 fallthrough', () {
    test(
      'merchant hit with unresolvable categoryId falls through to keyword preferences',
      () async {
        // Merchant DB returns a match whose categoryId no longer exists in
        // the category table (e.g. stale entry). _ensureL2 returns null, so
        // the resolver falls through to step 2 rather than hiding the
        // usable keyword signal.
        when(() => mockMerchantDb.findMerchant(any())).thenReturn(
          const MerchantMatch(
            merchantName: 'X',
            categoryId: 'cat_nonexistent',
            confidence: 0.9,
            ledgerType: LedgerType.daily,
          ),
        );
        when(
          () => mockCategoryRepo.findById('cat_nonexistent'),
        ).thenAnswer((_) async => null);
        when(() => mockPrefRepo.findByKeyword('X')).thenAnswer(
          (_) async => [_pref('X', 'cat_food_dining_out')],
        );
        when(
          () => mockCategoryRepo.findById('cat_food_dining_out'),
        ).thenAnswer(
          (_) async =>
              _makeCategory('cat_food_dining_out', parentId: 'cat_food'),
        );

        final result = await resolver.resolve('X');

        expect(result, isNotNull);
        expect(result!.categoryId, 'cat_food_dining_out');
        expect(result.source, MatchSource.keyword);
      },
    );
  });

  group('WR-05 normalizeToL2 public surface', () {
    test('L2 categoryId pass-through returns same id', () async {
      when(() => mockCategoryRepo.findById('cat_food_cafe')).thenAnswer(
        (_) async => _makeCategory('cat_food_cafe', parentId: 'cat_food'),
      );
      expect(await resolver.normalizeToL2('cat_food_cafe'), 'cat_food_cafe');
    });

    test('L1 categoryId routes through \${l1Id}_other convention', () async {
      when(() => mockCategoryRepo.findById('cat_food')).thenAnswer(
        (_) async => _makeCategory('cat_food', level: 1),
      );
      when(() => mockCategoryRepo.findById('cat_food_other')).thenAnswer(
        (_) async => _makeCategory('cat_food_other', parentId: 'cat_food'),
      );
      expect(await resolver.normalizeToL2('cat_food'), 'cat_food_other');
    });

    test('unknown id returns null without throwing', () async {
      when(() => mockCategoryRepo.findById('cat_missing'))
          .thenAnswer((_) async => null);
      expect(await resolver.normalizeToL2('cat_missing'), isNull);
    });
  });

  group('Step 2: keyword preferences', () {
    test('direct L2 hit returns the L2 with source=keyword (hitCount=0)', () async {
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
      when(() => mockPrefRepo.findByKeyword('早餐')).thenAnswer(
        (_) async => [_pref('早餐', 'cat_food_dining_out')],
      );
      when(() => mockCategoryRepo.findById('cat_food_dining_out')).thenAnswer(
        (_) async =>
            _makeCategory('cat_food_dining_out', parentId: 'cat_food'),
      );

      final result = await resolver.resolve('早餐');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food_dining_out');
      expect(result.source, MatchSource.keyword);
    });

    test('keyword resolves to L1 → \${l1Id}_other fallback', () async {
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
      when(() => mockPrefRepo.findByKeyword('吃饭')).thenAnswer(
        (_) async => [_pref('吃饭', 'cat_food')],
      );
      when(() => mockCategoryRepo.findById('cat_food')).thenAnswer(
        (_) async => _makeCategory('cat_food', level: 1),
      );
      when(() => mockCategoryRepo.findById('cat_food_other')).thenAnswer(
        (_) async => _makeCategory('cat_food_other', parentId: 'cat_food'),
      );

      final result = await resolver.resolve('吃饭');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food_other');
      expect(result.source, MatchSource.keyword);
    });

    test('learned override wins via DAO ordering (hitCount=3 first)', () async {
      // The DAO orders hitCount DESC, lastUsed DESC (Plan 02). Resolver takes
      // .first — so a learned row preceding a seed row in the list dominates.
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
      when(() => mockPrefRepo.findByKeyword('咖啡')).thenAnswer(
        (_) async => [
          _pref('咖啡', 'cat_hobbies_subscription', hitCount: 3),
          _pref('咖啡', 'cat_food_cafe'),
        ],
      );
      when(
        () => mockCategoryRepo.findById('cat_hobbies_subscription'),
      ).thenAnswer(
        (_) async => _makeCategory(
          'cat_hobbies_subscription',
          parentId: 'cat_hobbies',
        ),
      );

      final result = await resolver.resolve('咖啡');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_hobbies_subscription');
      // hitCount=3 → isLearned=true → source=learning
      expect(result.source, MatchSource.learning);
    });

    test('confidence formula clamps to 1.0 for both seed and learned', () async {
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);

      // Seed bonus 0.15 + base 0.85 = 1.00 (boundary).
      when(() => mockPrefRepo.findByKeyword('seed')).thenAnswer(
        (_) async => [_pref('seed', 'cat_seed_l2')],
      );
      when(() => mockCategoryRepo.findById('cat_seed_l2')).thenAnswer(
        (_) async => _makeCategory('cat_seed_l2', parentId: 'cat_x'),
      );
      final seedResult = await resolver.resolve('seed');
      expect(seedResult!.confidence, closeTo(1.0, 1e-9));

      // Learned bonus 0.30 + base 0.85 = 1.15 → clamped to 1.0.
      when(() => mockPrefRepo.findByKeyword('learned')).thenAnswer(
        (_) async => [_pref('learned', 'cat_learned_l2', hitCount: 3)],
      );
      when(() => mockCategoryRepo.findById('cat_learned_l2')).thenAnswer(
        (_) async => _makeCategory('cat_learned_l2', parentId: 'cat_x'),
      );
      final learnedResult = await resolver.resolve('learned');
      expect(learnedResult!.confidence, 1.0);
      expect(learnedResult.source, MatchSource.learning);
    });
  });

  group('D-03 _ensureL2 fallback', () {
    test('cat_other_expense L1 routes to cat_other_other via override map', () async {
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
      when(() => mockPrefRepo.findByKeyword('其他')).thenAnswer(
        (_) async => [_pref('其他', 'cat_other_expense')],
      );
      when(() => mockCategoryRepo.findById('cat_other_expense')).thenAnswer(
        (_) async => _makeCategory('cat_other_expense', level: 1),
      );
      // The synthesized id (cat_other_expense_other) does NOT exist — only
      // the override (cat_other_other) does.
      when(
        () => mockCategoryRepo.findById('cat_other_expense_other'),
      ).thenAnswer((_) async => null);
      when(() => mockCategoryRepo.findById('cat_other_other')).thenAnswer(
        (_) async => _makeCategory(
          'cat_other_other',
          parentId: 'cat_other_expense',
        ),
      );

      final result = await resolver.resolve('其他');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_other_other');
    });

    test('safety net falls back to findByParent.first when _other missing', () async {
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
      when(() => mockPrefRepo.findByKeyword('odd')).thenAnswer(
        (_) async => [_pref('odd', 'cat_oddL1')],
      );
      when(() => mockCategoryRepo.findById('cat_oddL1')).thenAnswer(
        (_) async => _makeCategory('cat_oddL1', level: 1),
      );
      // Neither override nor synthesized id resolves — fall back to children.
      when(() => mockCategoryRepo.findById('cat_oddL1_other')).thenAnswer(
        (_) async => null,
      );
      when(() => mockCategoryRepo.findByParent('cat_oddL1')).thenAnswer(
        (_) async => [
          _makeCategory('cat_oddL1_first', parentId: 'cat_oddL1'),
          _makeCategory('cat_oddL1_second', parentId: 'cat_oddL1'),
        ],
      );

      final result = await resolver.resolve('odd');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_oddL1_first');
    });
  });

  group('Misses', () {
    test('all miss returns null', () async {
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
      when(() => mockPrefRepo.findByKeyword(any())).thenAnswer((_) async => []);

      final result = await resolver.resolve('weird');

      expect(result, isNull);
    });

    test('empty input guard returns null without consulting any source', () async {
      final result = await resolver.resolve('');

      expect(result, isNull);
      verifyNever(() => mockMerchantDb.findMerchant(any()));
      verifyNever(() => mockPrefRepo.findByKeyword(any()));
    });
  });

  group('resolveLedgerType pass-through', () {
    test('forwards categoryId to CategoryService.resolveLedgerType', () async {
      when(() => mockCategoryService.resolveLedgerType('cat_food_cafe'))
          .thenAnswer((_) async => LedgerType.daily);

      final ledger = await resolver.resolveLedgerType('cat_food_cafe');

      expect(ledger, LedgerType.daily);
      verify(() => mockCategoryService.resolveLedgerType('cat_food_cafe'))
          .called(1);
    });
  });

  // ── Quick task 260526-pg6 (Option F — Task 3): learned promotion ─────────
  //
  // Step 2.5 substring fallback now scans seeds ∪ learned(hitCount ≥
  // kLearnedPromotionThreshold = 3). Longest-key-wins is preserved across
  // the union. Seeds cached lazily; learned fetched fresh each call.
  group('Quick task 260526-pg6 — learned promotion in step 2.5', () {
    test(
      'Test 3.B: learned row (hitCount=3) wins substring fallback when no '
      'seed matches; source=learning',
      () async {
        when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
        when(
          () => mockPrefRepo.findByKeyword(any()),
        ).thenAnswer((_) async => []);
        // No seed matches.
        when(() => mockPrefRepo.findAllSeedRows()).thenAnswer(
          (_) async => [_pref('外食', 'cat_food_dining_out')],
        );
        // Learned: 新干线 → cat_transport_taxi, hitCount=3.
        when(
          () => mockPrefRepo.findLearnedRowsAtOrAbove(
            kLearnedPromotionThreshold,
          ),
        ).thenAnswer(
          (_) async => [_pref('新干线', 'cat_transport_taxi', hitCount: 3)],
        );
        when(() => mockCategoryRepo.findById('cat_transport_taxi')).thenAnswer(
          (_) async =>
              _makeCategory('cat_transport_taxi', parentId: 'cat_transport'),
        );

        final result = await resolver.resolve('坐新干线去东京');

        expect(result, isNotNull);
        expect(result!.categoryId, equals('cat_transport_taxi'));
        expect(
          result.source,
          equals(MatchSource.learning),
          reason: 'pg6 3.B: learned row in step 2.5 must surface as '
              'MatchSource.learning, NOT keyword',
        );
      },
    );

    test(
      'Test 3.C: longest-key wins across seed-vs-learned boundary',
      () async {
        when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
        when(
          () => mockPrefRepo.findByKeyword(any()),
        ).thenAnswer((_) async => []);
        // Seed: 外食 (len=2) → cat_food_dining_out
        when(() => mockPrefRepo.findAllSeedRows()).thenAnswer(
          (_) async => [_pref('外食', 'cat_food_dining_out')],
        );
        // Learned: 去外食 (len=3, longer) → cat_food_other, hitCount=3
        when(
          () => mockPrefRepo.findLearnedRowsAtOrAbove(
            kLearnedPromotionThreshold,
          ),
        ).thenAnswer(
          (_) async => [_pref('去外食', 'cat_food_other', hitCount: 3)],
        );
        when(() => mockCategoryRepo.findById('cat_food_other')).thenAnswer(
          (_) async => _makeCategory('cat_food_other', parentId: 'cat_food'),
        );

        // Input contains BOTH `外食` and `去外食` — longer key wins.
        final result = await resolver.resolve('我打算去外食呢');

        expect(result, isNotNull);
        expect(
          result!.categoryId,
          equals('cat_food_other'),
          reason: 'pg6 3.C: longest-key-wins preserved across seed/learned '
              'union; 去外食 (3 chars, learned) beats 外食 (2 chars, seed)',
        );
        expect(result.source, equals(MatchSource.learning));
      },
    );

    test(
      'Test 3.D: learned row BELOW threshold does NOT participate in step 2.5; '
      'seed wins instead',
      () async {
        when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
        when(
          () => mockPrefRepo.findByKeyword(any()),
        ).thenAnswer((_) async => []);
        when(() => mockPrefRepo.findAllSeedRows()).thenAnswer(
          (_) async => [_pref('外食', 'cat_food_dining_out')],
        );
        // Learned 去外食 at hitCount=2 (below threshold of 3). The repo
        // call with kLearnedPromotionThreshold MUST return empty per the
        // contract (hitCount < threshold ⇒ excluded). Stub matches that.
        when(
          () => mockPrefRepo.findLearnedRowsAtOrAbove(
            kLearnedPromotionThreshold,
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockCategoryRepo.findById('cat_food_dining_out'),
        ).thenAnswer(
          (_) async =>
              _makeCategory('cat_food_dining_out', parentId: 'cat_food'),
        );

        final result = await resolver.resolve('我打算去外食呢');

        expect(result, isNotNull);
        expect(
          result!.categoryId,
          equals('cat_food_dining_out'),
          reason:
              'pg6 3.D: hitCount=2 learned row must NOT compete with seeds '
              'in step 2.5 — threshold contract locked at '
              'kLearnedPromotionThreshold',
        );
        expect(result.source, equals(MatchSource.keyword));
      },
    );

    test(
      'Test 3.E: exact-match step 2 wins over step 2.5 even when a learned '
      'row would also substring-match (short-circuit invariant)',
      () async {
        when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
        // Step 2 (exact match by keyword) hits — short-circuits before
        // step 2.5 fires.
        when(() => mockPrefRepo.findByKeyword('去外食')).thenAnswer(
          (_) async => [_pref('去外食', 'cat_food_dining_out', hitCount: 5)],
        );
        when(
          () => mockCategoryRepo.findById('cat_food_dining_out'),
        ).thenAnswer(
          (_) async =>
              _makeCategory('cat_food_dining_out', parentId: 'cat_food'),
        );

        final result = await resolver.resolve('去外食');

        expect(result, isNotNull);
        expect(result!.categoryId, equals('cat_food_dining_out'));
        // Step 2.5 must NOT be consulted on an exact-match hit.
        verifyNever(() => mockPrefRepo.findAllSeedRows());
        verifyNever(
          () => mockPrefRepo.findLearnedRowsAtOrAbove(
            kLearnedPromotionThreshold,
          ),
        );
      },
    );

    test(
      'Backward-compat: pre-v1.3.1 polluted row (e.g. "去外食日元" written by '
      'the divergent extractor) survives — does not poison the resolver for '
      'unrelated inputs',
      () async {
        // Pre-pg6 the form-side extractVoiceKeyword could leave a stray
        // currency suffix (`日元`) attached. Such a learned row written to
        // the table BEFORE Task 2 landed must survive untouched: it should
        // still appear in findLearnedRowsAtOrAbove and the resolver MUST
        // ignore it when the current utterance doesn't contain that literal
        // substring. No auto-purge, no schema migration.
        when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
        when(
          () => mockPrefRepo.findByKeyword(any()),
        ).thenAnswer((_) async => []);
        when(() => mockPrefRepo.findAllSeedRows()).thenAnswer(
          (_) async => [_pref('外食', 'cat_food_dining_out')],
        );
        // Stale polluted learned row from pre-pg6 testing.
        when(
          () => mockPrefRepo.findLearnedRowsAtOrAbove(
            kLearnedPromotionThreshold,
          ),
        ).thenAnswer(
          (_) async => [_pref('去外食日元', 'cat_food_dining_out', hitCount: 5)],
        );
        when(
          () => mockCategoryRepo.findById('cat_food_dining_out'),
        ).thenAnswer(
          (_) async =>
              _makeCategory('cat_food_dining_out', parentId: 'cat_food'),
        );

        // Current utterance does NOT contain "去外食日元" — only "外食".
        // The polluted learned row's keyword fails `contains` and is
        // harmlessly ignored. Seed `外食` wins.
        final result = await resolver.resolve('我打算去外食呢');

        expect(result, isNotNull);
        expect(
          result!.categoryId,
          equals('cat_food_dining_out'),
          reason: 'pg6 backward-compat: polluted "去外食日元" row must NOT '
              'pollute resolution for utterances that lack that literal '
              'substring — no auto-purge needed',
        );
        // Source is keyword (seed) because the seed `外食` matched, not the
        // polluted learned row.
        expect(result.source, equals(MatchSource.keyword));
      },
    );

    test(
      'Test 3.F: seed cache persists across calls; learned set fetched fresh '
      'each call (in-session visibility)',
      () async {
        when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
        when(
          () => mockPrefRepo.findByKeyword(any()),
        ).thenAnswer((_) async => []);
        // Seed empty so step 2.5 never short-circuits the cache fill.
        when(
          () => mockPrefRepo.findAllSeedRows(),
        ).thenAnswer((_) async => []);
        when(
          () => mockPrefRepo.findLearnedRowsAtOrAbove(
            kLearnedPromotionThreshold,
          ),
        ).thenAnswer((_) async => []);

        await resolver.resolve('one');
        await resolver.resolve('two');

        // Seed cache: 1 call total (lazy load).
        verify(() => mockPrefRepo.findAllSeedRows()).called(1);
        // Learned: 1 call per resolve (fresh).
        verify(
          () => mockPrefRepo.findLearnedRowsAtOrAbove(
            kLearnedPromotionThreshold,
          ),
        ).called(2);
      },
    );
  });
}

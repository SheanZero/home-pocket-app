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
  });

  group('Step 1: MerchantDatabase', () {
    test('L2 hit returns categoryId with source=merchant and merchant confidence', () async {
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(
        const MerchantMatch(
          merchantName: 'スターバックス',
          categoryId: 'cat_food_cafe',
          confidence: 0.90,
          ledgerType: LedgerType.survival,
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
          ledgerType: LedgerType.survival,
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
            ledgerType: LedgerType.survival,
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
          .thenAnswer((_) async => LedgerType.survival);

      final ledger = await resolver.resolveLedgerType('cat_food_cafe');

      expect(ledger, LedgerType.survival);
      verify(() => mockCategoryService.resolveLedgerType('cat_food_cafe'))
          .called(1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/voice/recognition/category_recognizer.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_keyword_preference.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/shared/constants/default_synonyms.dart';
import 'package:mocktail/mocktail.dart';

// Phase 50 (DECOUP-01/DECOUP-02): CategoryRecognizer is keyword-only and runs
// unconditionally. Ported from voice_category_resolver_test.dart MINUS every
// step-1 vendor-lookup case and the vendor-database mock — this engine is
// constructionally independent of vendor recognition. Every group below stubs
// ONLY the source it exercises so the test isolates the behavior under
// examination.

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockCategoryKeywordPreferenceRepository extends Mock
    implements CategoryKeywordPreferenceRepository {}

class _MockCategoryService extends Mock implements CategoryService {}

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
  late CategoryRecognizer recognizer;

  setUp(() {
    mockCategoryRepo = _MockCategoryRepository();
    mockPrefRepo = _MockCategoryKeywordPreferenceRepository();
    mockCategoryService = _MockCategoryService();
    recognizer = CategoryRecognizer(
      categoryRepository: mockCategoryRepo,
      preferenceRepository: mockPrefRepo,
      categoryService: mockCategoryService,
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

  group('WR-05 normalizeToL2 public surface', () {
    test('L2 categoryId pass-through returns same id', () async {
      when(() => mockCategoryRepo.findById('cat_food_cafe')).thenAnswer(
        (_) async => _makeCategory('cat_food_cafe', parentId: 'cat_food'),
      );
      expect(await recognizer.normalizeToL2('cat_food_cafe'), 'cat_food_cafe');
    });

    test('L1 categoryId routes through \${l1Id}_other convention', () async {
      when(() => mockCategoryRepo.findById('cat_food')).thenAnswer(
        (_) async => _makeCategory('cat_food', level: 1),
      );
      when(() => mockCategoryRepo.findById('cat_food_other')).thenAnswer(
        (_) async => _makeCategory('cat_food_other', parentId: 'cat_food'),
      );
      expect(await recognizer.normalizeToL2('cat_food'), 'cat_food_other');
    });

    test('unknown id returns null without throwing', () async {
      when(() => mockCategoryRepo.findById('cat_missing'))
          .thenAnswer((_) async => null);
      expect(await recognizer.normalizeToL2('cat_missing'), isNull);
    });
  });

  group('Step 2: keyword preferences', () {
    test('direct L2 hit returns the L2 with source=keyword (hitCount=0)', () async {
      when(() => mockPrefRepo.findByKeyword('早餐')).thenAnswer(
        (_) async => [_pref('早餐', 'cat_food_dining_out')],
      );
      when(() => mockCategoryRepo.findById('cat_food_dining_out')).thenAnswer(
        (_) async =>
            _makeCategory('cat_food_dining_out', parentId: 'cat_food'),
      );

      final result = await recognizer.resolve('早餐');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food_dining_out');
      expect(result.source, MatchSource.keyword);
    });

    test('keyword resolves to L1 → \${l1Id}_other fallback', () async {
      when(() => mockPrefRepo.findByKeyword('吃饭')).thenAnswer(
        (_) async => [_pref('吃饭', 'cat_food')],
      );
      when(() => mockCategoryRepo.findById('cat_food')).thenAnswer(
        (_) async => _makeCategory('cat_food', level: 1),
      );
      when(() => mockCategoryRepo.findById('cat_food_other')).thenAnswer(
        (_) async => _makeCategory('cat_food_other', parentId: 'cat_food'),
      );

      final result = await recognizer.resolve('吃饭');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food_other');
      expect(result.source, MatchSource.keyword);
    });

    test('learned override wins via DAO ordering (hitCount=3 first)', () async {
      // The DAO orders hitCount DESC, lastUsed DESC (Plan 02). Recognizer takes
      // .first — so a learned row preceding a seed row in the list dominates.
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

      final result = await recognizer.resolve('咖啡');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_hobbies_subscription');
      // hitCount=3 → isLearned=true → source=learning
      expect(result.source, MatchSource.learning);
    });

    test('confidence formula clamps to 1.0 for both seed and learned', () async {
      // Seed bonus 0.15 + base 0.85 = 1.00 (boundary).
      when(() => mockPrefRepo.findByKeyword('seed')).thenAnswer(
        (_) async => [_pref('seed', 'cat_seed_l2')],
      );
      when(() => mockCategoryRepo.findById('cat_seed_l2')).thenAnswer(
        (_) async => _makeCategory('cat_seed_l2', parentId: 'cat_x'),
      );
      final seedResult = await recognizer.resolve('seed');
      expect(seedResult!.confidence, closeTo(1.0, 1e-9));

      // Learned bonus 0.30 + base 0.85 = 1.15 → clamped to 1.0.
      when(() => mockPrefRepo.findByKeyword('learned')).thenAnswer(
        (_) async => [_pref('learned', 'cat_learned_l2', hitCount: 3)],
      );
      when(() => mockCategoryRepo.findById('cat_learned_l2')).thenAnswer(
        (_) async => _makeCategory('cat_learned_l2', parentId: 'cat_x'),
      );
      final learnedResult = await recognizer.resolve('learned');
      expect(learnedResult!.confidence, 1.0);
      expect(learnedResult.source, MatchSource.learning);
    });
  });

  // ── VEN-01 / D-12: English category-keyword seeds resolve ────────────────
  //
  // Plan 52-04 Task 1 added lowercase en seeds for every zh/ja-covered L2. The
  // recognizer's step-2 `findByKeyword` is an EXACT (case-sensitive) lookup, so
  // the en seeds were authored lowercase to pair with the 52-01 en-residual
  // lowercasing (`_extractKeyword` lowercases the en keyword BEFORE it reaches
  // the recognizer — the write==read identity contract). These tests prove the
  // recognizer resolves the correct L2 from a lowercase en keyword, and that a
  // capitalized iOS-STT keyword resolves once it has been lowercased upstream.
  group('VEN-01 English category seeds (D-12)', () {
    test('lowercase en keyword resolves the correct L2 (coffee → cafe)',
        () async {
      when(() => mockPrefRepo.findByKeyword('coffee')).thenAnswer(
        (_) async => [_pref('coffee', 'cat_food_cafe')],
      );
      when(() => mockCategoryRepo.findById('cat_food_cafe')).thenAnswer(
        (_) async => _makeCategory('cat_food_cafe', parentId: 'cat_food'),
      );

      final result = await recognizer.resolve('coffee');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food_cafe');
      expect(result.source, MatchSource.keyword);
    });

    test('lowercase en keyword resolves the correct L2 (rent → housing rent)',
        () async {
      when(() => mockPrefRepo.findByKeyword('rent')).thenAnswer(
        (_) async => [_pref('rent', 'cat_housing_rent')],
      );
      when(() => mockCategoryRepo.findById('cat_housing_rent')).thenAnswer(
        (_) async => _makeCategory('cat_housing_rent', parentId: 'cat_housing'),
      );

      final result = await recognizer.resolve('rent');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_housing_rent');
    });

    test(
      'capitalized iOS-STT keyword resolves after upstream lowercasing '
      '(Coffee → coffee → cafe)',
      () async {
        // The 52-01 _extractKeyword lowercases en residuals before the
        // recognizer is called. We mirror that contract here: the lookup key
        // the recognizer receives is already lowercase, so it matches the
        // lowercase seed. A NON-lowercased "Coffee" would miss the
        // case-sensitive findByKeyword — that is exactly why the seeds and the
        // upstream extractor both go lowercase.
        const sttKeyword = 'Coffee';
        final lookupKey = sttKeyword.toLowerCase(); // = what _extractKeyword emits
        when(() => mockPrefRepo.findByKeyword(lookupKey)).thenAnswer(
          (_) async => [_pref('coffee', 'cat_food_cafe')],
        );
        // The case-sensitive seed lookup must NOT resolve the capitalized form.
        when(() => mockPrefRepo.findByKeyword(sttKeyword))
            .thenAnswer((_) async => []);
        when(() => mockCategoryRepo.findById('cat_food_cafe')).thenAnswer(
          (_) async => _makeCategory('cat_food_cafe', parentId: 'cat_food'),
        );

        final resolved = await recognizer.resolve(lookupKey);
        expect(resolved, isNotNull);
        expect(resolved!.categoryId, 'cat_food_cafe');

        // Proves the casing pairing matters: the raw capitalized key misses.
        final rawMiss = await recognizer.resolve(sttKeyword);
        expect(
          rawMiss,
          isNull,
          reason:
              'case-sensitive findByKeyword misses "Coffee"; the 52-01 '
              'lowercasing is what makes capitalized STT input resolve',
        );
      },
    );

    test('en L1 keyword routes to its _other bucket (food → cat_food_other)',
        () async {
      when(() => mockPrefRepo.findByKeyword('food')).thenAnswer(
        (_) async => [_pref('food', 'cat_food')],
      );
      when(() => mockCategoryRepo.findById('cat_food')).thenAnswer(
        (_) async => _makeCategory('cat_food', level: 1),
      );
      when(() => mockCategoryRepo.findById('cat_food_other')).thenAnswer(
        (_) async => _makeCategory('cat_food_other', parentId: 'cat_food'),
      );

      final result = await recognizer.resolve('food');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food_other');
    });
  });

  // ── VEN-01 / D-12: the REAL seed data carries the en rows the mock tests
  // above stub. This guards against the mock tests passing while Task 1's data
  // is missing/typo'd — it reads DefaultVoiceSynonyms.all directly. ──────────
  group('VEN-01 real seed data carries lowercase en keywords (D-12)', () {
    CategoryKeywordPreference? findSeed(String keyword) {
      for (final s in DefaultVoiceSynonyms.all) {
        if (s.keyword == keyword) return s;
      }
      return null;
    }

    test('coffee → cat_food_cafe seed exists (lowercase)', () {
      final s = findSeed('coffee');
      expect(s, isNotNull, reason: 'en seed "coffee" must exist');
      expect(s!.categoryId, 'cat_food_cafe');
      expect(s.keyword, equals(s.keyword.toLowerCase()),
          reason: 'en seeds MUST be authored lowercase (write==read contract)');
    });

    test('rent / taxi / gym / book sample en seeds map to their L2', () {
      expect(findSeed('rent')?.categoryId, 'cat_housing_rent');
      expect(findSeed('taxi')?.categoryId, 'cat_transport_taxi');
      expect(findSeed('gym')?.categoryId, 'cat_health_fitness');
      expect(findSeed('book')?.categoryId, 'cat_education_books');
    });

    test('every en common-word seed is fully lowercase', () {
      // Proper-noun brand/product tokens predate VEN-01 and are intentionally
      // cased as the brand spells itself (transit IC cards, broadcaster name).
      // They are NOT the lowercase en COMMON-word seeds the write==read
      // contract governs, so they are allow-listed out of this gate.
      const properNounAllowlist = {'Suica', 'PASMO', 'NHK受信料'};

      final caps = DefaultVoiceSynonyms.all
          .where((s) {
            final first = s.keyword.isEmpty ? '' : s.keyword[0];
            // an ASCII-letter-leading keyword is an en seed
            return first.toLowerCase() != first.toUpperCase();
          })
          .where((s) => !properNounAllowlist.contains(s.keyword))
          .where((s) => s.keyword != s.keyword.toLowerCase())
          .map((s) => s.keyword)
          .toList();
      expect(caps, isEmpty,
          reason: 'Capitalized en common-word seeds break the 52-01 '
              'case-sensitive findByKeyword pairing:\n${caps.join('\n')}');
    });
  });

  group('D-03 _ensureL2 fallback', () {
    test('cat_other_expense L1 routes to cat_other_other via override map', () async {
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

      final result = await recognizer.resolve('其他');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_other_other');
    });

    test('safety net falls back to findByParent.first when _other missing', () async {
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

      final result = await recognizer.resolve('odd');

      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_oddL1_first');
    });
  });

  group('Misses', () {
    test('all miss returns null', () async {
      when(() => mockPrefRepo.findByKeyword(any())).thenAnswer((_) async => []);

      final result = await recognizer.resolve('weird');

      expect(result, isNull);
    });

    test('empty input guard returns null without consulting any source', () async {
      final result = await recognizer.resolve('');

      expect(result, isNull);
      verifyNever(() => mockPrefRepo.findByKeyword(any()));
    });
  });

  group('resolveLedgerType pass-through', () {
    test('forwards categoryId to CategoryService.resolveLedgerType', () async {
      when(() => mockCategoryService.resolveLedgerType('cat_food_cafe'))
          .thenAnswer((_) async => LedgerType.daily);

      final ledger = await recognizer.resolveLedgerType('cat_food_cafe');

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

        final result = await recognizer.resolve('坐新干线去东京');

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
        final result = await recognizer.resolve('我打算去外食呢');

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

        final result = await recognizer.resolve('我打算去外食呢');

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

        final result = await recognizer.resolve('去外食');

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
      'the divergent extractor) survives — does not poison the recognizer for '
      'unrelated inputs',
      () async {
        // Pre-pg6 the form-side extractVoiceKeyword could leave a stray
        // currency suffix (`日元`) attached. Such a learned row written to
        // the table BEFORE Task 2 landed must survive untouched: it should
        // still appear in findLearnedRowsAtOrAbove and the recognizer MUST
        // ignore it when the current utterance doesn't contain that literal
        // substring. No auto-purge, no schema migration.
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
        final result = await recognizer.resolve('我打算去外食呢');

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

        await recognizer.resolve('one');
        await recognizer.resolve('two');

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

# Phase 21: Voice Category Resolver Level-2 Enforcement — Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 13 (7 new, 6 modified/possibly-deleted)
**Analogs found:** 13 / 13

This document maps every file Phase 21 will create or modify to the closest existing analog in the codebase, and quotes the concrete code excerpts the planner / executor should mirror. All snippets carry absolute file paths and line ranges so the planner can verify or adapt them in place.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/application/voice/voice_category_resolver.dart` | application orchestrator | request-response (async DB lookup) | `lib/application/voice/fuzzy_category_matcher.dart` + `lib/application/voice/voice_chunk_merger.dart` | exact (role) + exact (sibling location) |
| `lib/shared/constants/default_synonyms.dart` (planner choice — Dart-literal seed source) | data seeder source | static const list | `lib/shared/constants/default_categories.dart` + `lib/shared/constants/warm_emojis.dart` | exact (sibling location + abstract-final-class idiom) |
| `assets/voice/synonyms_seed.yaml` (planner-alternative — YAML asset seed source) | data seeder source (asset) | one-shot first-launch read | none — no YAML asset is loaded today | **no analog** (use D-01 Dart-literal path) |
| `lib/application/accounting/seed_voice_synonyms_use_case.dart` (planner choice — new file) OR extend `seed_categories_use_case.dart` | data seeder use case | one-shot idempotent insert | `lib/application/accounting/seed_categories_use_case.dart` | exact |
| `test/unit/application/voice/voice_category_resolver_test.dart` | unit test (mocktail) | mock-DB orchestrator test | `test/unit/application/voice/fuzzy_category_matcher_test.dart` | exact (replaces it) |
| `test/integration/voice/voice_category_corpus_zh_test.dart` + `_ja_test.dart` | integration corpus test | per-locale anchor + statistical bucket | `test/integration/voice/voice_corpus_zh_test.dart` + `voice_corpus_ja_test.dart` (Phase 20) | exact |
| `test/fixtures/voice_category_corpus_zh.dart` + `_ja.dart` | data-only fixture | const record list | `test/fixtures/voice_corpus_zh.dart` + `voice_corpus_ja.dart` (Phase 20) | exact |
| `test/architecture/category_other_l2_invariant_test.dart` | architecture invariant test | static iteration over `DefaultCategories.all` | `test/unit/shared/constants/default_categories_test.dart` (logic) + `test/architecture/mod009_live_lib_scan_test.dart` (architecture style) | role-match (assertion logic exists in default_categories_test; architecture-test packaging is in mod009_live_lib_scan_test) |
| `lib/application/voice/fuzzy_category_matcher.dart` | (DELETE) | — | n/a — quote current shape so planner knows what to remove | exact |
| `lib/application/voice/parse_voice_input_use_case.dart` | application use case (MODIFY) | swap field type | self (file under modification) | exact |
| `lib/infrastructure/ml/merchant_database.dart` | infrastructure ML (MODIFY) | update categoryIds | self (file under modification) | exact |
| `lib/features/accounting/presentation/providers/repository_providers.dart` | Riverpod provider wiring (MODIFY) | delete + add provider | self (file under modification) | exact |
| `lib/application/voice/levenshtein.dart` | utility (DELETE if no other consumer) | — | n/a — grep confirms only `FuzzyCategoryMatcher` consumes it | exact |
| `lib/data/daos/category_keyword_preference_dao.dart` | Drift DAO (MODIFY — may need `findBestForKeyword`) | DB select ordered | self (extend existing pattern) | exact |
| `lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart` | domain repository interface (verify only) | — | self | exact |

---

## Pattern Assignments

### 1. `lib/application/voice/voice_category_resolver.dart` (NEW — application orchestrator)

**Primary analog:** `/Users/xinz/Development/home-pocket-app/lib/application/voice/fuzzy_category_matcher.dart`
**Secondary analog (constructor / DI shape):** `/Users/xinz/Development/home-pocket-app/lib/application/voice/voice_chunk_merger.dart`

**Imports & dependency-injection pattern** — copy from `fuzzy_category_matcher.dart:1-25`:

```dart
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../accounting/category_service.dart';
// REMOVE: import 'levenshtein.dart';   (D-08 — no fuzzy matching in Phase 21)
// ADD:    import '../../infrastructure/ml/merchant_database.dart';   (D-07 step 1)

class VoiceCategoryResolver {
  final CategoryRepository _categoryRepository;
  final CategoryKeywordPreferenceRepository _preferenceRepository;
  final CategoryService _categoryService;
  final MerchantDatabase _merchantDatabase;

  VoiceCategoryResolver({
    required CategoryRepository categoryRepository,
    required CategoryKeywordPreferenceRepository preferenceRepository,
    required CategoryService categoryService,
    required MerchantDatabase merchantDatabase,
  })  : _categoryRepository = categoryRepository,
        _preferenceRepository = preferenceRepository,
        _categoryService = categoryService,
        _merchantDatabase = merchantDatabase;
}
```

**Pipeline orchestrator pattern** — `fuzzy_category_matcher.dart:32-106` shows the multi-signal merge variant. Phase 21 **inverts** to strict short-circuit per D-07. The skeleton:

```dart
// Phase 21 D-07 — short-circuit pipeline, NOT score-based merge
Future<CategoryMatchResult?> resolve(String inputText, String extractedKeyword) async {
  // Step 1: MerchantDatabase
  final merchantMatch = _merchantDatabase.findMerchant(extractedKeyword);
  if (merchantMatch != null) {
    final l2 = await _ensureL2(merchantMatch.categoryId);   // D-03
    if (l2 != null) {
      return CategoryMatchResult(categoryId: l2, confidence: merchantMatch.confidence, source: MatchSource.merchant);
    }
  }

  // Step 2: category_keyword_preferences (seed + learned unified)
  final prefs = await _preferenceRepository.findByKeyword(extractedKeyword);
  if (prefs.isNotEmpty) {
    final best = prefs.first;   // DAO already orders by hitCount DESC (see DAO pattern below)
    final l2 = await _ensureL2(best.categoryId);
    if (l2 != null) {
      final source = best.isLearned ? MatchSource.learning : MatchSource.keyword;
      return CategoryMatchResult(categoryId: l2, confidence: 0.85 + best.scoreBonus, source: source);
    }
  }

  // Step 4: all miss
  return null;
}

// D-03: synthesize ${l1Id}_other; verify via findById; fallback to findByParent(l1).first
Future<String?> _ensureL2(String categoryId) async {
  final cat = await _categoryRepository.findById(categoryId);
  if (cat == null) return null;
  if (cat.level == 2) return cat.id;
  // L1 → synthesize ${l1Id}_other
  final otherId = '${cat.id}_other';
  final otherCat = await _categoryRepository.findById(otherId);
  if (otherCat != null && otherCat.level == 2) return otherCat.id;
  // Safety net: first L2 by sortOrder
  final children = await _categoryRepository.findByParent(cat.id);
  if (children.isNotEmpty) return children.first.id;
  return null;
}

Future<LedgerType?> resolveLedgerType(String categoryId) =>
    _categoryService.resolveLedgerType(categoryId);
```

**Library doc-comment idiom** — `voice_chunk_merger.dart:1-9` uses a `library;` declaration with the design rationale block. Apply the same style to Phase 21's resolver:

```dart
/// Voice category resolver — short-circuit pipeline that always returns an L2 categoryId.
///
/// Per Phase 21 CONTEXT D-07: strict short-circuit order:
///   1. MerchantDatabase
///   2. category_keyword_preferences (seed `hitCount=0` + learned)
///   3. L1 → `${l1Id}_other` fallback (D-03)
///   4. miss → null
///
/// Replaces FuzzyCategoryMatcher (D-06/D-08 removed _matchSeedKeywords + _matchEditDistance).
library;
```

**Caveats:**
- The existing `FuzzyCategoryMatcher._matchSeedKeywords` (lines 116-150) does an inline L1→L2 lookup via `_categoryRepository.findById(subId)`. Phase 21 centralizes this into `_ensureL2()` — do NOT carry the per-call inline lookup from lines 125-137.
- The existing `_matchLearned` (lines 190-207) returns a confidence of `0.85 + scoreBonus` regardless of whether the row is seed or learned. Phase 21's pipeline distinguishes via `MatchSource.keyword` vs `MatchSource.learning` (the `isLearned` getter at `category_keyword_preference.dart:23` — `hitCount >= 2` — is the threshold).
- `CategoryService.resolveLedgerType` (read separately) handles L1/L2 + override inheritance; do not reimplement.

---

### 2. Synonym seed source — Dart-literal recommended (D-01 + Claude discretion)

**Primary analog:** `/Users/xinz/Development/home-pocket-app/lib/shared/constants/default_categories.dart`
**Secondary analog (lightweight const list):** `/Users/xinz/Development/home-pocket-app/lib/shared/constants/warm_emojis.dart`

**Target file:** `lib/shared/constants/default_synonyms.dart`

**`abstract final class` pattern with `static final List<T> all` getter** — copy from `default_categories.dart:1-13`:

```dart
import '../../features/accounting/domain/models/category_keyword_preference.dart';

/// System default voice synonyms per Phase 21 D-01.
///
/// Seeded into `category_keyword_preferences` with `hitCount = 0`
/// (sentinel distinguishing seed from user-learned rows).
/// One-shot on first launch via SeedVoiceSynonymsUseCase.
abstract final class DefaultVoiceSynonyms {
  static final DateTime _epoch = DateTime(2026, 1, 1);

  static List<CategoryKeywordPreference> get all => _all;

  static final List<CategoryKeywordPreference> _all = [
    // ===== Food (zh + ja, no en — deferred to v1.4+) =====
    _seed('朝ごはん', 'cat_food_dining_out'),
    _seed('朝食',    'cat_food_dining_out'),
    _seed('昼ごはん', 'cat_food_dining_out'),
    _seed('ランチ',  'cat_food_dining_out'),
    _seed('晩ごはん', 'cat_food_dining_out'),
    _seed('夕食',    'cat_food_dining_out'),
    _seed('食事',    'cat_food'),         // L1 → ensureL2 routes to cat_food_other
    _seed('ご飯',    'cat_food'),
    _seed('弁当',    'cat_food'),
    _seed('コーヒー', 'cat_food_cafe'),
    _seed('カフェ',  'cat_food_cafe'),
    // zh
    _seed('早餐',    'cat_food_dining_out'),
    _seed('午饭',    'cat_food_dining_out'),
    _seed('晚饭',    'cat_food_dining_out'),
    _seed('吃饭',    'cat_food'),
    _seed('咖啡',    'cat_food_cafe'),
    // ===== Transport =====
    _seed('電車',    'cat_transport_train'),
    _seed('バス',    'cat_transport_bus'),
    _seed('タクシー', 'cat_transport_taxi'),
    _seed('地铁',    'cat_transport_train'),
    _seed('公交',    'cat_transport_bus'),
    _seed('打车',    'cat_transport_taxi'),
    // ===== Clothing — note: cat_shopping ID drift FIXED to cat_clothing (D-04) =====
    _seed('服',     'cat_clothing'),
    _seed('洋服',    'cat_clothing'),
    _seed('靴',     'cat_clothing_shoes'),
    _seed('衣服',    'cat_clothing'),
    _seed('鞋子',    'cat_clothing_shoes'),
    // ===== Hobbies — note: cat_entertainment ID drift FIXED to cat_hobbies (D-04) =====
    _seed('映画',    'cat_hobbies_movies'),
    _seed('ゲーム',  'cat_hobbies_games'),
    _seed('カラオケ', 'cat_hobbies'),
    _seed('电影',    'cat_hobbies_movies'),
    _seed('游戏',    'cat_hobbies_games'),
    // ===== Health — note: cat_medical ID drift FIXED to cat_health (D-04) =====
    _seed('病院',    'cat_health_hospital'),
    _seed('薬',     'cat_health_medicine'),
    _seed('医院',    'cat_health_hospital'),
    _seed('药',     'cat_health_medicine'),
    // ===== Housing & Utilities =====
    _seed('家賃',    'cat_housing_rent'),
    _seed('水道',    'cat_utilities_water'),
    _seed('電気',    'cat_utilities_electricity'),
    _seed('ガス',    'cat_utilities_gas'),
    _seed('房租',    'cat_housing_rent'),
    _seed('水费',    'cat_utilities_water'),
    _seed('电费',    'cat_utilities_electricity'),
    // ===== Education =====
    _seed('本',     'cat_education_books'),
    _seed('书',     'cat_education_books'),
  ];

  static CategoryKeywordPreference _seed(String keyword, String categoryId) =>
      CategoryKeywordPreference(
        keyword: keyword,
        categoryId: categoryId,
        hitCount: 0,           // D-01 sentinel — distinguishes seed from learned
        lastUsed: _epoch,
      );
}
```

**Lightweight const list style** (alternative when no factory helper is needed) — `warm_emojis.dart:3-28`:

```dart
const List<String> warmEmojis = [
  '🏠', '🌸', '🌿', '🐱', '🐶', '🌈', '☀️', '🦊', '🐼', '🍀',
  // ... 24 entries
];
```

**Caveats:**
- The current `_seedKeywordMap` in `fuzzy_category_matcher.dart:211-309` has ~14 English entries (`breakfast`, `lunch`, `dinner`, `coffee`, `food`, `clothes`, `shoes`, `book`, `hospital`, `medicine`, `rent`, `utilities`, `movie`, `game`, `train`, `bus`, `taxi`) — **DO NOT migrate them** (deferred per Context §Deferred).
- The current map uses `cat_shopping`/`cat_entertainment`/`cat_medical` which **do not exist** in `default_categories.dart`. Phase 21's D-04 fixes are bundled into the new seed entries above (mapped to `cat_clothing*`/`cat_hobbies*`/`cat_health*`).
- `CategoryKeywordPreference` is the existing domain model (`/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/models/category_keyword_preference.dart`): constructor takes `keyword`, `categoryId`, `hitCount`, `lastUsed`. Read-only — no `copyWith`. The `isLearned` getter (`hitCount >= 2`) is the seed/learned boundary.

**Alternative — `assets/voice/synonyms_seed.yaml`:** no analog exists in the project (no asset is loaded at first-launch today). The planner should default to the Dart-literal path above; YAML adds a `flutter/services` rootBundle dependency, a `pubspec.yaml` asset entry, and a `yaml` package parse step — all without an established pattern to mirror.

---

### 3. `lib/application/accounting/seed_voice_synonyms_use_case.dart` (NEW data seeder) — OR extend existing

**Primary analog:** `/Users/xinz/Development/home-pocket-app/lib/application/accounting/seed_categories_use_case.dart` (entire file, 30 lines)

**Idempotent first-launch seeder pattern** — copy verbatim from `seed_categories_use_case.dart:1-30`:

```dart
import '../../features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import '../../shared/constants/default_synonyms.dart';
import '../../shared/utils/result.dart';

/// Seeds default voice synonyms into category_keyword_preferences if none exist.
///
/// Phase 21 D-01: seed rows use `hitCount = 0` sentinel.
/// Phase 21 Claude-discretion: `INSERT OR IGNORE` semantics — never destroy
/// user-corrected rows. Idempotent — does nothing if seeds already present.
class SeedVoiceSynonymsUseCase {
  SeedVoiceSynonymsUseCase({
    required CategoryKeywordPreferenceRepository preferenceRepository,
  }) : _prefRepo = preferenceRepository;

  final CategoryKeywordPreferenceRepository _prefRepo;

  Future<Result<void>> execute() async {
    // Idempotency check: if ANY row exists with the first seed keyword,
    // assume seeding has run. (Mirrors SeedCategoriesUseCase.execute's
    // `existing.isNotEmpty` shape — see seed_categories_use_case.dart:21-24.)
    final probeKeyword = DefaultVoiceSynonyms.all.first.keyword;
    final existing = await _prefRepo.findByKeyword(probeKeyword);
    if (existing.isNotEmpty) {
      return Result.success(null);
    }

    for (final entry in DefaultVoiceSynonyms.all) {
      // Use existing recordCorrection() if no batch insert is available, OR
      // extend CategoryKeywordPreferenceRepository with insertBatch() to mirror
      // CategoryRepository.insertBatch (default_categories.dart line 26 pattern).
      await _prefRepo.recordCorrection(
        keyword: entry.keyword,
        categoryId: entry.categoryId,
      );
    }
    return Result.success(null);
  }
}
```

**Wiring into AppInitializer** — `main.dart:103-108` shows how `seedCategoriesUseCaseProvider` is read and `.execute()` called inside `_initialize()`. Add the parallel call AFTER `seedCategories.execute()` so the L2 categoryIds the synonyms reference are guaranteed present.

**Caveats:**
- The current `CategoryKeywordPreferenceRepository.recordCorrection` (interface line 10-13 of `category_keyword_preference_repository.dart`) calls `DAO.upsert` which increments `hitCount` from 1 by default (`category_keyword_preference_dao.dart:55-65`). This will produce `hitCount=1` rows, **NOT the `hitCount=0` sentinel D-01 requires.** The planner has three options:
  1. Add an `insertSeedBatch({Map<String,String> keywordsToCategoryIds})` method to the repository/DAO that inserts with `hitCount: 0` explicitly. **Recommended** — most aligned with `CategoryRepository.insertBatch` (referenced at `seed_categories_use_case.dart:26`).
  2. Treat any row with `hitCount <= 1` as "seed" (loosen D-01 sentinel). Less clean.
  3. Patch `upsert` to accept an `initialHitCount` parameter. Touches more code than option 1.
- `findByKeyword(probeKeyword)` is the cheapest idempotency probe — the DAO already returns all rows for a given keyword (`category_keyword_preference_dao.dart:11-22`).

---

### 4. `test/unit/application/voice/voice_category_resolver_test.dart` (NEW unit test)

**Primary analog:** `/Users/xinz/Development/home-pocket-app/test/unit/application/voice/fuzzy_category_matcher_test.dart` (entire file, will be deleted alongside `FuzzyCategoryMatcher`)
**Secondary analog (mock-MerchantDatabase pattern):** `/Users/xinz/Development/home-pocket-app/test/unit/application/voice/parse_voice_input_use_case_test.dart:10-38`

**Mock setup pattern** — copy from `fuzzy_category_matcher_test.dart:1-50` and add the merchant-DB mock from `parse_voice_input_use_case_test.dart:12-15`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/voice/voice_category_resolver.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_keyword_preference.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}
class _MockCategoryKeywordPreferenceRepository extends Mock
    implements CategoryKeywordPreferenceRepository {}
class _MockCategoryService extends Mock implements CategoryService {}
class _MockMerchantDatabase extends Mock implements MerchantDatabase {}

Category _makeCategory(String id, {int level = 2, String? parentId}) {
  return Category(
    id: id,
    name: id,
    icon: 'icon', color: '#000', level: level,
    parentId: parentId,
    createdAt: DateTime(2026),
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
  });

  group('Step 1: MerchantDatabase hit', () {
    test('merchant L2 hit returns L2 categoryId with source=merchant', () async {
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(MerchantMatch(
        merchantName: 'スターバックス',
        categoryId: 'cat_food_cafe',
        confidence: 0.90,
        ledgerType: LedgerType.survival,
      ));
      when(() => mockCategoryRepo.findById('cat_food_cafe'))
          .thenAnswer((_) async => _makeCategory('cat_food_cafe', parentId: 'cat_food'));

      final result = await resolver.resolve('スタバでコーヒー', 'スタバ');
      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food_cafe');
      expect(result.source, MatchSource.merchant);
    });
  });

  group('D-03 L1 → \${l1Id}_other fallback', () {
    test('keyword resolves to L1, returns ${'$'}{l1Id}_other', () async {
      when(() => mockMerchantDb.findMerchant(any())).thenReturn(null);
      when(() => mockPrefRepo.findByKeyword('吃饭')).thenAnswer((_) async => [
        CategoryKeywordPreference(
          keyword: '吃饭', categoryId: 'cat_food', hitCount: 0,
          lastUsed: DateTime(2026),
        ),
      ]);
      when(() => mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => _makeCategory('cat_food', level: 1));
      when(() => mockCategoryRepo.findById('cat_food_other'))
          .thenAnswer((_) async => _makeCategory('cat_food_other', parentId: 'cat_food'));

      final result = await resolver.resolve('吃饭 300元', '吃饭');
      expect(result!.categoryId, 'cat_food_other');
    });
  });
}
```

**Caveats:**
- The existing test uses `_MockCategoryService` (`fuzzy_category_matcher_test.dart:16`) but never stubs it — keep this idiom unless the planner moves `resolveLedgerType` calls into resolver core (the analog file fuzzy matcher had `resolveLedgerType` as a thin pass-through; Phase 21 may keep it that way at `voice_category_resolver.dart`'s `resolveLedgerType` getter shown above).
- `parse_voice_input_use_case_test.dart:16-21` shows the `_FakeMerchantDatabase extends Fake implements MerchantDatabase` + `registerFallbackValue(...)` pattern needed when mocktail tries to match `any<MerchantDatabase>()`. Adopt only if the resolver test ever stubs a method that takes a `MerchantDatabase` parameter (it should not — resolver owns the merchantDb instance).

---

### 5. `test/integration/voice/voice_category_corpus_{zh,ja}_test.dart` (NEW corpus tests)

**Primary analog:** `/Users/xinz/Development/home-pocket-app/test/integration/voice/voice_corpus_zh_test.dart` (entire 89-line file) + `voice_corpus_ja_test.dart` (mirror)

**Per-locale aggregate accuracy gate** — copy entire structure from `voice_corpus_zh_test.dart:1-89`. The reusable scaffold:

```dart
import 'package:flutter_test/flutter_test.dart';
// REPLACE these two lines with the resolver under test:
//   import 'package:home_pocket/application/voice/voice_text_parser.dart';
//   import '../../fixtures/voice_corpus_zh.dart';
import 'package:home_pocket/application/voice/voice_category_resolver.dart';
import '../../fixtures/voice_category_corpus_zh.dart';
// (Plus all the DI imports needed to instantiate the resolver with real
//  in-memory Drift DB — see test/helpers/test_provider_scope.dart for the
//  AppDatabase.forTesting() pattern at lines 13-25.)

void main() {
  // ... resolver setup with seeded in-memory DB ...
  Future<String?> resolveCategory(String input, String keyword) async {
    final r = await resolver.resolve(input, keyword);
    return r?.categoryId;
  }

  var passCount = 0;
  var totalCount = 0;

  group('zh anchor cases (VOICE-04 / VOICE-05 / VOICE-06)', () {
    final anchors = voiceCategoryCorpusZh
        .where((c) => c.note?.startsWith('anchor:') ?? false).toList();

    setUpAll(() {
      expect(anchors.length, greaterThanOrEqualTo(5),
          reason: 'Fixture must contain ≥5 anchor cases (D-10 contract)');
    });

    for (final c in anchors) {
      test('${'$'}{c.input} -> ${'$'}{c.expectedCategoryId}  [${'$'}{c.note}]', () async {
        totalCount++;
        final actual = await resolveCategory(c.input, c.keyword);
        if (actual == c.expectedCategoryId) {
          passCount++;
        } else {
          expect(actual, c.expectedCategoryId,
              reason: 'anchor case must pass strictly: input="${'$'}{c.input}"'
                      ' expected=${'$'}{c.expectedCategoryId} actual=$actual');
        }
      });
    }
  });

  group('zh statistical corpus (≥95% accuracy gate)', () {
    final nonAnchors = voiceCategoryCorpusZh
        .where((c) => !(c.note?.startsWith('anchor:') ?? false)).toList();
    for (final c in nonAnchors) {
      test(c.input, () async {
        totalCount++;
        final actual = await resolveCategory(c.input, c.keyword);
        if (actual == c.expectedCategoryId) {
          passCount++;
        } else {
          printOnFailure('mismatch: input="${'$'}{c.input}"'
              ' expected=${'$'}{c.expectedCategoryId} actual=$actual'
              ' note=${'$'}{c.note ?? ""}');
        }
      });
    }
  });

  tearDownAll(() {
    final pct = totalCount == 0 ? 0.0 : (passCount / totalCount * 100);
    // ignore: avoid_print
    print('═══════════════════════════════════════════');
    // ignore: avoid_print
    print('zh category corpus: $passCount/$totalCount (${'$'}{pct.toStringAsFixed(1)}%)');
    // ignore: avoid_print
    print('═══════════════════════════════════════════');
    expect(totalCount == 0 ? 0.0 : passCount / totalCount,
        greaterThanOrEqualTo(0.95),
        reason: 'VOICE-06 corpus accuracy ${'$'}{pct.toStringAsFixed(1)}% < 95%');
  });
}
```

**Caveats:**
- The Phase 20 corpus tests are PURE (no DB) — `VoiceTextParser` is stateless. Phase 21's resolver needs an **in-memory Drift DB** seeded with both categories AND synonyms. Use `AppDatabase.forTesting()` via `createTestProviderScope` (`test/helpers/test_provider_scope.dart:13-25`):
  ```dart
  final container = createTestProviderScope();
  // Seed categories + synonyms first, then resolve.
  ```
- The `// ignore: avoid_print` lines on the reporter `print()` calls are intentional — Phase 20 added them to the `stale_suppressions_scan` allow-list (per STATE.md `VOICE-SCANNER-ALLOWLIST` resolution, commit `f04b978`). Phase 21 should append its new test files to the same allow-list pattern to avoid scanner regressions.
- `voice_corpus_ja_test.dart` is the exact mirror of `_zh_test.dart` with `localeId: 'ja-JP'` and `voiceCorpusJa` fixture — Phase 21 does the same swap.

---

### 6. `test/fixtures/voice_category_corpus_{zh,ja}.dart` (NEW fixture files)

**Primary analog:** `/Users/xinz/Development/home-pocket-app/test/fixtures/voice_corpus_zh.dart` (99 lines) + `voice_corpus_ja.dart` (mirror)

**Data-only `typedef` + `const List` pattern** — copy from `voice_corpus_zh.dart:1-29`:

```dart
/// Voice category corpus for zh resolver (Phase 21 / VOICE-04/05/06).
///
/// ~30 cases covering 5 anchor categories (D-10):
///   1. Direct L2 synonym hit       (e.g. 早餐 → cat_food_dining_out)
///   2. Merchant → L2 hit            (e.g. 星巴克咖啡 → cat_food_cafe)
///   3. L1 → \${l1Id}_other fallback (e.g. 吃饭 → cat_food_other)
///   4. Learned override             (e.g. 咖啡 → cat_hobbies_subscription)
///   5. ID drift regression          (e.g. 洋服 → cat_clothing_clothes — NOT cat_shopping)
///
/// Used by:
///   - test/integration/voice/voice_category_corpus_zh_test.dart
///
/// Conventions (mirror voice_corpus_zh.dart):
///   - All entries are pure const (no IO, no DateTime.now()).
///   - `const` records, no class wrapper.
///   - No imports from project source (test fixture is data-only).
library;

/// Record type for a single voice category corpus test case.
typedef VoiceCategoryCorpusCase = ({
  String input,            // raw voice text (with amount + filler words)
  String keyword,          // extracted keyword fed to resolver.resolve()
  String expectedCategoryId,
  String? note,            // 'anchor: ...' for individual test() blocks
});

const List<VoiceCategoryCorpusCase> voiceCategoryCorpusZh = [
  // ---------------------------------------------------------------------------
  // Anchor cases (5) — note must contain "anchor"
  // ---------------------------------------------------------------------------
  (input: '早餐 100元', keyword: '早餐', expectedCategoryId: 'cat_food_dining_out',
      note: 'anchor: direct L2 synonym hit VOICE-04'),
  (input: '星巴克咖啡', keyword: '星巴克', expectedCategoryId: 'cat_food_cafe',
      note: 'anchor: merchant DB → L2 hit VOICE-04'),
  (input: '吃饭 300元', keyword: '吃饭', expectedCategoryId: 'cat_food_other',
      note: 'anchor: L1 → _other fallback VOICE-05'),
  (input: '打车回家', keyword: '打车', expectedCategoryId: 'cat_transport_taxi',
      note: 'anchor: direct L2 synonym hit (zh)'),
  (input: '洋服を買った', keyword: '洋服', expectedCategoryId: 'cat_clothing_other',
      note: 'anchor: ID drift regression — cat_shopping does NOT exist'),

  // ---------------------------------------------------------------------------
  // ... ~25 more bucket cases — synonym variants, merchant variants,
  //     L1 fallback edge cases, etc.
  // ---------------------------------------------------------------------------
];
```

**Caveats:**
- The Phase 20 record shape is `({String input, int expected, String? note})` — Phase 21 needs an additional `String keyword` field (resolver takes both `inputText` and `extractedKeyword` per `voice_category_resolver.resolve(inputText, extractedKeyword)`), and `expected` becomes a categoryId string instead of an `int`.
- The "learned override" anchor case (#4) requires **test-setup-time DB writes** (insert a `("咖啡", "cat_hobbies_subscription", hitCount=3)` row before resolving) — it is NOT just a static fixture entry. The fixture can mark this case with `note: 'anchor: requires-setup learned override'`, and the integration test reads that marker to do the setUp DB insert.
- ja fixture (`voice_category_corpus_ja.dart`) mirrors with the ja anchor list from Context §specifics: `朝ごはん500円→cat_food_dining_out`, `スタバでコーヒー→cat_food_cafe`, `何か食べた→cat_food_other`, `電車で会社→cat_transport_train`, `映画を見た→cat_hobbies_movies` (regression), `病院に行った→cat_health_hospital` (regression).

---

### 7. `test/architecture/category_other_l2_invariant_test.dart` (NEW architecture invariant)

**Primary analog (architecture-test packaging):** `/Users/xinz/Development/home-pocket-app/test/architecture/mod009_live_lib_scan_test.dart` (35 lines)
**Primary analog (assertion logic):** `/Users/xinz/Development/home-pocket-app/test/unit/shared/constants/default_categories_test.dart:97-110` (the "every L2 has a parentId" iteration is the closest existing idiom)

**Architecture test scaffold** — copy from `mod009_live_lib_scan_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

/// Architecture test: every L1 in DefaultCategories MUST have a
/// `${l1Id}_other` L2 child with matching parentId and level=2.
///
/// Phase 21 D-03 safety net. Prevents future drift if someone edits
/// default_categories.dart and forgets the `_other` convention.
///
/// VoiceCategoryResolver's L1 → ${l1Id}_other fallback depends on this
/// invariant; if it breaks, voice flow silently degrades to first-L2-by-sortOrder
/// (a less predictable but non-crashing fallback per resolver._ensureL2 safety net).
///
/// Run: flutter test test/architecture/category_other_l2_invariant_test.dart
void main() {
  group('Category L2 _other invariant (Phase 21 D-03)', () {
    test('every expense L1 has a corresponding ${'$'}{l1Id}_other L2', () {
      final l1Ids = DefaultCategories.expenseL1.map((c) => c.id).toSet();
      final l2ById = {
        for (final c in DefaultCategories.all.where((c) => c.level == 2))
          c.id: c,
      };

      final missing = <String>[];
      for (final l1Id in l1Ids) {
        final expectedOtherId = '${'$'}{l1Id}_other';
        final otherL2 = l2ById[expectedOtherId];
        if (otherL2 == null) {
          missing.add(expectedOtherId);
          continue;
        }
        expect(otherL2.level, 2,
            reason: '${'$'}{expectedOtherId} must be level=2');
        expect(otherL2.parentId, l1Id,
            reason: '${'$'}{expectedOtherId} parentId must equal $l1Id');
      }
      expect(missing, isEmpty,
          reason: 'Missing _other L2 for L1(s): $missing — '
                  'Phase 21 D-03 invariant broken; VoiceCategoryResolver fallback will degrade');
    });
  });
}
```

**Note about the special case `cat_other_expense`:** The L2 for this L1 is named `cat_other_other` (see `default_categories.dart:1180-1187`), NOT `cat_other_expense_other`. The architecture test must accept this aliasing — either via an explicit allowlist:

```dart
const _otherIdOverrides = {'cat_other_expense': 'cat_other_other'};
final expectedOtherId = _otherIdOverrides[l1Id] ?? '${l1Id}_other';
```

Verify all 19 L1s before merging: the cleanest fix may be to rename `cat_other_other` → `cat_other_expense_other` in `default_categories.dart`, but that is a destructive rename (affects sync, existing user DBs). Document the override; do not rename without an ADR.

---

### 8. `lib/application/voice/fuzzy_category_matcher.dart` (DELETE)

**Current shape to delete** — entire file at `/Users/xinz/Development/home-pocket-app/lib/application/voice/fuzzy_category_matcher.dart` (334 lines). Key elements removed:

- Class `FuzzyCategoryMatcher` (line 14)
- Private classes `_KeywordMapping` (line 312), `_ScoredCandidate` (line 320)
- Private methods `_matchSeedKeywords` (line 116), `_matchEditDistance` (line 155), `_matchLearned` (line 190)
- Static const map `_seedKeywordMap` (line 211, ~70 entries)

**Caveat:** the `_matchLearned` semantics (preference lookup + score-bonus boost) DO migrate into the resolver as step 2 of the pipeline. The score-merge logic at lines 78-99 is the part that genuinely disappears (D-08).

---

### 9. `lib/application/voice/parse_voice_input_use_case.dart` (MODIFY)

**Current state — quote lines 1-26** to show what changes:

```dart
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../infrastructure/ml/merchant_database.dart';
import '../../shared/utils/result.dart';
import 'fuzzy_category_matcher.dart';        // ← REPLACE with voice_category_resolver.dart
import 'voice_text_parser.dart';

class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final FuzzyCategoryMatcher _fuzzyCategoryMatcher;   // ← REPLACE field type
  final MerchantDatabase _merchantDatabase;

  ParseVoiceInputUseCase({
    required VoiceTextParser textParser,
    required FuzzyCategoryMatcher fuzzyCategoryMatcher,    // ← REPLACE param
    required MerchantDatabase merchantDatabase,
  }) : _textParser = textParser,
       _fuzzyCategoryMatcher = fuzzyCategoryMatcher,        // ← REPLACE init
       _merchantDatabase = merchantDatabase;
```

**Current call sites — lines 52-74** (the orchestration logic that swaps matcher → resolver):

```dart
      // 4. Match category and resolve ledger type
      CategoryMatchResult? categoryMatch;
      LedgerType? ledgerType;

      if (merchantMatch != null) {
        categoryMatch = CategoryMatchResult(
          categoryId: merchantMatch.categoryId,
          confidence: merchantMatch.confidence,
          source: MatchSource.merchant,
        );
        ledgerType = merchantMatch.ledgerType;
      } else {
        // Extract keyword: remove amount/date/merchant text from input
        final keyword = _extractKeyword(recognizedText);
        categoryMatch = await _fuzzyCategoryMatcher.match(    // ← swap to _resolver.resolve(...)
          recognizedText,
          keyword,
        );
        if (categoryMatch != null) {
          ledgerType = await _fuzzyCategoryMatcher.resolveLedgerType(  // ← swap to _resolver.resolveLedgerType(...)
            categoryMatch.categoryId,
          );
        }
      }
```

**`_extractKeyword` (lines 97-113)** — Claude-discretion decision (CONTEXT §Claude's Discretion bullet 5): keep as-is in use case, OR relocate into the resolver. The current implementation is purely text-cleanup, no DI required:

```dart
String _extractKeyword(String text) {
  var remaining = text;
  remaining = remaining.replaceAll(
    RegExp(r'[¥￥]?\s*[\d,]+\.?\d*\s*(円|元|ドル)?'),
    '',
  );
  remaining = remaining.replaceAll(RegExp(r'[のにでをはがもへとや]'), '');
  remaining = remaining.replaceAll(RegExp(r'[的了吗呢吧啊呀哦]'), '');
  return remaining.trim();
}
```

**Recommendation:** keep `_extractKeyword` in the use case. The resolver should take a pre-extracted keyword and stay focused on lookup. This keeps the resolver's surface area testable without text-cleanup mocks.

**Caveat:** the merchant-match branch currently uses `merchantMatch.categoryId` directly — which after D-04 is guaranteed L2, but if the underlying merchantDatabase ever returns L1 again (regression), this branch bypasses `_ensureL2`. Phase 21 should either:
- Route the merchant branch through `resolver.resolve(...)` so `_ensureL2` always runs (cleaner), OR
- Add an arch test that asserts every `_MerchantEntry.categoryId` in `merchant_database.dart` corresponds to a level=2 row in `DefaultCategories.all`.

---

### 10. `lib/infrastructure/ml/merchant_database.dart` (MODIFY — 12 `_MerchantEntry` records)

**Current `_MerchantEntry` literal list — lines 46-119**: 12 entries, three of which reference IDs that don't exist in `default_categories.dart`:

| Line | Merchant | Current `categoryId` | Phase 21 D-04/D-05 target (provisional) |
|---|---|---|---|
| 48-52 | マクドナルド | `cat_food` (L1) | `cat_food_dining_out` |
| 53-58 | スターバックス | `cat_food` (L1) | `cat_food_cafe` |
| 59-64 | 吉野家 | `cat_food` (L1) | `cat_food_dining_out` |
| 65-70 | セブンイレブン | `cat_food` (L1) | `cat_food_groceries` (planner may pick `_dining_out`) |
| 71-76 | ファミリーマート | `cat_food` (L1) | `cat_food_groceries` |
| 77-82 | ローソン | `cat_food` (L1) | `cat_food_groceries` |
| 83-88 | ユニクロ | **`cat_shopping`** (does not exist) | `cat_clothing_clothes` or `cat_clothing_other` |
| 89-94 | ニトリ | `cat_housing` (L1) | `cat_housing_furniture` |
| 95-100 | ヤマダ電機 | **`cat_shopping`** (does not exist) | `cat_housing_appliances` |
| 101-106 | すき家 | `cat_food` (L1) | `cat_food_dining_out` |
| 107-112 | Amazon | **`cat_shopping`** (does not exist) | `cat_daily_other` |
| 113-118 | Netflix | **`cat_entertainment`** (does not exist) | `cat_hobbies_subscription` |

**Pattern to copy** — single `_MerchantEntry` (lines 47-52):

```dart
_MerchantEntry(
  name: 'マクドナルド',
  aliases: ['マック', 'Mac', 'McDonald', 'mcdonalds'],
  categoryId: 'cat_food_dining_out',   // ← was 'cat_food' (L1)
  ledgerType: LedgerType.survival,
),
```

**`findMerchant` 3-stage matching — lines 125-161** is the public surface VoiceCategoryResolver consumes; **DO NOT MODIFY** the matching logic, only the `categoryId` values in the entries above.

**Caveats:**
- `ledgerType` stays as currently set per entry. Some L2 categories (e.g. `cat_clothing_clothes`) have a `CategoryLedgerConfig` override to `survival` (`default_categories.dart:1213-1216`); Yamada Denki's `LedgerType.soul` (line 99) survives because `cat_housing_appliances` has NO override (so it inherits `cat_housing → survival` via `CategoryService.resolveLedgerType`). **Verify ledger inheritance via `CategoryService.resolveLedgerType` test** if the entry's ledgerType disagrees with the L1/L2 config — this is a known consistency surface.
- The `categoryId` for `ヤマダ電機` should resolve to `LedgerType.survival` (cat_housing). The merchant entry's `LedgerType.soul` will be overridden downstream in `ParseVoiceInputUseCase` line 61 (`ledgerType = merchantMatch.ledgerType`), so the merchant entry's value DOES win. Planner should decide whether to keep `soul` semantically or align to the L1's `survival`.

---

### 11. `lib/features/accounting/presentation/providers/repository_providers.dart` (MODIFY)

**Provider to DELETE — lines 219-229:**

```dart
/// FuzzyCategoryMatcher — multi-signal category matcher with learning.
@riverpod
FuzzyCategoryMatcher fuzzyCategoryMatcher(Ref ref) {
  return FuzzyCategoryMatcher(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    preferenceRepository: ref.watch(
      categoryKeywordPreferenceRepositoryProvider,
    ),
    categoryService: ref.watch(categoryServiceProvider),
  );
}
```

**Replacement provider to ADD (mirror the existing `@riverpod` codegen pattern):**

```dart
/// VoiceCategoryResolver — Phase 21 short-circuit pipeline (D-07).
/// Replaces FuzzyCategoryMatcher (deleted in Phase 21 / D-06+D-08).
@riverpod
VoiceCategoryResolver voiceCategoryResolver(Ref ref) {
  return VoiceCategoryResolver(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    preferenceRepository: ref.watch(
      categoryKeywordPreferenceRepositoryProvider,
    ),
    categoryService: ref.watch(categoryServiceProvider),
    merchantDatabase: ref.watch(app_ml.appMerchantDatabaseProvider),
  );
}
```

**Update `parseVoiceInputUseCase` — lines 232-239** to consume the new provider:

```dart
@riverpod
ParseVoiceInputUseCase parseVoiceInputUseCase(Ref ref) {
  return ParseVoiceInputUseCase(
    textParser: ref.watch(voiceTextParserProvider),
    voiceCategoryResolver: ref.watch(voiceCategoryResolverProvider),   // ← was fuzzyCategoryMatcher
    merchantDatabase: ref.watch(app_ml.appMerchantDatabaseProvider),
  );
}
```

**Also seed-wire the synonyms** — add a new use-case provider following the `seedCategoriesUseCase` shape at lines 167-173:

```dart
@riverpod
SeedVoiceSynonymsUseCase seedVoiceSynonymsUseCase(Ref ref) {
  return SeedVoiceSynonymsUseCase(
    preferenceRepository: ref.watch(categoryKeywordPreferenceRepositoryProvider),
  );
}
```

**Caveats:**
- CLAUDE.md "Riverpod 3 conventions" warns that the generator strips `Notifier` suffix — but `voiceCategoryResolver` (function-style provider, NOT a Notifier class) generates `voiceCategoryResolverProvider` straight from the function name. Confirmed by the existing `fuzzyCategoryMatcher` → `fuzzyCategoryMatcherProvider` pattern at line 221+236.
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after this change — `repository_providers.g.dart` will need to be regenerated (CLAUDE.md Pitfall #3 — enforced by AUDIT-10).
- After deletion of `fuzzyCategoryMatcherProvider`, also delete the corresponding test at `/Users/xinz/Development/home-pocket-app/test/unit/features/accounting/presentation/providers/voice_providers_characterization_test.dart:86-89` (the `fuzzyCategoryMatcherProvider constructs FuzzyCategoryMatcher with injected deps` assertion).

---

### 12. `lib/application/voice/levenshtein.dart` (DELETE — verify first)

**Grep verification:**

```
$ grep -rn "levenshtein" lib/ test/
lib/application/voice/levenshtein.dart:6:int levenshteinDistance(String a, String b) {
lib/application/voice/levenshtein.dart:42:  final dist = levenshteinDistance(a, b);
lib/application/voice/fuzzy_category_matcher.dart:6:import 'levenshtein.dart';        ← will be deleted
test/unit/application/voice/levenshtein_test.dart:2:import 'package:home_pocket/application/voice/levenshtein.dart';
test/unit/application/voice/levenshtein_test.dart:5..42  ← test file
```

**Conclusion:** `levenshtein.dart` is ONLY consumed by `fuzzy_category_matcher.dart` (line 6 import) and its own test. After Phase 21 deletes the fuzzy matcher, both `lib/application/voice/levenshtein.dart` AND `test/unit/application/voice/levenshtein_test.dart` (43 lines) can be safely deleted. **Delete both atomically in the same commit** to avoid an orphan-test analyzer warning.

---

### 13. `lib/data/daos/category_keyword_preference_dao.dart` (POSSIBLY MODIFY — verify D-07 ordering)

**Current `findByKeyword` ordering — lines 12-22:**

```dart
Future<List<CategoryKeywordPreferenceRow>> findByKeyword(String keyword) async {
  return (_db.select(_db.categoryKeywordPreferences)
        ..where((t) => t.keyword.equals(keyword))
        ..orderBy([
          (t) =>
              OrderingTerm(expression: t.hitCount, mode: OrderingMode.desc),
        ]))
      .get();
}
```

**D-07 step 2 requires ordering `hitCount DESC, lastUsed DESC`.** Current DAO only orders by `hitCount DESC`. Extend the `orderBy` list:

```dart
..orderBy([
  (t) => OrderingTerm(expression: t.hitCount, mode: OrderingMode.desc),
  (t) => OrderingTerm(expression: t.lastUsed, mode: OrderingMode.desc),   // ← NEW
]))
```

**Repository surface verification — `category_keyword_preference_repository.dart:6` `findByKeyword`** returns a `List<CategoryKeywordPreference>` — resolver takes `.first` per D-07. The `RepositoryImpl` at `/Users/xinz/Development/home-pocket-app/lib/data/repositories/category_keyword_preference_repository_impl.dart:14-18` is a thin pass-through; ordering is preserved through the mapper.

**Alternative — add `findBestForKeyword(keyword)` returning single row** to the DAO. This is cleaner but adds a method to the public interface. Recommended only if multiple call sites need the "best single match" semantics; otherwise let the resolver call `.first` on `findByKeyword`.

**Caveats:**
- The DAO's `decayStalePreferences` (lines 71-90) decrements `hitCount` for stale entries. If `hitCount=0` seeds are ever marked stale (lastUsed far in the past), the decay path could DELETE them (line 73-80 deletes entries with `hitCount <= 1`). **Phase 21 must verify that seed rows with `hitCount=0` are NOT erased by the decay path.** Two options:
  1. Exclude `hitCount=0` rows from decay deletion (add `& t.hitCount.isBiggerThan(const Variable(0))` to the WHERE clause at line 73-79).
  2. Set seed `lastUsed` to `DateTime.now()` at seed time (current `DefaultVoiceSynonyms._epoch = 2026-01-01` may already be stale relative to decay duration).
  Recommendation: option 1 — semantic protection beats temporal protection.

---

### 14. `lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart` (VERIFY ONLY)

**Current interface — lines 4-21:**

```dart
abstract class CategoryKeywordPreferenceRepository {
  Future<List<CategoryKeywordPreference>> findByKeyword(String keyword);
  Future<void> recordCorrection({
    required String keyword,
    required String categoryId,
  });
  Future<CategoryKeywordPreference?> suggestForKeyword(String keyword);
  Future<void> decayStalePreferences(Duration staleDuration);
}
```

**Phase 21 needs:** existing `findByKeyword` (returns ordered list) is sufficient for D-07 step 2 if the DAO ordering is fixed. May want to add:

```dart
/// Phase 21: batch insert seed rows with hitCount=0 sentinel.
/// Used by SeedVoiceSynonymsUseCase. Idempotent — uses INSERT OR IGNORE.
Future<void> insertSeedBatch(List<CategoryKeywordPreference> seeds);
```

if the planner opts for batch-insert semantics (cleaner than per-row `recordCorrection` calls that increment `hitCount` to 1 instead of leaving 0).

---

## Shared Patterns

### Pattern A: Riverpod 3 `@riverpod` codegen + `repository_providers.dart` single-source-of-truth

**Source:** `lib/features/accounting/presentation/providers/repository_providers.dart` (entire file, especially lines 49-117 for repository providers and 167-205 for use-case providers)
**Apply to:** the new `voiceCategoryResolverProvider` and `seedVoiceSynonymsUseCaseProvider`

```dart
@riverpod
RepositoryOrUseCaseType providerName(Ref ref) {
  return RepositoryOrUseCaseType(
    dep1: ref.watch(dep1Provider),
    dep2: ref.watch(dep2Provider),
  );
}
```

Generated provider name = function name + `Provider` (e.g. `voiceCategoryResolver` → `voiceCategoryResolverProvider`). CLAUDE.md notes the `Notifier` suffix is stripped for class-style providers, but function-style providers are stable.

### Pattern B: Idempotent first-launch seeder

**Source:** `lib/application/accounting/seed_categories_use_case.dart:20-29`
**Apply to:** `SeedVoiceSynonymsUseCase.execute()`

```dart
Future<Result<void>> execute() async {
  final existing = await _repo.findAll();   // or .findByKeyword(probe)
  if (existing.isNotEmpty) {
    return Result.success(null);            // already seeded — short-circuit
  }
  await _repo.insertBatch(DefaultThings.all);
  return Result.success(null);
}
```

### Pattern C: Mocktail unit test scaffold

**Source:** `test/unit/application/voice/fuzzy_category_matcher_test.dart:1-50`
**Apply to:** `test/unit/application/voice/voice_category_resolver_test.dart`

Three building blocks:
1. `class _MockX extends Mock implements X {}` declarations (lines 11-16)
2. Factory helper for domain models (`_makeCategory`, lines 18-33)
3. `late` field + `setUp(() { mock = _MockX(); resolver = ... })` (lines 36-50)

### Pattern D: Per-locale corpus test with strict anchors + statistical bucket

**Source:** `test/integration/voice/voice_corpus_zh_test.dart` (89 lines, full file)
**Apply to:** both new corpus tests

Three building blocks:
1. Anchor cases: filter by `note?.startsWith('anchor:')`, strict `expect()` inside individual `test()` blocks
2. Statistical bucket: non-anchor cases, soft `printOnFailure` on mismatch, aggregate `passCount/totalCount`
3. `tearDownAll`: print formatted accuracy summary + `expect(ratio, greaterThanOrEqualTo(0.95))`

The `// ignore: avoid_print` markers on lines 64, 76, 78, 80 are intentional and already accepted by `stale_suppressions_scan_test.dart` per VOICE-SCANNER-ALLOWLIST (STATE.md, commit `f04b978`).

### Pattern E: Architecture test (filesystem or constant iteration)

**Source:** `test/architecture/mod009_live_lib_scan_test.dart` (35 lines, full file) + `test/unit/shared/constants/default_categories_test.dart:97-110`
**Apply to:** `test/architecture/category_other_l2_invariant_test.dart`

Architecture tests are colocated in `test/architecture/` and use direct iteration over `DefaultCategories.all` (no Riverpod scope needed for pure data invariants).

### Pattern F: Always use `S.of(context)` for UI strings; no UI in Phase 21

Phase 21 has NO UI work. Voice screen consumes resolver via `ParseVoiceInputUseCase` (Phase 22 will wire to shared details form). No ARB changes required.

---

## No Analog Found

| File | Role | Data Flow | Reason / Mitigation |
|---|---|---|---|
| `assets/voice/synonyms_seed.yaml` (planner-alternative) | YAML asset seed | first-launch read | No asset is loaded today in the project. Defaulting to Dart-literal `default_synonyms.dart` (D-01) avoids introducing a new pattern. If YAML is chosen anyway, planner must establish: (a) pubspec.yaml asset entry, (b) `rootBundle.loadString('assets/voice/synonyms_seed.yaml')` call site, (c) `yaml` package parse, (d) a test that the YAML parses cleanly. **Recommendation: do NOT take the YAML path.** |

---

## Files Phase 21 SHOULD NOT Touch (per CLAUDE.md / cross-cutting constraints)

- `lib/data/tables/category_keyword_preferences_table.dart` — schema stays v17 (no migration per CONTEXT scope §Out of scope). The table already has `hitCount` and `lastUsed` columns + `(keyword, categoryId)` PK.
- `lib/data/app_database.dart` — no schema bump, no new DAO registration if existing DAO covers the surface.
- `lib/main.dart` — only one line will change (add `seedVoiceSynonymsUseCase.execute()` after `seedCategories.execute()` at line 107); preserve all other initialization order.
- Anything in `lib/features/` other than `repository_providers.dart` — the resolver is application-layer; presentation widgets do not change (Phase 22 wires them).
- All `.g.dart` and `.freezed.dart` files — regenerated by `build_runner`, never hand-edited (CLAUDE.md Pitfall #1).

---

## Metadata

- **Analog search scope:** `lib/application/voice/`, `lib/application/accounting/`, `lib/infrastructure/ml/`, `lib/data/{daos,repositories,tables}/`, `lib/features/accounting/{domain,presentation/providers}/`, `lib/shared/constants/`, `test/{unit,integration,fixtures,architecture}/{voice,application,shared}/`
- **Files scanned:** ~25 (with deduplication on overlapping reads)
- **Pattern extraction date:** 2026-05-24
- **CONTEXT.md base commit:** Phase 21 context per `.planning/STATE.md` "Phase 21 context gathered" 2026-05-24
- **Phase 20 inheritance:** corpus fixture shape (`VoiceCorpusCase`-style record + `voice_corpus_{zh,ja}.dart` + per-locale `_test.dart` files + ≥95% gate + `// ignore: avoid_print` allow-list) mirrors Phase 20 exactly. The VOICE-SCANNER-ALLOWLIST accepts new entries; planner must add the new test files to the same allow-list pattern.

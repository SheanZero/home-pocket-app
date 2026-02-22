# Fuzzy Category Matching Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the hardcoded keyword-only `CategoryMatcher` with a multi-signal `FuzzyCategoryMatcher` that supports fuzzy edit-distance matching, user-added L2 category matching, and adaptive learning from user corrections.

**Architecture:** Three scoring signals (seed keywords, Levenshtein edit distance against DB category names, user-learned mappings) feed into a max-wins score aggregator. A new `CategoryKeywordPreferences` Drift table stores learned keyword→category mappings with hit counts. Corrections are recorded when users change the auto-matched category on TransactionConfirmScreen.

**Tech Stack:** Pure Dart (Levenshtein), Drift/SQLCipher (learning table), Riverpod (providers), Freezed (domain models)

**Design Doc:** `docs/plans/2026-02-22-fuzzy-category-matching-design.md`

---

## Task 1: Levenshtein Distance Algorithm

**Files:**
- Create: `lib/application/voice/levenshtein.dart`
- Test: `test/unit/application/voice/levenshtein_test.dart`

**Step 1: Write failing tests**

```dart
// test/unit/application/voice/levenshtein_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/levenshtein.dart';

void main() {
  group('levenshteinDistance', () {
    test('identical strings return 0', () {
      expect(levenshteinDistance('abc', 'abc'), 0);
    });

    test('empty vs non-empty returns length', () {
      expect(levenshteinDistance('', 'abc'), 3);
      expect(levenshteinDistance('abc', ''), 3);
    });

    test('both empty returns 0', () {
      expect(levenshteinDistance('', ''), 0);
    });

    test('single insertion', () {
      expect(levenshteinDistance('abc', 'abcd'), 1);
    });

    test('single deletion', () {
      expect(levenshteinDistance('abcd', 'abc'), 1);
    });

    test('single substitution', () {
      expect(levenshteinDistance('abc', 'axc'), 1);
    });

    test('kitten vs sitting = 3', () {
      expect(levenshteinDistance('kitten', 'sitting'), 3);
    });

    test('Japanese strings', () {
      // 朝ごはん vs 朝御飯 (speech recognition error)
      expect(levenshteinDistance('朝ごはん', '朝御飯'), 3);
    });

    test('Chinese strings', () {
      // 咖啡 vs 咖啡厅
      expect(levenshteinDistance('咖啡', '咖啡厅'), 1);
    });
  });

  group('normalizedSimilarity', () {
    test('identical strings return 1.0', () {
      expect(normalizedSimilarity('abc', 'abc'), 1.0);
    });

    test('both empty returns 1.0', () {
      expect(normalizedSimilarity('', ''), 1.0);
    });

    test('completely different returns 0.0', () {
      expect(normalizedSimilarity('abc', 'xyz'), 0.0);
    });

    test('one empty returns 0.0', () {
      expect(normalizedSimilarity('abc', ''), 0.0);
    });

    test('咖啡 vs 咖啡厅 similarity ~0.67', () {
      final sim = normalizedSimilarity('咖啡', '咖啡厅');
      expect(sim, closeTo(0.667, 0.01));
    });

    test('lunch vs lunhc (typo) similarity = 0.6', () {
      final sim = normalizedSimilarity('lunch', 'lunhc');
      expect(sim, closeTo(0.6, 0.01));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/voice/levenshtein_test.dart`
Expected: FAIL — `levenshtein.dart` does not exist

**Step 3: Write implementation**

```dart
// lib/application/voice/levenshtein.dart
import 'dart:math';

/// Computes the Levenshtein edit distance between two strings.
///
/// Uses O(min(n,m)) space via a rolling single-row DP approach.
int levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  // Ensure a is the shorter string for O(min(n,m)) space
  if (a.length > b.length) {
    final tmp = a;
    a = b;
    b = tmp;
  }

  final aLen = a.length;
  final bLen = b.length;
  var prev = List<int>.generate(aLen + 1, (i) => i);
  var curr = List<int>.filled(aLen + 1, 0);

  for (var j = 1; j <= bLen; j++) {
    curr[0] = j;
    for (var i = 1; i <= aLen; i++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[i] = min(
        min(curr[i - 1] + 1, prev[i] + 1),
        prev[i - 1] + cost,
      );
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }

  return prev[aLen];
}

/// Returns a similarity score between 0.0 (completely different) and
/// 1.0 (identical), computed as `1 - (editDistance / maxLength)`.
double normalizedSimilarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;
  final dist = levenshteinDistance(a, b);
  return 1.0 - (dist / max(a.length, b.length));
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/application/voice/levenshtein_test.dart`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/application/voice/levenshtein.dart test/unit/application/voice/levenshtein_test.dart
git commit -m "feat(voice): add Levenshtein edit distance algorithm"
```

---

## Task 2: Add `learning` to MatchSource enum

**Files:**
- Modify: `lib/features/accounting/domain/models/voice_parse_result.dart:42-46`

**Step 1: Update the enum**

In `lib/features/accounting/domain/models/voice_parse_result.dart`, change:

```dart
/// How the category match was derived.
enum MatchSource {
  merchant, // matched via MerchantDatabase
  keyword, // matched via keyword map
  fallback, // default fallback
}
```

To:

```dart
/// How the category match was derived.
enum MatchSource {
  merchant, // matched via MerchantDatabase
  keyword, // matched via keyword map
  learning, // matched via user correction history
  fallback, // default fallback
}
```

**Step 2: Regenerate Freezed code**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Succeeds, `voice_parse_result.freezed.dart` regenerated

**Step 3: Run existing tests to verify nothing breaks**

Run: `flutter test test/unit/application/voice/`
Expected: All existing voice tests PASS

**Step 4: Commit**

```bash
git add lib/features/accounting/domain/models/voice_parse_result.dart lib/features/accounting/domain/models/voice_parse_result.freezed.dart
git commit -m "feat(voice): add learning source to MatchSource enum"
```

---

## Task 3: CategoryKeywordPreference Data Layer

This task creates 5 files following the exact pattern of `MerchantCategoryPreference`.

**Files:**
- Create: `lib/data/tables/category_keyword_preferences_table.dart`
- Create: `lib/data/daos/category_keyword_preference_dao.dart`
- Create: `lib/features/accounting/domain/models/category_keyword_preference.dart`
- Create: `lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart`
- Create: `lib/data/repositories/category_keyword_preference_repository_impl.dart`
- Modify: `lib/data/app_database.dart` (add table + schema v7)
- Test: `test/unit/data/daos/category_keyword_preference_dao_test.dart`

### Step 1: Create the Drift table

```dart
// lib/data/tables/category_keyword_preferences_table.dart
import 'package:drift/drift.dart';

/// Stores learned keyword→category mappings from user corrections.
///
/// Primary key is (keyword, categoryId) — one row per unique mapping.
/// hitCount tracks how many times the user selected this mapping;
/// after hitCount >= 2 the mapping is considered "learned".
@DataClassName('CategoryKeywordPreferenceRow')
class CategoryKeywordPreferences extends Table {
  /// Normalized keyword extracted from voice input.
  TextColumn get keyword => text()();

  /// The category ID the user corrected to.
  TextColumn get categoryId => text()();

  /// Number of times the user selected this mapping.
  IntColumn get hitCount => integer().withDefault(const Constant(1))();

  /// When this mapping was last used/updated.
  DateTimeColumn get lastUsed => dateTime()();

  @override
  Set<Column> get primaryKey => {keyword, categoryId};

  List<TableIndex> get customIndices => [
    TableIndex(
      name: 'idx_keyword_prefs_keyword',
      columns: {#keyword},
    ),
  ];
}
```

### Step 2: Create the DAO

```dart
// lib/data/daos/category_keyword_preference_dao.dart
import 'package:drift/drift.dart';

import '../app_database.dart';

/// Data access object for [CategoryKeywordPreferences] table.
class CategoryKeywordPreferenceDao {
  CategoryKeywordPreferenceDao(this._db);

  final AppDatabase _db;

  /// Find all learned mappings for a keyword.
  Future<List<CategoryKeywordPreferenceRow>> findByKeyword(
    String keyword,
  ) async {
    return (_db.select(_db.categoryKeywordPreferences)
          ..where((t) => t.keyword.equals(keyword))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.hitCount,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// Find a specific keyword→categoryId mapping.
  Future<CategoryKeywordPreferenceRow?> findByKeywordAndCategory(
    String keyword,
    String categoryId,
  ) async {
    return (_db.select(_db.categoryKeywordPreferences)
          ..where(
            (t) =>
                t.keyword.equals(keyword) & t.categoryId.equals(categoryId),
          ))
        .getSingleOrNull();
  }

  /// Upsert a keyword→category preference.
  ///
  /// If the mapping exists, increments hitCount and updates lastUsed.
  /// If not, inserts with hitCount=1.
  Future<void> upsert({
    required String keyword,
    required String categoryId,
  }) async {
    final existing = await findByKeywordAndCategory(keyword, categoryId);
    final now = DateTime.now();

    if (existing != null) {
      await (_db.update(_db.categoryKeywordPreferences)
            ..where(
              (t) =>
                  t.keyword.equals(keyword) & t.categoryId.equals(categoryId),
            ))
          .write(
        CategoryKeywordPreferencesCompanion(
          hitCount: Value(existing.hitCount + 1),
          lastUsed: Value(now),
        ),
      );
    } else {
      await _db.into(_db.categoryKeywordPreferences).insert(
            CategoryKeywordPreferencesCompanion.insert(
              keyword: keyword,
              categoryId: categoryId,
              lastUsed: now,
            ),
          );
    }
  }

  /// Decay stale preferences: reduce hitCount by 1 for entries not used
  /// within [staleDuration]. Entries that reach hitCount=0 are deleted.
  Future<void> decayStalePreferences(Duration staleDuration) async {
    final cutoff = DateTime.now().subtract(staleDuration);

    // Delete entries with hitCount <= 1 that are stale
    await (_db.delete(_db.categoryKeywordPreferences)
          ..where(
            (t) =>
                t.lastUsed.isSmallerThan(Variable(cutoff)) &
                t.hitCount.isSmallerOrEqual(const Variable(1)),
          ))
        .go();

    // Decrement hitCount for remaining stale entries
    await _db.customUpdate(
      'UPDATE category_keyword_preferences '
      'SET hit_count = hit_count - 1 '
      'WHERE last_used < ?',
      variables: [Variable(cutoff)],
      updates: {_db.categoryKeywordPreferences},
    );
  }

  /// Delete all preferences (for testing/reset).
  Future<void> deleteAll() =>
      _db.delete(_db.categoryKeywordPreferences).go();
}
```

### Step 3: Create the domain model

```dart
// lib/features/accounting/domain/models/category_keyword_preference.dart

/// A learned keyword→category mapping from user voice input corrections.
class CategoryKeywordPreference {
  const CategoryKeywordPreference({
    required this.keyword,
    required this.categoryId,
    required this.hitCount,
    required this.lastUsed,
  });

  /// The normalized keyword from voice input.
  final String keyword;

  /// The category ID the user corrected to.
  final String categoryId;

  /// How many times the user selected this mapping.
  final int hitCount;

  /// When this mapping was last used.
  final DateTime lastUsed;

  /// Whether this mapping is "fully learned" (hitCount >= 2).
  bool get isLearned => hitCount >= 2;

  /// Score bonus for this learned mapping.
  /// hitCount >= 2 → 0.30 (fully learned)
  /// hitCount == 1 → 0.15 (partial)
  double get scoreBonus => isLearned ? 0.30 : 0.15;
}
```

### Step 4: Create the repository interface

```dart
// lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart

import '../models/category_keyword_preference.dart';

/// Repository interface for keyword→category learning data.
abstract class CategoryKeywordPreferenceRepository {
  /// Find all learned mappings for a given keyword.
  Future<List<CategoryKeywordPreference>> findByKeyword(String keyword);

  /// Record a user correction: keyword was mapped to categoryId.
  /// Increments hitCount if mapping already exists.
  Future<void> recordCorrection({
    required String keyword,
    required String categoryId,
  });

  /// Suggest the best category for a keyword based on learning data.
  /// Returns null if no learned mapping exists.
  Future<CategoryKeywordPreference?> suggestForKeyword(String keyword);

  /// Decay stale preferences older than [staleDuration].
  Future<void> decayStalePreferences(Duration staleDuration);
}
```

### Step 5: Create the repository implementation

```dart
// lib/data/repositories/category_keyword_preference_repository_impl.dart

import '../../features/accounting/domain/models/category_keyword_preference.dart';
import '../../features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import '../app_database.dart';
import '../daos/category_keyword_preference_dao.dart';

class CategoryKeywordPreferenceRepositoryImpl
    implements CategoryKeywordPreferenceRepository {
  CategoryKeywordPreferenceRepositoryImpl({
    required CategoryKeywordPreferenceDao dao,
  }) : _dao = dao;

  final CategoryKeywordPreferenceDao _dao;

  @override
  Future<List<CategoryKeywordPreference>> findByKeyword(
    String keyword,
  ) async {
    final rows = await _dao.findByKeyword(keyword);
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> recordCorrection({
    required String keyword,
    required String categoryId,
  }) async {
    await _dao.upsert(keyword: keyword, categoryId: categoryId);
  }

  @override
  Future<CategoryKeywordPreference?> suggestForKeyword(
    String keyword,
  ) async {
    final rows = await _dao.findByKeyword(keyword);
    if (rows.isEmpty) return null;
    // Return highest hitCount entry (already ordered by DAO)
    return _toModel(rows.first);
  }

  @override
  Future<void> decayStalePreferences(Duration staleDuration) async {
    await _dao.decayStalePreferences(staleDuration);
  }

  CategoryKeywordPreference _toModel(CategoryKeywordPreferenceRow row) {
    return CategoryKeywordPreference(
      keyword: row.keyword,
      categoryId: row.categoryId,
      hitCount: row.hitCount,
      lastUsed: row.lastUsed,
    );
  }
}
```

### Step 6: Update app_database.dart — add table and bump schema

In `lib/data/app_database.dart`:

Add import at top:
```dart
import 'tables/category_keyword_preferences_table.dart';
```

Add to `@DriftDatabase` tables list:
```dart
@DriftDatabase(
  tables: [
    AuditLogs,
    Books,
    Categories,
    CategoryLedgerConfigs,
    CategoryKeywordPreferences,  // NEW
    MerchantCategoryPreferences,
    Transactions,
  ],
)
```

Bump schema version:
```dart
@override
int get schemaVersion => 7;  // was 6
```

Add migration step inside `onUpgrade`:
```dart
if (from < 7) {
  await migrator.createTable(categoryKeywordPreferences);
}
```

### Step 7: Run code generation

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Succeeds, `app_database.g.dart` regenerated with new table

### Step 8: Write DAO tests

```dart
// test/unit/data/daos/category_keyword_preference_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_keyword_preference_dao.dart';

void main() {
  late AppDatabase db;
  late CategoryKeywordPreferenceDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = CategoryKeywordPreferenceDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryKeywordPreferenceDao', () {
    test('upsert creates new entry with hitCount 1', () async {
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');

      final results = await dao.findByKeyword('咖啡');
      expect(results, hasLength(1));
      expect(results.first.keyword, '咖啡');
      expect(results.first.categoryId, 'cat_food');
      expect(results.first.hitCount, 1);
    });

    test('upsert increments hitCount on duplicate', () async {
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');

      final results = await dao.findByKeyword('咖啡');
      expect(results, hasLength(1));
      expect(results.first.hitCount, 2);
    });

    test('upsert different category creates separate entry', () async {
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_entertainment');

      final results = await dao.findByKeyword('咖啡');
      expect(results, hasLength(2));
    });

    test('findByKeyword returns ordered by hitCount desc', () async {
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_entertainment');
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_entertainment');

      final results = await dao.findByKeyword('咖啡');
      expect(results.first.categoryId, 'cat_entertainment');
      expect(results.first.hitCount, 2);
    });

    test('findByKeyword returns empty for unknown keyword', () async {
      final results = await dao.findByKeyword('unknown');
      expect(results, isEmpty);
    });

    test('findByKeywordAndCategory returns specific entry', () async {
      await dao.upsert(keyword: '咖啡', categoryId: 'cat_food');

      final result =
          await dao.findByKeywordAndCategory('咖啡', 'cat_food');
      expect(result, isNotNull);
      expect(result!.hitCount, 1);

      final missing =
          await dao.findByKeywordAndCategory('咖啡', 'cat_nope');
      expect(missing, isNull);
    });

    test('deleteAll clears all entries', () async {
      await dao.upsert(keyword: 'a', categoryId: 'b');
      await dao.upsert(keyword: 'c', categoryId: 'd');

      await dao.deleteAll();

      final results = await dao.findByKeyword('a');
      expect(results, isEmpty);
    });
  });
}
```

**Step 9: Run tests**

Run: `flutter test test/unit/data/daos/category_keyword_preference_dao_test.dart`
Expected: All PASS

**Step 10: Commit**

```bash
git add \
  lib/data/tables/category_keyword_preferences_table.dart \
  lib/data/daos/category_keyword_preference_dao.dart \
  lib/features/accounting/domain/models/category_keyword_preference.dart \
  lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart \
  lib/data/repositories/category_keyword_preference_repository_impl.dart \
  lib/data/app_database.dart \
  lib/data/app_database.g.dart \
  test/unit/data/daos/category_keyword_preference_dao_test.dart
git commit -m "feat(data): add CategoryKeywordPreferences table, DAO, repo for voice learning"
```

---

## Task 4: FuzzyCategoryMatcher

The core multi-signal matching engine.

**Files:**
- Create: `lib/application/voice/fuzzy_category_matcher.dart`
- Test: `test/unit/application/voice/fuzzy_category_matcher_test.dart`

**Step 1: Write failing tests**

```dart
// test/unit/application/voice/fuzzy_category_matcher_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/fuzzy_category_matcher.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_keyword_preference.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:home_pocket/application/accounting/category_service.dart';

@GenerateMocks([
  CategoryRepository,
  CategoryKeywordPreferenceRepository,
  CategoryService,
])
import 'fuzzy_category_matcher_test.mocks.dart';

Category _makeCategory(String id, String name, {int level = 2, String? parentId}) {
  return Category(
    id: id,
    name: name,
    icon: 'food',
    color: '#FF0000',
    level: level,
    parentId: parentId,
    createdAt: DateTime(2026),
  );
}

void main() {
  late MockCategoryRepository mockCategoryRepo;
  late MockCategoryKeywordPreferenceRepository mockPrefRepo;
  late MockCategoryService mockCategoryService;
  late FuzzyCategoryMatcher matcher;

  setUp(() {
    mockCategoryRepo = MockCategoryRepository();
    mockPrefRepo = MockCategoryKeywordPreferenceRepository();
    mockCategoryService = MockCategoryService();
    matcher = FuzzyCategoryMatcher(
      categoryRepository: mockCategoryRepo,
      preferenceRepository: mockPrefRepo,
      categoryService: mockCategoryService,
    );
  });

  group('Signal 1: Seed keyword match', () {
    test('exact keyword match returns category with high confidence', () async {
      when(mockCategoryRepo.findById('cat_food_breakfast'))
          .thenAnswer((_) async => _makeCategory('cat_food_breakfast', '朝食'));
      when(mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(mockPrefRepo.findByKeyword(any)).thenAnswer((_) async => []);

      final result = await matcher.match('朝ごはん500円', '朝ごはん');
      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food_breakfast');
      expect(result.source, MatchSource.keyword);
    });
  });

  group('Signal 2: Edit distance match', () {
    test('fuzzy match against DB category name', () async {
      // No seed keyword match for "咖啡厅"
      when(mockCategoryRepo.findAll()).thenAnswer((_) async => [
            _makeCategory('cat_custom_cafe', '咖啡厅', parentId: 'cat_food'),
          ]);
      when(mockCategoryRepo.findById(any)).thenAnswer((_) async => null);
      when(mockPrefRepo.findByKeyword(any)).thenAnswer((_) async => []);

      final result = await matcher.match('咖啡500円', '咖啡');
      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_custom_cafe');
    });
  });

  group('Signal 3: Learned mapping', () {
    test('learned mapping boosts score to override seed keyword', () async {
      // Seed keyword would match cat_food for '咖啡'
      when(mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => _makeCategory('cat_food', '食費', level: 1));
      when(mockCategoryRepo.findById('cat_entertainment_cafe'))
          .thenAnswer((_) async =>
              _makeCategory('cat_entertainment_cafe', 'カフェ', parentId: 'cat_entertainment'));
      when(mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(mockPrefRepo.findByKeyword('咖啡')).thenAnswer((_) async => [
            CategoryKeywordPreference(
              keyword: '咖啡',
              categoryId: 'cat_entertainment_cafe',
              hitCount: 2,
              lastUsed: DateTime.now(),
            ),
          ]);

      final result = await matcher.match('咖啡500円', '咖啡');
      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_entertainment_cafe');
      expect(result.source, MatchSource.learning);
    });
  });

  group('Edge cases', () {
    test('empty keyword returns null', () async {
      when(mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(mockPrefRepo.findByKeyword(any)).thenAnswer((_) async => []);

      final result = await matcher.match('500円', '');
      expect(result, isNull);
    });

    test('no match from any signal returns null', () async {
      when(mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(mockCategoryRepo.findById(any)).thenAnswer((_) async => null);
      when(mockPrefRepo.findByKeyword(any)).thenAnswer((_) async => []);

      final result = await matcher.match('xyzzyx', 'xyzzyx');
      expect(result, isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter test test/unit/application/voice/fuzzy_category_matcher_test.dart`
Expected: FAIL — `fuzzy_category_matcher.dart` does not exist

**Step 3: Write implementation**

```dart
// lib/application/voice/fuzzy_category_matcher.dart
import 'dart:math';

import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../accounting/category_service.dart';
import 'levenshtein.dart';

/// Multi-signal category matcher for voice input.
///
/// Runs three scoring signals in parallel and picks the highest match:
/// 1. Seed keyword match (existing hardcoded keyword map)
/// 2. Edit distance match (fuzzy against DB category names)
/// 3. User learned mapping (from correction history)
class FuzzyCategoryMatcher {
  final CategoryRepository _categoryRepository;
  final CategoryKeywordPreferenceRepository _preferenceRepository;
  final CategoryService _categoryService;

  FuzzyCategoryMatcher({
    required CategoryRepository categoryRepository,
    required CategoryKeywordPreferenceRepository preferenceRepository,
    required CategoryService categoryService,
  })  : _categoryRepository = categoryRepository,
        _preferenceRepository = preferenceRepository,
        _categoryService = categoryService;

  /// Matches [inputText] to a category using multi-signal scoring.
  ///
  /// [extractedKeyword] is the category-relevant word extracted from input
  /// (with amount, date, merchant removed).
  /// Returns null if no signal produces a match.
  Future<CategoryMatchResult?> match(
    String inputText,
    String extractedKeyword,
  ) async {
    if (extractedKeyword.isEmpty && inputText.isEmpty) return null;

    final keyword =
        extractedKeyword.isNotEmpty ? extractedKeyword : inputText;

    // Run all three signals
    final seedResult = await _matchSeedKeywords(inputText);
    final editDistResult = await _matchEditDistance(keyword);
    final learnedResult = await _matchLearned(keyword);

    // Collect all candidates with their scores
    final candidates = <_ScoredCandidate>[];

    if (seedResult != null) {
      candidates.add(_ScoredCandidate(
        categoryId: seedResult.categoryId,
        baseScore: seedResult.confidence,
        source: MatchSource.keyword,
      ));
    }

    if (editDistResult != null) {
      candidates.add(_ScoredCandidate(
        categoryId: editDistResult.categoryId,
        baseScore: editDistResult.confidence,
        source: MatchSource.keyword, // edit distance is still keyword-based
      ));
    }

    if (learnedResult != null) {
      candidates.add(_ScoredCandidate(
        categoryId: learnedResult.categoryId,
        baseScore: learnedResult.confidence,
        source: MatchSource.learning,
      ));
    }

    if (candidates.isEmpty) return null;

    // Apply learning bonus: if a learned mapping exists for this keyword,
    // boost candidates that match the learned categoryId.
    final learnedPrefs = await _preferenceRepository.findByKeyword(keyword);
    for (final candidate in candidates) {
      for (final pref in learnedPrefs) {
        if (pref.categoryId == candidate.categoryId) {
          candidate.learningBonus = pref.scoreBonus;
          if (pref.isLearned) {
            candidate.source = MatchSource.learning;
          }
        }
      }
    }

    // Pick highest scoring candidate
    candidates.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    final best = candidates.first;

    // Minimum threshold: 0.5
    if (best.finalScore < 0.5) return null;

    return CategoryMatchResult(
      categoryId: best.categoryId,
      confidence: best.finalScore.clamp(0.0, 1.0),
      source: best.source,
    );
  }

  /// Resolves the ledger type for [categoryId].
  Future<LedgerType?> resolveLedgerType(String categoryId) async {
    return _categoryService.resolveLedgerType(categoryId);
  }

  // ── Signal 1: Seed Keyword Match ──

  /// Matches text against the hardcoded seed keyword map.
  Future<CategoryMatchResult?> _matchSeedKeywords(String text) async {
    final lowerText = text.toLowerCase();
    CategoryMatchResult? bestMatch;

    for (final entry in _seedKeywordMap.entries) {
      if (lowerText.contains(entry.key.toLowerCase())) {
        final mapping = entry.value;
        final subId = mapping.sub;

        // Validate sub-category exists; fall back to L1 if not
        String effectiveId = mapping.categoryId;
        if (subId != null) {
          final subCategory = await _categoryRepository.findById(subId);
          if (subCategory != null) {
            effectiveId = subId;
          }
        } else {
          final category =
              await _categoryRepository.findById(mapping.categoryId);
          if (category == null) continue;
        }

        if (bestMatch == null || mapping.confidence > bestMatch.confidence) {
          bestMatch = CategoryMatchResult(
            categoryId: effectiveId,
            confidence: mapping.confidence,
            source: MatchSource.keyword,
          );
        }
      }
    }

    return bestMatch;
  }

  // ── Signal 2: Edit Distance Match ──

  /// Fuzzy-matches keyword against all category names in the database.
  Future<CategoryMatchResult?> _matchEditDistance(String keyword) async {
    if (keyword.isEmpty) return null;

    final categories = await _categoryRepository.findAll();
    CategoryMatchResult? bestMatch;

    // Short tokens need higher threshold to avoid false positives
    final threshold = keyword.length <= 2 ? 0.8 : 0.6;

    for (final category in categories) {
      if (category.isArchived) continue;

      final similarity = normalizedSimilarity(
        keyword.toLowerCase(),
        category.name.toLowerCase(),
      );

      if (similarity >= threshold) {
        final score = similarity * 0.85; // scale factor
        if (bestMatch == null || score > bestMatch.confidence) {
          bestMatch = CategoryMatchResult(
            categoryId: category.id,
            confidence: score,
            source: MatchSource.keyword,
          );
        }
      }
    }

    return bestMatch;
  }

  // ── Signal 3: Learned Mapping ──

  /// Looks up learned preference for this keyword.
  Future<CategoryMatchResult?> _matchLearned(String keyword) async {
    if (keyword.isEmpty) return null;

    final pref = await _preferenceRepository.suggestForKeyword(keyword);
    if (pref == null) return null;

    // Validate category still exists
    final category = await _categoryRepository.findById(pref.categoryId);
    if (category == null) return null;

    // Base score from keyword or edit distance (use 0.85 as baseline)
    // Plus learning bonus
    return CategoryMatchResult(
      categoryId: pref.categoryId,
      confidence: (0.85 + pref.scoreBonus).clamp(0.0, 1.0),
      source: MatchSource.learning,
    );
  }

  // ── Seed keyword map (migrated from CategoryMatcher) ──

  static const Map<String, _KeywordMapping> _seedKeywordMap = {
    // ===== Food =====
    // Japanese
    '朝ごはん': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '朝食': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '昼ごはん': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '昼食': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    'ランチ': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '晩ごはん': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '夕食': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '夕飯': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '食事': _KeywordMapping('cat_food', 0.85),
    'ご飯': _KeywordMapping('cat_food', 0.85),
    '弁当': _KeywordMapping('cat_food', 0.85),
    'コーヒー': _KeywordMapping('cat_food', 0.80),
    'カフェ': _KeywordMapping('cat_food', 0.80),
    'おやつ': _KeywordMapping('cat_food', 0.80),
    // Chinese
    '早饭': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '早餐': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    '午饭': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '午餐': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    '晚饭': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '晚餐': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    '吃饭': _KeywordMapping('cat_food', 0.85),
    '外卖': _KeywordMapping('cat_food', 0.85),
    '咖啡': _KeywordMapping('cat_food', 0.80),
    // English
    'breakfast': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_breakfast'),
    'lunch': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_lunch'),
    'dinner': _KeywordMapping('cat_food', 0.90, sub: 'cat_food_dinner'),
    'food': _KeywordMapping('cat_food', 0.85),
    'coffee': _KeywordMapping('cat_food', 0.80),
    'cafe': _KeywordMapping('cat_food', 0.80),

    // ===== Transport =====
    '電車': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    '電車代': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    'バス': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    'バス代': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    'タクシー': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_taxi'),
    '交通費': _KeywordMapping('cat_transport', 0.95),
    '定期': _KeywordMapping('cat_transport', 0.85),
    'Suica': _KeywordMapping('cat_transport', 0.85),
    'PASMO': _KeywordMapping('cat_transport', 0.85),
    '地铁': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    '公交': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    '打车': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_taxi'),
    'train': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_commute'),
    'bus': _KeywordMapping('cat_transport', 0.90, sub: 'cat_transport_commute'),
    'taxi': _KeywordMapping('cat_transport', 0.95, sub: 'cat_transport_taxi'),

    // ===== Shopping =====
    '服': _KeywordMapping('cat_shopping', 0.80),
    '洋服': _KeywordMapping('cat_shopping', 0.85),
    '靴': _KeywordMapping('cat_shopping', 0.85),
    '衣服': _KeywordMapping('cat_shopping', 0.85),
    '鞋子': _KeywordMapping('cat_shopping', 0.85),
    'clothes': _KeywordMapping('cat_shopping', 0.85),
    'shoes': _KeywordMapping('cat_shopping', 0.85),

    // ===== Education =====
    '本': _KeywordMapping('cat_education', 0.80),
    '书': _KeywordMapping('cat_education', 0.80),
    'book': _KeywordMapping('cat_education', 0.80),

    // ===== Entertainment =====
    '映画': _KeywordMapping('cat_entertainment', 0.95),
    'ゲーム': _KeywordMapping('cat_entertainment', 0.90),
    'カラオケ': _KeywordMapping('cat_entertainment', 0.95),
    '電影': _KeywordMapping('cat_entertainment', 0.95),
    '电影': _KeywordMapping('cat_entertainment', 0.95),
    '游戏': _KeywordMapping('cat_entertainment', 0.90),
    'movie': _KeywordMapping('cat_entertainment', 0.95),
    'game': _KeywordMapping('cat_entertainment', 0.90),

    // ===== Medical =====
    '病院': _KeywordMapping('cat_medical', 0.95),
    '薬': _KeywordMapping('cat_medical', 0.90),
    '医院': _KeywordMapping('cat_medical', 0.95),
    '药': _KeywordMapping('cat_medical', 0.90),
    'hospital': _KeywordMapping('cat_medical', 0.95),
    'medicine': _KeywordMapping('cat_medical', 0.90),

    // ===== Housing =====
    '家賃': _KeywordMapping('cat_housing', 0.95),
    '水道': _KeywordMapping('cat_housing', 0.90),
    '電気': _KeywordMapping('cat_housing', 0.90),
    'ガス': _KeywordMapping('cat_housing', 0.90),
    '房租': _KeywordMapping('cat_housing', 0.95),
    '水费': _KeywordMapping('cat_housing', 0.90),
    '电费': _KeywordMapping('cat_housing', 0.90),
    'rent': _KeywordMapping('cat_housing', 0.95),
    'utilities': _KeywordMapping('cat_housing', 0.90),
  };
}

class _KeywordMapping {
  final String categoryId;
  final double confidence;
  final String? sub;

  const _KeywordMapping(this.categoryId, this.confidence, {this.sub});
}

class _ScoredCandidate {
  final String categoryId;
  final double baseScore;
  MatchSource source;
  double learningBonus;

  _ScoredCandidate({
    required this.categoryId,
    required this.baseScore,
    required this.source,
    this.learningBonus = 0.0,
  });

  double get finalScore => baseScore + learningBonus;
}
```

**Step 4: Run code generation (for mocks)**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 5: Run tests**

Run: `flutter test test/unit/application/voice/fuzzy_category_matcher_test.dart`
Expected: All PASS

**Step 6: Commit**

```bash
git add lib/application/voice/fuzzy_category_matcher.dart test/unit/application/voice/fuzzy_category_matcher_test.dart
git commit -m "feat(voice): add FuzzyCategoryMatcher with 3-signal scoring engine"
```

---

## Task 5: RecordCategoryCorrectionUseCase

**Files:**
- Create: `lib/application/voice/record_category_correction_use_case.dart`
- Test: `test/unit/application/voice/record_category_correction_use_case_test.dart`

**Step 1: Write failing test**

```dart
// test/unit/application/voice/record_category_correction_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/record_category_correction_use_case.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';

@GenerateMocks([CategoryKeywordPreferenceRepository])
import 'record_category_correction_use_case_test.mocks.dart';

void main() {
  late MockCategoryKeywordPreferenceRepository mockRepo;
  late RecordCategoryCorrectionUseCase useCase;

  setUp(() {
    mockRepo = MockCategoryKeywordPreferenceRepository();
    useCase = RecordCategoryCorrectionUseCase(
      preferenceRepository: mockRepo,
    );
  });

  test('execute calls recordCorrection on repository', () async {
    when(mockRepo.recordCorrection(
      keyword: anyNamed('keyword'),
      categoryId: anyNamed('categoryId'),
    )).thenAnswer((_) async {});

    await useCase.execute(
      keyword: '咖啡',
      correctedCategoryId: 'cat_entertainment_cafe',
    );

    verify(mockRepo.recordCorrection(
      keyword: '咖啡',
      categoryId: 'cat_entertainment_cafe',
    )).called(1);
  });

  test('execute does nothing for empty keyword', () async {
    await useCase.execute(
      keyword: '',
      correctedCategoryId: 'cat_food',
    );

    verifyNever(mockRepo.recordCorrection(
      keyword: anyNamed('keyword'),
      categoryId: anyNamed('categoryId'),
    ));
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter test test/unit/application/voice/record_category_correction_use_case_test.dart`
Expected: FAIL — file does not exist

**Step 3: Write implementation**

```dart
// lib/application/voice/record_category_correction_use_case.dart
import '../../features/accounting/domain/repositories/category_keyword_preference_repository.dart';

/// Records a user's category correction for voice input learning.
///
/// Called when the user changes the auto-matched category on
/// TransactionConfirmScreen. Increments the hitCount for the
/// (keyword, categoryId) pair in the learning table.
class RecordCategoryCorrectionUseCase {
  final CategoryKeywordPreferenceRepository _preferenceRepository;

  RecordCategoryCorrectionUseCase({
    required CategoryKeywordPreferenceRepository preferenceRepository,
  }) : _preferenceRepository = preferenceRepository;

  /// Records that [keyword] should map to [correctedCategoryId].
  ///
  /// Does nothing if [keyword] is empty.
  Future<void> execute({
    required String keyword,
    required String correctedCategoryId,
  }) async {
    if (keyword.isEmpty) return;

    await _preferenceRepository.recordCorrection(
      keyword: keyword,
      categoryId: correctedCategoryId,
    );
  }
}
```

**Step 4: Run tests**

Run: `flutter test test/unit/application/voice/record_category_correction_use_case_test.dart`
Expected: All PASS

**Step 5: Commit**

```bash
git add lib/application/voice/record_category_correction_use_case.dart test/unit/application/voice/record_category_correction_use_case_test.dart
git commit -m "feat(voice): add RecordCategoryCorrectionUseCase for learning"
```

---

## Task 6: Provider Wiring

Wire new components into Riverpod providers.

**Files:**
- Modify: `lib/features/accounting/presentation/providers/repository_providers.dart`
- Modify: `lib/features/accounting/presentation/providers/voice_providers.dart`
- Modify: `lib/features/accounting/presentation/providers/use_case_providers.dart`

**Step 1: Add repository provider in `repository_providers.dart`**

Add imports at the top of `lib/features/accounting/presentation/providers/repository_providers.dart`:

```dart
import '../../../../data/daos/category_keyword_preference_dao.dart';
import '../../../../data/repositories/category_keyword_preference_repository_impl.dart';
import '../../domain/repositories/category_keyword_preference_repository.dart';
```

Add provider at the end (before the `deviceIdentityRepositoryProvider`):

```dart
/// CategoryKeywordPreferenceRepository provider.
@riverpod
CategoryKeywordPreferenceRepository categoryKeywordPreferenceRepository(
  Ref ref,
) {
  final database = ref.watch(appDatabaseProvider);
  final dao = CategoryKeywordPreferenceDao(database);
  return CategoryKeywordPreferenceRepositoryImpl(dao: dao);
}
```

**Step 2: Replace CategoryMatcher with FuzzyCategoryMatcher in `voice_providers.dart`**

Update `lib/features/accounting/presentation/providers/voice_providers.dart`:

Replace the import:
```dart
// OLD:
import '../../../../application/voice/category_matcher.dart';
// NEW:
import '../../../../application/voice/fuzzy_category_matcher.dart';
```

Replace the categoryMatcher provider:
```dart
// OLD:
@riverpod
CategoryMatcher categoryMatcher(Ref ref) {
  return CategoryMatcher(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    categoryService: ref.watch(categoryServiceProvider),
  );
}

// NEW:
@riverpod
FuzzyCategoryMatcher fuzzyCategoryMatcher(Ref ref) {
  return FuzzyCategoryMatcher(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    preferenceRepository: ref.watch(categoryKeywordPreferenceRepositoryProvider),
    categoryService: ref.watch(categoryServiceProvider),
  );
}
```

Update `parseVoiceInputUseCase` to use the new matcher:
```dart
@riverpod
ParseVoiceInputUseCase parseVoiceInputUseCase(Ref ref) {
  return ParseVoiceInputUseCase(
    textParser: ref.watch(voiceTextParserProvider),
    fuzzyCategoryMatcher: ref.watch(fuzzyCategoryMatcherProvider),
    merchantDatabase: ref.watch(merchantDatabaseProvider),
  );
}
```

**Step 3: Add correction use case provider in `use_case_providers.dart`**

Add import at the top of `lib/features/accounting/presentation/providers/use_case_providers.dart`:

```dart
import '../../../../application/voice/record_category_correction_use_case.dart';
```

Add provider at the end:

```dart
@riverpod
RecordCategoryCorrectionUseCase recordCategoryCorrectionUseCase(Ref ref) {
  return RecordCategoryCorrectionUseCase(
    preferenceRepository: ref.watch(categoryKeywordPreferenceRepositoryProvider),
  );
}
```

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 5: Verify compilation**

Run: `flutter analyze`
Expected: No issues

**Step 6: Commit**

```bash
git add \
  lib/features/accounting/presentation/providers/repository_providers.dart \
  lib/features/accounting/presentation/providers/repository_providers.g.dart \
  lib/features/accounting/presentation/providers/voice_providers.dart \
  lib/features/accounting/presentation/providers/voice_providers.g.dart \
  lib/features/accounting/presentation/providers/use_case_providers.dart \
  lib/features/accounting/presentation/providers/use_case_providers.g.dart
git commit -m "feat(voice): wire FuzzyCategoryMatcher and correction use case providers"
```

---

## Task 7: Update ParseVoiceInputUseCase

**Files:**
- Modify: `lib/application/voice/parse_voice_input_use_case.dart`

**Step 1: Update the use case to use FuzzyCategoryMatcher**

Replace the current `CategoryMatcher` dependency with `FuzzyCategoryMatcher`:

```dart
// lib/application/voice/parse_voice_input_use_case.dart
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../infrastructure/ml/merchant_database.dart';
import '../../shared/utils/result.dart';
import 'fuzzy_category_matcher.dart';
import 'voice_text_parser.dart';

class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final FuzzyCategoryMatcher _fuzzyCategoryMatcher;
  final MerchantDatabase _merchantDatabase;

  ParseVoiceInputUseCase({
    required VoiceTextParser textParser,
    required FuzzyCategoryMatcher fuzzyCategoryMatcher,
    required MerchantDatabase merchantDatabase,
  })  : _textParser = textParser,
        _fuzzyCategoryMatcher = fuzzyCategoryMatcher,
        _merchantDatabase = merchantDatabase;

  Future<Result<VoiceParseResult>> execute(String recognizedText) async {
    try {
      // 1. Extract amount
      final amount = _textParser.extractAmount(recognizedText);

      // 2. Extract date
      final parsedDate = _textParser.extractDate(recognizedText);

      // 3. Match merchant (higher priority than keyword category)
      final merchantMatch = _textParser.extractAndMatchMerchant(
        recognizedText,
        _merchantDatabase,
      );

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
        categoryMatch = await _fuzzyCategoryMatcher.match(
          recognizedText,
          keyword,
        );
        if (categoryMatch != null) {
          ledgerType = await _fuzzyCategoryMatcher
              .resolveLedgerType(categoryMatch.categoryId);
        }
      }

      return Result.success(
        VoiceParseResult(
          rawText: recognizedText,
          amount: amount,
          parsedDate: parsedDate,
          merchantName: merchantMatch?.merchantName,
          merchantCategoryId: merchantMatch?.categoryId,
          merchantLedgerType: merchantMatch?.ledgerType,
          categoryMatch: categoryMatch,
          ledgerType: ledgerType,
        ),
      );
    } catch (e) {
      return Result.error('Voice parse failed: $e');
    }
  }

  /// Extracts the category-relevant keyword from voice input.
  ///
  /// Strips away recognized amount, date, and common particles,
  /// leaving only the word(s) that describe the expense category.
  String _extractKeyword(String text) {
    var remaining = text;

    // Remove amount patterns (numbers with currency markers)
    remaining = remaining.replaceAll(
      RegExp(r'[¥￥]?\s*[\d,]+\.?\d*\s*(円|元|ドル)?'),
      '',
    );

    // Remove common Japanese particles
    remaining = remaining.replaceAll(
      RegExp(r'[のにでをはがもへとや]'),
      '',
    );

    // Remove common Chinese particles
    remaining = remaining.replaceAll(
      RegExp(r'[的了吗呢吧啊呀哦]'),
      '',
    );

    return remaining.trim();
  }
}
```

**Step 2: Run existing tests**

Run: `flutter test test/unit/application/voice/`
Expected: PASS (adjust existing parse_voice_input tests if they reference `CategoryMatcher` directly — they should be updated to use `FuzzyCategoryMatcher`)

Note: If existing `parse_voice_input_use_case_test.dart` tests reference `CategoryMatcher`, update the mock to use `FuzzyCategoryMatcher` instead.

**Step 3: Commit**

```bash
git add lib/application/voice/parse_voice_input_use_case.dart
git commit -m "refactor(voice): replace CategoryMatcher with FuzzyCategoryMatcher in ParseVoiceInputUseCase"
```

---

## Task 8: Integration — TransactionConfirmScreen + VoiceInputScreen

Wire up correction recording when the user changes category.

**Files:**
- Modify: `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`
- Modify: `lib/features/accounting/presentation/screens/voice_input_screen.dart`

**Step 1: Add voice context parameters to TransactionConfirmScreen**

In `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`:

Add to constructor parameters (after `initialSatisfaction`):
```dart
this.voiceKeyword,
```

Add to fields (after `initialSatisfaction` field):
```dart
/// Extracted keyword from voice input for learning corrections.
final String? voiceKeyword;
```

Store the initial category ID in state. Add to `_TransactionConfirmScreenState`:
```dart
String? _initialCategoryId;
```

In `initState()`, after `_category = widget.category;` add:
```dart
_initialCategoryId = widget.category?.id;
```

**Step 2: Record correction in `_editCategory()` method**

After the `setState` block in `_editCategory()` (after `_resolveLedgerType(result.id);` on line 243), add:

```dart
// Record voice learning correction if category changed
if (widget.voiceKeyword != null &&
    widget.voiceKeyword!.isNotEmpty &&
    result.id != _initialCategoryId) {
  final correctionUseCase = ref.read(recordCategoryCorrectionUseCaseProvider);
  await correctionUseCase.execute(
    keyword: widget.voiceKeyword!,
    correctedCategoryId: result.id,
  );
}
```

Add import at top:
```dart
import '../providers/use_case_providers.dart';  // already imported
```

**Step 3: Pass voiceKeyword from VoiceInputScreen**

In `lib/features/accounting/presentation/screens/voice_input_screen.dart`, update `_navigateToConfirm()`:

After the existing `parentCategory` lookup (line 296-297), add keyword extraction:
```dart
// Extract keyword for voice learning
final keyword = _extractVoiceKeyword(result);
```

Add this method to `_VoiceInputScreenState`:
```dart
String _extractVoiceKeyword(VoiceParseResult result) {
  var remaining = result.rawText;

  // Remove amount patterns
  remaining = remaining.replaceAll(
    RegExp(r'[¥￥]?\s*[\d,]+\.?\d*\s*(円|元|ドル)?'),
    '',
  );

  // Remove merchant name if matched
  if (result.merchantName != null) {
    remaining = remaining.replaceFirst(result.merchantName!, '');
  }

  // Remove Japanese particles
  remaining = remaining.replaceAll(RegExp(r'[のにでをはがもへとや]'), '');

  // Remove Chinese particles
  remaining = remaining.replaceAll(RegExp(r'[的了吗呢吧啊呀哦]'), '');

  return remaining.trim();
}
```

Update the `TransactionConfirmScreen` constructor call in `_navigateToConfirm()`:
```dart
await Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => TransactionConfirmScreen(
      bookId: widget.bookId,
      amount: result.amount ?? 0,
      category: category,
      parentCategory: parentCategory,
      date: result.parsedDate ?? DateTime.now(),
      initialMerchant: result.merchantName,
      initialSatisfaction: result.ledgerType == LedgerType.soul
          ? result.estimatedSatisfaction
          : null,
      voiceKeyword: keyword,  // NEW
    ),
  ),
);
```

**Step 4: Verify compilation**

Run: `flutter analyze`
Expected: No issues

**Step 5: Commit**

```bash
git add \
  lib/features/accounting/presentation/screens/transaction_confirm_screen.dart \
  lib/features/accounting/presentation/screens/voice_input_screen.dart
git commit -m "feat(voice): record category corrections from TransactionConfirmScreen"
```

---

## Task 9: Delete Old CategoryMatcher

**Files:**
- Delete: `lib/application/voice/category_matcher.dart`
- Update: any remaining references

**Step 1: Search for remaining references**

Run: `grep -r "CategoryMatcher" lib/ --include="*.dart" -l` (use Grep tool)

Expected: Only `fuzzy_category_matcher.dart` should reference `_KeywordMapping` internally. Any other files referencing `CategoryMatcher` must be updated.

**Step 2: Delete the old file**

Delete `lib/application/voice/category_matcher.dart`

**Step 3: Verify no broken imports**

Run: `flutter analyze`
Expected: No issues (if issues found, fix remaining references)

**Step 4: Run all tests**

Run: `flutter test`
Expected: All PASS

**Step 5: Commit**

```bash
git rm lib/application/voice/category_matcher.dart
git commit -m "refactor(voice): remove old CategoryMatcher (replaced by FuzzyCategoryMatcher)"
```

---

## Task 10: Final Verification

**Step 1: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Succeeds

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found

**Step 3: Run all tests**

Run: `flutter test`
Expected: All tests pass

**Step 4: Verify test coverage**

Run: `flutter test --coverage`
Expected: Coverage >= 80% for new files

**Step 5: Final commit (if any formatting fixes needed)**

```bash
dart format .
git add -A
git commit -m "chore: format and cleanup after fuzzy category matching implementation"
```

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/fuzzy_category_matcher.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_keyword_preference.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockCategoryKeywordPreferenceRepository extends Mock
    implements CategoryKeywordPreferenceRepository {}

class _MockCategoryService extends Mock implements CategoryService {}

Category _makeCategory(
  String id,
  String name, {
  int level = 2,
  String? parentId,
}) {
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
  late _MockCategoryRepository mockCategoryRepo;
  late _MockCategoryKeywordPreferenceRepository mockPrefRepo;
  late _MockCategoryService mockCategoryService;
  late FuzzyCategoryMatcher matcher;

  setUp(() {
    mockCategoryRepo = _MockCategoryRepository();
    mockPrefRepo = _MockCategoryKeywordPreferenceRepository();
    mockCategoryService = _MockCategoryService();
    matcher = FuzzyCategoryMatcher(
      categoryRepository: mockCategoryRepo,
      preferenceRepository: mockPrefRepo,
      categoryService: mockCategoryService,
    );
  });

  group('Signal 1: Seed keyword match', () {
    test('exact keyword match returns category with high confidence', () async {
      when(
        () => mockCategoryRepo.findById('cat_food_dining_out'),
      ).thenAnswer((_) async => _makeCategory('cat_food_dining_out', '朝食'));
      when(() => mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(
        () => mockPrefRepo.findByKeyword(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockPrefRepo.suggestForKeyword(any()),
      ).thenAnswer((_) async => null);

      final result = await matcher.match('朝ごはん500円', '朝ごはん');
      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_food_dining_out');
      expect(result.source, MatchSource.keyword);
    });
  });

  group('Signal 2: Edit distance match', () {
    test('fuzzy match against DB category name', () async {
      when(() => mockCategoryRepo.findAll()).thenAnswer(
        (_) async => [
          _makeCategory('cat_custom_cafe', '咖啡厅', parentId: 'cat_food'),
        ],
      );
      when(
        () => mockCategoryRepo.findById(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockPrefRepo.findByKeyword(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockPrefRepo.suggestForKeyword(any()),
      ).thenAnswer((_) async => null);

      final result = await matcher.match('咖啡500円', '咖啡');
      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_custom_cafe');
    });
  });

  group('Signal 3: Learned mapping', () {
    test('learned mapping boosts score to override seed keyword', () async {
      when(
        () => mockCategoryRepo.findById('cat_food'),
      ).thenAnswer((_) async => _makeCategory('cat_food', '食費', level: 1));
      when(
        () => mockCategoryRepo.findById('cat_entertainment_cafe'),
      ).thenAnswer(
        (_) async => _makeCategory(
          'cat_entertainment_cafe',
          'カフェ',
          parentId: 'cat_entertainment',
        ),
      );
      when(() => mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(
        () => mockPrefRepo.findByKeyword('咖啡'),
      ).thenAnswer(
        (_) async => [
          CategoryKeywordPreference(
            keyword: '咖啡',
            categoryId: 'cat_entertainment_cafe',
            hitCount: 2,
            lastUsed: DateTime.now(),
          ),
        ],
      );
      when(
        () => mockPrefRepo.suggestForKeyword('咖啡'),
      ).thenAnswer(
        (_) async => CategoryKeywordPreference(
          keyword: '咖啡',
          categoryId: 'cat_entertainment_cafe',
          hitCount: 2,
          lastUsed: DateTime.now(),
        ),
      );

      final result = await matcher.match('咖啡500円', '咖啡');
      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_entertainment_cafe');
      expect(result.source, MatchSource.learning);
    });
  });

  group('Edge cases', () {
    test('empty keyword returns null', () async {
      when(() => mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(
        () => mockPrefRepo.findByKeyword(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockPrefRepo.suggestForKeyword(any()),
      ).thenAnswer((_) async => null);

      final result = await matcher.match('500円', '');
      expect(result, isNull);
    });

    test('no match from any signal returns null', () async {
      when(() => mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(
        () => mockCategoryRepo.findById(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockPrefRepo.findByKeyword(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockPrefRepo.suggestForKeyword(any()),
      ).thenAnswer((_) async => null);

      final result = await matcher.match('xyzzyx', 'xyzzyx');
      expect(result, isNull);
    });
  });
}

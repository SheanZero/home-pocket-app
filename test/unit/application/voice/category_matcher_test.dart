import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/voice/category_matcher.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryRepository, CategoryService])
import 'category_matcher_test.mocks.dart';

void main() {
  late MockCategoryRepository mockCategoryRepo;
  late MockCategoryService mockCategoryService;
  late CategoryMatcher matcher;

  // CORRECTION: Category requires createdAt (DateTime) — it is a required field.
  final fakeCategory = Category(
    id: 'cat_food',
    name: '食事',
    icon: '🍜',
    color: '#FF0000',
    level: 1,
    sortOrder: 0,
    isArchived: false,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockCategoryRepo = MockCategoryRepository();
    mockCategoryService = MockCategoryService();
    matcher = CategoryMatcher(
      categoryRepository: mockCategoryRepo,
      categoryService: mockCategoryService,
    );
    when(mockCategoryRepo.findById(any))
        .thenAnswer((_) async => fakeCategory);
  });

  group('CategoryMatcher - keyword matching', () {
    test('Japanese 昼ごはん matches cat_food with confidence > 0.8', () async {
      final result = await matcher.matchFromText('昼ごはんに680円');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
      expect(result.confidence, greaterThan(0.8));
    });

    test('Chinese 午饭 matches cat_food', () async {
      final result = await matcher.matchFromText('午饭吃了480块');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
    });

    test('English lunch matches cat_food', () async {
      final result = await matcher.matchFromText('lunch 550 yen');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
    });

    test('Japanese 電車 matches cat_transport', () async {
      final result = await matcher.matchFromText('電車代320円');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_transport'));
      expect(result.confidence, greaterThanOrEqualTo(0.9));
    });

    test('Chinese 地铁 matches cat_transport', () async {
      final result = await matcher.matchFromText('坐地铁花了280块');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_transport'));
    });

    test('English train matches cat_transport', () async {
      final result = await matcher.matchFromText('train pass 320 yen');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_transport'));
    });

    test('No match returns null', () async {
      when(mockCategoryRepo.findById(any)).thenAnswer((_) async => null);
      final result = await matcher.matchFromText('abc123');
      expect(result, isNull);
    });
  });

  group('CategoryMatcher - ledger type resolution', () {
    test('delegates resolveLedgerType to CategoryService', () async {
      when(mockCategoryService.resolveLedgerType('cat_food'))
          .thenAnswer((_) async => LedgerType.survival);

      final result = await matcher.resolveLedgerType('cat_food');
      expect(result, equals(LedgerType.survival));
      verify(mockCategoryService.resolveLedgerType('cat_food')).called(1);
    });
  });
}

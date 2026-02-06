import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/seed_categories_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryRepository])
import 'seed_categories_use_case_test.mocks.dart';

void main() {
  late MockCategoryRepository mockRepo;
  late SeedCategoriesUseCase useCase;

  setUp(() {
    mockRepo = MockCategoryRepository();
    useCase = SeedCategoriesUseCase(categoryRepository: mockRepo);
  });

  group('SeedCategoriesUseCase', () {
    test('inserts all default categories when db is empty', () async {
      when(mockRepo.findAll()).thenAnswer((_) async => []);
      when(mockRepo.insertBatch(any)).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      verify(mockRepo.insertBatch(DefaultCategories.all)).called(1);
    });

    test('skips seeding when categories already exist', () async {
      when(mockRepo.findAll()).thenAnswer((_) async => DefaultCategories.all);

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      verifyNever(mockRepo.insertBatch(any));
    });
  });
}

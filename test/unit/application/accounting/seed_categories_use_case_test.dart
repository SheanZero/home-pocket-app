import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/seed_categories_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryRepository, CategoryLedgerConfigRepository])
import 'seed_categories_use_case_test.mocks.dart';

void main() {
  late MockCategoryRepository mockCategoryRepo;
  late MockCategoryLedgerConfigRepository mockConfigRepo;
  late SeedCategoriesUseCase useCase;

  setUp(() {
    mockCategoryRepo = MockCategoryRepository();
    mockConfigRepo = MockCategoryLedgerConfigRepository();
    useCase = SeedCategoriesUseCase(
      categoryRepository: mockCategoryRepo,
      ledgerConfigRepository: mockConfigRepo,
    );
  });

  group('SeedCategoriesUseCase', () {
    test('inserts all default categories and ledger configs when db is empty',
        () async {
      when(mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(mockCategoryRepo.insertBatch(any)).thenAnswer((_) async {});
      when(mockConfigRepo.upsertBatch(any)).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      verify(mockCategoryRepo.insertBatch(DefaultCategories.all)).called(1);
      verify(mockConfigRepo.upsertBatch(DefaultCategories.defaultLedgerConfigs))
          .called(1);
    });

    test('skips seeding when categories already exist', () async {
      when(mockCategoryRepo.findAll())
          .thenAnswer((_) async => DefaultCategories.all);

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      verifyNever(mockCategoryRepo.insertBatch(any));
      verifyNever(mockConfigRepo.upsertBatch(any));
    });
  });
}

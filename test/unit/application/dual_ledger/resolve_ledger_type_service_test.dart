import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/dual_ledger/resolve_ledger_type_service.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryRepository, CategoryLedgerConfigRepository])
import 'resolve_ledger_type_service_test.mocks.dart';

void main() {
  late MockCategoryRepository mockCategoryRepo;
  late MockCategoryLedgerConfigRepository mockConfigRepo;
  late ResolveLedgerTypeService service;

  final epoch = DateTime(2026, 1, 1);

  setUp(() {
    mockCategoryRepo = MockCategoryRepository();
    mockConfigRepo = MockCategoryLedgerConfigRepository();
    service = ResolveLedgerTypeService(
      categoryRepository: mockCategoryRepo,
      ledgerConfigRepository: mockConfigRepo,
    );
  });

  group('ResolveLedgerTypeService', () {
    test('L1 category returns its own ledger config', () async {
      when(mockCategoryRepo.findById('cat_food')).thenAnswer(
        (_) async => Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          createdAt: epoch,
        ),
      );
      when(mockConfigRepo.findById('cat_food')).thenAnswer(
        (_) async => CategoryLedgerConfig(
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          updatedAt: epoch,
        ),
      );

      final result = await service.resolve('cat_food');
      expect(result, LedgerType.survival);
    });

    test('L2 with override returns L2 config', () async {
      when(mockCategoryRepo.findById('cat_food_lunch')).thenAnswer(
        (_) async => Category(
          id: 'cat_food_lunch',
          name: 'Lunch',
          icon: 'lunch',
          color: '#FF5722',
          parentId: 'cat_food',
          level: 2,
          createdAt: epoch,
        ),
      );
      when(mockConfigRepo.findById('cat_food_lunch')).thenAnswer(
        (_) async => CategoryLedgerConfig(
          categoryId: 'cat_food_lunch',
          ledgerType: LedgerType.soul,
          updatedAt: epoch,
        ),
      );

      final result = await service.resolve('cat_food_lunch');
      expect(result, LedgerType.soul);
    });

    test('L2 without override inherits from parent L1', () async {
      when(mockCategoryRepo.findById('cat_food_lunch')).thenAnswer(
        (_) async => Category(
          id: 'cat_food_lunch',
          name: 'Lunch',
          icon: 'lunch',
          color: '#FF5722',
          parentId: 'cat_food',
          level: 2,
          createdAt: epoch,
        ),
      );
      when(mockConfigRepo.findById('cat_food_lunch'))
          .thenAnswer((_) async => null);
      when(mockConfigRepo.findById('cat_food')).thenAnswer(
        (_) async => CategoryLedgerConfig(
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          updatedAt: epoch,
        ),
      );

      final result = await service.resolve('cat_food_lunch');
      expect(result, LedgerType.survival);
    });

    test('returns null when category not found', () async {
      when(mockCategoryRepo.findById('nonexistent'))
          .thenAnswer((_) async => null);

      final result = await service.resolve('nonexistent');
      expect(result, isNull);
    });

    test('resolveL1 returns parent L1 for L2 category', () async {
      when(mockCategoryRepo.findById('cat_food_lunch')).thenAnswer(
        (_) async => Category(
          id: 'cat_food_lunch',
          name: 'Lunch',
          icon: 'lunch',
          color: '#FF5722',
          parentId: 'cat_food',
          level: 2,
          createdAt: epoch,
        ),
      );

      final result = await service.resolveL1('cat_food_lunch');
      expect(result, 'cat_food');
    });

    test('resolveL1 returns own id for L1 category', () async {
      when(mockCategoryRepo.findById('cat_food')).thenAnswer(
        (_) async => Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          createdAt: epoch,
        ),
      );

      final result = await service.resolveL1('cat_food');
      expect(result, 'cat_food');
    });
  });
}

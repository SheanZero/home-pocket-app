import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/create_category_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/data/repositories/unit_of_work_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/unit_of_work.dart';

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository([List<Category>? seed]) : categories = [...?seed];

  final List<Category> categories;

  @override
  Future<void> insert(Category category) async => categories.add(category);

  @override
  Future<List<Category>> findActive() async => [...categories];

  @override
  Future<List<Category>> findAll() async => [...categories];

  @override
  Future<Category?> findById(String id) async {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  Future<List<Category>> findByLevel(int level) async =>
      categories.where((category) => category.level == level).toList();

  @override
  Future<List<Category>> findByParent(String parentId) async =>
      categories.where((category) => category.parentId == parentId).toList();

  @override
  Future<void> insertBatch(List<Category> categories) async =>
      this.categories.addAll(categories);

  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {}

  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}

  @override
  Future<void> deleteAll() async => categories.clear();
}

class _FakeLedgerConfigRepository implements CategoryLedgerConfigRepository {
  final List<CategoryLedgerConfig> configs = [];

  @override
  Future<void> upsert(CategoryLedgerConfig config) async => configs.add(config);

  @override
  Future<CategoryLedgerConfig?> findById(String categoryId) async => null;

  @override
  Future<List<CategoryLedgerConfig>> findAll() async => [...configs];

  @override
  Future<void> delete(String categoryId) async {}

  @override
  Future<void> deleteAll() async => configs.clear();

  @override
  Future<void> upsertBatch(List<CategoryLedgerConfig> configs) async =>
      this.configs.addAll(configs);
}

class _FailingLedgerConfigRepository extends _FakeLedgerConfigRepository {
  @override
  Future<void> upsert(CategoryLedgerConfig config) async {
    throw StateError('simulated ledger-config write failure');
  }
}

class _ImmediateUnitOfWork implements UnitOfWork {
  int runCount = 0;

  @override
  Future<T> run<T>(Future<T> Function() action) {
    runCount += 1;
    return action();
  }
}

void main() {
  final now = DateTime(2026, 7, 19, 10, 30);

  Category category({
    required String id,
    required String name,
    required int level,
    String? parentId,
    int sortOrder = 0,
    String icon = 'restaurant',
    String color = '#E85A4F',
  }) {
    return Category(
      id: id,
      name: name,
      icon: icon,
      color: color,
      parentId: parentId,
      level: level,
      sortOrder: sortOrder,
      createdAt: now,
    );
  }

  group('CreateCategoryUseCase', () {
    test('creates an L1 and its mandatory ledger config atomically', () async {
      final categoryRepo = _FakeCategoryRepository([
        category(id: 'existing', name: 'Existing', level: 1, sortOrder: 4),
      ]);
      final configRepo = _FakeLedgerConfigRepository();
      final unitOfWork = _ImmediateUnitOfWork();
      final useCase = CreateCategoryUseCase(
        categoryRepository: categoryRepo,
        ledgerConfigRepository: configRepo,
        unitOfWork: unitOfWork,
        idGenerator: () => 'custom-l1',
        clock: () => now,
      );

      final result = await useCase.execute(
        const CreateCategoryParams(
          name: '  Travel plans  ',
          ledgerType: LedgerType.joy,
          icon: 'flight',
          color: '#8B5CF6',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.id, 'custom-l1');
      expect(result.data?.name, 'Travel plans');
      expect(result.data?.level, 1);
      expect(result.data?.parentId, isNull);
      expect(result.data?.sortOrder, 5);
      expect(result.data?.isSystem, isFalse);
      expect(result.data?.icon, 'flight');
      expect(result.data?.color, '#8B5CF6');
      expect(configRepo.configs, hasLength(1));
      expect(configRepo.configs.single.categoryId, 'custom-l1');
      expect(configRepo.configs.single.ledgerType, LedgerType.joy);
      expect(unitOfWork.runCount, 1);
    });

    test(
      'creates an L2 under an active L1 and inherits its visual identity',
      () async {
        final parent = category(
          id: 'food',
          name: 'Food',
          level: 1,
          icon: 'restaurant',
          color: '#FF5722',
        );
        final categoryRepo = _FakeCategoryRepository([
          parent,
          category(
            id: 'groceries',
            name: 'Groceries',
            level: 2,
            parentId: parent.id,
            sortOrder: 2,
          ),
        ]);
        final configRepo = _FakeLedgerConfigRepository();
        final useCase = CreateCategoryUseCase(
          categoryRepository: categoryRepo,
          ledgerConfigRepository: configRepo,
          unitOfWork: _ImmediateUnitOfWork(),
          idGenerator: () => 'custom-l2',
          clock: () => now,
        );

        final result = await useCase.execute(
          const CreateCategoryParams(name: 'Bakery', parentId: 'food'),
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.level, 2);
        expect(result.data?.parentId, 'food');
        expect(result.data?.icon, parent.icon);
        expect(result.data?.color, parent.color);
        expect(result.data?.sortOrder, 3);
        expect(configRepo.configs, isEmpty);
      },
    );

    test(
      'rejects empty, too-long, duplicate, and invalid-parent input',
      () async {
        final parent = category(id: 'food', name: 'Food', level: 1);
        final categoryRepo = _FakeCategoryRepository([
          parent,
          category(id: 'bakery', name: 'Bakery', level: 2, parentId: parent.id),
        ]);
        final useCase = CreateCategoryUseCase(
          categoryRepository: categoryRepo,
          ledgerConfigRepository: _FakeLedgerConfigRepository(),
          unitOfWork: _ImmediateUnitOfWork(),
          idGenerator: () => 'unused',
          clock: () => now,
        );

        final empty = await useCase.execute(
          const CreateCategoryParams(name: '   ', ledgerType: LedgerType.daily),
        );
        final tooLong = await useCase.execute(
          CreateCategoryParams(name: 'x' * 51, ledgerType: LedgerType.daily),
        );
        final duplicate = await useCase.execute(
          const CreateCategoryParams(name: ' bakery ', parentId: 'food'),
        );
        final invalidParent = await useCase.execute(
          const CreateCategoryParams(name: 'New child', parentId: 'missing'),
        );

        expect(empty.error, CreateCategoryFailure.emptyName.name);
        expect(tooLong.error, CreateCategoryFailure.nameTooLong.name);
        expect(duplicate.error, CreateCategoryFailure.duplicateName.name);
        expect(invalidParent.error, CreateCategoryFailure.invalidParent.name);
        expect(categoryRepo.categories, hasLength(2));
      },
    );

    test('rolls the L1 row back if its ledger-config write fails', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final categoryRepo = CategoryRepositoryImpl(dao: CategoryDao(db));
      final useCase = CreateCategoryUseCase(
        categoryRepository: categoryRepo,
        ledgerConfigRepository: _FailingLedgerConfigRepository(),
        unitOfWork: UnitOfWorkImpl(db: db),
        idGenerator: () => 'rolled-back-l1',
        clock: () => now,
      );

      final result = await useCase.execute(
        const CreateCategoryParams(
          name: 'Must stay atomic',
          ledgerType: LedgerType.daily,
        ),
      );

      expect(result.error, CreateCategoryFailure.persistence.name);
      expect(await categoryRepo.findById('rolled-back-l1'), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_category_preference.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_category_preference_repository.dart';

class _InMemoryMerchantCategoryPreferenceRepository
    implements MerchantCategoryPreferenceRepository {
  final Map<String, MerchantCategoryPreference> _store = {};

  @override
  Future<MerchantCategoryPreference?> findByMerchantKey(
    String merchantKey,
  ) async {
    return _store[merchantKey];
  }

  @override
  Future<void> upsert(MerchantCategoryPreference preference) async {
    _store[preference.merchantKey] = preference;
  }

  @override
  Future<void> recordSelection({
    required String merchantKey,
    required String selectedCategoryId,
  }) async {
    final now = DateTime.now();
    final existing = _store[merchantKey];

    if (existing == null) {
      _store[merchantKey] = MerchantCategoryPreference(
        merchantKey: merchantKey,
        preferredCategoryId: selectedCategoryId,
        lastOverrideCategoryId: null,
        overrideStreak: 0,
        updatedAt: now,
      );
      return;
    }

    if (selectedCategoryId == existing.preferredCategoryId) {
      _store[merchantKey] = existing.copyWith(
        clearLastOverrideCategoryId: true,
        overrideStreak: 0,
        updatedAt: now,
      );
      return;
    }

    final streak = existing.lastOverrideCategoryId == selectedCategoryId
        ? existing.overrideStreak + 1
        : 1;

    if (streak >= 2) {
      _store[merchantKey] = existing.copyWith(
        preferredCategoryId: selectedCategoryId,
        clearLastOverrideCategoryId: true,
        overrideStreak: 0,
        updatedAt: now,
      );
      return;
    }

    _store[merchantKey] = existing.copyWith(
      lastOverrideCategoryId: selectedCategoryId,
      overrideStreak: streak,
      updatedAt: now,
    );
  }

  @override
  Future<String?> suggestCategoryId(String merchantKey) async {
    return _store[merchantKey]?.preferredCategoryId;
  }
}

class _InMemoryCategoryRepository implements CategoryRepository {
  _InMemoryCategoryRepository(this._categories);

  final Map<String, Category> _categories;

  @override
  Future<Category?> findById(String id) async => _categories[id];

  @override
  Future<void> deleteAll() async {}

  @override
  Future<List<Category>> findActive() async => _categories.values.toList();

  @override
  Future<List<Category>> findAll() async => _categories.values.toList();

  @override
  Future<List<Category>> findByLevel(int level) async =>
      _categories.values.where((c) => c.level == level).toList();

  @override
  Future<List<Category>> findByParent(String parentId) async =>
      _categories.values.where((c) => c.parentId == parentId).toList();

  @override
  Future<void> insert(Category category) async {
    _categories[category.id] = category;
  }

  @override
  Future<void> insertBatch(List<Category> categories) async {
    for (final category in categories) {
      _categories[category.id] = category;
    }
  }

  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {}
}

void main() {
  late _InMemoryMerchantCategoryPreferenceRepository prefRepository;
  late _InMemoryCategoryRepository categoryRepository;
  late MerchantCategoryLearningService service;

  setUp(() {
    prefRepository = _InMemoryMerchantCategoryPreferenceRepository();
    categoryRepository = _InMemoryCategoryRepository({
      'cat_food': Category(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime(2026, 1, 1),
      ),
      'cat_food_groceries': Category(
        id: 'cat_food_groceries',
        name: 'Groceries',
        icon: 'shopping_basket',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime(2026, 1, 1),
      ),
      'cat_food_dining_out': Category(
        id: 'cat_food_dining_out',
        name: 'Dining Out',
        icon: 'restaurant_menu',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        isSystem: true,
        sortOrder: 2,
        createdAt: DateTime(2026, 1, 1),
      ),
      'cat_transport_train': Category(
        id: 'cat_transport_train',
        name: 'Train',
        icon: 'train',
        color: '#2196F3',
        parentId: 'cat_transport',
        level: 2,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime(2026, 1, 1),
      ),
    });

    service = MerchantCategoryLearningService(
      repository: prefRepository,
      categoryRepository: categoryRepository,
    );
  });

  group('MerchantCategoryLearningService', () {
    test(
      'normalizeMerchant trims spaces and normalizes full-width letters',
      () {
        final normalized = service.normalizeMerchant('  ＳＥＶＥＮ　 ');
        expect(normalized, 'seven');
      },
    );

    test('creates initial preference for first merchant selection', () async {
      await service.recordSelection(
        merchantRaw: 'セブン',
        selectedCategoryId: 'cat_food_groceries',
      );

      final suggested = await service.suggestCategoryId('セブン');
      expect(suggested, 'cat_food_groceries');
    });

    test(
      'resets streak when user selects current preferred category',
      () async {
        await service.recordSelection(
          merchantRaw: 'セブン',
          selectedCategoryId: 'cat_food_groceries',
        );
        await service.recordSelection(
          merchantRaw: 'セブン',
          selectedCategoryId: 'cat_food_dining_out',
        );
        await service.recordSelection(
          merchantRaw: 'セブン',
          selectedCategoryId: 'cat_food_groceries',
        );

        final pref = await prefRepository.findByMerchantKey('セブン');
        expect(pref?.overrideStreak, 0);
        expect(pref?.lastOverrideCategoryId, isNull);
        expect(pref?.preferredCategoryId, 'cat_food_groceries');
      },
    );

    test(
      'updates preferred category after two consecutive same overrides',
      () async {
        await service.recordSelection(
          merchantRaw: 'セブン',
          selectedCategoryId: 'cat_food_groceries',
        );
        await service.recordSelection(
          merchantRaw: 'セブン',
          selectedCategoryId: 'cat_food_dining_out',
        );

        expect(await service.suggestCategoryId('セブン'), 'cat_food_groceries');

        await service.recordSelection(
          merchantRaw: 'セブン',
          selectedCategoryId: 'cat_food_dining_out',
        );

        expect(await service.suggestCategoryId('セブン'), 'cat_food_dining_out');
      },
    );

    test(
      'does not update preferred category when second override differs',
      () async {
        await service.recordSelection(
          merchantRaw: 'セブン',
          selectedCategoryId: 'cat_food_groceries',
        );
        await service.recordSelection(
          merchantRaw: 'セブン',
          selectedCategoryId: 'cat_food_dining_out',
        );
        await service.recordSelection(
          merchantRaw: 'セブン',
          selectedCategoryId: 'cat_transport_train',
        );

        final pref = await prefRepository.findByMerchantKey('セブン');
        expect(pref?.preferredCategoryId, 'cat_food_groceries');
        expect(pref?.lastOverrideCategoryId, 'cat_transport_train');
        expect(pref?.overrideStreak, 1);
      },
    );

    test(
      'normalization allows full-width and lowercase inputs to hit same key',
      () async {
        await service.recordSelection(
          merchantRaw: 'ＳＥＶＥＮ',
          selectedCategoryId: 'cat_food_groceries',
        );

        final suggested = await service.suggestCategoryId('seven');
        expect(suggested, 'cat_food_groceries');
      },
    );

    test('ignores updates when merchant is blank', () async {
      await service.recordSelection(
        merchantRaw: '   ',
        selectedCategoryId: 'cat_food_groceries',
      );

      expect(await service.suggestCategoryId(''), isNull);
    });

    test('rejects non-L2 categories', () async {
      await service.recordSelection(
        merchantRaw: 'セブン',
        selectedCategoryId: 'cat_food',
      );

      expect(await service.suggestCategoryId('セブン'), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/hide_category_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/unit_of_work.dart';

class _ImmediateUnitOfWork implements UnitOfWork {
  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

class _CategoryRepository implements CategoryRepository {
  _CategoryRepository(Iterable<Category> categories)
    : categories = {for (final category in categories) category.id: category};

  final Map<String, Category> categories;

  @override
  Future<Category?> findById(String id) async => categories[id];

  @override
  Future<List<Category>> findByParent(String parentId) async => categories
      .values
      .where((category) => category.parentId == parentId)
      .toList();

  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {
    final category = categories[id]!;
    categories[id] = category.copyWith(
      name: name ?? category.name,
      icon: icon ?? category.icon,
      color: color ?? category.color,
      isArchived: isArchived ?? category.isArchived,
      sortOrder: sortOrder ?? category.sortOrder,
    );
  }

  @override
  Future<List<Category>> findActive() async =>
      categories.values.where((category) => !category.isArchived).toList();

  @override
  Future<List<Category>> findAll() async => categories.values.toList();

  @override
  Future<List<Category>> findByLevel(int level) async =>
      categories.values.where((category) => category.level == level).toList();

  @override
  Future<void> deleteAll() async => categories.clear();

  @override
  Future<void> insert(Category category) async =>
      categories[category.id] = category;

  @override
  Future<void> insertBatch(List<Category> categories) async {
    for (final category in categories) {
      this.categories[category.id] = category;
    }
  }

  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}
}

Category _category(String id, {String? parentId, int level = 1}) => Category(
  id: id,
  name: id,
  icon: 'category',
  color: '#47B88A',
  parentId: parentId,
  level: level,
  createdAt: DateTime(2026, 8, 11),
);

void main() {
  test(
    'hiding an L2 category preserves its row but removes it from active',
    () async {
      final repository = _CategoryRepository([
        _category('parent'),
        _category('child', parentId: 'parent', level: 2),
      ]);

      final result = await HideCategoryUseCase(
        repository,
        _ImmediateUnitOfWork(),
      ).execute('child');

      expect(result.isSuccess, isTrue);
      expect((await repository.findById('child'))?.isArchived, isTrue);
      expect((await repository.findAll()).map((category) => category.id), [
        'parent',
        'child',
      ]);
      expect((await repository.findActive()).map((category) => category.id), [
        'parent',
      ]);
    },
  );

  test('hiding an L1 category also hides every L2 child', () async {
    final repository = _CategoryRepository([
      _category('parent'),
      _category('child-a', parentId: 'parent', level: 2),
      _category('child-b', parentId: 'parent', level: 2),
      _category('other-parent'),
    ]);

    final result = await HideCategoryUseCase(
      repository,
      _ImmediateUnitOfWork(),
    ).execute('parent');

    expect(result.isSuccess, isTrue);
    expect(repository.categories['parent']!.isArchived, isTrue);
    expect(repository.categories['child-a']!.isArchived, isTrue);
    expect(repository.categories['child-b']!.isArchived, isTrue);
    expect(repository.categories['other-parent']!.isArchived, isFalse);
  });
}

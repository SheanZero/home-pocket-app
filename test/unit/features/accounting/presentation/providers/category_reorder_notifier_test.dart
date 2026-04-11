import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_reorder_state.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/category_reorder_notifier.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';

class _FakeRepo implements CategoryRepository {
  Map<String, int>? lastSaved;
  bool shouldThrow = false;

  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {
    if (shouldThrow) throw Exception('db failure');
    lastSaved = Map.of(idToSortOrder);
  }

  // Unused in these tests — provide minimal stubs
  @override
  Future<void> deleteAll() async {}
  @override
  Future<List<Category>> findActive() async => const [];
  @override
  Future<List<Category>> findAll() async => const [];
  @override
  Future<List<Category>> findByLevel(int level) async => const [];
  @override
  Future<List<Category>> findByParent(String parentId) async => const [];
  @override
  Future<Category?> findById(String id) async => null;
  @override
  Future<void> insert(Category category) async {}
  @override
  Future<void> insertBatch(List<Category> categories) async {}
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

Category _cat(String id, {String? parent, int level = 1, int sortOrder = 0}) {
  return Category(
    id: id,
    name: id,
    icon: 'folder',
    color: '#888',
    parentId: parent,
    level: level,
    sortOrder: sortOrder,
    createdAt: DateTime(2026, 4, 11),
  );
}

void main() {
  late _FakeRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    container = ProviderContainer(
      overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  CategoryReorderNotifier notifier() =>
      container.read(categoryReorderNotifierProvider.notifier);

  CategoryReorderState state() =>
      container.read(categoryReorderNotifierProvider);

  group('CategoryReorderNotifier', () {
    test('initial state has mode == idle', () {
      expect(state().mode, CategoryReorderMode.idle);
      expect(state().isEditing, isFalse);
    });

    test('enterEditing switches to editing mode with isDirty=false', () {
      notifier().enterEditing(
        l1: [_cat('a'), _cat('b')],
        l2ByParent: {
          'a': [_cat('a1', parent: 'a', level: 2)],
        },
      );
      final s = state();
      expect(s.mode, CategoryReorderMode.editing);
      expect(s.isEditing, isTrue);
      expect(s.l1.map((c) => c.id), ['a', 'b']);
      expect(s.isDirty, isFalse);
    });

    test('reorderL1 moves item and sets isDirty=true', () {
      notifier().enterEditing(
        l1: [_cat('a'), _cat('b'), _cat('c')],
        l2ByParent: const {},
      );
      notifier().reorderL1(
        0,
        3,
      ); // move a to end (ReorderableListView semantics)
      final s = state();
      expect(s.l1.map((c) => c.id), ['b', 'c', 'a']);
      expect(s.isDirty, isTrue);
    });

    test('reorderL2 moves child within same parent only', () {
      notifier().enterEditing(
        l1: [_cat('food')],
        l2ByParent: {
          'food': [
            _cat('x', parent: 'food', level: 2),
            _cat('y', parent: 'food', level: 2),
          ],
        },
      );
      notifier().reorderL2('food', 0, 2); // x → end
      final s = state();
      expect(s.l2ByParent['food']!.map((c) => c.id), ['y', 'x']);
      expect(s.isDirty, isTrue);
    });

    test('save writes flat index map and returns to idle', () async {
      notifier().enterEditing(
        l1: [_cat('a'), _cat('b')],
        l2ByParent: {
          'a': [
            _cat('a1', parent: 'a', level: 2),
            _cat('a2', parent: 'a', level: 2),
          ],
        },
      );
      notifier().reorderL1(1, 0); // b → front
      await notifier().save();

      expect(repo.lastSaved, {'b': 0, 'a': 1, 'a1': 0, 'a2': 1});
      expect(state().mode, CategoryReorderMode.idle);
    });

    test('save failure keeps editing state dirty (user can retry)', () async {
      repo.shouldThrow = true;
      notifier().enterEditing(l1: [_cat('a'), _cat('b')], l2ByParent: const {});
      notifier().reorderL1(0, 2);
      expect(state().isDirty, isTrue);

      await expectLater(notifier().save(), throwsA(isA<Exception>()));

      final s = state();
      expect(s.mode, CategoryReorderMode.editing);
      expect(s.isDirty, isTrue);
      expect(s.l1.map((c) => c.id), ['b', 'a']);
    });

    test('cancel returns to idle even when dirty', () {
      notifier().enterEditing(l1: [_cat('a'), _cat('b')], l2ByParent: const {});
      notifier().reorderL1(0, 2);
      notifier().cancel();
      expect(state().mode, CategoryReorderMode.idle);
    });
  });
}

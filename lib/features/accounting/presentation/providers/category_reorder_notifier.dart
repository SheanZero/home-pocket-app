import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/category.dart';
import '../../domain/models/category_reorder_state.dart';
import 'repository_providers.dart';

part 'category_reorder_notifier.g.dart';

@riverpod
class CategoryReorderNotifier extends _$CategoryReorderNotifier {
  @override
  CategoryReorderState build() => const CategoryReorderState();

  /// Enter edit mode, taking ownership of a mutable copy of the lists.
  void enterEditing({
    required List<Category> l1,
    required Map<String, List<Category>> l2ByParent,
  }) {
    state = CategoryReorderState(
      mode: CategoryReorderMode.editing,
      l1: List.of(l1),
      l2ByParent: {
        for (final entry in l2ByParent.entries) entry.key: List.of(entry.value),
      },
      isDirty: false,
    );
  }

  /// Reorder an L1 row (`ReorderableListView` semantics: `newIndex` may equal
  /// `list.length` when dropped at the bottom; adjust by -1 if moving down).
  void reorderL1(int oldIndex, int newIndex) {
    if (!state.isEditing) return;
    final updated = List<Category>.of(state.l1);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    state = state.copyWith(l1: updated, isDirty: true);
  }

  /// Reorder an L2 row within a specific parent only.
  void reorderL2(String parentId, int oldIndex, int newIndex) {
    if (!state.isEditing) return;
    final children = List<Category>.of(state.l2ByParent[parentId] ?? const []);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = children.removeAt(oldIndex);
    children.insert(newIndex, moved);
    final updatedMap = Map<String, List<Category>>.of(state.l2ByParent);
    updatedMap[parentId] = children;
    state = state.copyWith(l2ByParent: updatedMap, isDirty: true);
  }

  /// Persist the working copy via
  /// [CategoryRepository.updateSortOrders] and return to idle.
  ///
  /// Throws through on DB failure — caller (screen) is responsible for
  /// surfacing the error via SnackBar. On failure, [state] is **left
  /// unchanged** so the user can retry without losing their work.
  Future<void> save() async {
    if (!state.isEditing) return;
    final orders = <String, int>{};
    state.l1.asMap().forEach((i, cat) => orders[cat.id] = i);
    for (final entry in state.l2ByParent.entries) {
      entry.value.asMap().forEach((i, cat) => orders[cat.id] = i);
    }
    final repo = ref.read(categoryRepositoryProvider);
    await repo.updateSortOrders(orders); // throws propagate
    state = const CategoryReorderState();
  }

  /// Discard unsaved changes and return to idle.
  void cancel() {
    state = const CategoryReorderState();
  }
}

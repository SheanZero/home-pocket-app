import 'package:freezed_annotation/freezed_annotation.dart';

import 'category.dart';

part 'category_reorder_state.freezed.dart';

/// Top-level mode of the category reorder editor.
enum CategoryReorderMode { idle, editing }

/// State of the category reorder editor.
///
/// - [CategoryReorderMode.idle] — the Category Selection screen is in its
///   normal read state; [l1]/[l2ByParent]/[isDirty] are ignored.
/// - [CategoryReorderMode.editing] — the user tapped the reorder button and
///   is actively dragging. [l1] and [l2ByParent] hold the working copies
///   (mutated in-place by the notifier). [isDirty] is true once any drag
///   has moved an item.
@freezed
abstract class CategoryReorderState with _$CategoryReorderState {
  const factory CategoryReorderState({
    @Default(CategoryReorderMode.idle) CategoryReorderMode mode,
    @Default([]) List<Category> l1,
    @Default({}) Map<String, List<Category>> l2ByParent,
    @Default(false) bool isDirty,
  }) = _CategoryReorderState;

  const CategoryReorderState._();

  /// Convenience for callers that want the old `is Editing` idiom.
  bool get isEditing => mode == CategoryReorderMode.editing;
}

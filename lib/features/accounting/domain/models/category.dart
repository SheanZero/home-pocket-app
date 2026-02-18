import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,

    /// Category display name.
    ///
    /// - System categories (isSystem=true): stores a localization key
    ///   (e.g. 'category_food'), resolved via `S.of(context)` at UI layer.
    /// - Custom categories (isSystem=false): stores user-entered display name.
    required String name,

    required String icon,
    required String color,
    String? parentId,
    required int level,
    @Default(false) bool isSystem,
    @Default(false) bool isArchived,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

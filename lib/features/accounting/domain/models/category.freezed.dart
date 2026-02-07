// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Category {
  String get id;

  /// Category display name.
  ///
  /// - System categories (isSystem=true): stores a localization key
  ///   (e.g. 'category_food'), resolved via `S.of(context)` at UI layer.
  /// - Custom categories (isSystem=false): stores user-entered display name.
  String get name;
  String get icon;
  String get color;
  String? get parentId;
  int get level;
  TransactionType get type;
  bool get isSystem;
  int get sortOrder;
  int? get budgetAmount;
  DateTime get createdAt;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CategoryCopyWith<Category> get copyWith =>
      _$CategoryCopyWithImpl<Category>(this as Category, _$identity);

  /// Serializes this Category to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Category &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isSystem, isSystem) ||
                other.isSystem == isSystem) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.budgetAmount, budgetAmount) ||
                other.budgetAmount == budgetAmount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    icon,
    color,
    parentId,
    level,
    type,
    isSystem,
    sortOrder,
    budgetAmount,
    createdAt,
  );

  @override
  String toString() {
    return 'Category(id: $id, name: $name, icon: $icon, color: $color, parentId: $parentId, level: $level, type: $type, isSystem: $isSystem, sortOrder: $sortOrder, budgetAmount: $budgetAmount, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $CategoryCopyWith<$Res> {
  factory $CategoryCopyWith(Category value, $Res Function(Category) _then) =
      _$CategoryCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String name,
    String icon,
    String color,
    String? parentId,
    int level,
    TransactionType type,
    bool isSystem,
    int sortOrder,
    int? budgetAmount,
    DateTime createdAt,
  });
}

/// @nodoc
class _$CategoryCopyWithImpl<$Res> implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._self, this._then);

  final Category _self;
  final $Res Function(Category) _then;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? icon = null,
    Object? color = null,
    Object? parentId = freezed,
    Object? level = null,
    Object? type = null,
    Object? isSystem = null,
    Object? sortOrder = null,
    Object? budgetAmount = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        icon: null == icon
            ? _self.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String,
        color: null == color
            ? _self.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String,
        parentId: freezed == parentId
            ? _self.parentId
            : parentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        level: null == level
            ? _self.level
            : level // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _self.type
            : type // ignore: cast_nullable_to_non_nullable
                  as TransactionType,
        isSystem: null == isSystem
            ? _self.isSystem
            : isSystem // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortOrder: null == sortOrder
            ? _self.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        budgetAmount: freezed == budgetAmount
            ? _self.budgetAmount
            : budgetAmount // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [Category].
extension CategoryPatterns on Category {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Category value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Category() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Category value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Category():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Category value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Category() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      String id,
      String name,
      String icon,
      String color,
      String? parentId,
      int level,
      TransactionType type,
      bool isSystem,
      int sortOrder,
      int? budgetAmount,
      DateTime createdAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Category() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.icon,
          _that.color,
          _that.parentId,
          _that.level,
          _that.type,
          _that.isSystem,
          _that.sortOrder,
          _that.budgetAmount,
          _that.createdAt,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      String id,
      String name,
      String icon,
      String color,
      String? parentId,
      int level,
      TransactionType type,
      bool isSystem,
      int sortOrder,
      int? budgetAmount,
      DateTime createdAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Category():
        return $default(
          _that.id,
          _that.name,
          _that.icon,
          _that.color,
          _that.parentId,
          _that.level,
          _that.type,
          _that.isSystem,
          _that.sortOrder,
          _that.budgetAmount,
          _that.createdAt,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      String id,
      String name,
      String icon,
      String color,
      String? parentId,
      int level,
      TransactionType type,
      bool isSystem,
      int sortOrder,
      int? budgetAmount,
      DateTime createdAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Category() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.icon,
          _that.color,
          _that.parentId,
          _that.level,
          _that.type,
          _that.isSystem,
          _that.sortOrder,
          _that.budgetAmount,
          _that.createdAt,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Category implements Category {
  const _Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.parentId,
    required this.level,
    required this.type,
    this.isSystem = false,
    this.sortOrder = 0,
    this.budgetAmount,
    required this.createdAt,
  });
  factory _Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  @override
  final String id;

  /// Category display name.
  ///
  /// - System categories (isSystem=true): stores a localization key
  ///   (e.g. 'category_food'), resolved via `S.of(context)` at UI layer.
  /// - Custom categories (isSystem=false): stores user-entered display name.
  @override
  final String name;
  @override
  final String icon;
  @override
  final String color;
  @override
  final String? parentId;
  @override
  final int level;
  @override
  final TransactionType type;
  @override
  @JsonKey()
  final bool isSystem;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  final int? budgetAmount;
  @override
  final DateTime createdAt;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CategoryCopyWith<_Category> get copyWith =>
      __$CategoryCopyWithImpl<_Category>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CategoryToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Category &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isSystem, isSystem) ||
                other.isSystem == isSystem) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.budgetAmount, budgetAmount) ||
                other.budgetAmount == budgetAmount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    icon,
    color,
    parentId,
    level,
    type,
    isSystem,
    sortOrder,
    budgetAmount,
    createdAt,
  );

  @override
  String toString() {
    return 'Category(id: $id, name: $name, icon: $icon, color: $color, parentId: $parentId, level: $level, type: $type, isSystem: $isSystem, sortOrder: $sortOrder, budgetAmount: $budgetAmount, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$CategoryCopyWith<$Res>
    implements $CategoryCopyWith<$Res> {
  factory _$CategoryCopyWith(_Category value, $Res Function(_Category) _then) =
      __$CategoryCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String icon,
    String color,
    String? parentId,
    int level,
    TransactionType type,
    bool isSystem,
    int sortOrder,
    int? budgetAmount,
    DateTime createdAt,
  });
}

/// @nodoc
class __$CategoryCopyWithImpl<$Res> implements _$CategoryCopyWith<$Res> {
  __$CategoryCopyWithImpl(this._self, this._then);

  final _Category _self;
  final $Res Function(_Category) _then;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? icon = null,
    Object? color = null,
    Object? parentId = freezed,
    Object? level = null,
    Object? type = null,
    Object? isSystem = null,
    Object? sortOrder = null,
    Object? budgetAmount = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _Category(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        icon: null == icon
            ? _self.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String,
        color: null == color
            ? _self.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String,
        parentId: freezed == parentId
            ? _self.parentId
            : parentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        level: null == level
            ? _self.level
            : level // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _self.type
            : type // ignore: cast_nullable_to_non_nullable
                  as TransactionType,
        isSystem: null == isSystem
            ? _self.isSystem
            : isSystem // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortOrder: null == sortOrder
            ? _self.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        budgetAmount: freezed == budgetAmount
            ? _self.budgetAmount
            : budgetAmount // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

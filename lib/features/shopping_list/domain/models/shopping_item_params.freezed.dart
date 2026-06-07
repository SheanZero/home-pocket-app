// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_item_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShoppingItemParams {
  String get name;
  String get listType;
  LedgerType? get ledgerType;
  String? get categoryId;
  List<String> get tags;
  String? get note;
  int get quantity;
  int? get estimatedPrice;
  String? get addedByBookId;

  /// Create a copy of ShoppingItemParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ShoppingItemParamsCopyWith<ShoppingItemParams> get copyWith =>
      _$ShoppingItemParamsCopyWithImpl<ShoppingItemParams>(
        this as ShoppingItemParams,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ShoppingItemParams &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.listType, listType) ||
                other.listType == listType) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.estimatedPrice, estimatedPrice) ||
                other.estimatedPrice == estimatedPrice) &&
            (identical(other.addedByBookId, addedByBookId) ||
                other.addedByBookId == addedByBookId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    listType,
    ledgerType,
    categoryId,
    const DeepCollectionEquality().hash(tags),
    note,
    quantity,
    estimatedPrice,
    addedByBookId,
  );

  @override
  String toString() {
    return 'ShoppingItemParams(name: $name, listType: $listType, ledgerType: $ledgerType, categoryId: $categoryId, tags: $tags, note: $note, quantity: $quantity, estimatedPrice: $estimatedPrice, addedByBookId: $addedByBookId)';
  }
}

/// @nodoc
abstract mixin class $ShoppingItemParamsCopyWith<$Res> {
  factory $ShoppingItemParamsCopyWith(
    ShoppingItemParams value,
    $Res Function(ShoppingItemParams) _then,
  ) = _$ShoppingItemParamsCopyWithImpl;
  @useResult
  $Res call({
    String name,
    String listType,
    LedgerType? ledgerType,
    String? categoryId,
    List<String> tags,
    String? note,
    int quantity,
    int? estimatedPrice,
    String? addedByBookId,
  });
}

/// @nodoc
class _$ShoppingItemParamsCopyWithImpl<$Res>
    implements $ShoppingItemParamsCopyWith<$Res> {
  _$ShoppingItemParamsCopyWithImpl(this._self, this._then);

  final ShoppingItemParams _self;
  final $Res Function(ShoppingItemParams) _then;

  /// Create a copy of ShoppingItemParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? listType = null,
    Object? ledgerType = freezed,
    Object? categoryId = freezed,
    Object? tags = null,
    Object? note = freezed,
    Object? quantity = null,
    Object? estimatedPrice = freezed,
    Object? addedByBookId = freezed,
  }) {
    return _then(
      _self.copyWith(
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        listType: null == listType
            ? _self.listType
            : listType // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerType: freezed == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        categoryId: freezed == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        tags: null == tags
            ? _self.tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        note: freezed == note
            ? _self.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantity: null == quantity
            ? _self.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        estimatedPrice: freezed == estimatedPrice
            ? _self.estimatedPrice
            : estimatedPrice // ignore: cast_nullable_to_non_nullable
                  as int?,
        addedByBookId: freezed == addedByBookId
            ? _self.addedByBookId
            : addedByBookId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ShoppingItemParams].
extension ShoppingItemParamsPatterns on ShoppingItemParams {
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
    TResult Function(_ShoppingItemParams value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemParams() when $default != null:
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
    TResult Function(_ShoppingItemParams value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemParams():
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
    TResult? Function(_ShoppingItemParams value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemParams() when $default != null:
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
      String name,
      String listType,
      LedgerType? ledgerType,
      String? categoryId,
      List<String> tags,
      String? note,
      int quantity,
      int? estimatedPrice,
      String? addedByBookId,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemParams() when $default != null:
        return $default(
          _that.name,
          _that.listType,
          _that.ledgerType,
          _that.categoryId,
          _that.tags,
          _that.note,
          _that.quantity,
          _that.estimatedPrice,
          _that.addedByBookId,
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
      String name,
      String listType,
      LedgerType? ledgerType,
      String? categoryId,
      List<String> tags,
      String? note,
      int quantity,
      int? estimatedPrice,
      String? addedByBookId,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemParams():
        return $default(
          _that.name,
          _that.listType,
          _that.ledgerType,
          _that.categoryId,
          _that.tags,
          _that.note,
          _that.quantity,
          _that.estimatedPrice,
          _that.addedByBookId,
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
      String name,
      String listType,
      LedgerType? ledgerType,
      String? categoryId,
      List<String> tags,
      String? note,
      int quantity,
      int? estimatedPrice,
      String? addedByBookId,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemParams() when $default != null:
        return $default(
          _that.name,
          _that.listType,
          _that.ledgerType,
          _that.categoryId,
          _that.tags,
          _that.note,
          _that.quantity,
          _that.estimatedPrice,
          _that.addedByBookId,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ShoppingItemParams implements ShoppingItemParams {
  const _ShoppingItemParams({
    required this.name,
    required this.listType,
    this.ledgerType,
    this.categoryId,
    final List<String> tags = const <String>[],
    this.note,
    this.quantity = 1,
    this.estimatedPrice,
    this.addedByBookId,
  }) : _tags = tags;

  @override
  final String name;
  @override
  final String listType;
  @override
  final LedgerType? ledgerType;
  @override
  final String? categoryId;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final String? note;
  @override
  @JsonKey()
  final int quantity;
  @override
  final int? estimatedPrice;
  @override
  final String? addedByBookId;

  /// Create a copy of ShoppingItemParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ShoppingItemParamsCopyWith<_ShoppingItemParams> get copyWith =>
      __$ShoppingItemParamsCopyWithImpl<_ShoppingItemParams>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ShoppingItemParams &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.listType, listType) ||
                other.listType == listType) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.estimatedPrice, estimatedPrice) ||
                other.estimatedPrice == estimatedPrice) &&
            (identical(other.addedByBookId, addedByBookId) ||
                other.addedByBookId == addedByBookId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    listType,
    ledgerType,
    categoryId,
    const DeepCollectionEquality().hash(_tags),
    note,
    quantity,
    estimatedPrice,
    addedByBookId,
  );

  @override
  String toString() {
    return 'ShoppingItemParams(name: $name, listType: $listType, ledgerType: $ledgerType, categoryId: $categoryId, tags: $tags, note: $note, quantity: $quantity, estimatedPrice: $estimatedPrice, addedByBookId: $addedByBookId)';
  }
}

/// @nodoc
abstract mixin class _$ShoppingItemParamsCopyWith<$Res>
    implements $ShoppingItemParamsCopyWith<$Res> {
  factory _$ShoppingItemParamsCopyWith(
    _ShoppingItemParams value,
    $Res Function(_ShoppingItemParams) _then,
  ) = __$ShoppingItemParamsCopyWithImpl;
  @override
  @useResult
  $Res call({
    String name,
    String listType,
    LedgerType? ledgerType,
    String? categoryId,
    List<String> tags,
    String? note,
    int quantity,
    int? estimatedPrice,
    String? addedByBookId,
  });
}

/// @nodoc
class __$ShoppingItemParamsCopyWithImpl<$Res>
    implements _$ShoppingItemParamsCopyWith<$Res> {
  __$ShoppingItemParamsCopyWithImpl(this._self, this._then);

  final _ShoppingItemParams _self;
  final $Res Function(_ShoppingItemParams) _then;

  /// Create a copy of ShoppingItemParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? listType = null,
    Object? ledgerType = freezed,
    Object? categoryId = freezed,
    Object? tags = null,
    Object? note = freezed,
    Object? quantity = null,
    Object? estimatedPrice = freezed,
    Object? addedByBookId = freezed,
  }) {
    return _then(
      _ShoppingItemParams(
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        listType: null == listType
            ? _self.listType
            : listType // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerType: freezed == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        categoryId: freezed == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        tags: null == tags
            ? _self._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        note: freezed == note
            ? _self.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantity: null == quantity
            ? _self.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        estimatedPrice: freezed == estimatedPrice
            ? _self.estimatedPrice
            : estimatedPrice // ignore: cast_nullable_to_non_nullable
                  as int?,
        addedByBookId: freezed == addedByBookId
            ? _self.addedByBookId
            : addedByBookId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

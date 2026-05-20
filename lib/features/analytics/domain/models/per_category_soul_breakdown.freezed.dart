// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'per_category_soul_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PerCategorySoulBreakdownItem {
  String get categoryId;
  double get avgSatisfaction;
  int get totalCount;

  /// Create a copy of PerCategorySoulBreakdownItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PerCategorySoulBreakdownItemCopyWith<PerCategorySoulBreakdownItem>
  get copyWith =>
      _$PerCategorySoulBreakdownItemCopyWithImpl<PerCategorySoulBreakdownItem>(
        this as PerCategorySoulBreakdownItem,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PerCategorySoulBreakdownItem &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.avgSatisfaction, avgSatisfaction) ||
                other.avgSatisfaction == avgSatisfaction) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, categoryId, avgSatisfaction, totalCount);

  @override
  String toString() {
    return 'PerCategorySoulBreakdownItem(categoryId: $categoryId, avgSatisfaction: $avgSatisfaction, totalCount: $totalCount)';
  }
}

/// @nodoc
abstract mixin class $PerCategorySoulBreakdownItemCopyWith<$Res> {
  factory $PerCategorySoulBreakdownItemCopyWith(
    PerCategorySoulBreakdownItem value,
    $Res Function(PerCategorySoulBreakdownItem) _then,
  ) = _$PerCategorySoulBreakdownItemCopyWithImpl;
  @useResult
  $Res call({String categoryId, double avgSatisfaction, int totalCount});
}

/// @nodoc
class _$PerCategorySoulBreakdownItemCopyWithImpl<$Res>
    implements $PerCategorySoulBreakdownItemCopyWith<$Res> {
  _$PerCategorySoulBreakdownItemCopyWithImpl(this._self, this._then);

  final PerCategorySoulBreakdownItem _self;
  final $Res Function(PerCategorySoulBreakdownItem) _then;

  /// Create a copy of PerCategorySoulBreakdownItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = null,
    Object? avgSatisfaction = null,
    Object? totalCount = null,
  }) {
    return _then(
      _self.copyWith(
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        avgSatisfaction: null == avgSatisfaction
            ? _self.avgSatisfaction
            : avgSatisfaction // ignore: cast_nullable_to_non_nullable
                  as double,
        totalCount: null == totalCount
            ? _self.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PerCategorySoulBreakdownItem].
extension PerCategorySoulBreakdownItemPatterns on PerCategorySoulBreakdownItem {
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
    TResult Function(_PerCategorySoulBreakdownItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdownItem() when $default != null:
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
    TResult Function(_PerCategorySoulBreakdownItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdownItem():
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
    TResult? Function(_PerCategorySoulBreakdownItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdownItem() when $default != null:
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
    TResult Function(String categoryId, double avgSatisfaction, int totalCount)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdownItem() when $default != null:
        return $default(
          _that.categoryId,
          _that.avgSatisfaction,
          _that.totalCount,
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
    TResult Function(String categoryId, double avgSatisfaction, int totalCount)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdownItem():
        return $default(
          _that.categoryId,
          _that.avgSatisfaction,
          _that.totalCount,
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
      String categoryId,
      double avgSatisfaction,
      int totalCount,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdownItem() when $default != null:
        return $default(
          _that.categoryId,
          _that.avgSatisfaction,
          _that.totalCount,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PerCategorySoulBreakdownItem implements PerCategorySoulBreakdownItem {
  const _PerCategorySoulBreakdownItem({
    required this.categoryId,
    required this.avgSatisfaction,
    required this.totalCount,
  });

  @override
  final String categoryId;
  @override
  final double avgSatisfaction;
  @override
  final int totalCount;

  /// Create a copy of PerCategorySoulBreakdownItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PerCategorySoulBreakdownItemCopyWith<_PerCategorySoulBreakdownItem>
  get copyWith =>
      __$PerCategorySoulBreakdownItemCopyWithImpl<
        _PerCategorySoulBreakdownItem
      >(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PerCategorySoulBreakdownItem &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.avgSatisfaction, avgSatisfaction) ||
                other.avgSatisfaction == avgSatisfaction) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, categoryId, avgSatisfaction, totalCount);

  @override
  String toString() {
    return 'PerCategorySoulBreakdownItem(categoryId: $categoryId, avgSatisfaction: $avgSatisfaction, totalCount: $totalCount)';
  }
}

/// @nodoc
abstract mixin class _$PerCategorySoulBreakdownItemCopyWith<$Res>
    implements $PerCategorySoulBreakdownItemCopyWith<$Res> {
  factory _$PerCategorySoulBreakdownItemCopyWith(
    _PerCategorySoulBreakdownItem value,
    $Res Function(_PerCategorySoulBreakdownItem) _then,
  ) = __$PerCategorySoulBreakdownItemCopyWithImpl;
  @override
  @useResult
  $Res call({String categoryId, double avgSatisfaction, int totalCount});
}

/// @nodoc
class __$PerCategorySoulBreakdownItemCopyWithImpl<$Res>
    implements _$PerCategorySoulBreakdownItemCopyWith<$Res> {
  __$PerCategorySoulBreakdownItemCopyWithImpl(this._self, this._then);

  final _PerCategorySoulBreakdownItem _self;
  final $Res Function(_PerCategorySoulBreakdownItem) _then;

  /// Create a copy of PerCategorySoulBreakdownItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? categoryId = null,
    Object? avgSatisfaction = null,
    Object? totalCount = null,
  }) {
    return _then(
      _PerCategorySoulBreakdownItem(
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        avgSatisfaction: null == avgSatisfaction
            ? _self.avgSatisfaction
            : avgSatisfaction // ignore: cast_nullable_to_non_nullable
                  as double,
        totalCount: null == totalCount
            ? _self.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$PerCategorySoulBreakdown {
  List<PerCategorySoulBreakdownItem> get items;
  int get totalCount;
  int get otherCount;
  int get otherCategoryCount;

  /// Create a copy of PerCategorySoulBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PerCategorySoulBreakdownCopyWith<PerCategorySoulBreakdown> get copyWith =>
      _$PerCategorySoulBreakdownCopyWithImpl<PerCategorySoulBreakdown>(
        this as PerCategorySoulBreakdown,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PerCategorySoulBreakdown &&
            const DeepCollectionEquality().equals(other.items, items) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.otherCount, otherCount) ||
                other.otherCount == otherCount) &&
            (identical(other.otherCategoryCount, otherCategoryCount) ||
                other.otherCategoryCount == otherCategoryCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(items),
    totalCount,
    otherCount,
    otherCategoryCount,
  );

  @override
  String toString() {
    return 'PerCategorySoulBreakdown(items: $items, totalCount: $totalCount, otherCount: $otherCount, otherCategoryCount: $otherCategoryCount)';
  }
}

/// @nodoc
abstract mixin class $PerCategorySoulBreakdownCopyWith<$Res> {
  factory $PerCategorySoulBreakdownCopyWith(
    PerCategorySoulBreakdown value,
    $Res Function(PerCategorySoulBreakdown) _then,
  ) = _$PerCategorySoulBreakdownCopyWithImpl;
  @useResult
  $Res call({
    List<PerCategorySoulBreakdownItem> items,
    int totalCount,
    int otherCount,
    int otherCategoryCount,
  });
}

/// @nodoc
class _$PerCategorySoulBreakdownCopyWithImpl<$Res>
    implements $PerCategorySoulBreakdownCopyWith<$Res> {
  _$PerCategorySoulBreakdownCopyWithImpl(this._self, this._then);

  final PerCategorySoulBreakdown _self;
  final $Res Function(PerCategorySoulBreakdown) _then;

  /// Create a copy of PerCategorySoulBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totalCount = null,
    Object? otherCount = null,
    Object? otherCategoryCount = null,
  }) {
    return _then(
      _self.copyWith(
        items: null == items
            ? _self.items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<PerCategorySoulBreakdownItem>,
        totalCount: null == totalCount
            ? _self.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
        otherCount: null == otherCount
            ? _self.otherCount
            : otherCount // ignore: cast_nullable_to_non_nullable
                  as int,
        otherCategoryCount: null == otherCategoryCount
            ? _self.otherCategoryCount
            : otherCategoryCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PerCategorySoulBreakdown].
extension PerCategorySoulBreakdownPatterns on PerCategorySoulBreakdown {
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
    TResult Function(_PerCategorySoulBreakdown value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdown() when $default != null:
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
    TResult Function(_PerCategorySoulBreakdown value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdown():
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
    TResult? Function(_PerCategorySoulBreakdown value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdown() when $default != null:
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
      List<PerCategorySoulBreakdownItem> items,
      int totalCount,
      int otherCount,
      int otherCategoryCount,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdown() when $default != null:
        return $default(
          _that.items,
          _that.totalCount,
          _that.otherCount,
          _that.otherCategoryCount,
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
      List<PerCategorySoulBreakdownItem> items,
      int totalCount,
      int otherCount,
      int otherCategoryCount,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdown():
        return $default(
          _that.items,
          _that.totalCount,
          _that.otherCount,
          _that.otherCategoryCount,
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
      List<PerCategorySoulBreakdownItem> items,
      int totalCount,
      int otherCount,
      int otherCategoryCount,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategorySoulBreakdown() when $default != null:
        return $default(
          _that.items,
          _that.totalCount,
          _that.otherCount,
          _that.otherCategoryCount,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PerCategorySoulBreakdown implements PerCategorySoulBreakdown {
  const _PerCategorySoulBreakdown({
    required final List<PerCategorySoulBreakdownItem> items,
    required this.totalCount,
    required this.otherCount,
    required this.otherCategoryCount,
  }) : _items = items;

  final List<PerCategorySoulBreakdownItem> _items;
  @override
  List<PerCategorySoulBreakdownItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int totalCount;
  @override
  final int otherCount;
  @override
  final int otherCategoryCount;

  /// Create a copy of PerCategorySoulBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PerCategorySoulBreakdownCopyWith<_PerCategorySoulBreakdown> get copyWith =>
      __$PerCategorySoulBreakdownCopyWithImpl<_PerCategorySoulBreakdown>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PerCategorySoulBreakdown &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.otherCount, otherCount) ||
                other.otherCount == otherCount) &&
            (identical(other.otherCategoryCount, otherCategoryCount) ||
                other.otherCategoryCount == otherCategoryCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    totalCount,
    otherCount,
    otherCategoryCount,
  );

  @override
  String toString() {
    return 'PerCategorySoulBreakdown(items: $items, totalCount: $totalCount, otherCount: $otherCount, otherCategoryCount: $otherCategoryCount)';
  }
}

/// @nodoc
abstract mixin class _$PerCategorySoulBreakdownCopyWith<$Res>
    implements $PerCategorySoulBreakdownCopyWith<$Res> {
  factory _$PerCategorySoulBreakdownCopyWith(
    _PerCategorySoulBreakdown value,
    $Res Function(_PerCategorySoulBreakdown) _then,
  ) = __$PerCategorySoulBreakdownCopyWithImpl;
  @override
  @useResult
  $Res call({
    List<PerCategorySoulBreakdownItem> items,
    int totalCount,
    int otherCount,
    int otherCategoryCount,
  });
}

/// @nodoc
class __$PerCategorySoulBreakdownCopyWithImpl<$Res>
    implements _$PerCategorySoulBreakdownCopyWith<$Res> {
  __$PerCategorySoulBreakdownCopyWithImpl(this._self, this._then);

  final _PerCategorySoulBreakdown _self;
  final $Res Function(_PerCategorySoulBreakdown) _then;

  /// Create a copy of PerCategorySoulBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? items = null,
    Object? totalCount = null,
    Object? otherCount = null,
    Object? otherCategoryCount = null,
  }) {
    return _then(
      _PerCategorySoulBreakdown(
        items: null == items
            ? _self._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<PerCategorySoulBreakdownItem>,
        totalCount: null == totalCount
            ? _self.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
        otherCount: null == otherCount
            ? _self.otherCount
            : otherCount // ignore: cast_nullable_to_non_nullable
                  as int,
        otherCategoryCount: null == otherCategoryCount
            ? _self.otherCategoryCount
            : otherCategoryCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

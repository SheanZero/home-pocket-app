// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'per_category_joy_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PerCategoryJoyBreakdownItem {
  String get categoryId;
  double get avgSatisfaction;
  int get totalCount;

  /// Create a copy of PerCategoryJoyBreakdownItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PerCategoryJoyBreakdownItemCopyWith<PerCategoryJoyBreakdownItem>
  get copyWith =>
      _$PerCategoryJoyBreakdownItemCopyWithImpl<PerCategoryJoyBreakdownItem>(
        this as PerCategoryJoyBreakdownItem,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PerCategoryJoyBreakdownItem &&
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
    return 'PerCategoryJoyBreakdownItem(categoryId: $categoryId, avgSatisfaction: $avgSatisfaction, totalCount: $totalCount)';
  }
}

/// @nodoc
abstract mixin class $PerCategoryJoyBreakdownItemCopyWith<$Res> {
  factory $PerCategoryJoyBreakdownItemCopyWith(
    PerCategoryJoyBreakdownItem value,
    $Res Function(PerCategoryJoyBreakdownItem) _then,
  ) = _$PerCategoryJoyBreakdownItemCopyWithImpl;
  @useResult
  $Res call({String categoryId, double avgSatisfaction, int totalCount});
}

/// @nodoc
class _$PerCategoryJoyBreakdownItemCopyWithImpl<$Res>
    implements $PerCategoryJoyBreakdownItemCopyWith<$Res> {
  _$PerCategoryJoyBreakdownItemCopyWithImpl(this._self, this._then);

  final PerCategoryJoyBreakdownItem _self;
  final $Res Function(PerCategoryJoyBreakdownItem) _then;

  /// Create a copy of PerCategoryJoyBreakdownItem
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

/// Adds pattern-matching-related methods to [PerCategoryJoyBreakdownItem].
extension PerCategoryJoyBreakdownItemPatterns on PerCategoryJoyBreakdownItem {
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
    TResult Function(_PerCategoryJoyBreakdownItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PerCategoryJoyBreakdownItem() when $default != null:
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
    TResult Function(_PerCategoryJoyBreakdownItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategoryJoyBreakdownItem():
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
    TResult? Function(_PerCategoryJoyBreakdownItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategoryJoyBreakdownItem() when $default != null:
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
      case _PerCategoryJoyBreakdownItem() when $default != null:
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
      case _PerCategoryJoyBreakdownItem():
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
      case _PerCategoryJoyBreakdownItem() when $default != null:
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

class _PerCategoryJoyBreakdownItem implements PerCategoryJoyBreakdownItem {
  const _PerCategoryJoyBreakdownItem({
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

  /// Create a copy of PerCategoryJoyBreakdownItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PerCategoryJoyBreakdownItemCopyWith<_PerCategoryJoyBreakdownItem>
  get copyWith =>
      __$PerCategoryJoyBreakdownItemCopyWithImpl<_PerCategoryJoyBreakdownItem>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PerCategoryJoyBreakdownItem &&
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
    return 'PerCategoryJoyBreakdownItem(categoryId: $categoryId, avgSatisfaction: $avgSatisfaction, totalCount: $totalCount)';
  }
}

/// @nodoc
abstract mixin class _$PerCategoryJoyBreakdownItemCopyWith<$Res>
    implements $PerCategoryJoyBreakdownItemCopyWith<$Res> {
  factory _$PerCategoryJoyBreakdownItemCopyWith(
    _PerCategoryJoyBreakdownItem value,
    $Res Function(_PerCategoryJoyBreakdownItem) _then,
  ) = __$PerCategoryJoyBreakdownItemCopyWithImpl;
  @override
  @useResult
  $Res call({String categoryId, double avgSatisfaction, int totalCount});
}

/// @nodoc
class __$PerCategoryJoyBreakdownItemCopyWithImpl<$Res>
    implements _$PerCategoryJoyBreakdownItemCopyWith<$Res> {
  __$PerCategoryJoyBreakdownItemCopyWithImpl(this._self, this._then);

  final _PerCategoryJoyBreakdownItem _self;
  final $Res Function(_PerCategoryJoyBreakdownItem) _then;

  /// Create a copy of PerCategoryJoyBreakdownItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? categoryId = null,
    Object? avgSatisfaction = null,
    Object? totalCount = null,
  }) {
    return _then(
      _PerCategoryJoyBreakdownItem(
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
mixin _$PerCategoryJoyBreakdown {
  List<PerCategoryJoyBreakdownItem> get items;
  int get totalCount;
  int get otherCount;
  int get otherCategoryCount;

  /// Create a copy of PerCategoryJoyBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PerCategoryJoyBreakdownCopyWith<PerCategoryJoyBreakdown> get copyWith =>
      _$PerCategoryJoyBreakdownCopyWithImpl<PerCategoryJoyBreakdown>(
        this as PerCategoryJoyBreakdown,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PerCategoryJoyBreakdown &&
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
    return 'PerCategoryJoyBreakdown(items: $items, totalCount: $totalCount, otherCount: $otherCount, otherCategoryCount: $otherCategoryCount)';
  }
}

/// @nodoc
abstract mixin class $PerCategoryJoyBreakdownCopyWith<$Res> {
  factory $PerCategoryJoyBreakdownCopyWith(
    PerCategoryJoyBreakdown value,
    $Res Function(PerCategoryJoyBreakdown) _then,
  ) = _$PerCategoryJoyBreakdownCopyWithImpl;
  @useResult
  $Res call({
    List<PerCategoryJoyBreakdownItem> items,
    int totalCount,
    int otherCount,
    int otherCategoryCount,
  });
}

/// @nodoc
class _$PerCategoryJoyBreakdownCopyWithImpl<$Res>
    implements $PerCategoryJoyBreakdownCopyWith<$Res> {
  _$PerCategoryJoyBreakdownCopyWithImpl(this._self, this._then);

  final PerCategoryJoyBreakdown _self;
  final $Res Function(PerCategoryJoyBreakdown) _then;

  /// Create a copy of PerCategoryJoyBreakdown
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
                  as List<PerCategoryJoyBreakdownItem>,
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

/// Adds pattern-matching-related methods to [PerCategoryJoyBreakdown].
extension PerCategoryJoyBreakdownPatterns on PerCategoryJoyBreakdown {
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
    TResult Function(_PerCategoryJoyBreakdown value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PerCategoryJoyBreakdown() when $default != null:
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
    TResult Function(_PerCategoryJoyBreakdown value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategoryJoyBreakdown():
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
    TResult? Function(_PerCategoryJoyBreakdown value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategoryJoyBreakdown() when $default != null:
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
      List<PerCategoryJoyBreakdownItem> items,
      int totalCount,
      int otherCount,
      int otherCategoryCount,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PerCategoryJoyBreakdown() when $default != null:
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
      List<PerCategoryJoyBreakdownItem> items,
      int totalCount,
      int otherCount,
      int otherCategoryCount,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategoryJoyBreakdown():
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
      List<PerCategoryJoyBreakdownItem> items,
      int totalCount,
      int otherCount,
      int otherCategoryCount,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PerCategoryJoyBreakdown() when $default != null:
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

class _PerCategoryJoyBreakdown implements PerCategoryJoyBreakdown {
  const _PerCategoryJoyBreakdown({
    required final List<PerCategoryJoyBreakdownItem> items,
    required this.totalCount,
    required this.otherCount,
    required this.otherCategoryCount,
  }) : _items = items;

  final List<PerCategoryJoyBreakdownItem> _items;
  @override
  List<PerCategoryJoyBreakdownItem> get items {
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

  /// Create a copy of PerCategoryJoyBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PerCategoryJoyBreakdownCopyWith<_PerCategoryJoyBreakdown> get copyWith =>
      __$PerCategoryJoyBreakdownCopyWithImpl<_PerCategoryJoyBreakdown>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PerCategoryJoyBreakdown &&
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
    return 'PerCategoryJoyBreakdown(items: $items, totalCount: $totalCount, otherCount: $otherCount, otherCategoryCount: $otherCategoryCount)';
  }
}

/// @nodoc
abstract mixin class _$PerCategoryJoyBreakdownCopyWith<$Res>
    implements $PerCategoryJoyBreakdownCopyWith<$Res> {
  factory _$PerCategoryJoyBreakdownCopyWith(
    _PerCategoryJoyBreakdown value,
    $Res Function(_PerCategoryJoyBreakdown) _then,
  ) = __$PerCategoryJoyBreakdownCopyWithImpl;
  @override
  @useResult
  $Res call({
    List<PerCategoryJoyBreakdownItem> items,
    int totalCount,
    int otherCount,
    int otherCategoryCount,
  });
}

/// @nodoc
class __$PerCategoryJoyBreakdownCopyWithImpl<$Res>
    implements _$PerCategoryJoyBreakdownCopyWith<$Res> {
  __$PerCategoryJoyBreakdownCopyWithImpl(this._self, this._then);

  final _PerCategoryJoyBreakdown _self;
  final $Res Function(_PerCategoryJoyBreakdown) _then;

  /// Create a copy of PerCategoryJoyBreakdown
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
      _PerCategoryJoyBreakdown(
        items: null == items
            ? _self._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<PerCategoryJoyBreakdownItem>,
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

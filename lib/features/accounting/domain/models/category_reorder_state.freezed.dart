// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_reorder_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryReorderState {
  CategoryReorderMode get mode;
  List<Category> get l1;
  Map<String, List<Category>> get l2ByParent;
  bool get isDirty;

  /// Create a copy of CategoryReorderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CategoryReorderStateCopyWith<CategoryReorderState> get copyWith =>
      _$CategoryReorderStateCopyWithImpl<CategoryReorderState>(
        this as CategoryReorderState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CategoryReorderState &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality().equals(other.l1, l1) &&
            const DeepCollectionEquality().equals(
              other.l2ByParent,
              l2ByParent,
            ) &&
            (identical(other.isDirty, isDirty) || other.isDirty == isDirty));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    mode,
    const DeepCollectionEquality().hash(l1),
    const DeepCollectionEquality().hash(l2ByParent),
    isDirty,
  );

  @override
  String toString() {
    return 'CategoryReorderState(mode: $mode, l1: $l1, l2ByParent: $l2ByParent, isDirty: $isDirty)';
  }
}

/// @nodoc
abstract mixin class $CategoryReorderStateCopyWith<$Res> {
  factory $CategoryReorderStateCopyWith(
    CategoryReorderState value,
    $Res Function(CategoryReorderState) _then,
  ) = _$CategoryReorderStateCopyWithImpl;
  @useResult
  $Res call({
    CategoryReorderMode mode,
    List<Category> l1,
    Map<String, List<Category>> l2ByParent,
    bool isDirty,
  });
}

/// @nodoc
class _$CategoryReorderStateCopyWithImpl<$Res>
    implements $CategoryReorderStateCopyWith<$Res> {
  _$CategoryReorderStateCopyWithImpl(this._self, this._then);

  final CategoryReorderState _self;
  final $Res Function(CategoryReorderState) _then;

  /// Create a copy of CategoryReorderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? l1 = null,
    Object? l2ByParent = null,
    Object? isDirty = null,
  }) {
    return _then(
      _self.copyWith(
        mode: null == mode
            ? _self.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as CategoryReorderMode,
        l1: null == l1
            ? _self.l1
            : l1 // ignore: cast_nullable_to_non_nullable
                  as List<Category>,
        l2ByParent: null == l2ByParent
            ? _self.l2ByParent
            : l2ByParent // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<Category>>,
        isDirty: null == isDirty
            ? _self.isDirty
            : isDirty // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [CategoryReorderState].
extension CategoryReorderStatePatterns on CategoryReorderState {
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
    TResult Function(_CategoryReorderState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CategoryReorderState() when $default != null:
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
    TResult Function(_CategoryReorderState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryReorderState():
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
    TResult? Function(_CategoryReorderState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryReorderState() when $default != null:
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
      CategoryReorderMode mode,
      List<Category> l1,
      Map<String, List<Category>> l2ByParent,
      bool isDirty,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CategoryReorderState() when $default != null:
        return $default(_that.mode, _that.l1, _that.l2ByParent, _that.isDirty);
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
      CategoryReorderMode mode,
      List<Category> l1,
      Map<String, List<Category>> l2ByParent,
      bool isDirty,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryReorderState():
        return $default(_that.mode, _that.l1, _that.l2ByParent, _that.isDirty);
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
      CategoryReorderMode mode,
      List<Category> l1,
      Map<String, List<Category>> l2ByParent,
      bool isDirty,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryReorderState() when $default != null:
        return $default(_that.mode, _that.l1, _that.l2ByParent, _that.isDirty);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CategoryReorderState extends CategoryReorderState {
  const _CategoryReorderState({
    this.mode = CategoryReorderMode.idle,
    final List<Category> l1 = const [],
    final Map<String, List<Category>> l2ByParent = const {},
    this.isDirty = false,
  }) : _l1 = l1,
       _l2ByParent = l2ByParent,
       super._();

  @override
  @JsonKey()
  final CategoryReorderMode mode;
  final List<Category> _l1;
  @override
  @JsonKey()
  List<Category> get l1 {
    if (_l1 is EqualUnmodifiableListView) return _l1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_l1);
  }

  final Map<String, List<Category>> _l2ByParent;
  @override
  @JsonKey()
  Map<String, List<Category>> get l2ByParent {
    if (_l2ByParent is EqualUnmodifiableMapView) return _l2ByParent;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_l2ByParent);
  }

  @override
  @JsonKey()
  final bool isDirty;

  /// Create a copy of CategoryReorderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CategoryReorderStateCopyWith<_CategoryReorderState> get copyWith =>
      __$CategoryReorderStateCopyWithImpl<_CategoryReorderState>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CategoryReorderState &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality().equals(other._l1, _l1) &&
            const DeepCollectionEquality().equals(
              other._l2ByParent,
              _l2ByParent,
            ) &&
            (identical(other.isDirty, isDirty) || other.isDirty == isDirty));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    mode,
    const DeepCollectionEquality().hash(_l1),
    const DeepCollectionEquality().hash(_l2ByParent),
    isDirty,
  );

  @override
  String toString() {
    return 'CategoryReorderState(mode: $mode, l1: $l1, l2ByParent: $l2ByParent, isDirty: $isDirty)';
  }
}

/// @nodoc
abstract mixin class _$CategoryReorderStateCopyWith<$Res>
    implements $CategoryReorderStateCopyWith<$Res> {
  factory _$CategoryReorderStateCopyWith(
    _CategoryReorderState value,
    $Res Function(_CategoryReorderState) _then,
  ) = __$CategoryReorderStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    CategoryReorderMode mode,
    List<Category> l1,
    Map<String, List<Category>> l2ByParent,
    bool isDirty,
  });
}

/// @nodoc
class __$CategoryReorderStateCopyWithImpl<$Res>
    implements _$CategoryReorderStateCopyWith<$Res> {
  __$CategoryReorderStateCopyWithImpl(this._self, this._then);

  final _CategoryReorderState _self;
  final $Res Function(_CategoryReorderState) _then;

  /// Create a copy of CategoryReorderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? mode = null,
    Object? l1 = null,
    Object? l2ByParent = null,
    Object? isDirty = null,
  }) {
    return _then(
      _CategoryReorderState(
        mode: null == mode
            ? _self.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as CategoryReorderMode,
        l1: null == l1
            ? _self._l1
            : l1 // ignore: cast_nullable_to_non_nullable
                  as List<Category>,
        l2ByParent: null == l2ByParent
            ? _self._l2ByParent
            : l2ByParent // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<Category>>,
        isDirty: null == isDirty
            ? _self.isDirty
            : isDirty // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

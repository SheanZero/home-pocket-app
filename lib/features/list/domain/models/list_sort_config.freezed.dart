// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_sort_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ListSortConfig {
  SortField get sortField;
  SortDirection get sortDirection;

  /// Create a copy of ListSortConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ListSortConfigCopyWith<ListSortConfig> get copyWith =>
      _$ListSortConfigCopyWithImpl<ListSortConfig>(
        this as ListSortConfig,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ListSortConfig &&
            (identical(other.sortField, sortField) ||
                other.sortField == sortField) &&
            (identical(other.sortDirection, sortDirection) ||
                other.sortDirection == sortDirection));
  }

  @override
  int get hashCode => Object.hash(runtimeType, sortField, sortDirection);

  @override
  String toString() {
    return 'ListSortConfig(sortField: $sortField, sortDirection: $sortDirection)';
  }
}

/// @nodoc
abstract mixin class $ListSortConfigCopyWith<$Res> {
  factory $ListSortConfigCopyWith(
    ListSortConfig value,
    $Res Function(ListSortConfig) _then,
  ) = _$ListSortConfigCopyWithImpl;
  @useResult
  $Res call({SortField sortField, SortDirection sortDirection});
}

/// @nodoc
class _$ListSortConfigCopyWithImpl<$Res>
    implements $ListSortConfigCopyWith<$Res> {
  _$ListSortConfigCopyWithImpl(this._self, this._then);

  final ListSortConfig _self;
  final $Res Function(ListSortConfig) _then;

  /// Create a copy of ListSortConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sortField = null, Object? sortDirection = null}) {
    return _then(
      _self.copyWith(
        sortField: null == sortField
            ? _self.sortField
            : sortField // ignore: cast_nullable_to_non_nullable
                  as SortField,
        sortDirection: null == sortDirection
            ? _self.sortDirection
            : sortDirection // ignore: cast_nullable_to_non_nullable
                  as SortDirection,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ListSortConfig].
extension ListSortConfigPatterns on ListSortConfig {
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
    TResult Function(_ListSortConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ListSortConfig() when $default != null:
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
    TResult Function(_ListSortConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ListSortConfig():
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
    TResult? Function(_ListSortConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ListSortConfig() when $default != null:
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
    TResult Function(SortField sortField, SortDirection sortDirection)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ListSortConfig() when $default != null:
        return $default(_that.sortField, _that.sortDirection);
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
    TResult Function(SortField sortField, SortDirection sortDirection) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ListSortConfig():
        return $default(_that.sortField, _that.sortDirection);
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
    TResult? Function(SortField sortField, SortDirection sortDirection)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ListSortConfig() when $default != null:
        return $default(_that.sortField, _that.sortDirection);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ListSortConfig implements ListSortConfig {
  const _ListSortConfig({
    this.sortField = SortField.updatedAt,
    this.sortDirection = SortDirection.desc,
  });

  @override
  @JsonKey()
  final SortField sortField;
  @override
  @JsonKey()
  final SortDirection sortDirection;

  /// Create a copy of ListSortConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ListSortConfigCopyWith<_ListSortConfig> get copyWith =>
      __$ListSortConfigCopyWithImpl<_ListSortConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ListSortConfig &&
            (identical(other.sortField, sortField) ||
                other.sortField == sortField) &&
            (identical(other.sortDirection, sortDirection) ||
                other.sortDirection == sortDirection));
  }

  @override
  int get hashCode => Object.hash(runtimeType, sortField, sortDirection);

  @override
  String toString() {
    return 'ListSortConfig(sortField: $sortField, sortDirection: $sortDirection)';
  }
}

/// @nodoc
abstract mixin class _$ListSortConfigCopyWith<$Res>
    implements $ListSortConfigCopyWith<$Res> {
  factory _$ListSortConfigCopyWith(
    _ListSortConfig value,
    $Res Function(_ListSortConfig) _then,
  ) = __$ListSortConfigCopyWithImpl;
  @override
  @useResult
  $Res call({SortField sortField, SortDirection sortDirection});
}

/// @nodoc
class __$ListSortConfigCopyWithImpl<$Res>
    implements _$ListSortConfigCopyWith<$Res> {
  __$ListSortConfigCopyWithImpl(this._self, this._then);

  final _ListSortConfig _self;
  final $Res Function(_ListSortConfig) _then;

  /// Create a copy of ListSortConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? sortField = null, Object? sortDirection = null}) {
    return _then(
      _ListSortConfig(
        sortField: null == sortField
            ? _self.sortField
            : sortField // ignore: cast_nullable_to_non_nullable
                  as SortField,
        sortDirection: null == sortDirection
            ? _self.sortDirection
            : sortDirection // ignore: cast_nullable_to_non_nullable
                  as SortDirection,
      ),
    );
  }
}

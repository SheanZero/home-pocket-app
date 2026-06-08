// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_list_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShoppingListFilter {
  String get listType;
  LedgerType? get ledgerType;
  String get statusFilter;
  String get searchQuery;
  Set<String> get categoryIds;

  /// Create a copy of ShoppingListFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ShoppingListFilterCopyWith<ShoppingListFilter> get copyWith =>
      _$ShoppingListFilterCopyWithImpl<ShoppingListFilter>(
        this as ShoppingListFilter,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ShoppingListFilter &&
            (identical(other.listType, listType) ||
                other.listType == listType) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.statusFilter, statusFilter) ||
                other.statusFilter == statusFilter) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            const DeepCollectionEquality().equals(
              other.categoryIds,
              categoryIds,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    listType,
    ledgerType,
    statusFilter,
    searchQuery,
    const DeepCollectionEquality().hash(categoryIds),
  );

  @override
  String toString() {
    return 'ShoppingListFilter(listType: $listType, ledgerType: $ledgerType, statusFilter: $statusFilter, searchQuery: $searchQuery, categoryIds: $categoryIds)';
  }
}

/// @nodoc
abstract mixin class $ShoppingListFilterCopyWith<$Res> {
  factory $ShoppingListFilterCopyWith(
    ShoppingListFilter value,
    $Res Function(ShoppingListFilter) _then,
  ) = _$ShoppingListFilterCopyWithImpl;
  @useResult
  $Res call({
    String listType,
    LedgerType? ledgerType,
    String statusFilter,
    String searchQuery,
    Set<String> categoryIds,
  });
}

/// @nodoc
class _$ShoppingListFilterCopyWithImpl<$Res>
    implements $ShoppingListFilterCopyWith<$Res> {
  _$ShoppingListFilterCopyWithImpl(this._self, this._then);

  final ShoppingListFilter _self;
  final $Res Function(ShoppingListFilter) _then;

  /// Create a copy of ShoppingListFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? listType = null,
    Object? ledgerType = freezed,
    Object? statusFilter = null,
    Object? searchQuery = null,
    Object? categoryIds = null,
  }) {
    return _then(
      _self.copyWith(
        listType: null == listType
            ? _self.listType
            : listType // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerType: freezed == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        statusFilter: null == statusFilter
            ? _self.statusFilter
            : statusFilter // ignore: cast_nullable_to_non_nullable
                  as String,
        searchQuery: null == searchQuery
            ? _self.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryIds: null == categoryIds
            ? _self.categoryIds
            : categoryIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ShoppingListFilter].
extension ShoppingListFilterPatterns on ShoppingListFilter {
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
    TResult Function(_ShoppingListFilter value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingListFilter() when $default != null:
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
    TResult Function(_ShoppingListFilter value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingListFilter():
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
    TResult? Function(_ShoppingListFilter value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingListFilter() when $default != null:
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
      String listType,
      LedgerType? ledgerType,
      String statusFilter,
      String searchQuery,
      Set<String> categoryIds,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingListFilter() when $default != null:
        return $default(
          _that.listType,
          _that.ledgerType,
          _that.statusFilter,
          _that.searchQuery,
          _that.categoryIds,
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
      String listType,
      LedgerType? ledgerType,
      String statusFilter,
      String searchQuery,
      Set<String> categoryIds,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingListFilter():
        return $default(
          _that.listType,
          _that.ledgerType,
          _that.statusFilter,
          _that.searchQuery,
          _that.categoryIds,
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
      String listType,
      LedgerType? ledgerType,
      String statusFilter,
      String searchQuery,
      Set<String> categoryIds,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingListFilter() when $default != null:
        return $default(
          _that.listType,
          _that.ledgerType,
          _that.statusFilter,
          _that.searchQuery,
          _that.categoryIds,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ShoppingListFilter implements ShoppingListFilter {
  const _ShoppingListFilter({
    this.listType = 'private',
    this.ledgerType,
    this.statusFilter = 'all',
    this.searchQuery = '',
    final Set<String> categoryIds = const <String>{},
  }) : _categoryIds = categoryIds;

  @override
  @JsonKey()
  final String listType;
  @override
  final LedgerType? ledgerType;
  @override
  @JsonKey()
  final String statusFilter;
  @override
  @JsonKey()
  final String searchQuery;
  final Set<String> _categoryIds;
  @override
  @JsonKey()
  Set<String> get categoryIds {
    if (_categoryIds is EqualUnmodifiableSetView) return _categoryIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_categoryIds);
  }

  /// Create a copy of ShoppingListFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ShoppingListFilterCopyWith<_ShoppingListFilter> get copyWith =>
      __$ShoppingListFilterCopyWithImpl<_ShoppingListFilter>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ShoppingListFilter &&
            (identical(other.listType, listType) ||
                other.listType == listType) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.statusFilter, statusFilter) ||
                other.statusFilter == statusFilter) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            const DeepCollectionEquality().equals(
              other._categoryIds,
              _categoryIds,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    listType,
    ledgerType,
    statusFilter,
    searchQuery,
    const DeepCollectionEquality().hash(_categoryIds),
  );

  @override
  String toString() {
    return 'ShoppingListFilter(listType: $listType, ledgerType: $ledgerType, statusFilter: $statusFilter, searchQuery: $searchQuery, categoryIds: $categoryIds)';
  }
}

/// @nodoc
abstract mixin class _$ShoppingListFilterCopyWith<$Res>
    implements $ShoppingListFilterCopyWith<$Res> {
  factory _$ShoppingListFilterCopyWith(
    _ShoppingListFilter value,
    $Res Function(_ShoppingListFilter) _then,
  ) = __$ShoppingListFilterCopyWithImpl;
  @override
  @useResult
  $Res call({
    String listType,
    LedgerType? ledgerType,
    String statusFilter,
    String searchQuery,
    Set<String> categoryIds,
  });
}

/// @nodoc
class __$ShoppingListFilterCopyWithImpl<$Res>
    implements _$ShoppingListFilterCopyWith<$Res> {
  __$ShoppingListFilterCopyWithImpl(this._self, this._then);

  final _ShoppingListFilter _self;
  final $Res Function(_ShoppingListFilter) _then;

  /// Create a copy of ShoppingListFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? listType = null,
    Object? ledgerType = freezed,
    Object? statusFilter = null,
    Object? searchQuery = null,
    Object? categoryIds = null,
  }) {
    return _then(
      _ShoppingListFilter(
        listType: null == listType
            ? _self.listType
            : listType // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerType: freezed == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        statusFilter: null == statusFilter
            ? _self.statusFilter
            : statusFilter // ignore: cast_nullable_to_non_nullable
                  as String,
        searchQuery: null == searchQuery
            ? _self.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryIds: null == categoryIds
            ? _self._categoryIds
            : categoryIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
      ),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_filter_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ListFilterState {
  int get selectedYear;
  int get selectedMonth;
  DateTime? get activeDayFilter;
  ListSortConfig get sortConfig;
  LedgerType? get ledgerType;
  Set<String> get categoryIds;
  String get searchQuery;
  String? get memberBookId;

  /// Create a copy of ListFilterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ListFilterStateCopyWith<ListFilterState> get copyWith =>
      _$ListFilterStateCopyWithImpl<ListFilterState>(
        this as ListFilterState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ListFilterState &&
            (identical(other.selectedYear, selectedYear) ||
                other.selectedYear == selectedYear) &&
            (identical(other.selectedMonth, selectedMonth) ||
                other.selectedMonth == selectedMonth) &&
            (identical(other.activeDayFilter, activeDayFilter) ||
                other.activeDayFilter == activeDayFilter) &&
            (identical(other.sortConfig, sortConfig) ||
                other.sortConfig == sortConfig) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            const DeepCollectionEquality().equals(
              other.categoryIds,
              categoryIds,
            ) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.memberBookId, memberBookId) ||
                other.memberBookId == memberBookId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    selectedYear,
    selectedMonth,
    activeDayFilter,
    sortConfig,
    ledgerType,
    const DeepCollectionEquality().hash(categoryIds),
    searchQuery,
    memberBookId,
  );

  @override
  String toString() {
    return 'ListFilterState(selectedYear: $selectedYear, selectedMonth: $selectedMonth, activeDayFilter: $activeDayFilter, sortConfig: $sortConfig, ledgerType: $ledgerType, categoryIds: $categoryIds, searchQuery: $searchQuery, memberBookId: $memberBookId)';
  }
}

/// @nodoc
abstract mixin class $ListFilterStateCopyWith<$Res> {
  factory $ListFilterStateCopyWith(
    ListFilterState value,
    $Res Function(ListFilterState) _then,
  ) = _$ListFilterStateCopyWithImpl;
  @useResult
  $Res call({
    int selectedYear,
    int selectedMonth,
    DateTime? activeDayFilter,
    ListSortConfig sortConfig,
    LedgerType? ledgerType,
    Set<String> categoryIds,
    String searchQuery,
    String? memberBookId,
  });

  $ListSortConfigCopyWith<$Res> get sortConfig;
}

/// @nodoc
class _$ListFilterStateCopyWithImpl<$Res>
    implements $ListFilterStateCopyWith<$Res> {
  _$ListFilterStateCopyWithImpl(this._self, this._then);

  final ListFilterState _self;
  final $Res Function(ListFilterState) _then;

  /// Create a copy of ListFilterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedYear = null,
    Object? selectedMonth = null,
    Object? activeDayFilter = freezed,
    Object? sortConfig = null,
    Object? ledgerType = freezed,
    Object? categoryIds = null,
    Object? searchQuery = null,
    Object? memberBookId = freezed,
  }) {
    return _then(
      _self.copyWith(
        selectedYear: null == selectedYear
            ? _self.selectedYear
            : selectedYear // ignore: cast_nullable_to_non_nullable
                  as int,
        selectedMonth: null == selectedMonth
            ? _self.selectedMonth
            : selectedMonth // ignore: cast_nullable_to_non_nullable
                  as int,
        activeDayFilter: freezed == activeDayFilter
            ? _self.activeDayFilter
            : activeDayFilter // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        sortConfig: null == sortConfig
            ? _self.sortConfig
            : sortConfig // ignore: cast_nullable_to_non_nullable
                  as ListSortConfig,
        ledgerType: freezed == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        categoryIds: null == categoryIds
            ? _self.categoryIds
            : categoryIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        searchQuery: null == searchQuery
            ? _self.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String,
        memberBookId: freezed == memberBookId
            ? _self.memberBookId
            : memberBookId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of ListFilterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ListSortConfigCopyWith<$Res> get sortConfig {
    return $ListSortConfigCopyWith<$Res>(_self.sortConfig, (value) {
      return _then(_self.copyWith(sortConfig: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ListFilterState].
extension ListFilterStatePatterns on ListFilterState {
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
    TResult Function(_ListFilterState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ListFilterState() when $default != null:
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
    TResult Function(_ListFilterState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ListFilterState():
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
    TResult? Function(_ListFilterState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ListFilterState() when $default != null:
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
      int selectedYear,
      int selectedMonth,
      DateTime? activeDayFilter,
      ListSortConfig sortConfig,
      LedgerType? ledgerType,
      Set<String> categoryIds,
      String searchQuery,
      String? memberBookId,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ListFilterState() when $default != null:
        return $default(
          _that.selectedYear,
          _that.selectedMonth,
          _that.activeDayFilter,
          _that.sortConfig,
          _that.ledgerType,
          _that.categoryIds,
          _that.searchQuery,
          _that.memberBookId,
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
      int selectedYear,
      int selectedMonth,
      DateTime? activeDayFilter,
      ListSortConfig sortConfig,
      LedgerType? ledgerType,
      Set<String> categoryIds,
      String searchQuery,
      String? memberBookId,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ListFilterState():
        return $default(
          _that.selectedYear,
          _that.selectedMonth,
          _that.activeDayFilter,
          _that.sortConfig,
          _that.ledgerType,
          _that.categoryIds,
          _that.searchQuery,
          _that.memberBookId,
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
      int selectedYear,
      int selectedMonth,
      DateTime? activeDayFilter,
      ListSortConfig sortConfig,
      LedgerType? ledgerType,
      Set<String> categoryIds,
      String searchQuery,
      String? memberBookId,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ListFilterState() when $default != null:
        return $default(
          _that.selectedYear,
          _that.selectedMonth,
          _that.activeDayFilter,
          _that.sortConfig,
          _that.ledgerType,
          _that.categoryIds,
          _that.searchQuery,
          _that.memberBookId,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ListFilterState extends ListFilterState {
  const _ListFilterState({
    required this.selectedYear,
    required this.selectedMonth,
    this.activeDayFilter,
    this.sortConfig = const ListSortConfig(),
    this.ledgerType,
    final Set<String> categoryIds = const <String>{},
    this.searchQuery = '',
    this.memberBookId,
  }) : _categoryIds = categoryIds,
       super._();

  @override
  final int selectedYear;
  @override
  final int selectedMonth;
  @override
  final DateTime? activeDayFilter;
  @override
  @JsonKey()
  final ListSortConfig sortConfig;
  @override
  final LedgerType? ledgerType;
  final Set<String> _categoryIds;
  @override
  @JsonKey()
  Set<String> get categoryIds {
    if (_categoryIds is EqualUnmodifiableSetView) return _categoryIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_categoryIds);
  }

  @override
  @JsonKey()
  final String searchQuery;
  @override
  final String? memberBookId;

  /// Create a copy of ListFilterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ListFilterStateCopyWith<_ListFilterState> get copyWith =>
      __$ListFilterStateCopyWithImpl<_ListFilterState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ListFilterState &&
            (identical(other.selectedYear, selectedYear) ||
                other.selectedYear == selectedYear) &&
            (identical(other.selectedMonth, selectedMonth) ||
                other.selectedMonth == selectedMonth) &&
            (identical(other.activeDayFilter, activeDayFilter) ||
                other.activeDayFilter == activeDayFilter) &&
            (identical(other.sortConfig, sortConfig) ||
                other.sortConfig == sortConfig) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            const DeepCollectionEquality().equals(
              other._categoryIds,
              _categoryIds,
            ) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.memberBookId, memberBookId) ||
                other.memberBookId == memberBookId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    selectedYear,
    selectedMonth,
    activeDayFilter,
    sortConfig,
    ledgerType,
    const DeepCollectionEquality().hash(_categoryIds),
    searchQuery,
    memberBookId,
  );

  @override
  String toString() {
    return 'ListFilterState(selectedYear: $selectedYear, selectedMonth: $selectedMonth, activeDayFilter: $activeDayFilter, sortConfig: $sortConfig, ledgerType: $ledgerType, categoryIds: $categoryIds, searchQuery: $searchQuery, memberBookId: $memberBookId)';
  }
}

/// @nodoc
abstract mixin class _$ListFilterStateCopyWith<$Res>
    implements $ListFilterStateCopyWith<$Res> {
  factory _$ListFilterStateCopyWith(
    _ListFilterState value,
    $Res Function(_ListFilterState) _then,
  ) = __$ListFilterStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    int selectedYear,
    int selectedMonth,
    DateTime? activeDayFilter,
    ListSortConfig sortConfig,
    LedgerType? ledgerType,
    Set<String> categoryIds,
    String searchQuery,
    String? memberBookId,
  });

  @override
  $ListSortConfigCopyWith<$Res> get sortConfig;
}

/// @nodoc
class __$ListFilterStateCopyWithImpl<$Res>
    implements _$ListFilterStateCopyWith<$Res> {
  __$ListFilterStateCopyWithImpl(this._self, this._then);

  final _ListFilterState _self;
  final $Res Function(_ListFilterState) _then;

  /// Create a copy of ListFilterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? selectedYear = null,
    Object? selectedMonth = null,
    Object? activeDayFilter = freezed,
    Object? sortConfig = null,
    Object? ledgerType = freezed,
    Object? categoryIds = null,
    Object? searchQuery = null,
    Object? memberBookId = freezed,
  }) {
    return _then(
      _ListFilterState(
        selectedYear: null == selectedYear
            ? _self.selectedYear
            : selectedYear // ignore: cast_nullable_to_non_nullable
                  as int,
        selectedMonth: null == selectedMonth
            ? _self.selectedMonth
            : selectedMonth // ignore: cast_nullable_to_non_nullable
                  as int,
        activeDayFilter: freezed == activeDayFilter
            ? _self.activeDayFilter
            : activeDayFilter // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        sortConfig: null == sortConfig
            ? _self.sortConfig
            : sortConfig // ignore: cast_nullable_to_non_nullable
                  as ListSortConfig,
        ledgerType: freezed == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        categoryIds: null == categoryIds
            ? _self._categoryIds
            : categoryIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        searchQuery: null == searchQuery
            ? _self.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String,
        memberBookId: freezed == memberBookId
            ? _self.memberBookId
            : memberBookId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of ListFilterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ListSortConfigCopyWith<$Res> get sortConfig {
    return $ListSortConfigCopyWith<$Res>(_self.sortConfig, (value) {
      return _then(_self.copyWith(sortConfig: value));
    });
  }
}

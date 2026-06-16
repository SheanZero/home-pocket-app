// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_drill_down.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryDrillDown {
  /// Window + L1-filtered transactions, sorted time-descending.
  List<Transaction> get transactions;

  /// Sum of [transactions] amounts (minor units), sourced from Plan 01's
  /// `l1RollupFromTransactions` — the single source-of-truth (D-11).
  int get subtotal;

  /// Number of transactions in this L1 for the window.
  int get count;

  /// Plain descriptive average per window-day (subtotal / window days).
  /// Descriptive only — never a target/goal (D-03, ADR-012-safe).
  int? get avgPerDay;

  /// Create a copy of CategoryDrillDown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CategoryDrillDownCopyWith<CategoryDrillDown> get copyWith =>
      _$CategoryDrillDownCopyWithImpl<CategoryDrillDown>(
        this as CategoryDrillDown,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CategoryDrillDown &&
            const DeepCollectionEquality().equals(
              other.transactions,
              transactions,
            ) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.avgPerDay, avgPerDay) ||
                other.avgPerDay == avgPerDay));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(transactions),
    subtotal,
    count,
    avgPerDay,
  );

  @override
  String toString() {
    return 'CategoryDrillDown(transactions: $transactions, subtotal: $subtotal, count: $count, avgPerDay: $avgPerDay)';
  }
}

/// @nodoc
abstract mixin class $CategoryDrillDownCopyWith<$Res> {
  factory $CategoryDrillDownCopyWith(
    CategoryDrillDown value,
    $Res Function(CategoryDrillDown) _then,
  ) = _$CategoryDrillDownCopyWithImpl;
  @useResult
  $Res call({
    List<Transaction> transactions,
    int subtotal,
    int count,
    int? avgPerDay,
  });
}

/// @nodoc
class _$CategoryDrillDownCopyWithImpl<$Res>
    implements $CategoryDrillDownCopyWith<$Res> {
  _$CategoryDrillDownCopyWithImpl(this._self, this._then);

  final CategoryDrillDown _self;
  final $Res Function(CategoryDrillDown) _then;

  /// Create a copy of CategoryDrillDown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transactions = null,
    Object? subtotal = null,
    Object? count = null,
    Object? avgPerDay = freezed,
  }) {
    return _then(
      _self.copyWith(
        transactions: null == transactions
            ? _self.transactions
            : transactions // ignore: cast_nullable_to_non_nullable
                  as List<Transaction>,
        subtotal: null == subtotal
            ? _self.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as int,
        count: null == count
            ? _self.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        avgPerDay: freezed == avgPerDay
            ? _self.avgPerDay
            : avgPerDay // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [CategoryDrillDown].
extension CategoryDrillDownPatterns on CategoryDrillDown {
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
    TResult Function(_CategoryDrillDown value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CategoryDrillDown() when $default != null:
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
    TResult Function(_CategoryDrillDown value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryDrillDown():
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
    TResult? Function(_CategoryDrillDown value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryDrillDown() when $default != null:
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
      List<Transaction> transactions,
      int subtotal,
      int count,
      int? avgPerDay,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CategoryDrillDown() when $default != null:
        return $default(
          _that.transactions,
          _that.subtotal,
          _that.count,
          _that.avgPerDay,
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
      List<Transaction> transactions,
      int subtotal,
      int count,
      int? avgPerDay,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryDrillDown():
        return $default(
          _that.transactions,
          _that.subtotal,
          _that.count,
          _that.avgPerDay,
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
      List<Transaction> transactions,
      int subtotal,
      int count,
      int? avgPerDay,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryDrillDown() when $default != null:
        return $default(
          _that.transactions,
          _that.subtotal,
          _that.count,
          _that.avgPerDay,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CategoryDrillDown implements CategoryDrillDown {
  const _CategoryDrillDown({
    required final List<Transaction> transactions,
    required this.subtotal,
    required this.count,
    this.avgPerDay,
  }) : _transactions = transactions;

  /// Window + L1-filtered transactions, sorted time-descending.
  final List<Transaction> _transactions;

  /// Window + L1-filtered transactions, sorted time-descending.
  @override
  List<Transaction> get transactions {
    if (_transactions is EqualUnmodifiableListView) return _transactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transactions);
  }

  /// Sum of [transactions] amounts (minor units), sourced from Plan 01's
  /// `l1RollupFromTransactions` — the single source-of-truth (D-11).
  @override
  final int subtotal;

  /// Number of transactions in this L1 for the window.
  @override
  final int count;

  /// Plain descriptive average per window-day (subtotal / window days).
  /// Descriptive only — never a target/goal (D-03, ADR-012-safe).
  @override
  final int? avgPerDay;

  /// Create a copy of CategoryDrillDown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CategoryDrillDownCopyWith<_CategoryDrillDown> get copyWith =>
      __$CategoryDrillDownCopyWithImpl<_CategoryDrillDown>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CategoryDrillDown &&
            const DeepCollectionEquality().equals(
              other._transactions,
              _transactions,
            ) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.avgPerDay, avgPerDay) ||
                other.avgPerDay == avgPerDay));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_transactions),
    subtotal,
    count,
    avgPerDay,
  );

  @override
  String toString() {
    return 'CategoryDrillDown(transactions: $transactions, subtotal: $subtotal, count: $count, avgPerDay: $avgPerDay)';
  }
}

/// @nodoc
abstract mixin class _$CategoryDrillDownCopyWith<$Res>
    implements $CategoryDrillDownCopyWith<$Res> {
  factory _$CategoryDrillDownCopyWith(
    _CategoryDrillDown value,
    $Res Function(_CategoryDrillDown) _then,
  ) = __$CategoryDrillDownCopyWithImpl;
  @override
  @useResult
  $Res call({
    List<Transaction> transactions,
    int subtotal,
    int count,
    int? avgPerDay,
  });
}

/// @nodoc
class __$CategoryDrillDownCopyWithImpl<$Res>
    implements _$CategoryDrillDownCopyWith<$Res> {
  __$CategoryDrillDownCopyWithImpl(this._self, this._then);

  final _CategoryDrillDown _self;
  final $Res Function(_CategoryDrillDown) _then;

  /// Create a copy of CategoryDrillDown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? transactions = null,
    Object? subtotal = null,
    Object? count = null,
    Object? avgPerDay = freezed,
  }) {
    return _then(
      _CategoryDrillDown(
        transactions: null == transactions
            ? _self._transactions
            : transactions // ignore: cast_nullable_to_non_nullable
                  as List<Transaction>,
        subtotal: null == subtotal
            ? _self.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as int,
        count: null == count
            ? _self.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        avgPerDay: freezed == avgPerDay
            ? _self.avgPerDay
            : avgPerDay // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'month_comparison.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MonthComparison {
  int get previousMonth;
  int get previousYear;
  int get previousIncome;
  int get previousExpenses;
  double get incomeChange;
  double get expenseChange;

  /// Create a copy of MonthComparison
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MonthComparisonCopyWith<MonthComparison> get copyWith =>
      _$MonthComparisonCopyWithImpl<MonthComparison>(
        this as MonthComparison,
        _$identity,
      );

  /// Serializes this MonthComparison to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MonthComparison &&
            (identical(other.previousMonth, previousMonth) ||
                other.previousMonth == previousMonth) &&
            (identical(other.previousYear, previousYear) ||
                other.previousYear == previousYear) &&
            (identical(other.previousIncome, previousIncome) ||
                other.previousIncome == previousIncome) &&
            (identical(other.previousExpenses, previousExpenses) ||
                other.previousExpenses == previousExpenses) &&
            (identical(other.incomeChange, incomeChange) ||
                other.incomeChange == incomeChange) &&
            (identical(other.expenseChange, expenseChange) ||
                other.expenseChange == expenseChange));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    previousMonth,
    previousYear,
    previousIncome,
    previousExpenses,
    incomeChange,
    expenseChange,
  );

  @override
  String toString() {
    return 'MonthComparison(previousMonth: $previousMonth, previousYear: $previousYear, previousIncome: $previousIncome, previousExpenses: $previousExpenses, incomeChange: $incomeChange, expenseChange: $expenseChange)';
  }
}

/// @nodoc
abstract mixin class $MonthComparisonCopyWith<$Res> {
  factory $MonthComparisonCopyWith(
    MonthComparison value,
    $Res Function(MonthComparison) _then,
  ) = _$MonthComparisonCopyWithImpl;
  @useResult
  $Res call({
    int previousMonth,
    int previousYear,
    int previousIncome,
    int previousExpenses,
    double incomeChange,
    double expenseChange,
  });
}

/// @nodoc
class _$MonthComparisonCopyWithImpl<$Res>
    implements $MonthComparisonCopyWith<$Res> {
  _$MonthComparisonCopyWithImpl(this._self, this._then);

  final MonthComparison _self;
  final $Res Function(MonthComparison) _then;

  /// Create a copy of MonthComparison
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? previousMonth = null,
    Object? previousYear = null,
    Object? previousIncome = null,
    Object? previousExpenses = null,
    Object? incomeChange = null,
    Object? expenseChange = null,
  }) {
    return _then(
      _self.copyWith(
        previousMonth: null == previousMonth
            ? _self.previousMonth
            : previousMonth // ignore: cast_nullable_to_non_nullable
                  as int,
        previousYear: null == previousYear
            ? _self.previousYear
            : previousYear // ignore: cast_nullable_to_non_nullable
                  as int,
        previousIncome: null == previousIncome
            ? _self.previousIncome
            : previousIncome // ignore: cast_nullable_to_non_nullable
                  as int,
        previousExpenses: null == previousExpenses
            ? _self.previousExpenses
            : previousExpenses // ignore: cast_nullable_to_non_nullable
                  as int,
        incomeChange: null == incomeChange
            ? _self.incomeChange
            : incomeChange // ignore: cast_nullable_to_non_nullable
                  as double,
        expenseChange: null == expenseChange
            ? _self.expenseChange
            : expenseChange // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MonthComparison].
extension MonthComparisonPatterns on MonthComparison {
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
    TResult Function(_MonthComparison value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MonthComparison() when $default != null:
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
    TResult Function(_MonthComparison value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthComparison():
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
    TResult? Function(_MonthComparison value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthComparison() when $default != null:
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
      int previousMonth,
      int previousYear,
      int previousIncome,
      int previousExpenses,
      double incomeChange,
      double expenseChange,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MonthComparison() when $default != null:
        return $default(
          _that.previousMonth,
          _that.previousYear,
          _that.previousIncome,
          _that.previousExpenses,
          _that.incomeChange,
          _that.expenseChange,
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
      int previousMonth,
      int previousYear,
      int previousIncome,
      int previousExpenses,
      double incomeChange,
      double expenseChange,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthComparison():
        return $default(
          _that.previousMonth,
          _that.previousYear,
          _that.previousIncome,
          _that.previousExpenses,
          _that.incomeChange,
          _that.expenseChange,
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
      int previousMonth,
      int previousYear,
      int previousIncome,
      int previousExpenses,
      double incomeChange,
      double expenseChange,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthComparison() when $default != null:
        return $default(
          _that.previousMonth,
          _that.previousYear,
          _that.previousIncome,
          _that.previousExpenses,
          _that.incomeChange,
          _that.expenseChange,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MonthComparison implements MonthComparison {
  const _MonthComparison({
    required this.previousMonth,
    required this.previousYear,
    required this.previousIncome,
    required this.previousExpenses,
    required this.incomeChange,
    required this.expenseChange,
  });
  factory _MonthComparison.fromJson(Map<String, dynamic> json) =>
      _$MonthComparisonFromJson(json);

  @override
  final int previousMonth;
  @override
  final int previousYear;
  @override
  final int previousIncome;
  @override
  final int previousExpenses;
  @override
  final double incomeChange;
  @override
  final double expenseChange;

  /// Create a copy of MonthComparison
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MonthComparisonCopyWith<_MonthComparison> get copyWith =>
      __$MonthComparisonCopyWithImpl<_MonthComparison>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MonthComparisonToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MonthComparison &&
            (identical(other.previousMonth, previousMonth) ||
                other.previousMonth == previousMonth) &&
            (identical(other.previousYear, previousYear) ||
                other.previousYear == previousYear) &&
            (identical(other.previousIncome, previousIncome) ||
                other.previousIncome == previousIncome) &&
            (identical(other.previousExpenses, previousExpenses) ||
                other.previousExpenses == previousExpenses) &&
            (identical(other.incomeChange, incomeChange) ||
                other.incomeChange == incomeChange) &&
            (identical(other.expenseChange, expenseChange) ||
                other.expenseChange == expenseChange));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    previousMonth,
    previousYear,
    previousIncome,
    previousExpenses,
    incomeChange,
    expenseChange,
  );

  @override
  String toString() {
    return 'MonthComparison(previousMonth: $previousMonth, previousYear: $previousYear, previousIncome: $previousIncome, previousExpenses: $previousExpenses, incomeChange: $incomeChange, expenseChange: $expenseChange)';
  }
}

/// @nodoc
abstract mixin class _$MonthComparisonCopyWith<$Res>
    implements $MonthComparisonCopyWith<$Res> {
  factory _$MonthComparisonCopyWith(
    _MonthComparison value,
    $Res Function(_MonthComparison) _then,
  ) = __$MonthComparisonCopyWithImpl;
  @override
  @useResult
  $Res call({
    int previousMonth,
    int previousYear,
    int previousIncome,
    int previousExpenses,
    double incomeChange,
    double expenseChange,
  });
}

/// @nodoc
class __$MonthComparisonCopyWithImpl<$Res>
    implements _$MonthComparisonCopyWith<$Res> {
  __$MonthComparisonCopyWithImpl(this._self, this._then);

  final _MonthComparison _self;
  final $Res Function(_MonthComparison) _then;

  /// Create a copy of MonthComparison
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? previousMonth = null,
    Object? previousYear = null,
    Object? previousIncome = null,
    Object? previousExpenses = null,
    Object? incomeChange = null,
    Object? expenseChange = null,
  }) {
    return _then(
      _MonthComparison(
        previousMonth: null == previousMonth
            ? _self.previousMonth
            : previousMonth // ignore: cast_nullable_to_non_nullable
                  as int,
        previousYear: null == previousYear
            ? _self.previousYear
            : previousYear // ignore: cast_nullable_to_non_nullable
                  as int,
        previousIncome: null == previousIncome
            ? _self.previousIncome
            : previousIncome // ignore: cast_nullable_to_non_nullable
                  as int,
        previousExpenses: null == previousExpenses
            ? _self.previousExpenses
            : previousExpenses // ignore: cast_nullable_to_non_nullable
                  as int,
        incomeChange: null == incomeChange
            ? _self.incomeChange
            : incomeChange // ignore: cast_nullable_to_non_nullable
                  as double,
        expenseChange: null == expenseChange
            ? _self.expenseChange
            : expenseChange // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

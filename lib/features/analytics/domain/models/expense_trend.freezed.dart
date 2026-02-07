// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense_trend.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MonthlyTrend {
  int get year;
  int get month;
  int get totalExpenses;
  int get totalIncome;

  /// Create a copy of MonthlyTrend
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MonthlyTrendCopyWith<MonthlyTrend> get copyWith =>
      _$MonthlyTrendCopyWithImpl<MonthlyTrend>(
        this as MonthlyTrend,
        _$identity,
      );

  /// Serializes this MonthlyTrend to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MonthlyTrend &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.totalExpenses, totalExpenses) ||
                other.totalExpenses == totalExpenses) &&
            (identical(other.totalIncome, totalIncome) ||
                other.totalIncome == totalIncome));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, year, month, totalExpenses, totalIncome);

  @override
  String toString() {
    return 'MonthlyTrend(year: $year, month: $month, totalExpenses: $totalExpenses, totalIncome: $totalIncome)';
  }
}

/// @nodoc
abstract mixin class $MonthlyTrendCopyWith<$Res> {
  factory $MonthlyTrendCopyWith(
    MonthlyTrend value,
    $Res Function(MonthlyTrend) _then,
  ) = _$MonthlyTrendCopyWithImpl;
  @useResult
  $Res call({int year, int month, int totalExpenses, int totalIncome});
}

/// @nodoc
class _$MonthlyTrendCopyWithImpl<$Res> implements $MonthlyTrendCopyWith<$Res> {
  _$MonthlyTrendCopyWithImpl(this._self, this._then);

  final MonthlyTrend _self;
  final $Res Function(MonthlyTrend) _then;

  /// Create a copy of MonthlyTrend
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? totalExpenses = null,
    Object? totalIncome = null,
  }) {
    return _then(
      _self.copyWith(
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _self.month
            : month // ignore: cast_nullable_to_non_nullable
                  as int,
        totalExpenses: null == totalExpenses
            ? _self.totalExpenses
            : totalExpenses // ignore: cast_nullable_to_non_nullable
                  as int,
        totalIncome: null == totalIncome
            ? _self.totalIncome
            : totalIncome // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MonthlyTrend].
extension MonthlyTrendPatterns on MonthlyTrend {
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
    TResult Function(_MonthlyTrend value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MonthlyTrend() when $default != null:
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
    TResult Function(_MonthlyTrend value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthlyTrend():
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
    TResult? Function(_MonthlyTrend value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthlyTrend() when $default != null:
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
    TResult Function(int year, int month, int totalExpenses, int totalIncome)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MonthlyTrend() when $default != null:
        return $default(
          _that.year,
          _that.month,
          _that.totalExpenses,
          _that.totalIncome,
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
    TResult Function(int year, int month, int totalExpenses, int totalIncome)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthlyTrend():
        return $default(
          _that.year,
          _that.month,
          _that.totalExpenses,
          _that.totalIncome,
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
    TResult? Function(int year, int month, int totalExpenses, int totalIncome)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthlyTrend() when $default != null:
        return $default(
          _that.year,
          _that.month,
          _that.totalExpenses,
          _that.totalIncome,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MonthlyTrend implements MonthlyTrend {
  const _MonthlyTrend({
    required this.year,
    required this.month,
    required this.totalExpenses,
    required this.totalIncome,
  });
  factory _MonthlyTrend.fromJson(Map<String, dynamic> json) =>
      _$MonthlyTrendFromJson(json);

  @override
  final int year;
  @override
  final int month;
  @override
  final int totalExpenses;
  @override
  final int totalIncome;

  /// Create a copy of MonthlyTrend
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MonthlyTrendCopyWith<_MonthlyTrend> get copyWith =>
      __$MonthlyTrendCopyWithImpl<_MonthlyTrend>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MonthlyTrendToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MonthlyTrend &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.totalExpenses, totalExpenses) ||
                other.totalExpenses == totalExpenses) &&
            (identical(other.totalIncome, totalIncome) ||
                other.totalIncome == totalIncome));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, year, month, totalExpenses, totalIncome);

  @override
  String toString() {
    return 'MonthlyTrend(year: $year, month: $month, totalExpenses: $totalExpenses, totalIncome: $totalIncome)';
  }
}

/// @nodoc
abstract mixin class _$MonthlyTrendCopyWith<$Res>
    implements $MonthlyTrendCopyWith<$Res> {
  factory _$MonthlyTrendCopyWith(
    _MonthlyTrend value,
    $Res Function(_MonthlyTrend) _then,
  ) = __$MonthlyTrendCopyWithImpl;
  @override
  @useResult
  $Res call({int year, int month, int totalExpenses, int totalIncome});
}

/// @nodoc
class __$MonthlyTrendCopyWithImpl<$Res>
    implements _$MonthlyTrendCopyWith<$Res> {
  __$MonthlyTrendCopyWithImpl(this._self, this._then);

  final _MonthlyTrend _self;
  final $Res Function(_MonthlyTrend) _then;

  /// Create a copy of MonthlyTrend
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? totalExpenses = null,
    Object? totalIncome = null,
  }) {
    return _then(
      _MonthlyTrend(
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _self.month
            : month // ignore: cast_nullable_to_non_nullable
                  as int,
        totalExpenses: null == totalExpenses
            ? _self.totalExpenses
            : totalExpenses // ignore: cast_nullable_to_non_nullable
                  as int,
        totalIncome: null == totalIncome
            ? _self.totalIncome
            : totalIncome // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$ExpenseTrendData {
  List<MonthlyTrend> get months;

  /// Create a copy of ExpenseTrendData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExpenseTrendDataCopyWith<ExpenseTrendData> get copyWith =>
      _$ExpenseTrendDataCopyWithImpl<ExpenseTrendData>(
        this as ExpenseTrendData,
        _$identity,
      );

  /// Serializes this ExpenseTrendData to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExpenseTrendData &&
            const DeepCollectionEquality().equals(other.months, months));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(months));

  @override
  String toString() {
    return 'ExpenseTrendData(months: $months)';
  }
}

/// @nodoc
abstract mixin class $ExpenseTrendDataCopyWith<$Res> {
  factory $ExpenseTrendDataCopyWith(
    ExpenseTrendData value,
    $Res Function(ExpenseTrendData) _then,
  ) = _$ExpenseTrendDataCopyWithImpl;
  @useResult
  $Res call({List<MonthlyTrend> months});
}

/// @nodoc
class _$ExpenseTrendDataCopyWithImpl<$Res>
    implements $ExpenseTrendDataCopyWith<$Res> {
  _$ExpenseTrendDataCopyWithImpl(this._self, this._then);

  final ExpenseTrendData _self;
  final $Res Function(ExpenseTrendData) _then;

  /// Create a copy of ExpenseTrendData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? months = null}) {
    return _then(
      _self.copyWith(
        months: null == months
            ? _self.months
            : months // ignore: cast_nullable_to_non_nullable
                  as List<MonthlyTrend>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ExpenseTrendData].
extension ExpenseTrendDataPatterns on ExpenseTrendData {
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
    TResult Function(_ExpenseTrendData value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExpenseTrendData() when $default != null:
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
    TResult Function(_ExpenseTrendData value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExpenseTrendData():
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
    TResult? Function(_ExpenseTrendData value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExpenseTrendData() when $default != null:
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
    TResult Function(List<MonthlyTrend> months)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExpenseTrendData() when $default != null:
        return $default(_that.months);
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
    TResult Function(List<MonthlyTrend> months) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExpenseTrendData():
        return $default(_that.months);
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
    TResult? Function(List<MonthlyTrend> months)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExpenseTrendData() when $default != null:
        return $default(_that.months);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ExpenseTrendData implements ExpenseTrendData {
  const _ExpenseTrendData({required final List<MonthlyTrend> months})
    : _months = months;
  factory _ExpenseTrendData.fromJson(Map<String, dynamic> json) =>
      _$ExpenseTrendDataFromJson(json);

  final List<MonthlyTrend> _months;
  @override
  List<MonthlyTrend> get months {
    if (_months is EqualUnmodifiableListView) return _months;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_months);
  }

  /// Create a copy of ExpenseTrendData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExpenseTrendDataCopyWith<_ExpenseTrendData> get copyWith =>
      __$ExpenseTrendDataCopyWithImpl<_ExpenseTrendData>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ExpenseTrendDataToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ExpenseTrendData &&
            const DeepCollectionEquality().equals(other._months, _months));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_months));

  @override
  String toString() {
    return 'ExpenseTrendData(months: $months)';
  }
}

/// @nodoc
abstract mixin class _$ExpenseTrendDataCopyWith<$Res>
    implements $ExpenseTrendDataCopyWith<$Res> {
  factory _$ExpenseTrendDataCopyWith(
    _ExpenseTrendData value,
    $Res Function(_ExpenseTrendData) _then,
  ) = __$ExpenseTrendDataCopyWithImpl;
  @override
  @useResult
  $Res call({List<MonthlyTrend> months});
}

/// @nodoc
class __$ExpenseTrendDataCopyWithImpl<$Res>
    implements _$ExpenseTrendDataCopyWith<$Res> {
  __$ExpenseTrendDataCopyWithImpl(this._self, this._then);

  final _ExpenseTrendData _self;
  final $Res Function(_ExpenseTrendData) _then;

  /// Create a copy of ExpenseTrendData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? months = null}) {
    return _then(
      _ExpenseTrendData(
        months: null == months
            ? _self._months
            : months // ignore: cast_nullable_to_non_nullable
                  as List<MonthlyTrend>,
      ),
    );
  }
}

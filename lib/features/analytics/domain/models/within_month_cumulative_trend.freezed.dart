// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'within_month_cumulative_trend.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CumulativePoint {
  int get day;
  int get cumulativeAmount;

  /// Create a copy of CumulativePoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CumulativePointCopyWith<CumulativePoint> get copyWith =>
      _$CumulativePointCopyWithImpl<CumulativePoint>(
        this as CumulativePoint,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CumulativePoint &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.cumulativeAmount, cumulativeAmount) ||
                other.cumulativeAmount == cumulativeAmount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, day, cumulativeAmount);

  @override
  String toString() {
    return 'CumulativePoint(day: $day, cumulativeAmount: $cumulativeAmount)';
  }
}

/// @nodoc
abstract mixin class $CumulativePointCopyWith<$Res> {
  factory $CumulativePointCopyWith(
    CumulativePoint value,
    $Res Function(CumulativePoint) _then,
  ) = _$CumulativePointCopyWithImpl;
  @useResult
  $Res call({int day, int cumulativeAmount});
}

/// @nodoc
class _$CumulativePointCopyWithImpl<$Res>
    implements $CumulativePointCopyWith<$Res> {
  _$CumulativePointCopyWithImpl(this._self, this._then);

  final CumulativePoint _self;
  final $Res Function(CumulativePoint) _then;

  /// Create a copy of CumulativePoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? day = null, Object? cumulativeAmount = null}) {
    return _then(
      _self.copyWith(
        day: null == day
            ? _self.day
            : day // ignore: cast_nullable_to_non_nullable
                  as int,
        cumulativeAmount: null == cumulativeAmount
            ? _self.cumulativeAmount
            : cumulativeAmount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [CumulativePoint].
extension CumulativePointPatterns on CumulativePoint {
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
    TResult Function(_CumulativePoint value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CumulativePoint() when $default != null:
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
    TResult Function(_CumulativePoint value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CumulativePoint():
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
    TResult? Function(_CumulativePoint value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CumulativePoint() when $default != null:
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
    TResult Function(int day, int cumulativeAmount)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CumulativePoint() when $default != null:
        return $default(_that.day, _that.cumulativeAmount);
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
    TResult Function(int day, int cumulativeAmount) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CumulativePoint():
        return $default(_that.day, _that.cumulativeAmount);
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
    TResult? Function(int day, int cumulativeAmount)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CumulativePoint() when $default != null:
        return $default(_that.day, _that.cumulativeAmount);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CumulativePoint implements CumulativePoint {
  const _CumulativePoint({required this.day, required this.cumulativeAmount});

  @override
  final int day;
  @override
  final int cumulativeAmount;

  /// Create a copy of CumulativePoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CumulativePointCopyWith<_CumulativePoint> get copyWith =>
      __$CumulativePointCopyWithImpl<_CumulativePoint>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CumulativePoint &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.cumulativeAmount, cumulativeAmount) ||
                other.cumulativeAmount == cumulativeAmount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, day, cumulativeAmount);

  @override
  String toString() {
    return 'CumulativePoint(day: $day, cumulativeAmount: $cumulativeAmount)';
  }
}

/// @nodoc
abstract mixin class _$CumulativePointCopyWith<$Res>
    implements $CumulativePointCopyWith<$Res> {
  factory _$CumulativePointCopyWith(
    _CumulativePoint value,
    $Res Function(_CumulativePoint) _then,
  ) = __$CumulativePointCopyWithImpl;
  @override
  @useResult
  $Res call({int day, int cumulativeAmount});
}

/// @nodoc
class __$CumulativePointCopyWithImpl<$Res>
    implements _$CumulativePointCopyWith<$Res> {
  __$CumulativePointCopyWithImpl(this._self, this._then);

  final _CumulativePoint _self;
  final $Res Function(_CumulativePoint) _then;

  /// Create a copy of CumulativePoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? day = null, Object? cumulativeAmount = null}) {
    return _then(
      _CumulativePoint(
        day: null == day
            ? _self.day
            : day // ignore: cast_nullable_to_non_nullable
                  as int,
        cumulativeAmount: null == cumulativeAmount
            ? _self.cumulativeAmount
            : cumulativeAmount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$WithinMonthCumulativeTrend {
  /// Current month, all-ledger expense cumulative (== daily + joy per point).
  List<CumulativePoint> get currentMonthTotal;

  /// Current month, daily-ledger-only expense cumulative.
  List<CumulativePoint> get currentMonthDaily;

  /// Current month, joy-ledger-only expense cumulative.
  List<CumulativePoint> get currentMonthJoy;

  /// Previous month, all-ledger expense cumulative (spend-side reference).
  List<CumulativePoint> get previousMonthTotal;

  /// Previous month, daily-ledger-only expense cumulative (spend-side
  /// reference). NOTE: there is deliberately NO previousMonthJoy — the joy
  /// side never crosses periods (D-E1).
  List<CumulativePoint> get previousMonthDaily;

  /// Create a copy of WithinMonthCumulativeTrend
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WithinMonthCumulativeTrendCopyWith<WithinMonthCumulativeTrend>
  get copyWith =>
      _$WithinMonthCumulativeTrendCopyWithImpl<WithinMonthCumulativeTrend>(
        this as WithinMonthCumulativeTrend,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WithinMonthCumulativeTrend &&
            const DeepCollectionEquality().equals(
              other.currentMonthTotal,
              currentMonthTotal,
            ) &&
            const DeepCollectionEquality().equals(
              other.currentMonthDaily,
              currentMonthDaily,
            ) &&
            const DeepCollectionEquality().equals(
              other.currentMonthJoy,
              currentMonthJoy,
            ) &&
            const DeepCollectionEquality().equals(
              other.previousMonthTotal,
              previousMonthTotal,
            ) &&
            const DeepCollectionEquality().equals(
              other.previousMonthDaily,
              previousMonthDaily,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(currentMonthTotal),
    const DeepCollectionEquality().hash(currentMonthDaily),
    const DeepCollectionEquality().hash(currentMonthJoy),
    const DeepCollectionEquality().hash(previousMonthTotal),
    const DeepCollectionEquality().hash(previousMonthDaily),
  );

  @override
  String toString() {
    return 'WithinMonthCumulativeTrend(currentMonthTotal: $currentMonthTotal, currentMonthDaily: $currentMonthDaily, currentMonthJoy: $currentMonthJoy, previousMonthTotal: $previousMonthTotal, previousMonthDaily: $previousMonthDaily)';
  }
}

/// @nodoc
abstract mixin class $WithinMonthCumulativeTrendCopyWith<$Res> {
  factory $WithinMonthCumulativeTrendCopyWith(
    WithinMonthCumulativeTrend value,
    $Res Function(WithinMonthCumulativeTrend) _then,
  ) = _$WithinMonthCumulativeTrendCopyWithImpl;
  @useResult
  $Res call({
    List<CumulativePoint> currentMonthTotal,
    List<CumulativePoint> currentMonthDaily,
    List<CumulativePoint> currentMonthJoy,
    List<CumulativePoint> previousMonthTotal,
    List<CumulativePoint> previousMonthDaily,
  });
}

/// @nodoc
class _$WithinMonthCumulativeTrendCopyWithImpl<$Res>
    implements $WithinMonthCumulativeTrendCopyWith<$Res> {
  _$WithinMonthCumulativeTrendCopyWithImpl(this._self, this._then);

  final WithinMonthCumulativeTrend _self;
  final $Res Function(WithinMonthCumulativeTrend) _then;

  /// Create a copy of WithinMonthCumulativeTrend
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentMonthTotal = null,
    Object? currentMonthDaily = null,
    Object? currentMonthJoy = null,
    Object? previousMonthTotal = null,
    Object? previousMonthDaily = null,
  }) {
    return _then(
      _self.copyWith(
        currentMonthTotal: null == currentMonthTotal
            ? _self.currentMonthTotal
            : currentMonthTotal // ignore: cast_nullable_to_non_nullable
                  as List<CumulativePoint>,
        currentMonthDaily: null == currentMonthDaily
            ? _self.currentMonthDaily
            : currentMonthDaily // ignore: cast_nullable_to_non_nullable
                  as List<CumulativePoint>,
        currentMonthJoy: null == currentMonthJoy
            ? _self.currentMonthJoy
            : currentMonthJoy // ignore: cast_nullable_to_non_nullable
                  as List<CumulativePoint>,
        previousMonthTotal: null == previousMonthTotal
            ? _self.previousMonthTotal
            : previousMonthTotal // ignore: cast_nullable_to_non_nullable
                  as List<CumulativePoint>,
        previousMonthDaily: null == previousMonthDaily
            ? _self.previousMonthDaily
            : previousMonthDaily // ignore: cast_nullable_to_non_nullable
                  as List<CumulativePoint>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [WithinMonthCumulativeTrend].
extension WithinMonthCumulativeTrendPatterns on WithinMonthCumulativeTrend {
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
    TResult Function(_WithinMonthCumulativeTrend value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WithinMonthCumulativeTrend() when $default != null:
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
    TResult Function(_WithinMonthCumulativeTrend value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WithinMonthCumulativeTrend():
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
    TResult? Function(_WithinMonthCumulativeTrend value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WithinMonthCumulativeTrend() when $default != null:
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
      List<CumulativePoint> currentMonthTotal,
      List<CumulativePoint> currentMonthDaily,
      List<CumulativePoint> currentMonthJoy,
      List<CumulativePoint> previousMonthTotal,
      List<CumulativePoint> previousMonthDaily,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WithinMonthCumulativeTrend() when $default != null:
        return $default(
          _that.currentMonthTotal,
          _that.currentMonthDaily,
          _that.currentMonthJoy,
          _that.previousMonthTotal,
          _that.previousMonthDaily,
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
      List<CumulativePoint> currentMonthTotal,
      List<CumulativePoint> currentMonthDaily,
      List<CumulativePoint> currentMonthJoy,
      List<CumulativePoint> previousMonthTotal,
      List<CumulativePoint> previousMonthDaily,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WithinMonthCumulativeTrend():
        return $default(
          _that.currentMonthTotal,
          _that.currentMonthDaily,
          _that.currentMonthJoy,
          _that.previousMonthTotal,
          _that.previousMonthDaily,
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
      List<CumulativePoint> currentMonthTotal,
      List<CumulativePoint> currentMonthDaily,
      List<CumulativePoint> currentMonthJoy,
      List<CumulativePoint> previousMonthTotal,
      List<CumulativePoint> previousMonthDaily,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WithinMonthCumulativeTrend() when $default != null:
        return $default(
          _that.currentMonthTotal,
          _that.currentMonthDaily,
          _that.currentMonthJoy,
          _that.previousMonthTotal,
          _that.previousMonthDaily,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _WithinMonthCumulativeTrend implements WithinMonthCumulativeTrend {
  const _WithinMonthCumulativeTrend({
    required final List<CumulativePoint> currentMonthTotal,
    required final List<CumulativePoint> currentMonthDaily,
    required final List<CumulativePoint> currentMonthJoy,
    required final List<CumulativePoint> previousMonthTotal,
    required final List<CumulativePoint> previousMonthDaily,
  }) : _currentMonthTotal = currentMonthTotal,
       _currentMonthDaily = currentMonthDaily,
       _currentMonthJoy = currentMonthJoy,
       _previousMonthTotal = previousMonthTotal,
       _previousMonthDaily = previousMonthDaily;

  /// Current month, all-ledger expense cumulative (== daily + joy per point).
  final List<CumulativePoint> _currentMonthTotal;

  /// Current month, all-ledger expense cumulative (== daily + joy per point).
  @override
  List<CumulativePoint> get currentMonthTotal {
    if (_currentMonthTotal is EqualUnmodifiableListView)
      return _currentMonthTotal;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_currentMonthTotal);
  }

  /// Current month, daily-ledger-only expense cumulative.
  final List<CumulativePoint> _currentMonthDaily;

  /// Current month, daily-ledger-only expense cumulative.
  @override
  List<CumulativePoint> get currentMonthDaily {
    if (_currentMonthDaily is EqualUnmodifiableListView)
      return _currentMonthDaily;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_currentMonthDaily);
  }

  /// Current month, joy-ledger-only expense cumulative.
  final List<CumulativePoint> _currentMonthJoy;

  /// Current month, joy-ledger-only expense cumulative.
  @override
  List<CumulativePoint> get currentMonthJoy {
    if (_currentMonthJoy is EqualUnmodifiableListView) return _currentMonthJoy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_currentMonthJoy);
  }

  /// Previous month, all-ledger expense cumulative (spend-side reference).
  final List<CumulativePoint> _previousMonthTotal;

  /// Previous month, all-ledger expense cumulative (spend-side reference).
  @override
  List<CumulativePoint> get previousMonthTotal {
    if (_previousMonthTotal is EqualUnmodifiableListView)
      return _previousMonthTotal;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_previousMonthTotal);
  }

  /// Previous month, daily-ledger-only expense cumulative (spend-side
  /// reference). NOTE: there is deliberately NO previousMonthJoy — the joy
  /// side never crosses periods (D-E1).
  final List<CumulativePoint> _previousMonthDaily;

  /// Previous month, daily-ledger-only expense cumulative (spend-side
  /// reference). NOTE: there is deliberately NO previousMonthJoy — the joy
  /// side never crosses periods (D-E1).
  @override
  List<CumulativePoint> get previousMonthDaily {
    if (_previousMonthDaily is EqualUnmodifiableListView)
      return _previousMonthDaily;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_previousMonthDaily);
  }

  /// Create a copy of WithinMonthCumulativeTrend
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WithinMonthCumulativeTrendCopyWith<_WithinMonthCumulativeTrend>
  get copyWith =>
      __$WithinMonthCumulativeTrendCopyWithImpl<_WithinMonthCumulativeTrend>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WithinMonthCumulativeTrend &&
            const DeepCollectionEquality().equals(
              other._currentMonthTotal,
              _currentMonthTotal,
            ) &&
            const DeepCollectionEquality().equals(
              other._currentMonthDaily,
              _currentMonthDaily,
            ) &&
            const DeepCollectionEquality().equals(
              other._currentMonthJoy,
              _currentMonthJoy,
            ) &&
            const DeepCollectionEquality().equals(
              other._previousMonthTotal,
              _previousMonthTotal,
            ) &&
            const DeepCollectionEquality().equals(
              other._previousMonthDaily,
              _previousMonthDaily,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_currentMonthTotal),
    const DeepCollectionEquality().hash(_currentMonthDaily),
    const DeepCollectionEquality().hash(_currentMonthJoy),
    const DeepCollectionEquality().hash(_previousMonthTotal),
    const DeepCollectionEquality().hash(_previousMonthDaily),
  );

  @override
  String toString() {
    return 'WithinMonthCumulativeTrend(currentMonthTotal: $currentMonthTotal, currentMonthDaily: $currentMonthDaily, currentMonthJoy: $currentMonthJoy, previousMonthTotal: $previousMonthTotal, previousMonthDaily: $previousMonthDaily)';
  }
}

/// @nodoc
abstract mixin class _$WithinMonthCumulativeTrendCopyWith<$Res>
    implements $WithinMonthCumulativeTrendCopyWith<$Res> {
  factory _$WithinMonthCumulativeTrendCopyWith(
    _WithinMonthCumulativeTrend value,
    $Res Function(_WithinMonthCumulativeTrend) _then,
  ) = __$WithinMonthCumulativeTrendCopyWithImpl;
  @override
  @useResult
  $Res call({
    List<CumulativePoint> currentMonthTotal,
    List<CumulativePoint> currentMonthDaily,
    List<CumulativePoint> currentMonthJoy,
    List<CumulativePoint> previousMonthTotal,
    List<CumulativePoint> previousMonthDaily,
  });
}

/// @nodoc
class __$WithinMonthCumulativeTrendCopyWithImpl<$Res>
    implements _$WithinMonthCumulativeTrendCopyWith<$Res> {
  __$WithinMonthCumulativeTrendCopyWithImpl(this._self, this._then);

  final _WithinMonthCumulativeTrend _self;
  final $Res Function(_WithinMonthCumulativeTrend) _then;

  /// Create a copy of WithinMonthCumulativeTrend
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? currentMonthTotal = null,
    Object? currentMonthDaily = null,
    Object? currentMonthJoy = null,
    Object? previousMonthTotal = null,
    Object? previousMonthDaily = null,
  }) {
    return _then(
      _WithinMonthCumulativeTrend(
        currentMonthTotal: null == currentMonthTotal
            ? _self._currentMonthTotal
            : currentMonthTotal // ignore: cast_nullable_to_non_nullable
                  as List<CumulativePoint>,
        currentMonthDaily: null == currentMonthDaily
            ? _self._currentMonthDaily
            : currentMonthDaily // ignore: cast_nullable_to_non_nullable
                  as List<CumulativePoint>,
        currentMonthJoy: null == currentMonthJoy
            ? _self._currentMonthJoy
            : currentMonthJoy // ignore: cast_nullable_to_non_nullable
                  as List<CumulativePoint>,
        previousMonthTotal: null == previousMonthTotal
            ? _self._previousMonthTotal
            : previousMonthTotal // ignore: cast_nullable_to_non_nullable
                  as List<CumulativePoint>,
        previousMonthDaily: null == previousMonthDaily
            ? _self._previousMonthDaily
            : previousMonthDaily // ignore: cast_nullable_to_non_nullable
                  as List<CumulativePoint>,
      ),
    );
  }
}

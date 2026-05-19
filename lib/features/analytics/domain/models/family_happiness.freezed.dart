// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_happiness.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FamilyHappiness {
  // aux (flat)
  /// Display anchor: the year of the active window's endDate (Phase 15+).
  /// Source-of-truth date range is the use-case (startDate, endDate) input.
  int get year;

  /// Display anchor: the month of the active window's endDate (Phase 15+).
  /// See use-case (startDate, endDate) for the queried range.
  int get month;
  int get totalGroupSoulTx; // main metrics
  MetricResult<int> get familyHighlightsSum;
  MetricResult<SharedJoyInsight> get sharedJoyInsight;
  MetricResult<double> get medianSatisfaction;

  /// Create a copy of FamilyHappiness
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FamilyHappinessCopyWith<FamilyHappiness> get copyWith =>
      _$FamilyHappinessCopyWithImpl<FamilyHappiness>(
        this as FamilyHappiness,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FamilyHappiness &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.totalGroupSoulTx, totalGroupSoulTx) ||
                other.totalGroupSoulTx == totalGroupSoulTx) &&
            (identical(other.familyHighlightsSum, familyHighlightsSum) ||
                other.familyHighlightsSum == familyHighlightsSum) &&
            (identical(other.sharedJoyInsight, sharedJoyInsight) ||
                other.sharedJoyInsight == sharedJoyInsight) &&
            (identical(other.medianSatisfaction, medianSatisfaction) ||
                other.medianSatisfaction == medianSatisfaction));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    year,
    month,
    totalGroupSoulTx,
    familyHighlightsSum,
    sharedJoyInsight,
    medianSatisfaction,
  );

  @override
  String toString() {
    return 'FamilyHappiness(year: $year, month: $month, totalGroupSoulTx: $totalGroupSoulTx, familyHighlightsSum: $familyHighlightsSum, sharedJoyInsight: $sharedJoyInsight, medianSatisfaction: $medianSatisfaction)';
  }
}

/// @nodoc
abstract mixin class $FamilyHappinessCopyWith<$Res> {
  factory $FamilyHappinessCopyWith(
    FamilyHappiness value,
    $Res Function(FamilyHappiness) _then,
  ) = _$FamilyHappinessCopyWithImpl;
  @useResult
  $Res call({
    int year,
    int month,
    int totalGroupSoulTx,
    MetricResult<int> familyHighlightsSum,
    MetricResult<SharedJoyInsight> sharedJoyInsight,
    MetricResult<double> medianSatisfaction,
  });
}

/// @nodoc
class _$FamilyHappinessCopyWithImpl<$Res>
    implements $FamilyHappinessCopyWith<$Res> {
  _$FamilyHappinessCopyWithImpl(this._self, this._then);

  final FamilyHappiness _self;
  final $Res Function(FamilyHappiness) _then;

  /// Create a copy of FamilyHappiness
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? totalGroupSoulTx = null,
    Object? familyHighlightsSum = null,
    Object? sharedJoyInsight = null,
    Object? medianSatisfaction = null,
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
        totalGroupSoulTx: null == totalGroupSoulTx
            ? _self.totalGroupSoulTx
            : totalGroupSoulTx // ignore: cast_nullable_to_non_nullable
                  as int,
        familyHighlightsSum: null == familyHighlightsSum
            ? _self.familyHighlightsSum
            : familyHighlightsSum // ignore: cast_nullable_to_non_nullable
                  as MetricResult<int>,
        sharedJoyInsight: null == sharedJoyInsight
            ? _self.sharedJoyInsight
            : sharedJoyInsight // ignore: cast_nullable_to_non_nullable
                  as MetricResult<SharedJoyInsight>,
        medianSatisfaction: null == medianSatisfaction
            ? _self.medianSatisfaction
            : medianSatisfaction // ignore: cast_nullable_to_non_nullable
                  as MetricResult<double>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [FamilyHappiness].
extension FamilyHappinessPatterns on FamilyHappiness {
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
    TResult Function(_FamilyHappiness value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FamilyHappiness() when $default != null:
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
    TResult Function(_FamilyHappiness value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FamilyHappiness():
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
    TResult? Function(_FamilyHappiness value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FamilyHappiness() when $default != null:
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
      int year,
      int month,
      int totalGroupSoulTx,
      MetricResult<int> familyHighlightsSum,
      MetricResult<SharedJoyInsight> sharedJoyInsight,
      MetricResult<double> medianSatisfaction,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FamilyHappiness() when $default != null:
        return $default(
          _that.year,
          _that.month,
          _that.totalGroupSoulTx,
          _that.familyHighlightsSum,
          _that.sharedJoyInsight,
          _that.medianSatisfaction,
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
      int year,
      int month,
      int totalGroupSoulTx,
      MetricResult<int> familyHighlightsSum,
      MetricResult<SharedJoyInsight> sharedJoyInsight,
      MetricResult<double> medianSatisfaction,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FamilyHappiness():
        return $default(
          _that.year,
          _that.month,
          _that.totalGroupSoulTx,
          _that.familyHighlightsSum,
          _that.sharedJoyInsight,
          _that.medianSatisfaction,
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
      int year,
      int month,
      int totalGroupSoulTx,
      MetricResult<int> familyHighlightsSum,
      MetricResult<SharedJoyInsight> sharedJoyInsight,
      MetricResult<double> medianSatisfaction,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FamilyHappiness() when $default != null:
        return $default(
          _that.year,
          _that.month,
          _that.totalGroupSoulTx,
          _that.familyHighlightsSum,
          _that.sharedJoyInsight,
          _that.medianSatisfaction,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _FamilyHappiness implements FamilyHappiness {
  const _FamilyHappiness({
    required this.year,
    required this.month,
    required this.totalGroupSoulTx,
    required this.familyHighlightsSum,
    required this.sharedJoyInsight,
    required this.medianSatisfaction,
  });

  // aux (flat)
  /// Display anchor: the year of the active window's endDate (Phase 15+).
  /// Source-of-truth date range is the use-case (startDate, endDate) input.
  @override
  final int year;

  /// Display anchor: the month of the active window's endDate (Phase 15+).
  /// See use-case (startDate, endDate) for the queried range.
  @override
  final int month;
  @override
  final int totalGroupSoulTx;
  // main metrics
  @override
  final MetricResult<int> familyHighlightsSum;
  @override
  final MetricResult<SharedJoyInsight> sharedJoyInsight;
  @override
  final MetricResult<double> medianSatisfaction;

  /// Create a copy of FamilyHappiness
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FamilyHappinessCopyWith<_FamilyHappiness> get copyWith =>
      __$FamilyHappinessCopyWithImpl<_FamilyHappiness>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FamilyHappiness &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.totalGroupSoulTx, totalGroupSoulTx) ||
                other.totalGroupSoulTx == totalGroupSoulTx) &&
            (identical(other.familyHighlightsSum, familyHighlightsSum) ||
                other.familyHighlightsSum == familyHighlightsSum) &&
            (identical(other.sharedJoyInsight, sharedJoyInsight) ||
                other.sharedJoyInsight == sharedJoyInsight) &&
            (identical(other.medianSatisfaction, medianSatisfaction) ||
                other.medianSatisfaction == medianSatisfaction));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    year,
    month,
    totalGroupSoulTx,
    familyHighlightsSum,
    sharedJoyInsight,
    medianSatisfaction,
  );

  @override
  String toString() {
    return 'FamilyHappiness(year: $year, month: $month, totalGroupSoulTx: $totalGroupSoulTx, familyHighlightsSum: $familyHighlightsSum, sharedJoyInsight: $sharedJoyInsight, medianSatisfaction: $medianSatisfaction)';
  }
}

/// @nodoc
abstract mixin class _$FamilyHappinessCopyWith<$Res>
    implements $FamilyHappinessCopyWith<$Res> {
  factory _$FamilyHappinessCopyWith(
    _FamilyHappiness value,
    $Res Function(_FamilyHappiness) _then,
  ) = __$FamilyHappinessCopyWithImpl;
  @override
  @useResult
  $Res call({
    int year,
    int month,
    int totalGroupSoulTx,
    MetricResult<int> familyHighlightsSum,
    MetricResult<SharedJoyInsight> sharedJoyInsight,
    MetricResult<double> medianSatisfaction,
  });
}

/// @nodoc
class __$FamilyHappinessCopyWithImpl<$Res>
    implements _$FamilyHappinessCopyWith<$Res> {
  __$FamilyHappinessCopyWithImpl(this._self, this._then);

  final _FamilyHappiness _self;
  final $Res Function(_FamilyHappiness) _then;

  /// Create a copy of FamilyHappiness
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? totalGroupSoulTx = null,
    Object? familyHighlightsSum = null,
    Object? sharedJoyInsight = null,
    Object? medianSatisfaction = null,
  }) {
    return _then(
      _FamilyHappiness(
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _self.month
            : month // ignore: cast_nullable_to_non_nullable
                  as int,
        totalGroupSoulTx: null == totalGroupSoulTx
            ? _self.totalGroupSoulTx
            : totalGroupSoulTx // ignore: cast_nullable_to_non_nullable
                  as int,
        familyHighlightsSum: null == familyHighlightsSum
            ? _self.familyHighlightsSum
            : familyHighlightsSum // ignore: cast_nullable_to_non_nullable
                  as MetricResult<int>,
        sharedJoyInsight: null == sharedJoyInsight
            ? _self.sharedJoyInsight
            : sharedJoyInsight // ignore: cast_nullable_to_non_nullable
                  as MetricResult<SharedJoyInsight>,
        medianSatisfaction: null == medianSatisfaction
            ? _self.medianSatisfaction
            : medianSatisfaction // ignore: cast_nullable_to_non_nullable
                  as MetricResult<double>,
      ),
    );
  }
}

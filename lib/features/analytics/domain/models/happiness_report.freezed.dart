// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'happiness_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HappinessReport {
  // aux (flat)
  int get year;
  int get month;
  String get bookId;
  int get totalSoulTx; // main metrics (MetricResult-wrapped)
  MetricResult<double> get avgSatisfaction;
  MetricResult<double> get joyPerYen;
  MetricResult<double> get medianSatisfaction;
  MetricResult<int> get highlightsCount;
  MetricResult<BestJoyMomentRow> get topJoy;

  /// Create a copy of HappinessReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HappinessReportCopyWith<HappinessReport> get copyWith =>
      _$HappinessReportCopyWithImpl<HappinessReport>(
        this as HappinessReport,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HappinessReport &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.totalSoulTx, totalSoulTx) ||
                other.totalSoulTx == totalSoulTx) &&
            (identical(other.avgSatisfaction, avgSatisfaction) ||
                other.avgSatisfaction == avgSatisfaction) &&
            (identical(other.joyPerYen, joyPerYen) ||
                other.joyPerYen == joyPerYen) &&
            (identical(other.medianSatisfaction, medianSatisfaction) ||
                other.medianSatisfaction == medianSatisfaction) &&
            (identical(other.highlightsCount, highlightsCount) ||
                other.highlightsCount == highlightsCount) &&
            (identical(other.topJoy, topJoy) || other.topJoy == topJoy));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    year,
    month,
    bookId,
    totalSoulTx,
    avgSatisfaction,
    joyPerYen,
    medianSatisfaction,
    highlightsCount,
    topJoy,
  );

  @override
  String toString() {
    return 'HappinessReport(year: $year, month: $month, bookId: $bookId, totalSoulTx: $totalSoulTx, avgSatisfaction: $avgSatisfaction, joyPerYen: $joyPerYen, medianSatisfaction: $medianSatisfaction, highlightsCount: $highlightsCount, topJoy: $topJoy)';
  }
}

/// @nodoc
abstract mixin class $HappinessReportCopyWith<$Res> {
  factory $HappinessReportCopyWith(
    HappinessReport value,
    $Res Function(HappinessReport) _then,
  ) = _$HappinessReportCopyWithImpl;
  @useResult
  $Res call({
    int year,
    int month,
    String bookId,
    int totalSoulTx,
    MetricResult<double> avgSatisfaction,
    MetricResult<double> joyPerYen,
    MetricResult<double> medianSatisfaction,
    MetricResult<int> highlightsCount,
    MetricResult<BestJoyMomentRow> topJoy,
  });
}

/// @nodoc
class _$HappinessReportCopyWithImpl<$Res>
    implements $HappinessReportCopyWith<$Res> {
  _$HappinessReportCopyWithImpl(this._self, this._then);

  final HappinessReport _self;
  final $Res Function(HappinessReport) _then;

  /// Create a copy of HappinessReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? bookId = null,
    Object? totalSoulTx = null,
    Object? avgSatisfaction = null,
    Object? joyPerYen = null,
    Object? medianSatisfaction = null,
    Object? highlightsCount = null,
    Object? topJoy = null,
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
        bookId: null == bookId
            ? _self.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String,
        totalSoulTx: null == totalSoulTx
            ? _self.totalSoulTx
            : totalSoulTx // ignore: cast_nullable_to_non_nullable
                  as int,
        avgSatisfaction: null == avgSatisfaction
            ? _self.avgSatisfaction
            : avgSatisfaction // ignore: cast_nullable_to_non_nullable
                  as MetricResult<double>,
        joyPerYen: null == joyPerYen
            ? _self.joyPerYen
            : joyPerYen // ignore: cast_nullable_to_non_nullable
                  as MetricResult<double>,
        medianSatisfaction: null == medianSatisfaction
            ? _self.medianSatisfaction
            : medianSatisfaction // ignore: cast_nullable_to_non_nullable
                  as MetricResult<double>,
        highlightsCount: null == highlightsCount
            ? _self.highlightsCount
            : highlightsCount // ignore: cast_nullable_to_non_nullable
                  as MetricResult<int>,
        topJoy: null == topJoy
            ? _self.topJoy
            : topJoy // ignore: cast_nullable_to_non_nullable
                  as MetricResult<BestJoyMomentRow>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [HappinessReport].
extension HappinessReportPatterns on HappinessReport {
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
    TResult Function(_HappinessReport value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HappinessReport() when $default != null:
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
    TResult Function(_HappinessReport value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HappinessReport():
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
    TResult? Function(_HappinessReport value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HappinessReport() when $default != null:
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
      String bookId,
      int totalSoulTx,
      MetricResult<double> avgSatisfaction,
      MetricResult<double> joyPerYen,
      MetricResult<double> medianSatisfaction,
      MetricResult<int> highlightsCount,
      MetricResult<BestJoyMomentRow> topJoy,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HappinessReport() when $default != null:
        return $default(
          _that.year,
          _that.month,
          _that.bookId,
          _that.totalSoulTx,
          _that.avgSatisfaction,
          _that.joyPerYen,
          _that.medianSatisfaction,
          _that.highlightsCount,
          _that.topJoy,
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
      String bookId,
      int totalSoulTx,
      MetricResult<double> avgSatisfaction,
      MetricResult<double> joyPerYen,
      MetricResult<double> medianSatisfaction,
      MetricResult<int> highlightsCount,
      MetricResult<BestJoyMomentRow> topJoy,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HappinessReport():
        return $default(
          _that.year,
          _that.month,
          _that.bookId,
          _that.totalSoulTx,
          _that.avgSatisfaction,
          _that.joyPerYen,
          _that.medianSatisfaction,
          _that.highlightsCount,
          _that.topJoy,
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
      String bookId,
      int totalSoulTx,
      MetricResult<double> avgSatisfaction,
      MetricResult<double> joyPerYen,
      MetricResult<double> medianSatisfaction,
      MetricResult<int> highlightsCount,
      MetricResult<BestJoyMomentRow> topJoy,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HappinessReport() when $default != null:
        return $default(
          _that.year,
          _that.month,
          _that.bookId,
          _that.totalSoulTx,
          _that.avgSatisfaction,
          _that.joyPerYen,
          _that.medianSatisfaction,
          _that.highlightsCount,
          _that.topJoy,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _HappinessReport implements HappinessReport {
  const _HappinessReport({
    required this.year,
    required this.month,
    required this.bookId,
    required this.totalSoulTx,
    required this.avgSatisfaction,
    required this.joyPerYen,
    required this.medianSatisfaction,
    required this.highlightsCount,
    required this.topJoy,
  });

  // aux (flat)
  @override
  final int year;
  @override
  final int month;
  @override
  final String bookId;
  @override
  final int totalSoulTx;
  // main metrics (MetricResult-wrapped)
  @override
  final MetricResult<double> avgSatisfaction;
  @override
  final MetricResult<double> joyPerYen;
  @override
  final MetricResult<double> medianSatisfaction;
  @override
  final MetricResult<int> highlightsCount;
  @override
  final MetricResult<BestJoyMomentRow> topJoy;

  /// Create a copy of HappinessReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HappinessReportCopyWith<_HappinessReport> get copyWith =>
      __$HappinessReportCopyWithImpl<_HappinessReport>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HappinessReport &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.totalSoulTx, totalSoulTx) ||
                other.totalSoulTx == totalSoulTx) &&
            (identical(other.avgSatisfaction, avgSatisfaction) ||
                other.avgSatisfaction == avgSatisfaction) &&
            (identical(other.joyPerYen, joyPerYen) ||
                other.joyPerYen == joyPerYen) &&
            (identical(other.medianSatisfaction, medianSatisfaction) ||
                other.medianSatisfaction == medianSatisfaction) &&
            (identical(other.highlightsCount, highlightsCount) ||
                other.highlightsCount == highlightsCount) &&
            (identical(other.topJoy, topJoy) || other.topJoy == topJoy));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    year,
    month,
    bookId,
    totalSoulTx,
    avgSatisfaction,
    joyPerYen,
    medianSatisfaction,
    highlightsCount,
    topJoy,
  );

  @override
  String toString() {
    return 'HappinessReport(year: $year, month: $month, bookId: $bookId, totalSoulTx: $totalSoulTx, avgSatisfaction: $avgSatisfaction, joyPerYen: $joyPerYen, medianSatisfaction: $medianSatisfaction, highlightsCount: $highlightsCount, topJoy: $topJoy)';
  }
}

/// @nodoc
abstract mixin class _$HappinessReportCopyWith<$Res>
    implements $HappinessReportCopyWith<$Res> {
  factory _$HappinessReportCopyWith(
    _HappinessReport value,
    $Res Function(_HappinessReport) _then,
  ) = __$HappinessReportCopyWithImpl;
  @override
  @useResult
  $Res call({
    int year,
    int month,
    String bookId,
    int totalSoulTx,
    MetricResult<double> avgSatisfaction,
    MetricResult<double> joyPerYen,
    MetricResult<double> medianSatisfaction,
    MetricResult<int> highlightsCount,
    MetricResult<BestJoyMomentRow> topJoy,
  });
}

/// @nodoc
class __$HappinessReportCopyWithImpl<$Res>
    implements _$HappinessReportCopyWith<$Res> {
  __$HappinessReportCopyWithImpl(this._self, this._then);

  final _HappinessReport _self;
  final $Res Function(_HappinessReport) _then;

  /// Create a copy of HappinessReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? bookId = null,
    Object? totalSoulTx = null,
    Object? avgSatisfaction = null,
    Object? joyPerYen = null,
    Object? medianSatisfaction = null,
    Object? highlightsCount = null,
    Object? topJoy = null,
  }) {
    return _then(
      _HappinessReport(
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _self.month
            : month // ignore: cast_nullable_to_non_nullable
                  as int,
        bookId: null == bookId
            ? _self.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String,
        totalSoulTx: null == totalSoulTx
            ? _self.totalSoulTx
            : totalSoulTx // ignore: cast_nullable_to_non_nullable
                  as int,
        avgSatisfaction: null == avgSatisfaction
            ? _self.avgSatisfaction
            : avgSatisfaction // ignore: cast_nullable_to_non_nullable
                  as MetricResult<double>,
        joyPerYen: null == joyPerYen
            ? _self.joyPerYen
            : joyPerYen // ignore: cast_nullable_to_non_nullable
                  as MetricResult<double>,
        medianSatisfaction: null == medianSatisfaction
            ? _self.medianSatisfaction
            : medianSatisfaction // ignore: cast_nullable_to_non_nullable
                  as MetricResult<double>,
        highlightsCount: null == highlightsCount
            ? _self.highlightsCount
            : highlightsCount // ignore: cast_nullable_to_non_nullable
                  as MetricResult<int>,
        topJoy: null == topJoy
            ? _self.topJoy
            : topJoy // ignore: cast_nullable_to_non_nullable
                  as MetricResult<BestJoyMomentRow>,
      ),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_window.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimeWindow {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TimeWindow);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TimeWindow()';
  }
}

/// @nodoc
class $TimeWindowCopyWith<$Res> {
  $TimeWindowCopyWith(TimeWindow _, $Res Function(TimeWindow) __);
}

/// Adds pattern-matching-related methods to [TimeWindow].
extension TimeWindowPatterns on TimeWindow {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WeekWindow value)? week,
    TResult Function(MonthWindow value)? month,
    TResult Function(QuarterWindow value)? quarter,
    TResult Function(YearWindow value)? year,
    TResult Function(CustomWindow value)? custom,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case WeekWindow() when week != null:
        return week(_that);
      case MonthWindow() when month != null:
        return month(_that);
      case QuarterWindow() when quarter != null:
        return quarter(_that);
      case YearWindow() when year != null:
        return year(_that);
      case CustomWindow() when custom != null:
        return custom(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(WeekWindow value) week,
    required TResult Function(MonthWindow value) month,
    required TResult Function(QuarterWindow value) quarter,
    required TResult Function(YearWindow value) year,
    required TResult Function(CustomWindow value) custom,
  }) {
    final _that = this;
    switch (_that) {
      case WeekWindow():
        return week(_that);
      case MonthWindow():
        return month(_that);
      case QuarterWindow():
        return quarter(_that);
      case YearWindow():
        return year(_that);
      case CustomWindow():
        return custom(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WeekWindow value)? week,
    TResult? Function(MonthWindow value)? month,
    TResult? Function(QuarterWindow value)? quarter,
    TResult? Function(YearWindow value)? year,
    TResult? Function(CustomWindow value)? custom,
  }) {
    final _that = this;
    switch (_that) {
      case WeekWindow() when week != null:
        return week(_that);
      case MonthWindow() when month != null:
        return month(_that);
      case QuarterWindow() when quarter != null:
        return quarter(_that);
      case YearWindow() when year != null:
        return year(_that);
      case CustomWindow() when custom != null:
        return custom(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(DateTime mondayStart)? week,
    TResult Function(int year, int month)? month,
    TResult Function(int year, int quarter)? quarter,
    TResult Function(int year)? year,
    TResult Function(DateTime startDate, DateTime endDate)? custom,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case WeekWindow() when week != null:
        return week(_that.mondayStart);
      case MonthWindow() when month != null:
        return month(_that.year, _that.month);
      case QuarterWindow() when quarter != null:
        return quarter(_that.year, _that.quarter);
      case YearWindow() when year != null:
        return year(_that.year);
      case CustomWindow() when custom != null:
        return custom(_that.startDate, _that.endDate);
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
  TResult when<TResult extends Object?>({
    required TResult Function(DateTime mondayStart) week,
    required TResult Function(int year, int month) month,
    required TResult Function(int year, int quarter) quarter,
    required TResult Function(int year) year,
    required TResult Function(DateTime startDate, DateTime endDate) custom,
  }) {
    final _that = this;
    switch (_that) {
      case WeekWindow():
        return week(_that.mondayStart);
      case MonthWindow():
        return month(_that.year, _that.month);
      case QuarterWindow():
        return quarter(_that.year, _that.quarter);
      case YearWindow():
        return year(_that.year);
      case CustomWindow():
        return custom(_that.startDate, _that.endDate);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(DateTime mondayStart)? week,
    TResult? Function(int year, int month)? month,
    TResult? Function(int year, int quarter)? quarter,
    TResult? Function(int year)? year,
    TResult? Function(DateTime startDate, DateTime endDate)? custom,
  }) {
    final _that = this;
    switch (_that) {
      case WeekWindow() when week != null:
        return week(_that.mondayStart);
      case MonthWindow() when month != null:
        return month(_that.year, _that.month);
      case QuarterWindow() when quarter != null:
        return quarter(_that.year, _that.quarter);
      case YearWindow() when year != null:
        return year(_that.year);
      case CustomWindow() when custom != null:
        return custom(_that.startDate, _that.endDate);
      case _:
        return null;
    }
  }
}

/// @nodoc

class WeekWindow extends TimeWindow {
  const WeekWindow({required this.mondayStart}) : super._();

  final DateTime mondayStart;

  /// Create a copy of TimeWindow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WeekWindowCopyWith<WeekWindow> get copyWith =>
      _$WeekWindowCopyWithImpl<WeekWindow>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WeekWindow &&
            (identical(other.mondayStart, mondayStart) ||
                other.mondayStart == mondayStart));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mondayStart);

  @override
  String toString() {
    return 'TimeWindow.week(mondayStart: $mondayStart)';
  }
}

/// @nodoc
abstract mixin class $WeekWindowCopyWith<$Res>
    implements $TimeWindowCopyWith<$Res> {
  factory $WeekWindowCopyWith(
    WeekWindow value,
    $Res Function(WeekWindow) _then,
  ) = _$WeekWindowCopyWithImpl;
  @useResult
  $Res call({DateTime mondayStart});
}

/// @nodoc
class _$WeekWindowCopyWithImpl<$Res> implements $WeekWindowCopyWith<$Res> {
  _$WeekWindowCopyWithImpl(this._self, this._then);

  final WeekWindow _self;
  final $Res Function(WeekWindow) _then;

  /// Create a copy of TimeWindow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? mondayStart = null}) {
    return _then(
      WeekWindow(
        mondayStart: null == mondayStart
            ? _self.mondayStart
            : mondayStart // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class MonthWindow extends TimeWindow {
  const MonthWindow({required this.year, required this.month}) : super._();

  final int year;
  final int month;

  /// Create a copy of TimeWindow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MonthWindowCopyWith<MonthWindow> get copyWith =>
      _$MonthWindowCopyWithImpl<MonthWindow>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MonthWindow &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month));
  }

  @override
  int get hashCode => Object.hash(runtimeType, year, month);

  @override
  String toString() {
    return 'TimeWindow.month(year: $year, month: $month)';
  }
}

/// @nodoc
abstract mixin class $MonthWindowCopyWith<$Res>
    implements $TimeWindowCopyWith<$Res> {
  factory $MonthWindowCopyWith(
    MonthWindow value,
    $Res Function(MonthWindow) _then,
  ) = _$MonthWindowCopyWithImpl;
  @useResult
  $Res call({int year, int month});
}

/// @nodoc
class _$MonthWindowCopyWithImpl<$Res> implements $MonthWindowCopyWith<$Res> {
  _$MonthWindowCopyWithImpl(this._self, this._then);

  final MonthWindow _self;
  final $Res Function(MonthWindow) _then;

  /// Create a copy of TimeWindow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? year = null, Object? month = null}) {
    return _then(
      MonthWindow(
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _self.month
            : month // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class QuarterWindow extends TimeWindow {
  const QuarterWindow({required this.year, required this.quarter}) : super._();

  final int year;
  final int quarter;

  /// Create a copy of TimeWindow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QuarterWindowCopyWith<QuarterWindow> get copyWith =>
      _$QuarterWindowCopyWithImpl<QuarterWindow>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QuarterWindow &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.quarter, quarter) || other.quarter == quarter));
  }

  @override
  int get hashCode => Object.hash(runtimeType, year, quarter);

  @override
  String toString() {
    return 'TimeWindow.quarter(year: $year, quarter: $quarter)';
  }
}

/// @nodoc
abstract mixin class $QuarterWindowCopyWith<$Res>
    implements $TimeWindowCopyWith<$Res> {
  factory $QuarterWindowCopyWith(
    QuarterWindow value,
    $Res Function(QuarterWindow) _then,
  ) = _$QuarterWindowCopyWithImpl;
  @useResult
  $Res call({int year, int quarter});
}

/// @nodoc
class _$QuarterWindowCopyWithImpl<$Res>
    implements $QuarterWindowCopyWith<$Res> {
  _$QuarterWindowCopyWithImpl(this._self, this._then);

  final QuarterWindow _self;
  final $Res Function(QuarterWindow) _then;

  /// Create a copy of TimeWindow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? year = null, Object? quarter = null}) {
    return _then(
      QuarterWindow(
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        quarter: null == quarter
            ? _self.quarter
            : quarter // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class YearWindow extends TimeWindow {
  const YearWindow({required this.year}) : super._();

  final int year;

  /// Create a copy of TimeWindow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $YearWindowCopyWith<YearWindow> get copyWith =>
      _$YearWindowCopyWithImpl<YearWindow>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is YearWindow &&
            (identical(other.year, year) || other.year == year));
  }

  @override
  int get hashCode => Object.hash(runtimeType, year);

  @override
  String toString() {
    return 'TimeWindow.year(year: $year)';
  }
}

/// @nodoc
abstract mixin class $YearWindowCopyWith<$Res>
    implements $TimeWindowCopyWith<$Res> {
  factory $YearWindowCopyWith(
    YearWindow value,
    $Res Function(YearWindow) _then,
  ) = _$YearWindowCopyWithImpl;
  @useResult
  $Res call({int year});
}

/// @nodoc
class _$YearWindowCopyWithImpl<$Res> implements $YearWindowCopyWith<$Res> {
  _$YearWindowCopyWithImpl(this._self, this._then);

  final YearWindow _self;
  final $Res Function(YearWindow) _then;

  /// Create a copy of TimeWindow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? year = null}) {
    return _then(
      YearWindow(
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class CustomWindow extends TimeWindow {
  const CustomWindow({required this.startDate, required this.endDate})
    : super._();

  final DateTime startDate;
  final DateTime endDate;

  /// Create a copy of TimeWindow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CustomWindowCopyWith<CustomWindow> get copyWith =>
      _$CustomWindowCopyWithImpl<CustomWindow>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CustomWindow &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate));
  }

  @override
  int get hashCode => Object.hash(runtimeType, startDate, endDate);

  @override
  String toString() {
    return 'TimeWindow.custom(startDate: $startDate, endDate: $endDate)';
  }
}

/// @nodoc
abstract mixin class $CustomWindowCopyWith<$Res>
    implements $TimeWindowCopyWith<$Res> {
  factory $CustomWindowCopyWith(
    CustomWindow value,
    $Res Function(CustomWindow) _then,
  ) = _$CustomWindowCopyWithImpl;
  @useResult
  $Res call({DateTime startDate, DateTime endDate});
}

/// @nodoc
class _$CustomWindowCopyWithImpl<$Res> implements $CustomWindowCopyWith<$Res> {
  _$CustomWindowCopyWithImpl(this._self, this._then);

  final CustomWindow _self;
  final $Res Function(CustomWindow) _then;

  /// Create a copy of TimeWindow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? startDate = null, Object? endDate = null}) {
    return _then(
      CustomWindow(
        startDate: null == startDate
            ? _self.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: null == endDate
            ? _self.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

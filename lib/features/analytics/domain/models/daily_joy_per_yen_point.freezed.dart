// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_joy_per_yen_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyJoyPerYenPoint {
  /// Day-of-month (1..31).
  int get day;

  /// PTVF density for this day: Σ(sat × (amount/base)^0.88) / Σ(amount).
  double get joyPerYen;

  /// Number of soul transactions folded into this point.
  int get sampleSize;

  /// Create a copy of DailyJoyPerYenPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DailyJoyPerYenPointCopyWith<DailyJoyPerYenPoint> get copyWith =>
      _$DailyJoyPerYenPointCopyWithImpl<DailyJoyPerYenPoint>(
        this as DailyJoyPerYenPoint,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DailyJoyPerYenPoint &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.joyPerYen, joyPerYen) ||
                other.joyPerYen == joyPerYen) &&
            (identical(other.sampleSize, sampleSize) ||
                other.sampleSize == sampleSize));
  }

  @override
  int get hashCode => Object.hash(runtimeType, day, joyPerYen, sampleSize);

  @override
  String toString() {
    return 'DailyJoyPerYenPoint(day: $day, joyPerYen: $joyPerYen, sampleSize: $sampleSize)';
  }
}

/// @nodoc
abstract mixin class $DailyJoyPerYenPointCopyWith<$Res> {
  factory $DailyJoyPerYenPointCopyWith(
    DailyJoyPerYenPoint value,
    $Res Function(DailyJoyPerYenPoint) _then,
  ) = _$DailyJoyPerYenPointCopyWithImpl;
  @useResult
  $Res call({int day, double joyPerYen, int sampleSize});
}

/// @nodoc
class _$DailyJoyPerYenPointCopyWithImpl<$Res>
    implements $DailyJoyPerYenPointCopyWith<$Res> {
  _$DailyJoyPerYenPointCopyWithImpl(this._self, this._then);

  final DailyJoyPerYenPoint _self;
  final $Res Function(DailyJoyPerYenPoint) _then;

  /// Create a copy of DailyJoyPerYenPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? day = null,
    Object? joyPerYen = null,
    Object? sampleSize = null,
  }) {
    return _then(
      _self.copyWith(
        day: null == day
            ? _self.day
            : day // ignore: cast_nullable_to_non_nullable
                  as int,
        joyPerYen: null == joyPerYen
            ? _self.joyPerYen
            : joyPerYen // ignore: cast_nullable_to_non_nullable
                  as double,
        sampleSize: null == sampleSize
            ? _self.sampleSize
            : sampleSize // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [DailyJoyPerYenPoint].
extension DailyJoyPerYenPointPatterns on DailyJoyPerYenPoint {
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
    TResult Function(_DailyJoyPerYenPoint value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DailyJoyPerYenPoint() when $default != null:
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
    TResult Function(_DailyJoyPerYenPoint value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyJoyPerYenPoint():
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
    TResult? Function(_DailyJoyPerYenPoint value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyJoyPerYenPoint() when $default != null:
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
    TResult Function(int day, double joyPerYen, int sampleSize)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DailyJoyPerYenPoint() when $default != null:
        return $default(_that.day, _that.joyPerYen, _that.sampleSize);
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
    TResult Function(int day, double joyPerYen, int sampleSize) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyJoyPerYenPoint():
        return $default(_that.day, _that.joyPerYen, _that.sampleSize);
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
    TResult? Function(int day, double joyPerYen, int sampleSize)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyJoyPerYenPoint() when $default != null:
        return $default(_that.day, _that.joyPerYen, _that.sampleSize);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DailyJoyPerYenPoint implements DailyJoyPerYenPoint {
  const _DailyJoyPerYenPoint({
    required this.day,
    required this.joyPerYen,
    required this.sampleSize,
  });

  /// Day-of-month (1..31).
  @override
  final int day;

  /// PTVF density for this day: Σ(sat × (amount/base)^0.88) / Σ(amount).
  @override
  final double joyPerYen;

  /// Number of soul transactions folded into this point.
  @override
  final int sampleSize;

  /// Create a copy of DailyJoyPerYenPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DailyJoyPerYenPointCopyWith<_DailyJoyPerYenPoint> get copyWith =>
      __$DailyJoyPerYenPointCopyWithImpl<_DailyJoyPerYenPoint>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DailyJoyPerYenPoint &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.joyPerYen, joyPerYen) ||
                other.joyPerYen == joyPerYen) &&
            (identical(other.sampleSize, sampleSize) ||
                other.sampleSize == sampleSize));
  }

  @override
  int get hashCode => Object.hash(runtimeType, day, joyPerYen, sampleSize);

  @override
  String toString() {
    return 'DailyJoyPerYenPoint(day: $day, joyPerYen: $joyPerYen, sampleSize: $sampleSize)';
  }
}

/// @nodoc
abstract mixin class _$DailyJoyPerYenPointCopyWith<$Res>
    implements $DailyJoyPerYenPointCopyWith<$Res> {
  factory _$DailyJoyPerYenPointCopyWith(
    _DailyJoyPerYenPoint value,
    $Res Function(_DailyJoyPerYenPoint) _then,
  ) = __$DailyJoyPerYenPointCopyWithImpl;
  @override
  @useResult
  $Res call({int day, double joyPerYen, int sampleSize});
}

/// @nodoc
class __$DailyJoyPerYenPointCopyWithImpl<$Res>
    implements _$DailyJoyPerYenPointCopyWith<$Res> {
  __$DailyJoyPerYenPointCopyWithImpl(this._self, this._then);

  final _DailyJoyPerYenPoint _self;
  final $Res Function(_DailyJoyPerYenPoint) _then;

  /// Create a copy of DailyJoyPerYenPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? day = null,
    Object? joyPerYen = null,
    Object? sampleSize = null,
  }) {
    return _then(
      _DailyJoyPerYenPoint(
        day: null == day
            ? _self.day
            : day // ignore: cast_nullable_to_non_nullable
                  as int,
        joyPerYen: null == joyPerYen
            ? _self.joyPerYen
            : joyPerYen // ignore: cast_nullable_to_non_nullable
                  as double,
        sampleSize: null == sampleSize
            ? _self.sampleSize
            : sampleSize // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

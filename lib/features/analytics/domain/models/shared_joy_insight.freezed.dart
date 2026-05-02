// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shared_joy_insight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SharedJoyInsight {
  String get categoryId;
  double get avgSatisfaction;
  int get totalCount;

  /// Create a copy of SharedJoyInsight
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SharedJoyInsightCopyWith<SharedJoyInsight> get copyWith =>
      _$SharedJoyInsightCopyWithImpl<SharedJoyInsight>(
        this as SharedJoyInsight,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SharedJoyInsight &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.avgSatisfaction, avgSatisfaction) ||
                other.avgSatisfaction == avgSatisfaction) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, categoryId, avgSatisfaction, totalCount);

  @override
  String toString() {
    return 'SharedJoyInsight(categoryId: $categoryId, avgSatisfaction: $avgSatisfaction, totalCount: $totalCount)';
  }
}

/// @nodoc
abstract mixin class $SharedJoyInsightCopyWith<$Res> {
  factory $SharedJoyInsightCopyWith(
    SharedJoyInsight value,
    $Res Function(SharedJoyInsight) _then,
  ) = _$SharedJoyInsightCopyWithImpl;
  @useResult
  $Res call({String categoryId, double avgSatisfaction, int totalCount});
}

/// @nodoc
class _$SharedJoyInsightCopyWithImpl<$Res>
    implements $SharedJoyInsightCopyWith<$Res> {
  _$SharedJoyInsightCopyWithImpl(this._self, this._then);

  final SharedJoyInsight _self;
  final $Res Function(SharedJoyInsight) _then;

  /// Create a copy of SharedJoyInsight
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = null,
    Object? avgSatisfaction = null,
    Object? totalCount = null,
  }) {
    return _then(
      _self.copyWith(
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        avgSatisfaction: null == avgSatisfaction
            ? _self.avgSatisfaction
            : avgSatisfaction // ignore: cast_nullable_to_non_nullable
                  as double,
        totalCount: null == totalCount
            ? _self.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SharedJoyInsight].
extension SharedJoyInsightPatterns on SharedJoyInsight {
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
    TResult Function(_SharedJoyInsight value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SharedJoyInsight() when $default != null:
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
    TResult Function(_SharedJoyInsight value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SharedJoyInsight():
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
    TResult? Function(_SharedJoyInsight value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SharedJoyInsight() when $default != null:
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
    TResult Function(String categoryId, double avgSatisfaction, int totalCount)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SharedJoyInsight() when $default != null:
        return $default(
          _that.categoryId,
          _that.avgSatisfaction,
          _that.totalCount,
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
    TResult Function(String categoryId, double avgSatisfaction, int totalCount)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SharedJoyInsight():
        return $default(
          _that.categoryId,
          _that.avgSatisfaction,
          _that.totalCount,
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
      String categoryId,
      double avgSatisfaction,
      int totalCount,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SharedJoyInsight() when $default != null:
        return $default(
          _that.categoryId,
          _that.avgSatisfaction,
          _that.totalCount,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SharedJoyInsight implements SharedJoyInsight {
  const _SharedJoyInsight({
    required this.categoryId,
    required this.avgSatisfaction,
    required this.totalCount,
  });

  @override
  final String categoryId;
  @override
  final double avgSatisfaction;
  @override
  final int totalCount;

  /// Create a copy of SharedJoyInsight
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SharedJoyInsightCopyWith<_SharedJoyInsight> get copyWith =>
      __$SharedJoyInsightCopyWithImpl<_SharedJoyInsight>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SharedJoyInsight &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.avgSatisfaction, avgSatisfaction) ||
                other.avgSatisfaction == avgSatisfaction) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, categoryId, avgSatisfaction, totalCount);

  @override
  String toString() {
    return 'SharedJoyInsight(categoryId: $categoryId, avgSatisfaction: $avgSatisfaction, totalCount: $totalCount)';
  }
}

/// @nodoc
abstract mixin class _$SharedJoyInsightCopyWith<$Res>
    implements $SharedJoyInsightCopyWith<$Res> {
  factory _$SharedJoyInsightCopyWith(
    _SharedJoyInsight value,
    $Res Function(_SharedJoyInsight) _then,
  ) = __$SharedJoyInsightCopyWithImpl;
  @override
  @useResult
  $Res call({String categoryId, double avgSatisfaction, int totalCount});
}

/// @nodoc
class __$SharedJoyInsightCopyWithImpl<$Res>
    implements _$SharedJoyInsightCopyWith<$Res> {
  __$SharedJoyInsightCopyWithImpl(this._self, this._then);

  final _SharedJoyInsight _self;
  final $Res Function(_SharedJoyInsight) _then;

  /// Create a copy of SharedJoyInsight
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? categoryId = null,
    Object? avgSatisfaction = null,
    Object? totalCount = null,
  }) {
    return _then(
      _SharedJoyInsight(
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        avgSatisfaction: null == avgSatisfaction
            ? _self.avgSatisfaction
            : avgSatisfaction // ignore: cast_nullable_to_non_nullable
                  as double,
        totalCount: null == totalCount
            ? _self.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

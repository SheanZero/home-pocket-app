// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'best_joy_moment_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BestJoyMomentRow {
  String get transactionId;
  int get amount;
  int get soulSatisfaction;
  String get categoryId;
  DateTime get timestamp;

  /// Create a copy of BestJoyMomentRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BestJoyMomentRowCopyWith<BestJoyMomentRow> get copyWith =>
      _$BestJoyMomentRowCopyWithImpl<BestJoyMomentRow>(
        this as BestJoyMomentRow,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BestJoyMomentRow &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.soulSatisfaction, soulSatisfaction) ||
                other.soulSatisfaction == soulSatisfaction) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    transactionId,
    amount,
    soulSatisfaction,
    categoryId,
    timestamp,
  );

  @override
  String toString() {
    return 'BestJoyMomentRow(transactionId: $transactionId, amount: $amount, soulSatisfaction: $soulSatisfaction, categoryId: $categoryId, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $BestJoyMomentRowCopyWith<$Res> {
  factory $BestJoyMomentRowCopyWith(
    BestJoyMomentRow value,
    $Res Function(BestJoyMomentRow) _then,
  ) = _$BestJoyMomentRowCopyWithImpl;
  @useResult
  $Res call({
    String transactionId,
    int amount,
    int soulSatisfaction,
    String categoryId,
    DateTime timestamp,
  });
}

/// @nodoc
class _$BestJoyMomentRowCopyWithImpl<$Res>
    implements $BestJoyMomentRowCopyWith<$Res> {
  _$BestJoyMomentRowCopyWithImpl(this._self, this._then);

  final BestJoyMomentRow _self;
  final $Res Function(BestJoyMomentRow) _then;

  /// Create a copy of BestJoyMomentRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transactionId = null,
    Object? amount = null,
    Object? soulSatisfaction = null,
    Object? categoryId = null,
    Object? timestamp = null,
  }) {
    return _then(
      _self.copyWith(
        transactionId: null == transactionId
            ? _self.transactionId
            : transactionId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _self.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        soulSatisfaction: null == soulSatisfaction
            ? _self.soulSatisfaction
            : soulSatisfaction // ignore: cast_nullable_to_non_nullable
                  as int,
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _self.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [BestJoyMomentRow].
extension BestJoyMomentRowPatterns on BestJoyMomentRow {
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
    TResult Function(_BestJoyMomentRow value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BestJoyMomentRow() when $default != null:
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
    TResult Function(_BestJoyMomentRow value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BestJoyMomentRow():
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
    TResult? Function(_BestJoyMomentRow value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BestJoyMomentRow() when $default != null:
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
      String transactionId,
      int amount,
      int soulSatisfaction,
      String categoryId,
      DateTime timestamp,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BestJoyMomentRow() when $default != null:
        return $default(
          _that.transactionId,
          _that.amount,
          _that.soulSatisfaction,
          _that.categoryId,
          _that.timestamp,
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
      String transactionId,
      int amount,
      int soulSatisfaction,
      String categoryId,
      DateTime timestamp,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BestJoyMomentRow():
        return $default(
          _that.transactionId,
          _that.amount,
          _that.soulSatisfaction,
          _that.categoryId,
          _that.timestamp,
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
      String transactionId,
      int amount,
      int soulSatisfaction,
      String categoryId,
      DateTime timestamp,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BestJoyMomentRow() when $default != null:
        return $default(
          _that.transactionId,
          _that.amount,
          _that.soulSatisfaction,
          _that.categoryId,
          _that.timestamp,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _BestJoyMomentRow implements BestJoyMomentRow {
  const _BestJoyMomentRow({
    required this.transactionId,
    required this.amount,
    required this.soulSatisfaction,
    required this.categoryId,
    required this.timestamp,
  });

  @override
  final String transactionId;
  @override
  final int amount;
  @override
  final int soulSatisfaction;
  @override
  final String categoryId;
  @override
  final DateTime timestamp;

  /// Create a copy of BestJoyMomentRow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BestJoyMomentRowCopyWith<_BestJoyMomentRow> get copyWith =>
      __$BestJoyMomentRowCopyWithImpl<_BestJoyMomentRow>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BestJoyMomentRow &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.soulSatisfaction, soulSatisfaction) ||
                other.soulSatisfaction == soulSatisfaction) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    transactionId,
    amount,
    soulSatisfaction,
    categoryId,
    timestamp,
  );

  @override
  String toString() {
    return 'BestJoyMomentRow(transactionId: $transactionId, amount: $amount, soulSatisfaction: $soulSatisfaction, categoryId: $categoryId, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$BestJoyMomentRowCopyWith<$Res>
    implements $BestJoyMomentRowCopyWith<$Res> {
  factory _$BestJoyMomentRowCopyWith(
    _BestJoyMomentRow value,
    $Res Function(_BestJoyMomentRow) _then,
  ) = __$BestJoyMomentRowCopyWithImpl;
  @override
  @useResult
  $Res call({
    String transactionId,
    int amount,
    int soulSatisfaction,
    String categoryId,
    DateTime timestamp,
  });
}

/// @nodoc
class __$BestJoyMomentRowCopyWithImpl<$Res>
    implements _$BestJoyMomentRowCopyWith<$Res> {
  __$BestJoyMomentRowCopyWithImpl(this._self, this._then);

  final _BestJoyMomentRow _self;
  final $Res Function(_BestJoyMomentRow) _then;

  /// Create a copy of BestJoyMomentRow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? transactionId = null,
    Object? amount = null,
    Object? soulSatisfaction = null,
    Object? categoryId = null,
    Object? timestamp = null,
  }) {
    return _then(
      _BestJoyMomentRow(
        transactionId: null == transactionId
            ? _self.transactionId
            : transactionId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _self.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        soulSatisfaction: null == soulSatisfaction
            ? _self.soulSatisfaction
            : soulSatisfaction // ignore: cast_nullable_to_non_nullable
                  as int,
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _self.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

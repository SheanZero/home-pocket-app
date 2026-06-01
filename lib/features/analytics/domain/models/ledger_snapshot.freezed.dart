// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ledger_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JoyLedgerSnapshot {
  int get entryCount;
  int get totalSpend;
  double get avgSatisfaction;

  /// Create a copy of JoyLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JoyLedgerSnapshotCopyWith<JoyLedgerSnapshot> get copyWith =>
      _$JoyLedgerSnapshotCopyWithImpl<JoyLedgerSnapshot>(
        this as JoyLedgerSnapshot,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JoyLedgerSnapshot &&
            (identical(other.entryCount, entryCount) ||
                other.entryCount == entryCount) &&
            (identical(other.totalSpend, totalSpend) ||
                other.totalSpend == totalSpend) &&
            (identical(other.avgSatisfaction, avgSatisfaction) ||
                other.avgSatisfaction == avgSatisfaction));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, entryCount, totalSpend, avgSatisfaction);

  @override
  String toString() {
    return 'JoyLedgerSnapshot(entryCount: $entryCount, totalSpend: $totalSpend, avgSatisfaction: $avgSatisfaction)';
  }
}

/// @nodoc
abstract mixin class $JoyLedgerSnapshotCopyWith<$Res> {
  factory $JoyLedgerSnapshotCopyWith(
    JoyLedgerSnapshot value,
    $Res Function(JoyLedgerSnapshot) _then,
  ) = _$JoyLedgerSnapshotCopyWithImpl;
  @useResult
  $Res call({int entryCount, int totalSpend, double avgSatisfaction});
}

/// @nodoc
class _$JoyLedgerSnapshotCopyWithImpl<$Res>
    implements $JoyLedgerSnapshotCopyWith<$Res> {
  _$JoyLedgerSnapshotCopyWithImpl(this._self, this._then);

  final JoyLedgerSnapshot _self;
  final $Res Function(JoyLedgerSnapshot) _then;

  /// Create a copy of JoyLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entryCount = null,
    Object? totalSpend = null,
    Object? avgSatisfaction = null,
  }) {
    return _then(
      _self.copyWith(
        entryCount: null == entryCount
            ? _self.entryCount
            : entryCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalSpend: null == totalSpend
            ? _self.totalSpend
            : totalSpend // ignore: cast_nullable_to_non_nullable
                  as int,
        avgSatisfaction: null == avgSatisfaction
            ? _self.avgSatisfaction
            : avgSatisfaction // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [JoyLedgerSnapshot].
extension JoyLedgerSnapshotPatterns on JoyLedgerSnapshot {
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
    TResult Function(_JoyLedgerSnapshot value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JoyLedgerSnapshot() when $default != null:
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
    TResult Function(_JoyLedgerSnapshot value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JoyLedgerSnapshot():
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
    TResult? Function(_JoyLedgerSnapshot value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JoyLedgerSnapshot() when $default != null:
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
    TResult Function(int entryCount, int totalSpend, double avgSatisfaction)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JoyLedgerSnapshot() when $default != null:
        return $default(
          _that.entryCount,
          _that.totalSpend,
          _that.avgSatisfaction,
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
    TResult Function(int entryCount, int totalSpend, double avgSatisfaction)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JoyLedgerSnapshot():
        return $default(
          _that.entryCount,
          _that.totalSpend,
          _that.avgSatisfaction,
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
    TResult? Function(int entryCount, int totalSpend, double avgSatisfaction)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _JoyLedgerSnapshot() when $default != null:
        return $default(
          _that.entryCount,
          _that.totalSpend,
          _that.avgSatisfaction,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _JoyLedgerSnapshot implements JoyLedgerSnapshot {
  const _JoyLedgerSnapshot({
    required this.entryCount,
    required this.totalSpend,
    required this.avgSatisfaction,
  });

  @override
  final int entryCount;
  @override
  final int totalSpend;
  @override
  final double avgSatisfaction;

  /// Create a copy of JoyLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$JoyLedgerSnapshotCopyWith<_JoyLedgerSnapshot> get copyWith =>
      __$JoyLedgerSnapshotCopyWithImpl<_JoyLedgerSnapshot>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _JoyLedgerSnapshot &&
            (identical(other.entryCount, entryCount) ||
                other.entryCount == entryCount) &&
            (identical(other.totalSpend, totalSpend) ||
                other.totalSpend == totalSpend) &&
            (identical(other.avgSatisfaction, avgSatisfaction) ||
                other.avgSatisfaction == avgSatisfaction));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, entryCount, totalSpend, avgSatisfaction);

  @override
  String toString() {
    return 'JoyLedgerSnapshot(entryCount: $entryCount, totalSpend: $totalSpend, avgSatisfaction: $avgSatisfaction)';
  }
}

/// @nodoc
abstract mixin class _$JoyLedgerSnapshotCopyWith<$Res>
    implements $JoyLedgerSnapshotCopyWith<$Res> {
  factory _$JoyLedgerSnapshotCopyWith(
    _JoyLedgerSnapshot value,
    $Res Function(_JoyLedgerSnapshot) _then,
  ) = __$JoyLedgerSnapshotCopyWithImpl;
  @override
  @useResult
  $Res call({int entryCount, int totalSpend, double avgSatisfaction});
}

/// @nodoc
class __$JoyLedgerSnapshotCopyWithImpl<$Res>
    implements _$JoyLedgerSnapshotCopyWith<$Res> {
  __$JoyLedgerSnapshotCopyWithImpl(this._self, this._then);

  final _JoyLedgerSnapshot _self;
  final $Res Function(_JoyLedgerSnapshot) _then;

  /// Create a copy of JoyLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? entryCount = null,
    Object? totalSpend = null,
    Object? avgSatisfaction = null,
  }) {
    return _then(
      _JoyLedgerSnapshot(
        entryCount: null == entryCount
            ? _self.entryCount
            : entryCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalSpend: null == totalSpend
            ? _self.totalSpend
            : totalSpend // ignore: cast_nullable_to_non_nullable
                  as int,
        avgSatisfaction: null == avgSatisfaction
            ? _self.avgSatisfaction
            : avgSatisfaction // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
mixin _$DailyLedgerSnapshot {
  int get entryCount;
  int get totalSpend;

  /// Create a copy of DailyLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DailyLedgerSnapshotCopyWith<DailyLedgerSnapshot> get copyWith =>
      _$DailyLedgerSnapshotCopyWithImpl<DailyLedgerSnapshot>(
        this as DailyLedgerSnapshot,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DailyLedgerSnapshot &&
            (identical(other.entryCount, entryCount) ||
                other.entryCount == entryCount) &&
            (identical(other.totalSpend, totalSpend) ||
                other.totalSpend == totalSpend));
  }

  @override
  int get hashCode => Object.hash(runtimeType, entryCount, totalSpend);

  @override
  String toString() {
    return 'DailyLedgerSnapshot(entryCount: $entryCount, totalSpend: $totalSpend)';
  }
}

/// @nodoc
abstract mixin class $DailyLedgerSnapshotCopyWith<$Res> {
  factory $DailyLedgerSnapshotCopyWith(
    DailyLedgerSnapshot value,
    $Res Function(DailyLedgerSnapshot) _then,
  ) = _$DailyLedgerSnapshotCopyWithImpl;
  @useResult
  $Res call({int entryCount, int totalSpend});
}

/// @nodoc
class _$DailyLedgerSnapshotCopyWithImpl<$Res>
    implements $DailyLedgerSnapshotCopyWith<$Res> {
  _$DailyLedgerSnapshotCopyWithImpl(this._self, this._then);

  final DailyLedgerSnapshot _self;
  final $Res Function(DailyLedgerSnapshot) _then;

  /// Create a copy of DailyLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? entryCount = null, Object? totalSpend = null}) {
    return _then(
      _self.copyWith(
        entryCount: null == entryCount
            ? _self.entryCount
            : entryCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalSpend: null == totalSpend
            ? _self.totalSpend
            : totalSpend // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [DailyLedgerSnapshot].
extension DailyLedgerSnapshotPatterns on DailyLedgerSnapshot {
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
    TResult Function(_DailyLedgerSnapshot value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DailyLedgerSnapshot() when $default != null:
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
    TResult Function(_DailyLedgerSnapshot value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyLedgerSnapshot():
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
    TResult? Function(_DailyLedgerSnapshot value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyLedgerSnapshot() when $default != null:
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
    TResult Function(int entryCount, int totalSpend)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DailyLedgerSnapshot() when $default != null:
        return $default(_that.entryCount, _that.totalSpend);
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
    TResult Function(int entryCount, int totalSpend) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyLedgerSnapshot():
        return $default(_that.entryCount, _that.totalSpend);
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
    TResult? Function(int entryCount, int totalSpend)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyLedgerSnapshot() when $default != null:
        return $default(_that.entryCount, _that.totalSpend);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DailyLedgerSnapshot implements DailyLedgerSnapshot {
  const _DailyLedgerSnapshot({
    required this.entryCount,
    required this.totalSpend,
  });

  @override
  final int entryCount;
  @override
  final int totalSpend;

  /// Create a copy of DailyLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DailyLedgerSnapshotCopyWith<_DailyLedgerSnapshot> get copyWith =>
      __$DailyLedgerSnapshotCopyWithImpl<_DailyLedgerSnapshot>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DailyLedgerSnapshot &&
            (identical(other.entryCount, entryCount) ||
                other.entryCount == entryCount) &&
            (identical(other.totalSpend, totalSpend) ||
                other.totalSpend == totalSpend));
  }

  @override
  int get hashCode => Object.hash(runtimeType, entryCount, totalSpend);

  @override
  String toString() {
    return 'DailyLedgerSnapshot(entryCount: $entryCount, totalSpend: $totalSpend)';
  }
}

/// @nodoc
abstract mixin class _$DailyLedgerSnapshotCopyWith<$Res>
    implements $DailyLedgerSnapshotCopyWith<$Res> {
  factory _$DailyLedgerSnapshotCopyWith(
    _DailyLedgerSnapshot value,
    $Res Function(_DailyLedgerSnapshot) _then,
  ) = __$DailyLedgerSnapshotCopyWithImpl;
  @override
  @useResult
  $Res call({int entryCount, int totalSpend});
}

/// @nodoc
class __$DailyLedgerSnapshotCopyWithImpl<$Res>
    implements _$DailyLedgerSnapshotCopyWith<$Res> {
  __$DailyLedgerSnapshotCopyWithImpl(this._self, this._then);

  final _DailyLedgerSnapshot _self;
  final $Res Function(_DailyLedgerSnapshot) _then;

  /// Create a copy of DailyLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? entryCount = null, Object? totalSpend = null}) {
    return _then(
      _DailyLedgerSnapshot(
        entryCount: null == entryCount
            ? _self.entryCount
            : entryCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalSpend: null == totalSpend
            ? _self.totalSpend
            : totalSpend // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$DailyVsJoySnapshot {
  JoyLedgerSnapshot get joy;
  DailyLedgerSnapshot get daily;
  JoyLedgerSnapshot? get familyJoy;
  DailyLedgerSnapshot? get familyDaily;

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DailyVsJoySnapshotCopyWith<DailyVsJoySnapshot> get copyWith =>
      _$DailyVsJoySnapshotCopyWithImpl<DailyVsJoySnapshot>(
        this as DailyVsJoySnapshot,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DailyVsJoySnapshot &&
            (identical(other.joy, joy) || other.joy == joy) &&
            (identical(other.daily, daily) || other.daily == daily) &&
            (identical(other.familyJoy, familyJoy) ||
                other.familyJoy == familyJoy) &&
            (identical(other.familyDaily, familyDaily) ||
                other.familyDaily == familyDaily));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, joy, daily, familyJoy, familyDaily);

  @override
  String toString() {
    return 'DailyVsJoySnapshot(joy: $joy, daily: $daily, familyJoy: $familyJoy, familyDaily: $familyDaily)';
  }
}

/// @nodoc
abstract mixin class $DailyVsJoySnapshotCopyWith<$Res> {
  factory $DailyVsJoySnapshotCopyWith(
    DailyVsJoySnapshot value,
    $Res Function(DailyVsJoySnapshot) _then,
  ) = _$DailyVsJoySnapshotCopyWithImpl;
  @useResult
  $Res call({
    JoyLedgerSnapshot joy,
    DailyLedgerSnapshot daily,
    JoyLedgerSnapshot? familyJoy,
    DailyLedgerSnapshot? familyDaily,
  });

  $JoyLedgerSnapshotCopyWith<$Res> get joy;
  $DailyLedgerSnapshotCopyWith<$Res> get daily;
  $JoyLedgerSnapshotCopyWith<$Res>? get familyJoy;
  $DailyLedgerSnapshotCopyWith<$Res>? get familyDaily;
}

/// @nodoc
class _$DailyVsJoySnapshotCopyWithImpl<$Res>
    implements $DailyVsJoySnapshotCopyWith<$Res> {
  _$DailyVsJoySnapshotCopyWithImpl(this._self, this._then);

  final DailyVsJoySnapshot _self;
  final $Res Function(DailyVsJoySnapshot) _then;

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? joy = null,
    Object? daily = null,
    Object? familyJoy = freezed,
    Object? familyDaily = freezed,
  }) {
    return _then(
      _self.copyWith(
        joy: null == joy
            ? _self.joy
            : joy // ignore: cast_nullable_to_non_nullable
                  as JoyLedgerSnapshot,
        daily: null == daily
            ? _self.daily
            : daily // ignore: cast_nullable_to_non_nullable
                  as DailyLedgerSnapshot,
        familyJoy: freezed == familyJoy
            ? _self.familyJoy
            : familyJoy // ignore: cast_nullable_to_non_nullable
                  as JoyLedgerSnapshot?,
        familyDaily: freezed == familyDaily
            ? _self.familyDaily
            : familyDaily // ignore: cast_nullable_to_non_nullable
                  as DailyLedgerSnapshot?,
      ),
    );
  }

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JoyLedgerSnapshotCopyWith<$Res> get joy {
    return $JoyLedgerSnapshotCopyWith<$Res>(_self.joy, (value) {
      return _then(_self.copyWith(joy: value));
    });
  }

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DailyLedgerSnapshotCopyWith<$Res> get daily {
    return $DailyLedgerSnapshotCopyWith<$Res>(_self.daily, (value) {
      return _then(_self.copyWith(daily: value));
    });
  }

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JoyLedgerSnapshotCopyWith<$Res>? get familyJoy {
    if (_self.familyJoy == null) {
      return null;
    }

    return $JoyLedgerSnapshotCopyWith<$Res>(_self.familyJoy!, (value) {
      return _then(_self.copyWith(familyJoy: value));
    });
  }

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DailyLedgerSnapshotCopyWith<$Res>? get familyDaily {
    if (_self.familyDaily == null) {
      return null;
    }

    return $DailyLedgerSnapshotCopyWith<$Res>(_self.familyDaily!, (value) {
      return _then(_self.copyWith(familyDaily: value));
    });
  }
}

/// Adds pattern-matching-related methods to [DailyVsJoySnapshot].
extension DailyVsJoySnapshotPatterns on DailyVsJoySnapshot {
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
    TResult Function(_DailyVsJoySnapshot value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DailyVsJoySnapshot() when $default != null:
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
    TResult Function(_DailyVsJoySnapshot value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyVsJoySnapshot():
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
    TResult? Function(_DailyVsJoySnapshot value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyVsJoySnapshot() when $default != null:
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
      JoyLedgerSnapshot joy,
      DailyLedgerSnapshot daily,
      JoyLedgerSnapshot? familyJoy,
      DailyLedgerSnapshot? familyDaily,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DailyVsJoySnapshot() when $default != null:
        return $default(
          _that.joy,
          _that.daily,
          _that.familyJoy,
          _that.familyDaily,
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
      JoyLedgerSnapshot joy,
      DailyLedgerSnapshot daily,
      JoyLedgerSnapshot? familyJoy,
      DailyLedgerSnapshot? familyDaily,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyVsJoySnapshot():
        return $default(
          _that.joy,
          _that.daily,
          _that.familyJoy,
          _that.familyDaily,
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
      JoyLedgerSnapshot joy,
      DailyLedgerSnapshot daily,
      JoyLedgerSnapshot? familyJoy,
      DailyLedgerSnapshot? familyDaily,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyVsJoySnapshot() when $default != null:
        return $default(
          _that.joy,
          _that.daily,
          _that.familyJoy,
          _that.familyDaily,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DailyVsJoySnapshot implements DailyVsJoySnapshot {
  const _DailyVsJoySnapshot({
    required this.joy,
    required this.daily,
    this.familyJoy,
    this.familyDaily,
  });

  @override
  final JoyLedgerSnapshot joy;
  @override
  final DailyLedgerSnapshot daily;
  @override
  final JoyLedgerSnapshot? familyJoy;
  @override
  final DailyLedgerSnapshot? familyDaily;

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DailyVsJoySnapshotCopyWith<_DailyVsJoySnapshot> get copyWith =>
      __$DailyVsJoySnapshotCopyWithImpl<_DailyVsJoySnapshot>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DailyVsJoySnapshot &&
            (identical(other.joy, joy) || other.joy == joy) &&
            (identical(other.daily, daily) || other.daily == daily) &&
            (identical(other.familyJoy, familyJoy) ||
                other.familyJoy == familyJoy) &&
            (identical(other.familyDaily, familyDaily) ||
                other.familyDaily == familyDaily));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, joy, daily, familyJoy, familyDaily);

  @override
  String toString() {
    return 'DailyVsJoySnapshot(joy: $joy, daily: $daily, familyJoy: $familyJoy, familyDaily: $familyDaily)';
  }
}

/// @nodoc
abstract mixin class _$DailyVsJoySnapshotCopyWith<$Res>
    implements $DailyVsJoySnapshotCopyWith<$Res> {
  factory _$DailyVsJoySnapshotCopyWith(
    _DailyVsJoySnapshot value,
    $Res Function(_DailyVsJoySnapshot) _then,
  ) = __$DailyVsJoySnapshotCopyWithImpl;
  @override
  @useResult
  $Res call({
    JoyLedgerSnapshot joy,
    DailyLedgerSnapshot daily,
    JoyLedgerSnapshot? familyJoy,
    DailyLedgerSnapshot? familyDaily,
  });

  @override
  $JoyLedgerSnapshotCopyWith<$Res> get joy;
  @override
  $DailyLedgerSnapshotCopyWith<$Res> get daily;
  @override
  $JoyLedgerSnapshotCopyWith<$Res>? get familyJoy;
  @override
  $DailyLedgerSnapshotCopyWith<$Res>? get familyDaily;
}

/// @nodoc
class __$DailyVsJoySnapshotCopyWithImpl<$Res>
    implements _$DailyVsJoySnapshotCopyWith<$Res> {
  __$DailyVsJoySnapshotCopyWithImpl(this._self, this._then);

  final _DailyVsJoySnapshot _self;
  final $Res Function(_DailyVsJoySnapshot) _then;

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? joy = null,
    Object? daily = null,
    Object? familyJoy = freezed,
    Object? familyDaily = freezed,
  }) {
    return _then(
      _DailyVsJoySnapshot(
        joy: null == joy
            ? _self.joy
            : joy // ignore: cast_nullable_to_non_nullable
                  as JoyLedgerSnapshot,
        daily: null == daily
            ? _self.daily
            : daily // ignore: cast_nullable_to_non_nullable
                  as DailyLedgerSnapshot,
        familyJoy: freezed == familyJoy
            ? _self.familyJoy
            : familyJoy // ignore: cast_nullable_to_non_nullable
                  as JoyLedgerSnapshot?,
        familyDaily: freezed == familyDaily
            ? _self.familyDaily
            : familyDaily // ignore: cast_nullable_to_non_nullable
                  as DailyLedgerSnapshot?,
      ),
    );
  }

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JoyLedgerSnapshotCopyWith<$Res> get joy {
    return $JoyLedgerSnapshotCopyWith<$Res>(_self.joy, (value) {
      return _then(_self.copyWith(joy: value));
    });
  }

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DailyLedgerSnapshotCopyWith<$Res> get daily {
    return $DailyLedgerSnapshotCopyWith<$Res>(_self.daily, (value) {
      return _then(_self.copyWith(daily: value));
    });
  }

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JoyLedgerSnapshotCopyWith<$Res>? get familyJoy {
    if (_self.familyJoy == null) {
      return null;
    }

    return $JoyLedgerSnapshotCopyWith<$Res>(_self.familyJoy!, (value) {
      return _then(_self.copyWith(familyJoy: value));
    });
  }

  /// Create a copy of DailyVsJoySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DailyLedgerSnapshotCopyWith<$Res>? get familyDaily {
    if (_self.familyDaily == null) {
      return null;
    }

    return $DailyLedgerSnapshotCopyWith<$Res>(_self.familyDaily!, (value) {
      return _then(_self.copyWith(familyDaily: value));
    });
  }
}

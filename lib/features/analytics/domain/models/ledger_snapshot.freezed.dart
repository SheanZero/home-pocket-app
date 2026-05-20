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
mixin _$SoulLedgerSnapshot {
  int get entryCount;
  int get totalSpend;
  double get avgSatisfaction;

  /// Create a copy of SoulLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SoulLedgerSnapshotCopyWith<SoulLedgerSnapshot> get copyWith =>
      _$SoulLedgerSnapshotCopyWithImpl<SoulLedgerSnapshot>(
        this as SoulLedgerSnapshot,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SoulLedgerSnapshot &&
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
    return 'SoulLedgerSnapshot(entryCount: $entryCount, totalSpend: $totalSpend, avgSatisfaction: $avgSatisfaction)';
  }
}

/// @nodoc
abstract mixin class $SoulLedgerSnapshotCopyWith<$Res> {
  factory $SoulLedgerSnapshotCopyWith(
    SoulLedgerSnapshot value,
    $Res Function(SoulLedgerSnapshot) _then,
  ) = _$SoulLedgerSnapshotCopyWithImpl;
  @useResult
  $Res call({int entryCount, int totalSpend, double avgSatisfaction});
}

/// @nodoc
class _$SoulLedgerSnapshotCopyWithImpl<$Res>
    implements $SoulLedgerSnapshotCopyWith<$Res> {
  _$SoulLedgerSnapshotCopyWithImpl(this._self, this._then);

  final SoulLedgerSnapshot _self;
  final $Res Function(SoulLedgerSnapshot) _then;

  /// Create a copy of SoulLedgerSnapshot
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

/// Adds pattern-matching-related methods to [SoulLedgerSnapshot].
extension SoulLedgerSnapshotPatterns on SoulLedgerSnapshot {
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
    TResult Function(_SoulLedgerSnapshot value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SoulLedgerSnapshot() when $default != null:
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
    TResult Function(_SoulLedgerSnapshot value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SoulLedgerSnapshot():
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
    TResult? Function(_SoulLedgerSnapshot value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SoulLedgerSnapshot() when $default != null:
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
      case _SoulLedgerSnapshot() when $default != null:
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
      case _SoulLedgerSnapshot():
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
      case _SoulLedgerSnapshot() when $default != null:
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

class _SoulLedgerSnapshot implements SoulLedgerSnapshot {
  const _SoulLedgerSnapshot({
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

  /// Create a copy of SoulLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SoulLedgerSnapshotCopyWith<_SoulLedgerSnapshot> get copyWith =>
      __$SoulLedgerSnapshotCopyWithImpl<_SoulLedgerSnapshot>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SoulLedgerSnapshot &&
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
    return 'SoulLedgerSnapshot(entryCount: $entryCount, totalSpend: $totalSpend, avgSatisfaction: $avgSatisfaction)';
  }
}

/// @nodoc
abstract mixin class _$SoulLedgerSnapshotCopyWith<$Res>
    implements $SoulLedgerSnapshotCopyWith<$Res> {
  factory _$SoulLedgerSnapshotCopyWith(
    _SoulLedgerSnapshot value,
    $Res Function(_SoulLedgerSnapshot) _then,
  ) = __$SoulLedgerSnapshotCopyWithImpl;
  @override
  @useResult
  $Res call({int entryCount, int totalSpend, double avgSatisfaction});
}

/// @nodoc
class __$SoulLedgerSnapshotCopyWithImpl<$Res>
    implements _$SoulLedgerSnapshotCopyWith<$Res> {
  __$SoulLedgerSnapshotCopyWithImpl(this._self, this._then);

  final _SoulLedgerSnapshot _self;
  final $Res Function(_SoulLedgerSnapshot) _then;

  /// Create a copy of SoulLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? entryCount = null,
    Object? totalSpend = null,
    Object? avgSatisfaction = null,
  }) {
    return _then(
      _SoulLedgerSnapshot(
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
mixin _$SurvivalLedgerSnapshot {
  int get entryCount;
  int get totalSpend;

  /// Create a copy of SurvivalLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SurvivalLedgerSnapshotCopyWith<SurvivalLedgerSnapshot> get copyWith =>
      _$SurvivalLedgerSnapshotCopyWithImpl<SurvivalLedgerSnapshot>(
        this as SurvivalLedgerSnapshot,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SurvivalLedgerSnapshot &&
            (identical(other.entryCount, entryCount) ||
                other.entryCount == entryCount) &&
            (identical(other.totalSpend, totalSpend) ||
                other.totalSpend == totalSpend));
  }

  @override
  int get hashCode => Object.hash(runtimeType, entryCount, totalSpend);

  @override
  String toString() {
    return 'SurvivalLedgerSnapshot(entryCount: $entryCount, totalSpend: $totalSpend)';
  }
}

/// @nodoc
abstract mixin class $SurvivalLedgerSnapshotCopyWith<$Res> {
  factory $SurvivalLedgerSnapshotCopyWith(
    SurvivalLedgerSnapshot value,
    $Res Function(SurvivalLedgerSnapshot) _then,
  ) = _$SurvivalLedgerSnapshotCopyWithImpl;
  @useResult
  $Res call({int entryCount, int totalSpend});
}

/// @nodoc
class _$SurvivalLedgerSnapshotCopyWithImpl<$Res>
    implements $SurvivalLedgerSnapshotCopyWith<$Res> {
  _$SurvivalLedgerSnapshotCopyWithImpl(this._self, this._then);

  final SurvivalLedgerSnapshot _self;
  final $Res Function(SurvivalLedgerSnapshot) _then;

  /// Create a copy of SurvivalLedgerSnapshot
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

/// Adds pattern-matching-related methods to [SurvivalLedgerSnapshot].
extension SurvivalLedgerSnapshotPatterns on SurvivalLedgerSnapshot {
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
    TResult Function(_SurvivalLedgerSnapshot value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SurvivalLedgerSnapshot() when $default != null:
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
    TResult Function(_SurvivalLedgerSnapshot value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SurvivalLedgerSnapshot():
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
    TResult? Function(_SurvivalLedgerSnapshot value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SurvivalLedgerSnapshot() when $default != null:
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
      case _SurvivalLedgerSnapshot() when $default != null:
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
      case _SurvivalLedgerSnapshot():
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
      case _SurvivalLedgerSnapshot() when $default != null:
        return $default(_that.entryCount, _that.totalSpend);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SurvivalLedgerSnapshot implements SurvivalLedgerSnapshot {
  const _SurvivalLedgerSnapshot({
    required this.entryCount,
    required this.totalSpend,
  });

  @override
  final int entryCount;
  @override
  final int totalSpend;

  /// Create a copy of SurvivalLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SurvivalLedgerSnapshotCopyWith<_SurvivalLedgerSnapshot> get copyWith =>
      __$SurvivalLedgerSnapshotCopyWithImpl<_SurvivalLedgerSnapshot>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SurvivalLedgerSnapshot &&
            (identical(other.entryCount, entryCount) ||
                other.entryCount == entryCount) &&
            (identical(other.totalSpend, totalSpend) ||
                other.totalSpend == totalSpend));
  }

  @override
  int get hashCode => Object.hash(runtimeType, entryCount, totalSpend);

  @override
  String toString() {
    return 'SurvivalLedgerSnapshot(entryCount: $entryCount, totalSpend: $totalSpend)';
  }
}

/// @nodoc
abstract mixin class _$SurvivalLedgerSnapshotCopyWith<$Res>
    implements $SurvivalLedgerSnapshotCopyWith<$Res> {
  factory _$SurvivalLedgerSnapshotCopyWith(
    _SurvivalLedgerSnapshot value,
    $Res Function(_SurvivalLedgerSnapshot) _then,
  ) = __$SurvivalLedgerSnapshotCopyWithImpl;
  @override
  @useResult
  $Res call({int entryCount, int totalSpend});
}

/// @nodoc
class __$SurvivalLedgerSnapshotCopyWithImpl<$Res>
    implements _$SurvivalLedgerSnapshotCopyWith<$Res> {
  __$SurvivalLedgerSnapshotCopyWithImpl(this._self, this._then);

  final _SurvivalLedgerSnapshot _self;
  final $Res Function(_SurvivalLedgerSnapshot) _then;

  /// Create a copy of SurvivalLedgerSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? entryCount = null, Object? totalSpend = null}) {
    return _then(
      _SurvivalLedgerSnapshot(
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
mixin _$SoulVsSurvivalSnapshot {
  SoulLedgerSnapshot get soul;
  SurvivalLedgerSnapshot get survival;
  SoulLedgerSnapshot? get familySoul;
  SurvivalLedgerSnapshot? get familySurvival;

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SoulVsSurvivalSnapshotCopyWith<SoulVsSurvivalSnapshot> get copyWith =>
      _$SoulVsSurvivalSnapshotCopyWithImpl<SoulVsSurvivalSnapshot>(
        this as SoulVsSurvivalSnapshot,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SoulVsSurvivalSnapshot &&
            (identical(other.soul, soul) || other.soul == soul) &&
            (identical(other.survival, survival) ||
                other.survival == survival) &&
            (identical(other.familySoul, familySoul) ||
                other.familySoul == familySoul) &&
            (identical(other.familySurvival, familySurvival) ||
                other.familySurvival == familySurvival));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, soul, survival, familySoul, familySurvival);

  @override
  String toString() {
    return 'SoulVsSurvivalSnapshot(soul: $soul, survival: $survival, familySoul: $familySoul, familySurvival: $familySurvival)';
  }
}

/// @nodoc
abstract mixin class $SoulVsSurvivalSnapshotCopyWith<$Res> {
  factory $SoulVsSurvivalSnapshotCopyWith(
    SoulVsSurvivalSnapshot value,
    $Res Function(SoulVsSurvivalSnapshot) _then,
  ) = _$SoulVsSurvivalSnapshotCopyWithImpl;
  @useResult
  $Res call({
    SoulLedgerSnapshot soul,
    SurvivalLedgerSnapshot survival,
    SoulLedgerSnapshot? familySoul,
    SurvivalLedgerSnapshot? familySurvival,
  });

  $SoulLedgerSnapshotCopyWith<$Res> get soul;
  $SurvivalLedgerSnapshotCopyWith<$Res> get survival;
  $SoulLedgerSnapshotCopyWith<$Res>? get familySoul;
  $SurvivalLedgerSnapshotCopyWith<$Res>? get familySurvival;
}

/// @nodoc
class _$SoulVsSurvivalSnapshotCopyWithImpl<$Res>
    implements $SoulVsSurvivalSnapshotCopyWith<$Res> {
  _$SoulVsSurvivalSnapshotCopyWithImpl(this._self, this._then);

  final SoulVsSurvivalSnapshot _self;
  final $Res Function(SoulVsSurvivalSnapshot) _then;

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? soul = null,
    Object? survival = null,
    Object? familySoul = freezed,
    Object? familySurvival = freezed,
  }) {
    return _then(
      _self.copyWith(
        soul: null == soul
            ? _self.soul
            : soul // ignore: cast_nullable_to_non_nullable
                  as SoulLedgerSnapshot,
        survival: null == survival
            ? _self.survival
            : survival // ignore: cast_nullable_to_non_nullable
                  as SurvivalLedgerSnapshot,
        familySoul: freezed == familySoul
            ? _self.familySoul
            : familySoul // ignore: cast_nullable_to_non_nullable
                  as SoulLedgerSnapshot?,
        familySurvival: freezed == familySurvival
            ? _self.familySurvival
            : familySurvival // ignore: cast_nullable_to_non_nullable
                  as SurvivalLedgerSnapshot?,
      ),
    );
  }

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SoulLedgerSnapshotCopyWith<$Res> get soul {
    return $SoulLedgerSnapshotCopyWith<$Res>(_self.soul, (value) {
      return _then(_self.copyWith(soul: value));
    });
  }

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SurvivalLedgerSnapshotCopyWith<$Res> get survival {
    return $SurvivalLedgerSnapshotCopyWith<$Res>(_self.survival, (value) {
      return _then(_self.copyWith(survival: value));
    });
  }

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SoulLedgerSnapshotCopyWith<$Res>? get familySoul {
    if (_self.familySoul == null) {
      return null;
    }

    return $SoulLedgerSnapshotCopyWith<$Res>(_self.familySoul!, (value) {
      return _then(_self.copyWith(familySoul: value));
    });
  }

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SurvivalLedgerSnapshotCopyWith<$Res>? get familySurvival {
    if (_self.familySurvival == null) {
      return null;
    }

    return $SurvivalLedgerSnapshotCopyWith<$Res>(_self.familySurvival!, (
      value,
    ) {
      return _then(_self.copyWith(familySurvival: value));
    });
  }
}

/// Adds pattern-matching-related methods to [SoulVsSurvivalSnapshot].
extension SoulVsSurvivalSnapshotPatterns on SoulVsSurvivalSnapshot {
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
    TResult Function(_SoulVsSurvivalSnapshot value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SoulVsSurvivalSnapshot() when $default != null:
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
    TResult Function(_SoulVsSurvivalSnapshot value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SoulVsSurvivalSnapshot():
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
    TResult? Function(_SoulVsSurvivalSnapshot value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SoulVsSurvivalSnapshot() when $default != null:
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
      SoulLedgerSnapshot soul,
      SurvivalLedgerSnapshot survival,
      SoulLedgerSnapshot? familySoul,
      SurvivalLedgerSnapshot? familySurvival,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SoulVsSurvivalSnapshot() when $default != null:
        return $default(
          _that.soul,
          _that.survival,
          _that.familySoul,
          _that.familySurvival,
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
      SoulLedgerSnapshot soul,
      SurvivalLedgerSnapshot survival,
      SoulLedgerSnapshot? familySoul,
      SurvivalLedgerSnapshot? familySurvival,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SoulVsSurvivalSnapshot():
        return $default(
          _that.soul,
          _that.survival,
          _that.familySoul,
          _that.familySurvival,
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
      SoulLedgerSnapshot soul,
      SurvivalLedgerSnapshot survival,
      SoulLedgerSnapshot? familySoul,
      SurvivalLedgerSnapshot? familySurvival,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SoulVsSurvivalSnapshot() when $default != null:
        return $default(
          _that.soul,
          _that.survival,
          _that.familySoul,
          _that.familySurvival,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SoulVsSurvivalSnapshot implements SoulVsSurvivalSnapshot {
  const _SoulVsSurvivalSnapshot({
    required this.soul,
    required this.survival,
    this.familySoul,
    this.familySurvival,
  });

  @override
  final SoulLedgerSnapshot soul;
  @override
  final SurvivalLedgerSnapshot survival;
  @override
  final SoulLedgerSnapshot? familySoul;
  @override
  final SurvivalLedgerSnapshot? familySurvival;

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SoulVsSurvivalSnapshotCopyWith<_SoulVsSurvivalSnapshot> get copyWith =>
      __$SoulVsSurvivalSnapshotCopyWithImpl<_SoulVsSurvivalSnapshot>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SoulVsSurvivalSnapshot &&
            (identical(other.soul, soul) || other.soul == soul) &&
            (identical(other.survival, survival) ||
                other.survival == survival) &&
            (identical(other.familySoul, familySoul) ||
                other.familySoul == familySoul) &&
            (identical(other.familySurvival, familySurvival) ||
                other.familySurvival == familySurvival));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, soul, survival, familySoul, familySurvival);

  @override
  String toString() {
    return 'SoulVsSurvivalSnapshot(soul: $soul, survival: $survival, familySoul: $familySoul, familySurvival: $familySurvival)';
  }
}

/// @nodoc
abstract mixin class _$SoulVsSurvivalSnapshotCopyWith<$Res>
    implements $SoulVsSurvivalSnapshotCopyWith<$Res> {
  factory _$SoulVsSurvivalSnapshotCopyWith(
    _SoulVsSurvivalSnapshot value,
    $Res Function(_SoulVsSurvivalSnapshot) _then,
  ) = __$SoulVsSurvivalSnapshotCopyWithImpl;
  @override
  @useResult
  $Res call({
    SoulLedgerSnapshot soul,
    SurvivalLedgerSnapshot survival,
    SoulLedgerSnapshot? familySoul,
    SurvivalLedgerSnapshot? familySurvival,
  });

  @override
  $SoulLedgerSnapshotCopyWith<$Res> get soul;
  @override
  $SurvivalLedgerSnapshotCopyWith<$Res> get survival;
  @override
  $SoulLedgerSnapshotCopyWith<$Res>? get familySoul;
  @override
  $SurvivalLedgerSnapshotCopyWith<$Res>? get familySurvival;
}

/// @nodoc
class __$SoulVsSurvivalSnapshotCopyWithImpl<$Res>
    implements _$SoulVsSurvivalSnapshotCopyWith<$Res> {
  __$SoulVsSurvivalSnapshotCopyWithImpl(this._self, this._then);

  final _SoulVsSurvivalSnapshot _self;
  final $Res Function(_SoulVsSurvivalSnapshot) _then;

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? soul = null,
    Object? survival = null,
    Object? familySoul = freezed,
    Object? familySurvival = freezed,
  }) {
    return _then(
      _SoulVsSurvivalSnapshot(
        soul: null == soul
            ? _self.soul
            : soul // ignore: cast_nullable_to_non_nullable
                  as SoulLedgerSnapshot,
        survival: null == survival
            ? _self.survival
            : survival // ignore: cast_nullable_to_non_nullable
                  as SurvivalLedgerSnapshot,
        familySoul: freezed == familySoul
            ? _self.familySoul
            : familySoul // ignore: cast_nullable_to_non_nullable
                  as SoulLedgerSnapshot?,
        familySurvival: freezed == familySurvival
            ? _self.familySurvival
            : familySurvival // ignore: cast_nullable_to_non_nullable
                  as SurvivalLedgerSnapshot?,
      ),
    );
  }

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SoulLedgerSnapshotCopyWith<$Res> get soul {
    return $SoulLedgerSnapshotCopyWith<$Res>(_self.soul, (value) {
      return _then(_self.copyWith(soul: value));
    });
  }

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SurvivalLedgerSnapshotCopyWith<$Res> get survival {
    return $SurvivalLedgerSnapshotCopyWith<$Res>(_self.survival, (value) {
      return _then(_self.copyWith(survival: value));
    });
  }

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SoulLedgerSnapshotCopyWith<$Res>? get familySoul {
    if (_self.familySoul == null) {
      return null;
    }

    return $SoulLedgerSnapshotCopyWith<$Res>(_self.familySoul!, (value) {
      return _then(_self.copyWith(familySoul: value));
    });
  }

  /// Create a copy of SoulVsSurvivalSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SurvivalLedgerSnapshotCopyWith<$Res>? get familySurvival {
    if (_self.familySurvival == null) {
      return null;
    }

    return $SurvivalLedgerSnapshotCopyWith<$Res>(_self.familySurvival!, (
      value,
    ) {
      return _then(_self.copyWith(familySurvival: value));
    });
  }
}

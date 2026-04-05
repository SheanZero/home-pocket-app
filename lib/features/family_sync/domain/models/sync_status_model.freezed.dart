// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_status_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncStatus {
  SyncState get state;
  DateTime? get lastSyncAt;
  int? get pendingQueueCount;
  String? get errorMessage;

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SyncStatusCopyWith<SyncStatus> get copyWith =>
      _$SyncStatusCopyWithImpl<SyncStatus>(this as SyncStatus, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SyncStatus &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.lastSyncAt, lastSyncAt) ||
                other.lastSyncAt == lastSyncAt) &&
            (identical(other.pendingQueueCount, pendingQueueCount) ||
                other.pendingQueueCount == pendingQueueCount) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    state,
    lastSyncAt,
    pendingQueueCount,
    errorMessage,
  );

  @override
  String toString() {
    return 'SyncStatus(state: $state, lastSyncAt: $lastSyncAt, pendingQueueCount: $pendingQueueCount, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class $SyncStatusCopyWith<$Res> {
  factory $SyncStatusCopyWith(
    SyncStatus value,
    $Res Function(SyncStatus) _then,
  ) = _$SyncStatusCopyWithImpl;
  @useResult
  $Res call({
    SyncState state,
    DateTime? lastSyncAt,
    int? pendingQueueCount,
    String? errorMessage,
  });
}

/// @nodoc
class _$SyncStatusCopyWithImpl<$Res> implements $SyncStatusCopyWith<$Res> {
  _$SyncStatusCopyWithImpl(this._self, this._then);

  final SyncStatus _self;
  final $Res Function(SyncStatus) _then;

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? lastSyncAt = freezed,
    Object? pendingQueueCount = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _self.copyWith(
        state: null == state
            ? _self.state
            : state // ignore: cast_nullable_to_non_nullable
                  as SyncState,
        lastSyncAt: freezed == lastSyncAt
            ? _self.lastSyncAt
            : lastSyncAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        pendingQueueCount: freezed == pendingQueueCount
            ? _self.pendingQueueCount
            : pendingQueueCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        errorMessage: freezed == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SyncStatus].
extension SyncStatusPatterns on SyncStatus {
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
    TResult Function(_SyncStatus value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SyncStatus() when $default != null:
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
    TResult Function(_SyncStatus value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncStatus():
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
    TResult? Function(_SyncStatus value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncStatus() when $default != null:
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
      SyncState state,
      DateTime? lastSyncAt,
      int? pendingQueueCount,
      String? errorMessage,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SyncStatus() when $default != null:
        return $default(
          _that.state,
          _that.lastSyncAt,
          _that.pendingQueueCount,
          _that.errorMessage,
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
      SyncState state,
      DateTime? lastSyncAt,
      int? pendingQueueCount,
      String? errorMessage,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncStatus():
        return $default(
          _that.state,
          _that.lastSyncAt,
          _that.pendingQueueCount,
          _that.errorMessage,
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
      SyncState state,
      DateTime? lastSyncAt,
      int? pendingQueueCount,
      String? errorMessage,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncStatus() when $default != null:
        return $default(
          _that.state,
          _that.lastSyncAt,
          _that.pendingQueueCount,
          _that.errorMessage,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SyncStatus implements SyncStatus {
  const _SyncStatus({
    required this.state,
    this.lastSyncAt,
    this.pendingQueueCount,
    this.errorMessage,
  });

  @override
  final SyncState state;
  @override
  final DateTime? lastSyncAt;
  @override
  final int? pendingQueueCount;
  @override
  final String? errorMessage;

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SyncStatusCopyWith<_SyncStatus> get copyWith =>
      __$SyncStatusCopyWithImpl<_SyncStatus>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SyncStatus &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.lastSyncAt, lastSyncAt) ||
                other.lastSyncAt == lastSyncAt) &&
            (identical(other.pendingQueueCount, pendingQueueCount) ||
                other.pendingQueueCount == pendingQueueCount) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    state,
    lastSyncAt,
    pendingQueueCount,
    errorMessage,
  );

  @override
  String toString() {
    return 'SyncStatus(state: $state, lastSyncAt: $lastSyncAt, pendingQueueCount: $pendingQueueCount, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class _$SyncStatusCopyWith<$Res>
    implements $SyncStatusCopyWith<$Res> {
  factory _$SyncStatusCopyWith(
    _SyncStatus value,
    $Res Function(_SyncStatus) _then,
  ) = __$SyncStatusCopyWithImpl;
  @override
  @useResult
  $Res call({
    SyncState state,
    DateTime? lastSyncAt,
    int? pendingQueueCount,
    String? errorMessage,
  });
}

/// @nodoc
class __$SyncStatusCopyWithImpl<$Res> implements _$SyncStatusCopyWith<$Res> {
  __$SyncStatusCopyWithImpl(this._self, this._then);

  final _SyncStatus _self;
  final $Res Function(_SyncStatus) _then;

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? state = null,
    Object? lastSyncAt = freezed,
    Object? pendingQueueCount = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _SyncStatus(
        state: null == state
            ? _self.state
            : state // ignore: cast_nullable_to_non_nullable
                  as SyncState,
        lastSyncAt: freezed == lastSyncAt
            ? _self.lastSyncAt
            : lastSyncAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        pendingQueueCount: freezed == pendingQueueCount
            ? _self.pendingQueueCount
            : pendingQueueCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        errorMessage: freezed == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

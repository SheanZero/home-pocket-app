// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_key_pair.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceKeyPair {
  /// Base64-encoded Ed25519 public key (32 bytes).
  String get publicKey;

  /// Device ID: Base64URL(SHA-256(publicKey))[0:16].
  String get deviceId;

  /// Timestamp when the key pair was generated.
  DateTime get createdAt;

  /// Create a copy of DeviceKeyPair
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DeviceKeyPairCopyWith<DeviceKeyPair> get copyWith =>
      _$DeviceKeyPairCopyWithImpl<DeviceKeyPair>(
        this as DeviceKeyPair,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DeviceKeyPair &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, publicKey, deviceId, createdAt);

  @override
  String toString() {
    return 'DeviceKeyPair(publicKey: $publicKey, deviceId: $deviceId, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $DeviceKeyPairCopyWith<$Res> {
  factory $DeviceKeyPairCopyWith(
    DeviceKeyPair value,
    $Res Function(DeviceKeyPair) _then,
  ) = _$DeviceKeyPairCopyWithImpl;
  @useResult
  $Res call({String publicKey, String deviceId, DateTime createdAt});
}

/// @nodoc
class _$DeviceKeyPairCopyWithImpl<$Res>
    implements $DeviceKeyPairCopyWith<$Res> {
  _$DeviceKeyPairCopyWithImpl(this._self, this._then);

  final DeviceKeyPair _self;
  final $Res Function(DeviceKeyPair) _then;

  /// Create a copy of DeviceKeyPair
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicKey = null,
    Object? deviceId = null,
    Object? createdAt = null,
  }) {
    return _then(
      _self.copyWith(
        publicKey: null == publicKey
            ? _self.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [DeviceKeyPair].
extension DeviceKeyPairPatterns on DeviceKeyPair {
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
    TResult Function(_DeviceKeyPair value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DeviceKeyPair() when $default != null:
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
    TResult Function(_DeviceKeyPair value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeviceKeyPair():
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
    TResult? Function(_DeviceKeyPair value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeviceKeyPair() when $default != null:
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
    TResult Function(String publicKey, String deviceId, DateTime createdAt)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DeviceKeyPair() when $default != null:
        return $default(_that.publicKey, _that.deviceId, _that.createdAt);
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
    TResult Function(String publicKey, String deviceId, DateTime createdAt)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeviceKeyPair():
        return $default(_that.publicKey, _that.deviceId, _that.createdAt);
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
    TResult? Function(String publicKey, String deviceId, DateTime createdAt)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DeviceKeyPair() when $default != null:
        return $default(_that.publicKey, _that.deviceId, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DeviceKeyPair implements DeviceKeyPair {
  const _DeviceKeyPair({
    required this.publicKey,
    required this.deviceId,
    required this.createdAt,
  });

  /// Base64-encoded Ed25519 public key (32 bytes).
  @override
  final String publicKey;

  /// Device ID: Base64URL(SHA-256(publicKey))[0:16].
  @override
  final String deviceId;

  /// Timestamp when the key pair was generated.
  @override
  final DateTime createdAt;

  /// Create a copy of DeviceKeyPair
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DeviceKeyPairCopyWith<_DeviceKeyPair> get copyWith =>
      __$DeviceKeyPairCopyWithImpl<_DeviceKeyPair>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DeviceKeyPair &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, publicKey, deviceId, createdAt);

  @override
  String toString() {
    return 'DeviceKeyPair(publicKey: $publicKey, deviceId: $deviceId, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$DeviceKeyPairCopyWith<$Res>
    implements $DeviceKeyPairCopyWith<$Res> {
  factory _$DeviceKeyPairCopyWith(
    _DeviceKeyPair value,
    $Res Function(_DeviceKeyPair) _then,
  ) = __$DeviceKeyPairCopyWithImpl;
  @override
  @useResult
  $Res call({String publicKey, String deviceId, DateTime createdAt});
}

/// @nodoc
class __$DeviceKeyPairCopyWithImpl<$Res>
    implements _$DeviceKeyPairCopyWith<$Res> {
  __$DeviceKeyPairCopyWithImpl(this._self, this._then);

  final _DeviceKeyPair _self;
  final $Res Function(_DeviceKeyPair) _then;

  /// Create a copy of DeviceKeyPair
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? publicKey = null,
    Object? deviceId = null,
    Object? createdAt = null,
  }) {
    return _then(
      _DeviceKeyPair(
        publicKey: null == publicKey
            ? _self.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupMember {
  String get deviceId;
  String get publicKey;
  String get deviceName;
  String get role;
  String get status;
  String get displayName;
  String get avatarEmoji;
  String? get avatarImagePath;
  String? get avatarImageHash;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GroupMemberCopyWith<GroupMember> get copyWith =>
      _$GroupMemberCopyWithImpl<GroupMember>(this as GroupMember, _$identity);

  /// Serializes this GroupMember to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GroupMember &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarEmoji, avatarEmoji) ||
                other.avatarEmoji == avatarEmoji) &&
            (identical(other.avatarImagePath, avatarImagePath) ||
                other.avatarImagePath == avatarImagePath) &&
            (identical(other.avatarImageHash, avatarImageHash) ||
                other.avatarImageHash == avatarImageHash));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    deviceId,
    publicKey,
    deviceName,
    role,
    status,
    displayName,
    avatarEmoji,
    avatarImagePath,
    avatarImageHash,
  );

  @override
  String toString() {
    return 'GroupMember(deviceId: $deviceId, publicKey: $publicKey, deviceName: $deviceName, role: $role, status: $status, displayName: $displayName, avatarEmoji: $avatarEmoji, avatarImagePath: $avatarImagePath, avatarImageHash: $avatarImageHash)';
  }
}

/// @nodoc
abstract mixin class $GroupMemberCopyWith<$Res> {
  factory $GroupMemberCopyWith(
    GroupMember value,
    $Res Function(GroupMember) _then,
  ) = _$GroupMemberCopyWithImpl;
  @useResult
  $Res call({
    String deviceId,
    String publicKey,
    String deviceName,
    String role,
    String status,
    String displayName,
    String avatarEmoji,
    String? avatarImagePath,
    String? avatarImageHash,
  });
}

/// @nodoc
class _$GroupMemberCopyWithImpl<$Res> implements $GroupMemberCopyWith<$Res> {
  _$GroupMemberCopyWithImpl(this._self, this._then);

  final GroupMember _self;
  final $Res Function(GroupMember) _then;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? publicKey = null,
    Object? deviceName = null,
    Object? role = null,
    Object? status = null,
    Object? displayName = null,
    Object? avatarEmoji = null,
    Object? avatarImagePath = freezed,
    Object? avatarImageHash = freezed,
  }) {
    return _then(
      _self.copyWith(
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        publicKey: null == publicKey
            ? _self.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceName: null == deviceName
            ? _self.deviceName
            : deviceName // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _self.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _self.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        avatarEmoji: null == avatarEmoji
            ? _self.avatarEmoji
            : avatarEmoji // ignore: cast_nullable_to_non_nullable
                  as String,
        avatarImagePath: freezed == avatarImagePath
            ? _self.avatarImagePath
            : avatarImagePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatarImageHash: freezed == avatarImageHash
            ? _self.avatarImageHash
            : avatarImageHash // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [GroupMember].
extension GroupMemberPatterns on GroupMember {
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
    TResult Function(_GroupMember value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupMember() when $default != null:
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
    TResult Function(_GroupMember value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupMember():
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
    TResult? Function(_GroupMember value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupMember() when $default != null:
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
      String deviceId,
      String publicKey,
      String deviceName,
      String role,
      String status,
      String displayName,
      String avatarEmoji,
      String? avatarImagePath,
      String? avatarImageHash,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupMember() when $default != null:
        return $default(
          _that.deviceId,
          _that.publicKey,
          _that.deviceName,
          _that.role,
          _that.status,
          _that.displayName,
          _that.avatarEmoji,
          _that.avatarImagePath,
          _that.avatarImageHash,
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
      String deviceId,
      String publicKey,
      String deviceName,
      String role,
      String status,
      String displayName,
      String avatarEmoji,
      String? avatarImagePath,
      String? avatarImageHash,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupMember():
        return $default(
          _that.deviceId,
          _that.publicKey,
          _that.deviceName,
          _that.role,
          _that.status,
          _that.displayName,
          _that.avatarEmoji,
          _that.avatarImagePath,
          _that.avatarImageHash,
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
      String deviceId,
      String publicKey,
      String deviceName,
      String role,
      String status,
      String displayName,
      String avatarEmoji,
      String? avatarImagePath,
      String? avatarImageHash,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupMember() when $default != null:
        return $default(
          _that.deviceId,
          _that.publicKey,
          _that.deviceName,
          _that.role,
          _that.status,
          _that.displayName,
          _that.avatarEmoji,
          _that.avatarImagePath,
          _that.avatarImageHash,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _GroupMember implements GroupMember {
  const _GroupMember({
    required this.deviceId,
    required this.publicKey,
    required this.deviceName,
    required this.role,
    required this.status,
    required this.displayName,
    required this.avatarEmoji,
    this.avatarImagePath,
    this.avatarImageHash,
  });
  factory _GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);

  @override
  final String deviceId;
  @override
  final String publicKey;
  @override
  final String deviceName;
  @override
  final String role;
  @override
  final String status;
  @override
  final String displayName;
  @override
  final String avatarEmoji;
  @override
  final String? avatarImagePath;
  @override
  final String? avatarImageHash;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GroupMemberCopyWith<_GroupMember> get copyWith =>
      __$GroupMemberCopyWithImpl<_GroupMember>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GroupMemberToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GroupMember &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarEmoji, avatarEmoji) ||
                other.avatarEmoji == avatarEmoji) &&
            (identical(other.avatarImagePath, avatarImagePath) ||
                other.avatarImagePath == avatarImagePath) &&
            (identical(other.avatarImageHash, avatarImageHash) ||
                other.avatarImageHash == avatarImageHash));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    deviceId,
    publicKey,
    deviceName,
    role,
    status,
    displayName,
    avatarEmoji,
    avatarImagePath,
    avatarImageHash,
  );

  @override
  String toString() {
    return 'GroupMember(deviceId: $deviceId, publicKey: $publicKey, deviceName: $deviceName, role: $role, status: $status, displayName: $displayName, avatarEmoji: $avatarEmoji, avatarImagePath: $avatarImagePath, avatarImageHash: $avatarImageHash)';
  }
}

/// @nodoc
abstract mixin class _$GroupMemberCopyWith<$Res>
    implements $GroupMemberCopyWith<$Res> {
  factory _$GroupMemberCopyWith(
    _GroupMember value,
    $Res Function(_GroupMember) _then,
  ) = __$GroupMemberCopyWithImpl;
  @override
  @useResult
  $Res call({
    String deviceId,
    String publicKey,
    String deviceName,
    String role,
    String status,
    String displayName,
    String avatarEmoji,
    String? avatarImagePath,
    String? avatarImageHash,
  });
}

/// @nodoc
class __$GroupMemberCopyWithImpl<$Res> implements _$GroupMemberCopyWith<$Res> {
  __$GroupMemberCopyWithImpl(this._self, this._then);

  final _GroupMember _self;
  final $Res Function(_GroupMember) _then;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? deviceId = null,
    Object? publicKey = null,
    Object? deviceName = null,
    Object? role = null,
    Object? status = null,
    Object? displayName = null,
    Object? avatarEmoji = null,
    Object? avatarImagePath = freezed,
    Object? avatarImageHash = freezed,
  }) {
    return _then(
      _GroupMember(
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        publicKey: null == publicKey
            ? _self.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceName: null == deviceName
            ? _self.deviceName
            : deviceName // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _self.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _self.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        avatarEmoji: null == avatarEmoji
            ? _self.avatarEmoji
            : avatarEmoji // ignore: cast_nullable_to_non_nullable
                  as String,
        avatarImagePath: freezed == avatarImagePath
            ? _self.avatarImagePath
            : avatarImagePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatarImageHash: freezed == avatarImageHash
            ? _self.avatarImageHash
            : avatarImageHash // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

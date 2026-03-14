// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupInfo {
  String get groupId;
  GroupStatus get status;
  String? get inviteCode;
  DateTime? get inviteExpiresAt;
  String get role;
  String? get groupKey;
  List<GroupMember> get members;
  DateTime get createdAt;
  DateTime? get confirmedAt;
  DateTime? get lastSyncAt;

  /// Create a copy of GroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GroupInfoCopyWith<GroupInfo> get copyWith =>
      _$GroupInfoCopyWithImpl<GroupInfo>(this as GroupInfo, _$identity);

  /// Serializes this GroupInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GroupInfo &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.inviteExpiresAt, inviteExpiresAt) ||
                other.inviteExpiresAt == inviteExpiresAt) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.groupKey, groupKey) ||
                other.groupKey == groupKey) &&
            const DeepCollectionEquality().equals(other.members, members) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt) &&
            (identical(other.lastSyncAt, lastSyncAt) ||
                other.lastSyncAt == lastSyncAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    groupId,
    status,
    inviteCode,
    inviteExpiresAt,
    role,
    groupKey,
    const DeepCollectionEquality().hash(members),
    createdAt,
    confirmedAt,
    lastSyncAt,
  );

  @override
  String toString() {
    return 'GroupInfo(groupId: $groupId, status: $status, inviteCode: $inviteCode, inviteExpiresAt: $inviteExpiresAt, role: $role, groupKey: $groupKey, members: $members, createdAt: $createdAt, confirmedAt: $confirmedAt, lastSyncAt: $lastSyncAt)';
  }
}

/// @nodoc
abstract mixin class $GroupInfoCopyWith<$Res> {
  factory $GroupInfoCopyWith(GroupInfo value, $Res Function(GroupInfo) _then) =
      _$GroupInfoCopyWithImpl;
  @useResult
  $Res call({
    String groupId,
    GroupStatus status,
    String? inviteCode,
    DateTime? inviteExpiresAt,
    String role,
    String? groupKey,
    List<GroupMember> members,
    DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
  });
}

/// @nodoc
class _$GroupInfoCopyWithImpl<$Res> implements $GroupInfoCopyWith<$Res> {
  _$GroupInfoCopyWithImpl(this._self, this._then);

  final GroupInfo _self;
  final $Res Function(GroupInfo) _then;

  /// Create a copy of GroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? status = null,
    Object? inviteCode = freezed,
    Object? inviteExpiresAt = freezed,
    Object? role = null,
    Object? groupKey = freezed,
    Object? members = null,
    Object? createdAt = null,
    Object? confirmedAt = freezed,
    Object? lastSyncAt = freezed,
  }) {
    return _then(
      _self.copyWith(
        groupId: null == groupId
            ? _self.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as GroupStatus,
        inviteCode: freezed == inviteCode
            ? _self.inviteCode
            : inviteCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        inviteExpiresAt: freezed == inviteExpiresAt
            ? _self.inviteExpiresAt
            : inviteExpiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        role: null == role
            ? _self.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        groupKey: freezed == groupKey
            ? _self.groupKey
            : groupKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        members: null == members
            ? _self.members
            : members // ignore: cast_nullable_to_non_nullable
                  as List<GroupMember>,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        confirmedAt: freezed == confirmedAt
            ? _self.confirmedAt
            : confirmedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastSyncAt: freezed == lastSyncAt
            ? _self.lastSyncAt
            : lastSyncAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [GroupInfo].
extension GroupInfoPatterns on GroupInfo {
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
    TResult Function(_GroupInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupInfo() when $default != null:
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
    TResult Function(_GroupInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupInfo():
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
    TResult? Function(_GroupInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupInfo() when $default != null:
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
      String groupId,
      GroupStatus status,
      String? inviteCode,
      DateTime? inviteExpiresAt,
      String role,
      String? groupKey,
      List<GroupMember> members,
      DateTime createdAt,
      DateTime? confirmedAt,
      DateTime? lastSyncAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupInfo() when $default != null:
        return $default(
          _that.groupId,
          _that.status,
          _that.inviteCode,
          _that.inviteExpiresAt,
          _that.role,
          _that.groupKey,
          _that.members,
          _that.createdAt,
          _that.confirmedAt,
          _that.lastSyncAt,
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
      String groupId,
      GroupStatus status,
      String? inviteCode,
      DateTime? inviteExpiresAt,
      String role,
      String? groupKey,
      List<GroupMember> members,
      DateTime createdAt,
      DateTime? confirmedAt,
      DateTime? lastSyncAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupInfo():
        return $default(
          _that.groupId,
          _that.status,
          _that.inviteCode,
          _that.inviteExpiresAt,
          _that.role,
          _that.groupKey,
          _that.members,
          _that.createdAt,
          _that.confirmedAt,
          _that.lastSyncAt,
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
      String groupId,
      GroupStatus status,
      String? inviteCode,
      DateTime? inviteExpiresAt,
      String role,
      String? groupKey,
      List<GroupMember> members,
      DateTime createdAt,
      DateTime? confirmedAt,
      DateTime? lastSyncAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupInfo() when $default != null:
        return $default(
          _that.groupId,
          _that.status,
          _that.inviteCode,
          _that.inviteExpiresAt,
          _that.role,
          _that.groupKey,
          _that.members,
          _that.createdAt,
          _that.confirmedAt,
          _that.lastSyncAt,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _GroupInfo implements GroupInfo {
  const _GroupInfo({
    required this.groupId,
    required this.status,
    this.inviteCode,
    this.inviteExpiresAt,
    required this.role,
    this.groupKey,
    required final List<GroupMember> members,
    required this.createdAt,
    this.confirmedAt,
    this.lastSyncAt,
  }) : _members = members;
  factory _GroupInfo.fromJson(Map<String, dynamic> json) =>
      _$GroupInfoFromJson(json);

  @override
  final String groupId;
  @override
  final GroupStatus status;
  @override
  final String? inviteCode;
  @override
  final DateTime? inviteExpiresAt;
  @override
  final String role;
  @override
  final String? groupKey;
  final List<GroupMember> _members;
  @override
  List<GroupMember> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime? confirmedAt;
  @override
  final DateTime? lastSyncAt;

  /// Create a copy of GroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GroupInfoCopyWith<_GroupInfo> get copyWith =>
      __$GroupInfoCopyWithImpl<_GroupInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GroupInfoToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GroupInfo &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.inviteExpiresAt, inviteExpiresAt) ||
                other.inviteExpiresAt == inviteExpiresAt) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.groupKey, groupKey) ||
                other.groupKey == groupKey) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt) &&
            (identical(other.lastSyncAt, lastSyncAt) ||
                other.lastSyncAt == lastSyncAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    groupId,
    status,
    inviteCode,
    inviteExpiresAt,
    role,
    groupKey,
    const DeepCollectionEquality().hash(_members),
    createdAt,
    confirmedAt,
    lastSyncAt,
  );

  @override
  String toString() {
    return 'GroupInfo(groupId: $groupId, status: $status, inviteCode: $inviteCode, inviteExpiresAt: $inviteExpiresAt, role: $role, groupKey: $groupKey, members: $members, createdAt: $createdAt, confirmedAt: $confirmedAt, lastSyncAt: $lastSyncAt)';
  }
}

/// @nodoc
abstract mixin class _$GroupInfoCopyWith<$Res>
    implements $GroupInfoCopyWith<$Res> {
  factory _$GroupInfoCopyWith(
    _GroupInfo value,
    $Res Function(_GroupInfo) _then,
  ) = __$GroupInfoCopyWithImpl;
  @override
  @useResult
  $Res call({
    String groupId,
    GroupStatus status,
    String? inviteCode,
    DateTime? inviteExpiresAt,
    String role,
    String? groupKey,
    List<GroupMember> members,
    DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
  });
}

/// @nodoc
class __$GroupInfoCopyWithImpl<$Res> implements _$GroupInfoCopyWith<$Res> {
  __$GroupInfoCopyWithImpl(this._self, this._then);

  final _GroupInfo _self;
  final $Res Function(_GroupInfo) _then;

  /// Create a copy of GroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? groupId = null,
    Object? status = null,
    Object? inviteCode = freezed,
    Object? inviteExpiresAt = freezed,
    Object? role = null,
    Object? groupKey = freezed,
    Object? members = null,
    Object? createdAt = null,
    Object? confirmedAt = freezed,
    Object? lastSyncAt = freezed,
  }) {
    return _then(
      _GroupInfo(
        groupId: null == groupId
            ? _self.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as GroupStatus,
        inviteCode: freezed == inviteCode
            ? _self.inviteCode
            : inviteCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        inviteExpiresAt: freezed == inviteExpiresAt
            ? _self.inviteExpiresAt
            : inviteExpiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        role: null == role
            ? _self.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        groupKey: freezed == groupKey
            ? _self.groupKey
            : groupKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        members: null == members
            ? _self._members
            : members // ignore: cast_nullable_to_non_nullable
                  as List<GroupMember>,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        confirmedAt: freezed == confirmedAt
            ? _self.confirmedAt
            : confirmedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastSyncAt: freezed == lastSyncAt
            ? _self.lastSyncAt
            : lastSyncAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

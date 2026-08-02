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
  String get groupName;
  String? get inviteCode;
  DateTime? get inviteExpiresAt;
  String get role;
  String? get groupKey;
  int get keyEpoch;
  List<GroupMember> get members;
  DateTime get createdAt;
  DateTime? get confirmedAt;
  DateTime? get lastSyncAt;
  int get controlRevision;
  DateTime? get controlUpdatedAt;
  String get controlSnapshotDigest;

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
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.inviteExpiresAt, inviteExpiresAt) ||
                other.inviteExpiresAt == inviteExpiresAt) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.groupKey, groupKey) ||
                other.groupKey == groupKey) &&
            (identical(other.keyEpoch, keyEpoch) ||
                other.keyEpoch == keyEpoch) &&
            const DeepCollectionEquality().equals(other.members, members) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt) &&
            (identical(other.lastSyncAt, lastSyncAt) ||
                other.lastSyncAt == lastSyncAt) &&
            (identical(other.controlRevision, controlRevision) ||
                other.controlRevision == controlRevision) &&
            (identical(other.controlUpdatedAt, controlUpdatedAt) ||
                other.controlUpdatedAt == controlUpdatedAt) &&
            (identical(other.controlSnapshotDigest, controlSnapshotDigest) ||
                other.controlSnapshotDigest == controlSnapshotDigest));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    groupId,
    status,
    groupName,
    inviteCode,
    inviteExpiresAt,
    role,
    groupKey,
    keyEpoch,
    const DeepCollectionEquality().hash(members),
    createdAt,
    confirmedAt,
    lastSyncAt,
    controlRevision,
    controlUpdatedAt,
    controlSnapshotDigest,
  );

  @override
  String toString() {
    return 'GroupInfo(groupId: $groupId, status: $status, groupName: $groupName, inviteCode: $inviteCode, inviteExpiresAt: $inviteExpiresAt, role: $role, groupKey: $groupKey, keyEpoch: $keyEpoch, members: $members, createdAt: $createdAt, confirmedAt: $confirmedAt, lastSyncAt: $lastSyncAt, controlRevision: $controlRevision, controlUpdatedAt: $controlUpdatedAt, controlSnapshotDigest: $controlSnapshotDigest)';
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
    String groupName,
    String? inviteCode,
    DateTime? inviteExpiresAt,
    String role,
    String? groupKey,
    int keyEpoch,
    List<GroupMember> members,
    DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
    int controlRevision,
    DateTime? controlUpdatedAt,
    String controlSnapshotDigest,
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
    Object? groupName = null,
    Object? inviteCode = freezed,
    Object? inviteExpiresAt = freezed,
    Object? role = null,
    Object? groupKey = freezed,
    Object? keyEpoch = null,
    Object? members = null,
    Object? createdAt = null,
    Object? confirmedAt = freezed,
    Object? lastSyncAt = freezed,
    Object? controlRevision = null,
    Object? controlUpdatedAt = freezed,
    Object? controlSnapshotDigest = null,
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
        groupName: null == groupName
            ? _self.groupName
            : groupName // ignore: cast_nullable_to_non_nullable
                  as String,
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
        keyEpoch: null == keyEpoch
            ? _self.keyEpoch
            : keyEpoch // ignore: cast_nullable_to_non_nullable
                  as int,
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
        controlRevision: null == controlRevision
            ? _self.controlRevision
            : controlRevision // ignore: cast_nullable_to_non_nullable
                  as int,
        controlUpdatedAt: freezed == controlUpdatedAt
            ? _self.controlUpdatedAt
            : controlUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        controlSnapshotDigest: null == controlSnapshotDigest
            ? _self.controlSnapshotDigest
            : controlSnapshotDigest // ignore: cast_nullable_to_non_nullable
                  as String,
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
      String groupName,
      String? inviteCode,
      DateTime? inviteExpiresAt,
      String role,
      String? groupKey,
      int keyEpoch,
      List<GroupMember> members,
      DateTime createdAt,
      DateTime? confirmedAt,
      DateTime? lastSyncAt,
      int controlRevision,
      DateTime? controlUpdatedAt,
      String controlSnapshotDigest,
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
          _that.groupName,
          _that.inviteCode,
          _that.inviteExpiresAt,
          _that.role,
          _that.groupKey,
          _that.keyEpoch,
          _that.members,
          _that.createdAt,
          _that.confirmedAt,
          _that.lastSyncAt,
          _that.controlRevision,
          _that.controlUpdatedAt,
          _that.controlSnapshotDigest,
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
      String groupName,
      String? inviteCode,
      DateTime? inviteExpiresAt,
      String role,
      String? groupKey,
      int keyEpoch,
      List<GroupMember> members,
      DateTime createdAt,
      DateTime? confirmedAt,
      DateTime? lastSyncAt,
      int controlRevision,
      DateTime? controlUpdatedAt,
      String controlSnapshotDigest,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupInfo():
        return $default(
          _that.groupId,
          _that.status,
          _that.groupName,
          _that.inviteCode,
          _that.inviteExpiresAt,
          _that.role,
          _that.groupKey,
          _that.keyEpoch,
          _that.members,
          _that.createdAt,
          _that.confirmedAt,
          _that.lastSyncAt,
          _that.controlRevision,
          _that.controlUpdatedAt,
          _that.controlSnapshotDigest,
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
      String groupName,
      String? inviteCode,
      DateTime? inviteExpiresAt,
      String role,
      String? groupKey,
      int keyEpoch,
      List<GroupMember> members,
      DateTime createdAt,
      DateTime? confirmedAt,
      DateTime? lastSyncAt,
      int controlRevision,
      DateTime? controlUpdatedAt,
      String controlSnapshotDigest,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupInfo() when $default != null:
        return $default(
          _that.groupId,
          _that.status,
          _that.groupName,
          _that.inviteCode,
          _that.inviteExpiresAt,
          _that.role,
          _that.groupKey,
          _that.keyEpoch,
          _that.members,
          _that.createdAt,
          _that.confirmedAt,
          _that.lastSyncAt,
          _that.controlRevision,
          _that.controlUpdatedAt,
          _that.controlSnapshotDigest,
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
    required this.groupName,
    this.inviteCode,
    this.inviteExpiresAt,
    required this.role,
    this.groupKey,
    this.keyEpoch = 1,
    required final List<GroupMember> members,
    required this.createdAt,
    this.confirmedAt,
    this.lastSyncAt,
    this.controlRevision = 0,
    this.controlUpdatedAt,
    this.controlSnapshotDigest = '',
  }) : _members = members;
  factory _GroupInfo.fromJson(Map<String, dynamic> json) =>
      _$GroupInfoFromJson(json);

  @override
  final String groupId;
  @override
  final GroupStatus status;
  @override
  final String groupName;
  @override
  final String? inviteCode;
  @override
  final DateTime? inviteExpiresAt;
  @override
  final String role;
  @override
  final String? groupKey;
  @override
  @JsonKey()
  final int keyEpoch;
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
  @override
  @JsonKey()
  final int controlRevision;
  @override
  final DateTime? controlUpdatedAt;
  @override
  @JsonKey()
  final String controlSnapshotDigest;

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
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.inviteExpiresAt, inviteExpiresAt) ||
                other.inviteExpiresAt == inviteExpiresAt) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.groupKey, groupKey) ||
                other.groupKey == groupKey) &&
            (identical(other.keyEpoch, keyEpoch) ||
                other.keyEpoch == keyEpoch) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt) &&
            (identical(other.lastSyncAt, lastSyncAt) ||
                other.lastSyncAt == lastSyncAt) &&
            (identical(other.controlRevision, controlRevision) ||
                other.controlRevision == controlRevision) &&
            (identical(other.controlUpdatedAt, controlUpdatedAt) ||
                other.controlUpdatedAt == controlUpdatedAt) &&
            (identical(other.controlSnapshotDigest, controlSnapshotDigest) ||
                other.controlSnapshotDigest == controlSnapshotDigest));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    groupId,
    status,
    groupName,
    inviteCode,
    inviteExpiresAt,
    role,
    groupKey,
    keyEpoch,
    const DeepCollectionEquality().hash(_members),
    createdAt,
    confirmedAt,
    lastSyncAt,
    controlRevision,
    controlUpdatedAt,
    controlSnapshotDigest,
  );

  @override
  String toString() {
    return 'GroupInfo(groupId: $groupId, status: $status, groupName: $groupName, inviteCode: $inviteCode, inviteExpiresAt: $inviteExpiresAt, role: $role, groupKey: $groupKey, keyEpoch: $keyEpoch, members: $members, createdAt: $createdAt, confirmedAt: $confirmedAt, lastSyncAt: $lastSyncAt, controlRevision: $controlRevision, controlUpdatedAt: $controlUpdatedAt, controlSnapshotDigest: $controlSnapshotDigest)';
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
    String groupName,
    String? inviteCode,
    DateTime? inviteExpiresAt,
    String role,
    String? groupKey,
    int keyEpoch,
    List<GroupMember> members,
    DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
    int controlRevision,
    DateTime? controlUpdatedAt,
    String controlSnapshotDigest,
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
    Object? groupName = null,
    Object? inviteCode = freezed,
    Object? inviteExpiresAt = freezed,
    Object? role = null,
    Object? groupKey = freezed,
    Object? keyEpoch = null,
    Object? members = null,
    Object? createdAt = null,
    Object? confirmedAt = freezed,
    Object? lastSyncAt = freezed,
    Object? controlRevision = null,
    Object? controlUpdatedAt = freezed,
    Object? controlSnapshotDigest = null,
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
        groupName: null == groupName
            ? _self.groupName
            : groupName // ignore: cast_nullable_to_non_nullable
                  as String,
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
        keyEpoch: null == keyEpoch
            ? _self.keyEpoch
            : keyEpoch // ignore: cast_nullable_to_non_nullable
                  as int,
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
        controlRevision: null == controlRevision
            ? _self.controlRevision
            : controlRevision // ignore: cast_nullable_to_non_nullable
                  as int,
        controlUpdatedAt: freezed == controlUpdatedAt
            ? _self.controlUpdatedAt
            : controlUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        controlSnapshotDigest: null == controlSnapshotDigest
            ? _self.controlSnapshotDigest
            : controlSnapshotDigest // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

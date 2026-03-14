// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupInfo _$GroupInfoFromJson(Map<String, dynamic> json) => _GroupInfo(
  groupId: json['groupId'] as String,
  status: $enumDecode(_$GroupStatusEnumMap, json['status']),
  inviteCode: json['inviteCode'] as String?,
  inviteExpiresAt: json['inviteExpiresAt'] == null
      ? null
      : DateTime.parse(json['inviteExpiresAt'] as String),
  role: json['role'] as String,
  groupKey: json['groupKey'] as String?,
  members: (json['members'] as List<dynamic>)
      .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  confirmedAt: json['confirmedAt'] == null
      ? null
      : DateTime.parse(json['confirmedAt'] as String),
  lastSyncAt: json['lastSyncAt'] == null
      ? null
      : DateTime.parse(json['lastSyncAt'] as String),
);

Map<String, dynamic> _$GroupInfoToJson(_GroupInfo instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'status': _$GroupStatusEnumMap[instance.status]!,
      'inviteCode': instance.inviteCode,
      'inviteExpiresAt': instance.inviteExpiresAt?.toIso8601String(),
      'role': instance.role,
      'groupKey': instance.groupKey,
      'members': instance.members.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
      'lastSyncAt': instance.lastSyncAt?.toIso8601String(),
    };

const _$GroupStatusEnumMap = {
  GroupStatus.pending: 'pending',
  GroupStatus.confirming: 'confirming',
  GroupStatus.active: 'active',
  GroupStatus.inactive: 'inactive',
};

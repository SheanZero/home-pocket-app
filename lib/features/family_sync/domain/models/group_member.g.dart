// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupMember _$GroupMemberFromJson(Map<String, dynamic> json) => _GroupMember(
  deviceId: json['deviceId'] as String,
  publicKey: json['publicKey'] as String,
  deviceName: json['deviceName'] as String,
  role: json['role'] as String,
  status: json['status'] as String,
  displayName: json['displayName'] as String,
  avatarEmoji: json['avatarEmoji'] as String,
  avatarImagePath: json['avatarImagePath'] as String?,
  avatarImageHash: json['avatarImageHash'] as String?,
  profileRevision: (json['profileRevision'] as num?)?.toInt() ?? 0,
  profileOriginDeviceId: json['profileOriginDeviceId'] as String? ?? '',
  profileDigest: json['profileDigest'] as String? ?? '',
  avatarRevision: (json['avatarRevision'] as num?)?.toInt() ?? 0,
  avatarOriginDeviceId: json['avatarOriginDeviceId'] as String? ?? '',
  avatarContentHash: json['avatarContentHash'] as String? ?? '',
  joinedAt: json['joinedAt'] == null
      ? null
      : DateTime.parse(json['joinedAt'] as String),
  confirmedAt: json['confirmedAt'] == null
      ? null
      : DateTime.parse(json['confirmedAt'] as String),
  removedAt: json['removedAt'] == null
      ? null
      : DateTime.parse(json['removedAt'] as String),
  removalReason: json['removalReason'] as String?,
);

Map<String, dynamic> _$GroupMemberToJson(_GroupMember instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'publicKey': instance.publicKey,
      'deviceName': instance.deviceName,
      'role': instance.role,
      'status': instance.status,
      'displayName': instance.displayName,
      'avatarEmoji': instance.avatarEmoji,
      'avatarImagePath': instance.avatarImagePath,
      'avatarImageHash': instance.avatarImageHash,
      'profileRevision': instance.profileRevision,
      'profileOriginDeviceId': instance.profileOriginDeviceId,
      'profileDigest': instance.profileDigest,
      'avatarRevision': instance.avatarRevision,
      'avatarOriginDeviceId': instance.avatarOriginDeviceId,
      'avatarContentHash': instance.avatarContentHash,
      'joinedAt': instance.joinedAt?.toIso8601String(),
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
      'removedAt': instance.removedAt?.toIso8601String(),
      'removalReason': instance.removalReason,
    };

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
);

Map<String, dynamic> _$GroupMemberToJson(_GroupMember instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'publicKey': instance.publicKey,
      'deviceName': instance.deviceName,
      'role': instance.role,
      'status': instance.status,
    };

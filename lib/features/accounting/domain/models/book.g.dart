// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Book _$BookFromJson(Map<String, dynamic> json) => _Book(
  id: json['id'] as String,
  name: json['name'] as String,
  currency: json['currency'] as String,
  deviceId: json['deviceId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  isArchived: json['isArchived'] as bool? ?? false,
  isShadow: json['isShadow'] as bool? ?? false,
  groupId: json['groupId'] as String?,
  ownerDeviceId: json['ownerDeviceId'] as String?,
  ownerDeviceName: json['ownerDeviceName'] as String?,
  transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
  survivalBalance: (json['survivalBalance'] as num?)?.toInt() ?? 0,
  soulBalance: (json['soulBalance'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BookToJson(_Book instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'currency': instance.currency,
  'deviceId': instance.deviceId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'isArchived': instance.isArchived,
  'isShadow': instance.isShadow,
  'groupId': instance.groupId,
  'ownerDeviceId': instance.ownerDeviceId,
  'ownerDeviceName': instance.ownerDeviceName,
  'transactionCount': instance.transactionCount,
  'survivalBalance': instance.survivalBalance,
  'soulBalance': instance.soulBalance,
};

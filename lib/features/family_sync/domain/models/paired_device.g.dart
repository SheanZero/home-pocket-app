// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paired_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PairedDevice _$PairedDeviceFromJson(Map<String, dynamic> json) =>
    _PairedDevice(
      pairId: json['pairId'] as String,
      bookId: json['bookId'] as String,
      partnerDeviceId: json['partnerDeviceId'] as String?,
      partnerPublicKey: json['partnerPublicKey'] as String?,
      partnerDeviceName: json['partnerDeviceName'] as String?,
      status: $enumDecode(_$PairStatusEnumMap, json['status']),
      pairCode: json['pairCode'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
      lastSyncAt: json['lastSyncAt'] == null
          ? null
          : DateTime.parse(json['lastSyncAt'] as String),
    );

Map<String, dynamic> _$PairedDeviceToJson(_PairedDevice instance) =>
    <String, dynamic>{
      'pairId': instance.pairId,
      'bookId': instance.bookId,
      'partnerDeviceId': instance.partnerDeviceId,
      'partnerPublicKey': instance.partnerPublicKey,
      'partnerDeviceName': instance.partnerDeviceName,
      'status': _$PairStatusEnumMap[instance.status]!,
      'pairCode': instance.pairCode,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
      'lastSyncAt': instance.lastSyncAt?.toIso8601String(),
    };

const _$PairStatusEnumMap = {
  PairStatus.pending: 'pending',
  PairStatus.confirming: 'confirming',
  PairStatus.active: 'active',
  PairStatus.inactive: 'inactive',
};

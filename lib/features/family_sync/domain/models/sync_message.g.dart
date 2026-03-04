// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncMessage _$SyncMessageFromJson(Map<String, dynamic> json) => _SyncMessage(
  messageId: json['messageId'] as String,
  fromDeviceId: json['fromDeviceId'] as String,
  payload: json['payload'] as String,
  vectorClock: Map<String, int>.from(json['vectorClock'] as Map),
  operationCount: (json['operationCount'] as num).toInt(),
  chunkIndex: (json['chunkIndex'] as num).toInt(),
  totalChunks: (json['totalChunks'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SyncMessageToJson(_SyncMessage instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'fromDeviceId': instance.fromDeviceId,
      'payload': instance.payload,
      'vectorClock': instance.vectorClock,
      'operationCount': instance.operationCount,
      'chunkIndex': instance.chunkIndex,
      'totalChunks': instance.totalChunks,
      'createdAt': instance.createdAt.toIso8601String(),
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BackupData _$BackupDataFromJson(Map<String, dynamic> json) => _BackupData(
  metadata: BackupMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
  transactions: (json['transactions'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  categories: (json['categories'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  books: (json['books'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  settings: json['settings'] as Map<String, dynamic>,
);

Map<String, dynamic> _$BackupDataToJson(_BackupData instance) =>
    <String, dynamic>{
      'metadata': instance.metadata.toJson(),
      'transactions': instance.transactions,
      'categories': instance.categories,
      'books': instance.books,
      'settings': instance.settings,
    };

_BackupMetadata _$BackupMetadataFromJson(Map<String, dynamic> json) =>
    _BackupMetadata(
      version: json['version'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
      deviceId: json['deviceId'] as String,
      appVersion: json['appVersion'] as String,
    );

Map<String, dynamic> _$BackupMetadataToJson(_BackupMetadata instance) =>
    <String, dynamic>{
      'version': instance.version,
      'createdAt': instance.createdAt,
      'deviceId': instance.deviceId,
      'appVersion': instance.appVersion,
    };

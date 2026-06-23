// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MerchantMatchKey _$MerchantMatchKeyFromJson(Map<String, dynamic> json) =>
    _MerchantMatchKey(
      surface: json['surface'] as String,
      matchKey: json['matchKey'] as String,
      kind: json['kind'] as String,
    );

Map<String, dynamic> _$MerchantMatchKeyToJson(_MerchantMatchKey instance) =>
    <String, dynamic>{
      'surface': instance.surface,
      'matchKey': instance.matchKey,
      'kind': instance.kind,
    };

_Merchant _$MerchantFromJson(Map<String, dynamic> json) => _Merchant(
  id: json['id'] as String,
  nameJa: json['nameJa'] as String,
  nameZh: json['nameZh'] as String?,
  nameEn: json['nameEn'] as String?,
  region: json['region'] as String,
  categoryId: json['categoryId'] as String,
  ledgerHint: json['ledgerHint'] as String,
  surfaces:
      (json['surfaces'] as List<dynamic>?)
          ?.map((e) => MerchantMatchKey.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MerchantMatchKey>[],
);

Map<String, dynamic> _$MerchantToJson(_Merchant instance) => <String, dynamic>{
  'id': instance.id,
  'nameJa': instance.nameJa,
  'nameZh': instance.nameZh,
  'nameEn': instance.nameEn,
  'region': instance.region,
  'categoryId': instance.categoryId,
  'ledgerHint': instance.ledgerHint,
  'surfaces': instance.surfaces.map((e) => e.toJson()).toList(),
};

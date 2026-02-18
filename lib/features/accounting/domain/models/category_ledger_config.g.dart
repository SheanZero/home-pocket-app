// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_ledger_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryLedgerConfig _$CategoryLedgerConfigFromJson(
  Map<String, dynamic> json,
) => _CategoryLedgerConfig(
  categoryId: json['categoryId'] as String,
  ledgerType: $enumDecode(_$LedgerTypeEnumMap, json['ledgerType']),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CategoryLedgerConfigToJson(
  _CategoryLedgerConfig instance,
) => <String, dynamic>{
  'categoryId': instance.categoryId,
  'ledgerType': _$LedgerTypeEnumMap[instance.ledgerType]!,
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$LedgerTypeEnumMap = {
  LedgerType.survival: 'survival',
  LedgerType.soul: 'soul',
};

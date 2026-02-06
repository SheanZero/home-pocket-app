// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Category _$CategoryFromJson(Map<String, dynamic> json) => _Category(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  color: json['color'] as String,
  parentId: json['parentId'] as String?,
  level: (json['level'] as num).toInt(),
  type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
  isSystem: json['isSystem'] as bool? ?? false,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'icon': instance.icon,
  'color': instance.color,
  'parentId': instance.parentId,
  'level': instance.level,
  'type': _$TransactionTypeEnumMap[instance.type]!,
  'isSystem': instance.isSystem,
  'sortOrder': instance.sortOrder,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$TransactionTypeEnumMap = {
  TransactionType.expense: 'expense',
  TransactionType.income: 'income',
  TransactionType.transfer: 'transfer',
};

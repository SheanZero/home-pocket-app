// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transaction _$TransactionFromJson(Map<String, dynamic> json) => _Transaction(
  id: json['id'] as String,
  bookId: json['bookId'] as String,
  deviceId: json['deviceId'] as String,
  amount: (json['amount'] as num).toInt(),
  type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
  categoryId: json['categoryId'] as String,
  ledgerType: $enumDecode(_$LedgerTypeEnumMap, json['ledgerType']),
  timestamp: DateTime.parse(json['timestamp'] as String),
  note: json['note'] as String?,
  photoHash: json['photoHash'] as String?,
  merchant: json['merchant'] as String?,
  prevHash: json['prevHash'] as String?,
  currentHash: json['currentHash'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  isPrivate: json['isPrivate'] as bool? ?? false,
  isSynced: json['isSynced'] as bool? ?? false,
  isDeleted: json['isDeleted'] as bool? ?? false,
  soulSatisfaction: (json['soulSatisfaction'] as num?)?.toInt() ?? 5,
);

Map<String, dynamic> _$TransactionToJson(_Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookId': instance.bookId,
      'deviceId': instance.deviceId,
      'amount': instance.amount,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'categoryId': instance.categoryId,
      'ledgerType': _$LedgerTypeEnumMap[instance.ledgerType]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'note': instance.note,
      'photoHash': instance.photoHash,
      'merchant': instance.merchant,
      'prevHash': instance.prevHash,
      'currentHash': instance.currentHash,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isPrivate': instance.isPrivate,
      'isSynced': instance.isSynced,
      'isDeleted': instance.isDeleted,
      'soulSatisfaction': instance.soulSatisfaction,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.expense: 'expense',
  TransactionType.income: 'income',
  TransactionType.transfer: 'transfer',
};

const _$LedgerTypeEnumMap = {
  LedgerType.survival: 'survival',
  LedgerType.soul: 'soul',
};

import '../../../accounting/domain/models/transaction.dart';
import 'shopping_item.dart';
import 'shopping_unit.dart';

/// Lossless serialization used only inside encrypted local backup archives.
///
/// Unlike the family-sync mapper, this includes device-local ordering and
/// completion state so a restore reproduces the shopping list exactly.
class ShoppingItemBackupPolicy {
  ShoppingItemBackupPolicy._();

  static Map<String, dynamic> toBackupJson(ShoppingItem item) => {
    'id': item.id,
    'deviceId': item.deviceId,
    'listType': item.listType,
    'name': item.name,
    'ledgerType': item.ledgerType?.name,
    'categoryId': item.categoryId,
    'tags': item.tags,
    'note': item.note,
    'quantity': item.quantity,
    'unitId': item.unit.name,
    'customUnit': item.customUnit,
    'estimatedPrice': item.estimatedPrice,
    'completedAt': item.completedAt?.toUtc().toIso8601String(),
    'isCompleted': item.isCompleted,
    'sortOrder': item.sortOrder,
    'isSynced': item.isSynced,
    'isDeleted': item.isDeleted,
    'addedByBookId': item.addedByBookId,
    'createdAt': item.createdAt.toUtc().toIso8601String(),
    'updatedAt': item.updatedAt?.toUtc().toIso8601String(),
    'syncRevision': item.syncRevision,
    'syncOriginDeviceId': item.syncOriginDeviceId,
  };

  static ShoppingItem fromBackupJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags.map((value) => value.toString()).toList(growable: false)
        : const <String>[];
    return ShoppingItem(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String? ?? '',
      listType: json['listType'] as String? ?? 'private',
      name: json['name'] as String,
      ledgerType: _ledgerType(json['ledgerType'] as String?),
      categoryId: json['categoryId'] as String?,
      tags: tags,
      note: json['note'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: ShoppingUnit.fromId(json['unitId'] as String?),
      customUnit: json['customUnit'] as String?,
      estimatedPrice: (json['estimatedPrice'] as num?)?.toInt(),
      completedAt: _dateTime(json['completedAt']),
      isCompleted: json['isCompleted'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      addedByBookId: json['addedByBookId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: _dateTime(json['updatedAt']),
      syncRevision: (json['syncRevision'] as num?)?.toInt() ?? 0,
      syncOriginDeviceId: json['syncOriginDeviceId'] as String? ?? '',
    );
  }

  static DateTime? _dateTime(Object? raw) =>
      raw is String && raw.isNotEmpty ? DateTime.parse(raw) : null;

  static LedgerType? _ledgerType(String? raw) {
    for (final type in LedgerType.values) {
      if (type.name == raw) return type;
    }
    return null;
  }
}

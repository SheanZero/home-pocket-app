import 'dart:convert';

import '../../../accounting/domain/models/transaction.dart';
import 'shopping_item.dart';

/// Maps [ShoppingItem] to and from the sync protocol payload.
///
/// All methods are static — no constructor, no state (mirrors TransactionSyncMapper).
/// [kShoppingItemEntityType] is defined in shopping_item.dart (same domain layer);
/// it is NOT redefined here.
class ShoppingItemSyncMapper {
  ShoppingItemSyncMapper._();

  /// Serialize [item] to a wire-format map.
  ///
  /// Excludes fields that are local-per-device or internal to the sync pipeline:
  /// - sortOrder: EXCLUDED — D37-01: sortOrder is local-per-device, NOT synced
  /// - isDeleted: EXCLUDED — tombstone communicated by 'delete' op itself
  /// - isSynced: EXCLUDED — internal pipeline flag
  static Map<String, dynamic> toSyncMap(ShoppingItem item) {
    return {
      'id': item.id,
      'listType': item.listType,
      'name': item.name,
      'ledgerType': item.ledgerType?.name, // nullable enum → string ('daily'/'joy'/null)
      'categoryId': item.categoryId,
      'tags': jsonEncode(item.tags), // JSON string; empty list → '[]'
      // WR-06: note is emitted as PLAINTEXT on the sync wire. The field-level
      // ChaCha20 encryption in ShoppingItemRepositoryImpl._encryptNote applies
      // only on the LOCAL DB write path; this sync push path serializes the
      // domain model directly and never passes through the repository. Wire
      // confidentiality of note therefore depends entirely on the transport-layer
      // E2EE wrapping the whole payload — NOT on field encryption.
      'note': item.note,
      'quantity': item.quantity,
      'estimatedPrice': item.estimatedPrice,
      'isCompleted': item.isCompleted,
      'completedAt': item.completedAt?.toUtc().toIso8601String(),
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'updatedAt': item.updatedAt?.toUtc().toIso8601String(),
      'deviceId': item.deviceId,
      'addedByBookId': item.addedByBookId,
      // D37-01: sortOrder is local-per-device, NOT synced — intentionally absent
    };
  }

  /// Build a create operation envelope for the sync protocol.
  static Map<String, dynamic> toCreateOperation(ShoppingItem item) {
    return {
      'op': 'create',
      'entityType': kShoppingItemEntityType,
      'entityId': item.id,
      'data': toSyncMap(item),
      'timestamp': item.createdAt.toUtc().toIso8601String(),
    };
  }

  /// Build an update operation envelope for the sync protocol.
  ///
  /// Uses [item.updatedAt] when available, falling back to [item.createdAt].
  static Map<String, dynamic> toUpdateOperation(ShoppingItem item) {
    return {
      'op': 'update',
      'entityType': kShoppingItemEntityType,
      'entityId': item.id,
      'data': toSyncMap(item),
      'timestamp': (item.updatedAt ?? item.createdAt).toUtc().toIso8601String(),
    };
  }

  /// Reconstruct a [ShoppingItem] from a sync wire map.
  ///
  /// Sets [isSynced] to `true` — indicates the item came from the sync pipeline.
  /// [fromDeviceId], when provided, overrides the map's 'deviceId' value.
  static ShoppingItem fromSyncMap(
    Map<String, dynamic> data, {
    String? fromDeviceId,
  }) {
    // WR-05: coerce tags field-by-field. A malformed tags payload (non-JSON
    // string, or JSON that is not a list) must NOT throw and discard the entire
    // record — keep the rest of the item and fall back to an empty tag list.
    List<String> tags = const [];
    final rawTags = data['tags'];
    if (rawTags is String && rawTags.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTags);
        if (decoded is List) {
          tags = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        tags = const []; // corrupt tag payload — keep the rest of the item
      }
    }

    return ShoppingItem(
      id: data['id'] as String,
      deviceId: fromDeviceId ?? data['deviceId'] as String? ?? '',
      listType: data['listType'] as String? ?? 'public',
      name: data['name'] as String? ?? '',
      ledgerType: _parseLedgerType(data['ledgerType'] as String?),
      categoryId: data['categoryId'] as String?,
      tags: tags,
      note: data['note'] as String?,
      quantity: (data['quantity'] as int?) ?? 1,
      estimatedPrice: data['estimatedPrice'] as int?,
      isCompleted: (data['isCompleted'] as bool?) ?? false,
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'] as String)
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
      addedByBookId: data['addedByBookId'] as String?,
      isSynced: true, // always true when coming from sync pipeline
    );
  }

  /// Parse a [LedgerType] from a wire string value.
  ///
  /// Returns `null` for absent or unrecognized values.
  static LedgerType? _parseLedgerType(String? raw) {
    switch (raw) {
      case 'daily':
        return LedgerType.daily;
      case 'joy':
        return LedgerType.joy;
      default:
        return null;
    }
  }
}

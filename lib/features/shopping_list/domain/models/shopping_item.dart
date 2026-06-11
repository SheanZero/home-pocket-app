import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../accounting/domain/models/transaction.dart';

part 'shopping_item.freezed.dart';

/// Entity type constant for shopping items in the sync protocol.
///
/// Defined exactly ONCE here (domain — the inner layer everyone may depend on);
/// import this everywhere, never inline the string literal. This prevents typo
/// mismatches ('shopping-item' vs 'shopping_item').
const kShoppingItemEntityType = 'shopping_item';

/// Immutable domain model representing a single shopping list item.
///
/// Fields mirror the v20 `shopping_items` Drift table column order.
/// No Drift or Flutter imports — this is a pure domain type.
@freezed
abstract class ShoppingItem with _$ShoppingItem {
  const ShoppingItem._();

  const factory ShoppingItem({
    required String id,
    required String deviceId,
    required String listType, // 'public' | 'private'
    required String name,
    LedgerType? ledgerType,
    String? categoryId,
    @Default(<String>[]) List<String> tags, // D-01: JSON-encoded at repo boundary
    String? note, // decrypted plaintext
    @Default(1) int quantity, // D-02
    int? estimatedPrice, // ITEM-05
    DateTime? completedAt, // D-03
    @Default(false) bool isCompleted,
    @Default(0) int sortOrder,
    @Default(false) bool isSynced,
    @Default(false) bool isDeleted,
    String? addedByBookId,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _ShoppingItem;
}

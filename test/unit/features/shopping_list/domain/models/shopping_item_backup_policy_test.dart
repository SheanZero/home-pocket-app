import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item_backup_policy.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_unit.dart';

void main() {
  test('round-trips every persisted shopping item field', () {
    final createdAt = DateTime.utc(2026, 8, 10, 9, 30);
    final updatedAt = DateTime.utc(2026, 8, 11, 10, 45);
    final completedAt = DateTime.utc(2026, 8, 11, 10, 40);
    final item = ShoppingItem(
      id: 'item-1',
      deviceId: 'device-1',
      listType: 'public',
      name: 'Coffee beans',
      ledgerType: LedgerType.joy,
      categoryId: 'category-1',
      tags: const ['drink', 'weekly'],
      note: 'Medium roast',
      quantity: 2.5,
      unit: ShoppingUnit.custom,
      customUnit: '袋',
      estimatedPrice: 2480,
      completedAt: completedAt,
      isCompleted: true,
      sortOrder: 7,
      isSynced: true,
      isDeleted: false,
      addedByBookId: 'book-1',
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncRevision: 42,
      syncOriginDeviceId: 'origin-1',
    );

    final restored = ShoppingItemBackupPolicy.fromBackupJson(
      ShoppingItemBackupPolicy.toBackupJson(item),
    );

    expect(restored, item);
  });
}

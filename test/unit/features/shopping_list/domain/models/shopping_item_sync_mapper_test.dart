import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item_sync_mapper.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_unit.dart';

void main() {
  test('sync payload round-trips decimal quantity and unit', () {
    final item = ShoppingItem(
      id: 'sugar',
      deviceId: 'device-1',
      listType: 'public',
      name: 'Sugar',
      quantity: 200.5,
      unit: ShoppingUnit.gram,
      createdAt: DateTime.utc(2026, 8, 4),
    );

    final payload = ShoppingItemSyncMapper.toSyncMap(item);
    final decoded = ShoppingItemSyncMapper.fromSyncMap(payload);

    expect(payload['quantity'], 200.5);
    expect(payload['unitId'], 'gram');
    expect(decoded.quantity, 200.5);
    expect(decoded.unit, ShoppingUnit.gram);
  });

  test('custom unit is included in the encrypted shopping payload', () {
    final item = ShoppingItem(
      id: 'coffee',
      deviceId: 'device-1',
      listType: 'public',
      name: 'Coffee',
      quantity: 2,
      unit: ShoppingUnit.custom,
      customUnit: 'scoop',
      createdAt: DateTime.utc(2026, 8, 4),
    );

    final decoded = ShoppingItemSyncMapper.fromSyncMap(
      ShoppingItemSyncMapper.toSyncMap(item),
    );

    expect(decoded.unit, ShoppingUnit.custom);
    expect(decoded.customUnit, 'scoop');
  });
}

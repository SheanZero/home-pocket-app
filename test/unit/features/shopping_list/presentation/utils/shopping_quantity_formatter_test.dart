import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_unit.dart';
import 'package:home_pocket/features/shopping_list/presentation/utils/shopping_quantity_formatter.dart';
import 'package:home_pocket/generated/app_localizations.dart';

ShoppingItem _item({
  required double quantity,
  required ShoppingUnit unit,
  String? customUnit,
}) => ShoppingItem(
  id: 'item',
  deviceId: 'device',
  listType: 'private',
  name: 'Item',
  quantity: quantity,
  unit: unit,
  customUnit: customUnit,
  createdAt: DateTime(2026, 8, 4),
);

void main() {
  test('formats metric and count units naturally in Chinese', () async {
    const locale = Locale('zh');
    final l = await S.delegate.load(locale);

    expect(
      formatShoppingQuantity(
        _item(quantity: 200, unit: ShoppingUnit.gram),
        l,
        locale,
      ),
      '200 g',
    );
    expect(
      formatShoppingQuantity(
        _item(quantity: 2, unit: ShoppingUnit.bottle),
        l,
        locale,
      ),
      '2瓶',
    );
  });

  test('trims redundant decimal zeros', () async {
    const locale = Locale('en');
    final l = await S.delegate.load(locale);

    expect(
      formatShoppingQuantity(
        _item(quantity: 1.5, unit: ShoppingUnit.kilogram),
        l,
        locale,
      ),
      '1.5 kg',
    );
  });
}

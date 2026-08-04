import 'package:flutter/widgets.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/shopping_item.dart';
import '../../domain/models/shopping_unit.dart';

String formatShoppingQuantityValue(double value) {
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String shoppingUnitLabel(S l, ShoppingUnitSelection selection) =>
    switch (selection.unit) {
      ShoppingUnit.piece => l.shoppingUnitPiece,
      ShoppingUnit.gram => l.shoppingUnitGram,
      ShoppingUnit.kilogram => l.shoppingUnitKilogram,
      ShoppingUnit.milliliter => l.shoppingUnitMilliliter,
      ShoppingUnit.liter => l.shoppingUnitLiter,
      ShoppingUnit.bag => l.shoppingUnitBag,
      ShoppingUnit.bottle => l.shoppingUnitBottle,
      ShoppingUnit.pack => l.shoppingUnitPack,
      ShoppingUnit.custom => selection.normalizedCustomLabel,
    };

String formatShoppingQuantity(ShoppingItem item, S l, Locale locale) {
  final amount = formatShoppingQuantityValue(item.quantity);
  final selection = ShoppingUnitSelection(
    item.unit,
    customLabel: item.customUnit,
  );
  final unit = shoppingUnitLabel(l, selection);
  final language = locale.languageCode;
  final isCjk = language == 'ja' || language == 'zh';
  final isCountLike = switch (selection.unit) {
    ShoppingUnit.piece ||
    ShoppingUnit.bag ||
    ShoppingUnit.bottle ||
    ShoppingUnit.pack ||
    ShoppingUnit.custom => true,
    _ => false,
  };
  return isCjk && isCountLike ? '$amount$unit' : '$amount $unit';
}

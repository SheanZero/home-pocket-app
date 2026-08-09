import '../../features/shopping_list/domain/models/shopping_unit.dart';
import '../../features/shopping_list/domain/repositories/shopping_unit_usage_repository.dart';
import '../daos/shopping_unit_usage_dao.dart';

class ShoppingUnitUsageRepositoryImpl implements ShoppingUnitUsageRepository {
  ShoppingUnitUsageRepositoryImpl({required this._dao});

  final ShoppingUnitUsageDao _dao;

  @override
  Future<void> record(ShoppingUnitSelection selection, DateTime usedAt) {
    if (!selection.isValid) {
      throw ArgumentError.value(selection.customLabel, 'customLabel');
    }
    return _dao.record(
      usageKey: selection.usageKey,
      unitId: selection.unit.name,
      customUnit: selection.unit == ShoppingUnit.custom
          ? selection.normalizedCustomLabel
          : null,
      usedAt: usedAt,
    );
  }

  @override
  Stream<List<ShoppingUnitUsage>> watchAll() => _dao.watchAll().map(
    (rows) => rows
        .map(
          (row) => ShoppingUnitUsage(
            selection: ShoppingUnitSelection(
              ShoppingUnit.fromId(row.unitId),
              customLabel: row.customUnit,
            ),
            useCount: row.useCount,
            lastUsedAt: row.lastUsedAt,
          ),
        )
        .toList(growable: false),
  );
}

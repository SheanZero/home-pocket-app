import '../models/shopping_unit.dart';

/// Local learned-preference boundary for shopping units.
abstract class ShoppingUnitUsageRepository {
  Future<void> record(ShoppingUnitSelection selection, DateTime usedAt);

  Stream<List<ShoppingUnitUsage>> watchAll();
}

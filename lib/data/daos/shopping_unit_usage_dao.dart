import 'package:drift/drift.dart';

import '../app_database.dart';

class ShoppingUnitUsageDao {
  ShoppingUnitUsageDao(this._db);

  final AppDatabase _db;

  Future<void> record({
    required String usageKey,
    required String unitId,
    required String? customUnit,
    required DateTime usedAt,
  }) async {
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.shoppingUnitUsages,
      )..where((row) => row.usageKey.equals(usageKey))).getSingleOrNull();
      if (existing == null) {
        await _db
            .into(_db.shoppingUnitUsages)
            .insert(
              ShoppingUnitUsagesCompanion.insert(
                usageKey: usageKey,
                unitId: unitId,
                customUnit: Value(customUnit),
                lastUsedAt: usedAt,
              ),
            );
        return;
      }
      await (_db.update(
        _db.shoppingUnitUsages,
      )..where((row) => row.usageKey.equals(usageKey))).write(
        ShoppingUnitUsagesCompanion(
          customUnit: Value(customUnit),
          useCount: Value(existing.useCount + 1),
          lastUsedAt: Value(usedAt),
        ),
      );
    });
  }

  Stream<List<ShoppingUnitUsageRow>> watchAll() =>
      (_db.select(_db.shoppingUnitUsages)..orderBy([
            (row) => OrderingTerm.desc(row.useCount),
            (row) => OrderingTerm.desc(row.lastUsedAt),
            (row) => OrderingTerm.asc(row.usageKey),
          ]))
          .watch();
}

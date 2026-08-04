import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/shopping_unit_usage_dao.dart';
import 'package:home_pocket/data/repositories/shopping_unit_usage_repository_impl.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_unit.dart';

void main() {
  late AppDatabase database;
  late ShoppingUnitUsageRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting();
    repository = ShoppingUnitUsageRepositoryImpl(
      dao: ShoppingUnitUsageDao(database),
    );
  });

  tearDown(() => database.close());

  test('record aggregates count and retains the latest timestamp', () async {
    const piece = ShoppingUnitSelection.piece();
    await repository.record(piece, DateTime(2026, 8, 1));
    await repository.record(piece, DateTime(2026, 8, 2));

    final usages = await repository.watchAll().first;
    expect(usages, hasLength(1));
    expect(usages.single.selection, piece);
    expect(usages.single.useCount, 2);
    expect(usages.single.lastUsedAt, DateTime(2026, 8, 2));
  });

  test('custom units are distinct and preserve their visible label', () async {
    const cup = ShoppingUnitSelection(ShoppingUnit.custom, customLabel: '杯');
    await repository.record(cup, DateTime(2026, 8, 1));

    final usage = (await repository.watchAll().first).single;
    expect(usage.selection.unit, ShoppingUnit.custom);
    expect(usage.selection.customLabel, '杯');
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/watch_shopping_unit_suggestions_use_case.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_unit.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_unit_usage_repository.dart';

class _FakeUsageRepository implements ShoppingUnitUsageRepository {
  final controller = StreamController<List<ShoppingUnitUsage>>();

  @override
  Future<void> record(ShoppingUnitSelection selection, DateTime usedAt) async {}

  @override
  Stream<List<ShoppingUnitUsage>> watchAll() => controller.stream;
}

ShoppingUnitUsage _usage(
  ShoppingUnit unit,
  int count, {
  int day = 1,
  String? customLabel,
}) => ShoppingUnitUsage(
  selection: ShoppingUnitSelection(unit, customLabel: customLabel),
  useCount: count,
  lastUsedAt: DateTime(2026, 8, day),
);

void main() {
  late _FakeUsageRepository repository;
  late WatchShoppingUnitSuggestionsUseCase useCase;

  setUp(() {
    repository = _FakeUsageRepository();
    useCase = WatchShoppingUnitSuggestionsUseCase(repository: repository);
  });

  tearDown(() => repository.controller.close());

  test('ten saved inputs keep suggestions hidden', () async {
    final result = useCase.watch().first;
    repository.controller.add([
      _usage(ShoppingUnit.piece, 8),
      _usage(ShoppingUnit.bag, 2),
    ]);

    expect(await result, isEmpty);
  });

  test('eleven inputs with only piece keep suggestions hidden', () async {
    final result = useCase.watch().first;
    repository.controller.add([_usage(ShoppingUnit.piece, 11)]);

    expect(await result, isEmpty);
  });

  test('eleven inputs with one non-default unit expose that unit', () async {
    final result = useCase.watch().first;
    repository.controller.add([_usage(ShoppingUnit.gram, 11)]);

    final suggestions = await result;
    expect(suggestions, hasLength(1));
    expect(suggestions.single.selection.unit, ShoppingUnit.gram);
  });

  test('the eleventh input exposes at most three most-used units', () async {
    final result = useCase.watch().first;
    repository.controller.add([
      _usage(ShoppingUnit.gram, 2, day: 4),
      _usage(ShoppingUnit.piece, 5, day: 1),
      _usage(ShoppingUnit.bag, 3, day: 2),
      _usage(ShoppingUnit.pack, 1, day: 3),
    ]);

    final suggestions = await result;
    expect(suggestions, hasLength(3));
    expect(suggestions.map((value) => value.selection.unit), [
      ShoppingUnit.piece,
      ShoppingUnit.bag,
      ShoppingUnit.gram,
    ]);
  });
}

// ignore_for_file: unused_import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/clear_completed_items_use_case.dart';
import 'package:home_pocket/application/shopping_list/create_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/delete_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/reorder_shopping_items_use_case.dart';
import 'package:home_pocket/application/shopping_list/toggle_item_completed_use_case.dart';
import 'package:home_pocket/application/shopping_list/update_shopping_item_use_case.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

// TODO(Wave-1): Uncomment once state_shopping_filter.dart lands in Phase 38 Wave 1.
// import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_filter.dart';

// TODO(Wave-1): Uncomment once state_shopping_batch.dart lands in Phase 38 Wave 1.
// import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_batch.dart';

// TODO(Wave-1): Uncomment provider overrides once use-case providers land in Phase 38 Wave 1.
// import 'package:home_pocket/features/shopping_list/presentation/providers/use_case_providers.dart';

/// Mocktail stubs for all 6 shopping list use cases.
class MockCreateShoppingItemUseCase extends Mock
    implements CreateShoppingItemUseCase {}

class MockUpdateShoppingItemUseCase extends Mock
    implements UpdateShoppingItemUseCase {}

class MockDeleteShoppingItemUseCase extends Mock
    implements DeleteShoppingItemUseCase {}

class MockToggleItemCompletedUseCase extends Mock
    implements ToggleItemCompletedUseCase {}

class MockReorderShoppingItemsUseCase extends Mock
    implements ReorderShoppingItemsUseCase {}

class MockClearCompletedItemsUseCase extends Mock
    implements ClearCompletedItemsUseCase {}

/// Mocktail stub for ShoppingItemRepository.
class MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

/// Returns a [List<Override>] for the ShoppingItemRepository provider.
///
/// Wave 1 will extend this with per-use-case provider overrides once
/// the use-case providers land (see TODO comments above).
List<Override> shoppingRepositoryOverride(MockShoppingItemRepository mock) {
  return [
    shoppingItemRepositoryProvider.overrideWithValue(mock),
  ];
}

// TODO(Wave-1): Replace with full shoppingTestOverrides(...) helper that accepts
// all 6 mock use cases and wires them to their provider overrides.
// Signature will be:
//   List<Override> shoppingTestOverrides({
//     required MockCreateShoppingItemUseCase createUseCase,
//     required MockUpdateShoppingItemUseCase updateUseCase,
//     required MockDeleteShoppingItemUseCase deleteUseCase,
//     required MockToggleItemCompletedUseCase toggleUseCase,
//     required MockReorderShoppingItemsUseCase reorderUseCase,
//     required MockClearCompletedItemsUseCase clearUseCase,
//   }) { ... }

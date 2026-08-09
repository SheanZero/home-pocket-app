import '../../features/shopping_list/domain/models/shopping_unit.dart';
import '../../features/shopping_list/domain/repositories/shopping_unit_usage_repository.dart';

/// Learns compact unit shortcuts from successful local item creation.
///
/// The shortcuts remain hidden until the user has created more than ten items.
/// A history containing only the default `piece` unit also remains hidden,
/// because repeating the already-selected default would not reduce effort.
class WatchShoppingUnitSuggestionsUseCase {
  const WatchShoppingUnitSuggestionsUseCase({
    required this._repository,
  });

  final ShoppingUnitUsageRepository _repository;

  Stream<List<ShoppingUnitSuggestion>> watch() =>
      _repository.watchAll().map((usages) {
        final totalUses = usages.fold<int>(
          0,
          (total, usage) => total + usage.useCount,
        );
        final onlyUsesDefaultPiece =
            usages.length == 1 &&
            usages.single.selection.unit == ShoppingUnit.piece;
        if (totalUses <= 10 || onlyUsesDefaultPiece) {
          return const <ShoppingUnitSuggestion>[];
        }
        final ranked = [...usages]
          ..sort((left, right) {
            final countOrder = right.useCount.compareTo(left.useCount);
            if (countOrder != 0) return countOrder;
            final timeOrder = right.lastUsedAt.compareTo(left.lastUsedAt);
            if (timeOrder != 0) return timeOrder;
            return left.selection.usageKey.compareTo(right.selection.usageKey);
          });
        return ranked
            .take(3)
            .map(
              (usage) => ShoppingUnitSuggestion(
                selection: usage.selection,
                useCount: usage.useCount,
              ),
            )
            .toList(growable: false);
      });
}

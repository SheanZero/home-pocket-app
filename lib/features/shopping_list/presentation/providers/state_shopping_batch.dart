import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'state_shopping_batch.freezed.dart';
part 'state_shopping_batch.g.dart';

/// Immutable state for batch-selection mode on the shopping list.
///
/// - [isActive]: whether batch-selection mode is currently active.
/// - [selectedIds]: the set of item IDs currently selected.
@freezed
abstract class BatchSelectModeState with _$BatchSelectModeState {
  const factory BatchSelectModeState({
    @Default(false) bool isActive,
    @Default(<String>{}) Set<String> selectedIds,
  }) = _BatchSelectModeState;

  /// Creates the initial inactive state (no selection).
  factory BatchSelectModeState.inactive() =>
      const BatchSelectModeState(isActive: false, selectedIds: {});
}

/// Manages batch-selection mode for the shopping list.
///
/// NOT keepAlive (transient, D38-03) — resets when the provider is no longer
/// watched. MUST remain at app-root scope so [MainShellScreen] can read it
/// to hide the nav bar during batch mode (Pitfall 3 — never override in a
/// local ProviderScope).
///
/// Riverpod 3 suffix-stripping: `class BatchSelectMode` → `batchSelectModeProvider`.
@riverpod
class BatchSelectMode extends _$BatchSelectMode {
  @override
  BatchSelectModeState build() => BatchSelectModeState.inactive();

  /// Enters batch-selection mode with an empty selection.
  void enter() {
    state = BatchSelectModeState(isActive: true, selectedIds: {});
  }

  /// Toggles a single item ID in/out of the selection set.
  void toggle(String id) {
    final current = Set<String>.from(state.selectedIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(selectedIds: current);
  }

  /// Selects all provided item IDs at once.
  void selectAll(Iterable<String> ids) {
    state = state.copyWith(selectedIds: Set<String>.from(ids));
  }

  /// Exits batch-selection mode and resets to inactive.
  void exit() {
    state = BatchSelectModeState.inactive();
  }
}

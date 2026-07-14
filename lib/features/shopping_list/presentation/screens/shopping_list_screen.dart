import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../providers/repository_providers.dart';
import '../providers/state_shopping_batch.dart';
import '../providers/state_shopping_filter.dart';
import '../providers/state_shopping_reorder.dart';
import '../widgets/shopping_batch_action_bar.dart';
import '../widgets/shopping_empty_state.dart';
import '../widgets/shopping_filter_bar.dart';
import '../widgets/shopping_item_tile.dart';
import '../widgets/shopping_selection_header.dart';

/// Main shopping list shell screen — v15 warm-Japanese port (D-02, ADR-019).
///
/// Structure (top → bottom), mirroring the mockup `shopping()`:
/// 1. ShoppingFilterBar — the v15 filter card (scope + ledger segments +
///    私有/カテゴリ chips). Scope segment shows only in group mode.
/// 2. ShoppingSelectionHeader — visible only in batch mode (D38-03).
/// 3. Body: 買うもの section header (with 並べ替え reorder toggle) → active
///    items list-card → 完了 section header → completed items list-card.
/// 4. ShoppingBatchActionBar — visible only in batch mode (D38-03).
///
/// NEVER call ref.invalidate(filteredShoppingItemsProvider) for sync-driven
/// updates — the Drift .watch() stream handles reactivity (GAP-2 lesson).
/// ref.invalidate is ONLY used in the error state's retry button.
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final listType = ref.watch(listTypeProvider);
    final batchActive = ref.watch(batchSelectModeProvider).isActive;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(S.of(context).shoppingListScreenTitle),
      ),
      // SafeArea(top) keeps the filter card clear of the status bar / Dynamic
      // Island; bottom is owned by the floating nav bar.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // v15 filter card — scope + ledger segments + 私有/カテゴリ chips.
            const ShoppingFilterBar(),
            // Batch chrome — selection header (D38-03, MGMT-02)
            if (batchActive) _BatchHeaderWrapper(),
            // Main body
            Expanded(child: _buildBody(context, ref, palette, listType)),
            // Batch chrome — bottom action bar (D38-03, MGMT-02)
            if (batchActive) const ShoppingBatchActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
    String listType,
  ) {
    final l10n = S.of(context);
    final itemsAsync = ref.watch(filteredShoppingItemsProvider);
    // Hide the completed section while reordering (quick-260609-pmc-07).
    final reorderMode = ref.watch(shoppingReorderModeProvider);

    return itemsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: palette.accentPrimary,
          strokeWidth: 2,
        ),
      ),
      error: (err, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: palette.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.shoppingListLoadError,
              style: AppTextStyles.caption.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            // ref.invalidate is appropriate here — user-triggered retry.
            TextButton(
              onPressed: () => ref.invalidate(filteredShoppingItemsProvider),
              child: Text(l10n.shoppingRetry),
            ),
          ],
        ),
      ),
      data: (items) {
        final activeItems = items.where((i) => !i.isCompleted).toList();
        final completedItems = items.where((i) => i.isCompleted).toList();

        if (activeItems.isEmpty && completedItems.isEmpty) {
          return ShoppingEmptyState(listType: listType);
        }

        return CustomScrollView(
          slivers: [
            // 買うもの section header + 並べ替え reorder toggle.
            SliverToBoxAdapter(child: _ToBuySectionHeader()),
            // Active items — single list-card with SliverReorderableList (D38-02).
            if (activeItems.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: DecoratedSliver(
                  decoration: _cardDecoration(palette),
                  sliver: SliverReorderableList(
                    itemCount: activeItems.length,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (ctx, _) {
                          final double elevation = Tween<double>(begin: 0, end: 6)
                              .animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ))
                              .value;
                          return Material(
                            elevation: elevation,
                            color: ctx.palette.card,
                            borderRadius: BorderRadius.circular(14),
                            child: child,
                          );
                        },
                      );
                    },
                    onReorderItem: (oldIndex, newIndex) {
                      final orderedIds =
                          activeItems.map((e) => e.id).toList(growable: true);
                      final moved = orderedIds.removeAt(oldIndex);
                      orderedIds.insert(newIndex, moved);
                      ref
                          .read(reorderShoppingItemsUseCaseProvider)
                          .applyOrder(orderedIds);
                    },
                    itemBuilder: (context, index) =>
                        ReorderableDelayedDragStartListener(
                      key: ValueKey(activeItems[index].id),
                      index: index,
                      child: _DividedRow(
                        showDivider: index > 0,
                        child: ShoppingItemTile(
                          item: activeItems[index],
                          index: index,
                          isActive: true,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              // Filtered-empty: no pending items but completed items exist
              // (a filter hid every pending row). Inline muted card under the
              // 買うもの header — NOT the big 3-variant empty state.
              const SliverToBoxAdapter(child: _FilteredEmptyPlaceholder()),
            // Completed section — hidden during reorder mode (pmc-07).
            if (completedItems.isNotEmpty && !reorderMode) ...[
              SliverToBoxAdapter(
                child: _CompletedSectionHeader(
                  listType: listType,
                  completedCount: completedItems.length,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: DecoratedSliver(
                  decoration: _cardDecoration(palette),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _DividedRow(
                        key: ValueKey(completedItems[i].id),
                        showDivider: i > 0,
                        child: ShoppingItemTile(
                          item: completedItems[i],
                          index: i,
                          isActive: false,
                        ),
                      ),
                      childCount: completedItems.length,
                    ),
                  ),
                ),
              ),
            ],
            // Bottom padding so last item clears the FAB.
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  BoxDecoration _cardDecoration(AppPalette palette) => BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderDefault, width: 1),
      );
}

/// A list-card row that draws a top divider between rows (mockup
/// `.shopping-list-card .shopping-item + .shopping-item`). Transparent so the
/// parent card fill / rounded corners show through.
class _DividedRow extends StatelessWidget {
  const _DividedRow({super.key, required this.child, required this.showDivider});

  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(top: BorderSide(color: palette.borderList, width: 1))
            : null,
      ),
      child: child,
    );
  }
}

/// 買うもの section header with the 並べ替え / 完了 reorder toggle
/// (mockup `<div class="section-title"><h2>買うもの</h2>…`).
class _ToBuySectionHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = S.of(context);
    final reorderMode = ref.watch(shoppingReorderModeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 8),
      child: Row(
        children: [
          Text(
            l10n.shoppingSectionToBuy,
            style: AppTextStyles.titleMedium.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            key: const Key('shopping_reorder_toggle'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 36),
            ),
            onPressed: () =>
                ref.read(shoppingReorderModeProvider.notifier).toggle(),
            child: Text(
              reorderMode
                  ? l10n.shoppingExitReorderMode
                  : l10n.shoppingEnterReorderMode,
              style: AppTextStyles.labelMedium.copyWith(
                color: palette.accentPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper widget that reads active item IDs and passes them to
/// [ShoppingSelectionHeader] for the "Select All" functionality.
class _BatchHeaderWrapper extends ConsumerWidget {
  const _BatchHeaderWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(filteredShoppingItemsProvider);
    final activeIds = itemsAsync.value
            ?.where((i) => !i.isCompleted)
            .map((i) => i.id)
            .toList() ??
        const [];

    return ShoppingSelectionHeader(allItemIds: activeIds);
  }
}

/// 完了 section header — heading + すべて削除 clear-all button (DONE-03).
///
/// The clear-all button fires [ClearCompletedItemsUseCase] for [listType]
/// regardless of active filter (SC5 — clears all completed in the segment).
class _CompletedSectionHeader extends ConsumerWidget {
  const _CompletedSectionHeader({
    required this.listType,
    required this.completedCount,
  });

  final String listType;
  final int completedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = S.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 8),
      child: Row(
        children: [
          Text(
            l10n.shoppingCompletedDivider,
            style: AppTextStyles.titleMedium.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const Spacer(),
          // Clear-all-completed button (DONE-03, SC5)
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 36),
            ),
            onPressed: () async {
              final confirmed = await showSoftConfirmDialog(
                context,
                title: l10n.shoppingClearCompletedTitle,
                body: l10n.shoppingClearCompletedBody,
                confirmLabel: l10n.shoppingClearCompletedConfirm,
                cancelLabel: l10n.shoppingDeleteCancelButton,
              );
              if (!confirmed) return;
              // Show feedback BEFORE use-case call (context validity rule)
              if (context.mounted) {
                showSuccessFeedback(
                  context,
                  l10n.shoppingClearCompletedSnackBar,
                );
              }
              // SC5/DONE-03: fire for current listType regardless of active filter
              await ref
                  .read(clearCompletedItemsUseCaseProvider)
                  .execute(listType);
            },
            child: Text(
              l10n.shoppingClearCompletedAction,
              style: AppTextStyles.labelMedium.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline muted placeholder shown under the 買うもの header when the active
/// (pending) list is filtered-empty but completed items still exist — e.g. a
/// ledger/category/私有 filter hid every pending item.
///
/// This is intentionally NOT the big 3-variant [ShoppingEmptyState]; that is
/// reserved for the all-empty case (no active AND no completed items). Mockup:
/// the `.shopping-empty` warm muted card under the 買うもの section title.
class _FilteredEmptyPlaceholder extends StatelessWidget {
  const _FilteredEmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.borderDefault, width: 1),
        ),
        child: Text(
          l10n.shoppingFilteredEmpty,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

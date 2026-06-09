import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../providers/repository_providers.dart';
import '../providers/state_shopping_batch.dart';
import '../providers/state_shopping_filter.dart';
import '../widgets/shopping_batch_action_bar.dart';
import '../widgets/shopping_empty_state.dart';
import '../widgets/shopping_filter_bar.dart';
import '../widgets/shopping_item_tile.dart';
import '../widgets/shopping_selection_header.dart';

/// Main shopping list shell screen (SC2, D38-02, DONE-03, MGMT-02).
///
/// Structure (top → bottom):
/// 1. SegmentedButton: Public / Private (SHOP-01)
/// 2. ShoppingFilterBar (D38-04)
/// 3. ShoppingSelectionHeader — visible only when batch mode is active (D38-03)
/// 4. Expanded body: _buildBody() — the streaming item list
/// 5. ShoppingBatchActionBar — visible only when batch mode is active (D38-03)
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
    // Only family-group members see the 全部 / 个人 view toggle. When solo,
    // 个人 IS 全部, so the toggle would be meaningless (and is hidden).
    final isGroupMode = ref.watch(isGroupModeProvider);

    return Scaffold(
      backgroundColor: palette.background,
      // SafeArea(top) keeps the toggle/filter bar clear of the iOS status bar
      // and Dynamic Island; bottom is owned by the floating nav bar.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // All/Personal segmented control — group mode only (SHOP-01)
            if (isGroupMode)
              _buildSegmentedControl(context, ref, palette, listType),
            // Chip filter bar (D38-04)
            const ShoppingFilterBar(),
            // Batch chrome — selection header (D38-03, MGMT-02)
            if (batchActive)
              // Pass active item IDs via a watch to avoid prop drilling issues;
              // ShoppingSelectionHeader receives allItemIds from the parent build context.
              _BatchHeaderWrapper(),
            // Main body
            Expanded(child: _buildBody(context, ref, palette, listType)),
            // Batch chrome — bottom action bar (D38-03, MGMT-02)
            if (batchActive) const ShoppingBatchActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
    String listType,
  ) {
    final l10n = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<String>(
        segments: [
          // 全部 (All) first and default; then 个人 (Personal).
          ButtonSegment(
            value: 'all',
            label: Text(
              l10n.shoppingSegmentAll,
              style: AppTextStyles.titleSmall,
            ),
          ),
          ButtonSegment(
            value: 'private',
            label: Text(
              l10n.shoppingSegmentPrivate,
              style: AppTextStyles.titleSmall,
            ),
          ),
        ],
        selected: {listType},
        onSelectionChanged: (newSet) {
          if (newSet.isNotEmpty) {
            ref.read(listTypeProvider.notifier).setListType(newSet.first);
          }
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: palette.borderInputActive,
          selectedForegroundColor: Colors.white,
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
            // ref.invalidate is appropriate here — user-triggered retry (not a sync update)
            TextButton(
              onPressed: () => ref.invalidate(filteredShoppingItemsProvider),
              child: Text(l10n.shoppingRetry),
            ),
          ],
        ),
      ),
      data: (items) {
        final activeItems =
            items.where((i) => !i.isCompleted).toList();
        final completedItems =
            items.where((i) => i.isCompleted).toList();

        if (activeItems.isEmpty && completedItems.isEmpty) {
          return ShoppingEmptyState(listType: listType);
        }

        return CustomScrollView(
          slivers: [
            // Active items — SliverReorderableList (D38-02).
            // Fix 2: ReorderableDelayedDragStartListener wraps the full tile so
            // a long-press anywhere on the row initiates drag (not just the handle).
            // Fix 3: proxyDecorator wraps the dragged item in an opaque card surface
            // (palette.card) with an animated elevation shadow (0→6) for visual lift.
            // onReorderItem provides the already-adjusted newIndex (item removed before insertion).
            // We persist the FULL new order (contiguous 0..N-1) rather than a single
            // sort_order, so a drag to the very top/bottom truly lands first/last even
            // when other items hold non-contiguous values (quick-260609-pmc-04).
            SliverReorderableList(
              itemCount: activeItems.length,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (ctx, _) {
                    final double elevation =
                        Tween<double>(begin: 0, end: 6)
                            .animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ))
                            .value;
                    return Material(
                      elevation: elevation,
                      color: ctx.palette.card,
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
                child: ShoppingItemTile(
                  item: activeItems[index],
                  index: index,
                  isActive: true,
                ),
              ),
            ),
            // Completed section
            if (completedItems.isNotEmpty) ...[
              // Clear-all-completed button + divider row (DONE-03)
              SliverToBoxAdapter(
                child: _CompletedSectionHeader(
                  listType: listType,
                  completedCount: completedItems.length,
                ),
              ),
              // Completed items list (plain SliverList — no drag)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => ShoppingItemTile(
                    key: ValueKey(completedItems[i].id),
                    item: completedItems[i],
                    index: i,
                    isActive: false,
                  ),
                  childCount: completedItems.length,
                ),
              ),
            ],
            // Bottom padding so last item clears the FAB
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
}

/// Wrapper widget that reads active item IDs and passes them to
/// [ShoppingSelectionHeader] for the "Select All" functionality.
///
/// Uses a separate [ConsumerWidget] to avoid rebuild of the whole screen
/// body when batch IDs change.
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

/// Header row above the completed section — shows completed-items divider
/// and a clear-all button (DONE-03).
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: palette.borderList,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              l10n.shoppingCompletedDivider,
              style: AppTextStyles.dividerLabel.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: palette.borderList,
            ),
          ),
          const SizedBox(width: 8),
          // Clear-all-completed button (DONE-03, SC5)
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 32),
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
            child: Icon(
              Icons.delete_sweep_outlined,
              size: 20,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

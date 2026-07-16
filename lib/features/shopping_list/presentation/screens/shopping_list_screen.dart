import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/main_surface_header.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../providers/repository_providers.dart';
import '../providers/state_shopping_filter.dart';
import '../widgets/shopping_empty_state.dart';
import '../widgets/shopping_filter_bar.dart';
import '../widgets/shopping_item_tile.dart';

/// Main shopping list shell screen — v15 warm-Japanese port (D-02, ADR-019).
///
/// Structure (top → bottom), mirroring the mockup `shopping()`:
/// 1. ShoppingFilterBar — the v15 uncarded ledger segment; group mode adds the
///    range segment above it.
/// 2. Body: 買うもの section header → active items list-card → 完了 section
///    header → individual completed cards.
///
/// Active items are always reorderable from their trailing long-press handle;
/// the rest of each row owns the single-item action menu. Batch selection and
/// the separate reorder mode are intentionally absent.
///
/// NEVER call ref.invalidate(filteredShoppingItemsProvider) for sync-driven
/// updates — the Drift .watch() stream handles reactivity (GAP-2 lesson).
/// ref.invalidate is ONLY used in the error state's retry button.
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key, this.onSettingsTap});

  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final listType = ref.watch(listTypeProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: MainSurfaceHeader.screenPadding,
              child: MainSurfaceHeader(
                key: const Key('shopping-main-header'),
                title: S.of(context).shoppingListScreenTitle,
                titleKey: const Key('shopping-main-title'),
                actions: [
                  MainSurfaceHeaderAction(
                    key: const Key('shopping-settings-button'),
                    icon: Icons.settings_outlined,
                    tooltip: S.of(context).settings,
                    onPressed: onSettingsTap ?? () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: MainSurfaceHeader.contentSpacing),
            // v15 filter surface — ledger, plus family scope when applicable.
            const ShoppingFilterBar(),
            // Main body
            Expanded(child: _buildBody(context, ref, palette, listType)),
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
            Icon(Icons.error_outline, size: 40, color: palette.textTertiary),
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
            const SliverToBoxAdapter(child: _ToBuySectionHeader()),
            // Active items — single list-card with SliverReorderableList (D38-02).
            if (activeItems.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: DecoratedSliver(
                  decoration: _cardDecoration(palette),
                  sliver: SliverReorderableList(
                    itemCount: activeItems.length,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (ctx, _) {
                          final double elevation =
                              Tween<double>(begin: 0, end: 6)
                                  .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOut,
                                    ),
                                  )
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
                      final orderedIds = activeItems
                          .map((e) => e.id)
                          .toList(growable: true);
                      final moved = orderedIds.removeAt(oldIndex);
                      orderedIds.insert(newIndex, moved);
                      ref
                          .read(reorderShoppingItemsUseCaseProvider)
                          .applyOrder(orderedIds);
                    },
                    itemBuilder: (context, index) => _DividedRow(
                      key: ValueKey(activeItems[index].id),
                      showDivider: index > 0,
                      child: ShoppingItemTile(
                        item: activeItems[index],
                        index: index,
                        isActive: true,
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
            if (completedItems.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _CompletedSectionHeader(
                  listType: listType,
                  completedCount: completedItems.length,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AnimatedOpacity(
                        key: ValueKey(
                          'completed-item-opacity-${completedItems[i].id}',
                        ),
                        duration: const Duration(milliseconds: 200),
                        opacity: 0.58,
                        child: DecoratedBox(
                          key: ValueKey(
                            'completed-item-card-${completedItems[i].id}',
                          ),
                          decoration: _cardDecoration(palette),
                          child: ShoppingItemTile(
                            item: completedItems[i],
                            index: i,
                            isActive: false,
                          ),
                        ),
                      ),
                    ),
                    childCount: completedItems.length,
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
  const _DividedRow({
    super.key,
    required this.child,
    required this.showDivider,
  });

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

/// 買うもの section header. Reordering is owned by each trailing handle, so
/// there is no separate sorting mode or header action.
class _ToBuySectionHeader extends StatelessWidget {
  const _ToBuySectionHeader();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(21, 18, 21, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.shoppingSectionToBuy,
          style: AppTextStyles.sectionTitle.copyWith(
            color: palette.textPrimary,
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(21, 18, 21, 8),
      child: Row(
        children: [
          Text(
            l10n.shoppingCompletedDivider,
            style: AppTextStyles.sectionTitle.copyWith(
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
              style: AppTextStyles.label.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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

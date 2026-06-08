import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../../domain/models/shopping_item.dart';
import '../providers/repository_providers.dart';
import '../providers/state_shopping_batch.dart';
import '../screens/shopping_item_form_screen.dart';
import '../../../home/presentation/providers/state_shadow_books.dart';

/// Shopping list item tile implementing all D38 interaction affordances.
///
/// Covers:
/// - SHOP-02: item.name as primary text
/// - SHOP-03: 4px left-border with dual-ledger accent colour
/// - DONE-01: animated toggle (strikethrough + opacity) on tap; calls [ToggleItemCompletedUseCase]
/// - MGMT-01: swipe-delete with [showSoftConfirmDialog]; [showSuccessFeedback] BEFORE use-case call
/// - MGMT-02: long-press enters batch mode
/// - MGMT-03: swipe and drag handle disabled in batch mode
/// - SYNC-04: attribution chip on public tiles when shadow book resolves
/// - D38-01: edit chevron in trailing cluster
/// - D38-02: drag handle via [ReorderableDragStartListener] (L2 fix for `buildDefaultDragHandles:false`)
class ShoppingItemTile extends ConsumerWidget {
  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.isActive,
  });

  final ShoppingItem item;

  /// Position in the parent [SliverReorderableList] — required by
  /// [ReorderableDragStartListener].
  final int index;

  /// `true` for active (uncompleted) items; `false` for completed items.
  /// Controls trailing cluster: active shows edit + drag handle; completed
  /// shows edit only (no drag).
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final batchActive = ref.watch(batchSelectModeProvider).isActive;

    return Dismissible(
      key: ValueKey(item.id),
      direction: batchActive
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        color: palette.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: palette.card, size: 20),
      ),
      confirmDismiss: (_) => showSoftConfirmDialog(
        context,
        title: S.of(context).shoppingDeleteConfirmTitle,
        body: S.of(context).shoppingDeleteConfirmBody,
        confirmLabel: S.of(context).shoppingDeleteConfirmButton,
        cancelLabel: S.of(context).shoppingDeleteCancelButton,
      ),
      onDismissed: (_) {
        // CRITICAL order: feedback toast BEFORE provider call (context still valid)
        showSuccessFeedback(context, S.of(context).shoppingDeletedSnackBar);
        ref.read(deleteShoppingItemUseCaseProvider).execute(item.id);
      },
      child: GestureDetector(
        onTap: () =>
            ref.read(toggleItemCompletedUseCaseProvider).execute(item.id),
        onLongPress: batchActive
            ? null
            : () {
                ref.read(batchSelectModeProvider.notifier).enter();
                ref.read(batchSelectModeProvider.notifier).toggle(item.id);
              },
        behavior: HitTestBehavior.opaque,
        child: _buildTileContent(context, ref, palette, batchActive),
      ),
    );
  }

  Widget _buildTileContent(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
    bool batchActive,
  ) {
    final locale = Localizations.localeOf(context);

    // Left-border accent colour per SHOP-03
    final borderColor = switch (item.ledgerType) {
      LedgerType.daily => palette.daily,
      LedgerType.joy => palette.joy,
      null => palette.borderList,
    };

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Padding(
        // 14px vertical matches list_transaction_tile.dart golden (UI-SPEC off-grid exception)
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Expanded text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary: animated strikethrough + fade (DONE-01)
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    style: item.isCompleted
                        ? AppTextStyles.bodyLarge.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: palette.textTertiary,
                          )
                        : AppTextStyles.bodyLarge,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: item.isCompleted ? 0.5 : 1.0,
                      child: Text(item.name),
                    ),
                  ),
                  // Secondary row: quantity + estimated price (bodySmall)
                  if (item.quantity > 1 || item.estimatedPrice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.quantity > 1)
                            Text(
                              '${item.quantity}×',
                              style: AppTextStyles.bodySmall,
                            ),
                          if (item.quantity > 1 && item.estimatedPrice != null)
                            const SizedBox(width: 6),
                          if (item.estimatedPrice != null)
                            Text(
                              NumberFormatter.formatCurrency(
                                item.estimatedPrice!,
                                'JPY',
                                locale,
                              ),
                              style: AppTextStyles.amountSmall.copyWith(
                                color: switch (item.ledgerType) {
                                  LedgerType.daily => palette.dailyText,
                                  // NEVER raw palette.joy — fails WCAG AA
                                  LedgerType.joy => palette.joyText,
                                  null => palette.textSecondary,
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Attribution chip — public-list tiles only (SYNC-04 / T-38-04-01)
            if (item.listType == 'public' && item.addedByBookId != null)
              Builder(builder: (ctx) {
                // Riverpod 3: .value (nullable), NOT .valueOrNull (removed in v3)
                final shadows = ref.watch(shadowBooksProvider).value ?? const [];
                final tag = shadows.firstWhereOrNull(
                  (s) => s.book.id == item.addedByBookId,
                );
                if (tag == null) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 72),
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.sharedLight,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        child: Text(
                          '${tag.memberAvatarEmoji} ${tag.memberDisplayName}',
                          style: AppTextStyles.micro
                              .copyWith(color: palette.sharedText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              }),
            // Trailing cluster: edit chevron + optional drag handle
            _buildTrailingCluster(context, batchActive),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingCluster(BuildContext context, bool batchActive) {
    final palette = context.palette;
    final editAffordance = Semantics(
      label: S.of(context).shoppingEditItem,
      button: true,
      child: Tooltip(
        message: S.of(context).shoppingEditItem,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ShoppingItemFormScreen(
                listType: item.listType,
                item: item,
              ),
            ),
          ),
          // ≥44px hit target (WCAG 2.1 SC 2.5.5)
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );

    if (!isActive) {
      // Completed items: edit chevron only, no drag handle
      return editAffordance;
    }

    // Active items: edit chevron + optional drag handle (hidden in batch mode)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        editAffordance,
        if (!batchActive) ...[
          const SizedBox(width: 8),
          Semantics(
            label: S.of(context).shoppingReorderItem,
            button: true,
            child: Tooltip(
              message: S.of(context).shoppingReorderItem,
              child: ReorderableDragStartListener(
                index: index,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.drag_handle,
                      size: 20,
                      color: palette.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

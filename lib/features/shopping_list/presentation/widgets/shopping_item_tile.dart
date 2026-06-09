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
import '../providers/state_shopping_reorder.dart';
import '../screens/shopping_item_form_screen.dart';
import '../../../home/presentation/providers/state_shadow_books.dart';

/// Shopping list item tile implementing the EC2 interaction model.
///
/// Covers:
/// - SHOP-02: item.name as primary text
/// - SHOP-03: 4px left-border with dual-ledger accent colour
/// - DONE-01: leading circular toggle (strikethrough + opacity); tapping the
///   circle calls [ToggleItemCompletedUseCase] (EC2 D-domain#1 — was full-row)
/// - EC2 D-domain#3: tapping the tile BODY opens [ShoppingItemFormScreen]
///   (replaces the removed edit chevron, EC2 D-1)
/// - EC2 D-1: quantity moved to the trailing edge as a badge (shown for every
///   item, quantity >= 1); the edit chevron is gone
/// - 日常/悦己 ledger badge under the title (dual-ledger identity indicator)
/// - MGMT-01: swipe-delete with [showSoftConfirmDialog]; [showSuccessFeedback]
///   BEFORE use-case call
/// - MGMT-02: long-press enters batch mode
/// - MGMT-03: swipe and drag handle disabled in batch mode
/// - SYNC-04: attribution chip on public tiles when shadow book resolves
/// - EC2 D-2: drag handle via [ReorderableDragStartListener] is gated on
///   [shoppingReorderModeProvider] — rendered ONLY in reorder mode (was always
///   shown for active items). In reorder mode toggle / body-edit / swipe-delete
///   are all suppressed so the only available gesture is dragging.
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
  /// Only active items render a drag handle (and only in reorder mode).
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final batchActive = ref.watch(batchSelectModeProvider).isActive;
    final reorderMode = ref.watch(shoppingReorderModeProvider);

    // Reorder mode suppresses every gesture except dragging (EC2 D-2 /
    // Claude's Discretion). Batch mode keeps its existing guard (MGMT-03).
    final gesturesLocked = batchActive || reorderMode;

    return Dismissible(
      key: ValueKey(item.id),
      direction: gesturesLocked
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
        // EC2 D-domain#3: tapping the tile body opens the edit form
        // (replaces the old full-row toggle). Suppressed while gestures locked.
        onTap: gesturesLocked
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ShoppingItemFormScreen(
                      listType: item.listType,
                      item: item,
                    ),
                  ),
                ),
        onLongPress: gesturesLocked
            ? null
            : () {
                ref.read(batchSelectModeProvider.notifier).enter();
                ref.read(batchSelectModeProvider.notifier).toggle(item.id);
              },
        behavior: HitTestBehavior.opaque,
        child: _buildTileContent(context, ref, palette, reorderMode),
      ),
    );
  }

  Widget _buildTileContent(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
    bool reorderMode,
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
            // Leading circular completion toggle (EC2 D-domain#1)
            _buildCompletionToggle(context, ref, palette, reorderMode),
            const SizedBox(width: 12),
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
                  // Secondary row: 日常/悦己 ledger badge + estimated price.
                  // The badge is the dual-ledger identity indicator under the
                  // title (per user request); price (when set) sits after it.
                  if (item.ledgerType != null || item.estimatedPrice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.ledgerType != null)
                            _buildLedgerBadge(context, palette),
                          if (item.ledgerType != null &&
                              item.estimatedPrice != null)
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
            // Trailing cluster: quantity badge (quantity > 1) + reorder-mode
            // drag handle (active items only).
            _buildTrailingCluster(context, palette, reorderMode),
          ],
        ),
      ),
    );
  }

  /// Leading circular completion toggle (EC2 D-domain#1).
  ///
  /// Unfilled (incomplete): neutral outline circle with a faint check.
  /// Filled (complete): ledger-accent fill + white check.
  /// Tapping toggles completion via [ToggleItemCompletedUseCase]; the onTap is
  /// suppressed in reorder mode (gestures locked — drag only).
  Widget _buildCompletionToggle(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
    bool reorderMode,
  ) {
    // Filled colour uses the item's ledger accent; null ledger falls back to
    // the neutral daily green (EC2 Claude's Discretion).
    final fillColor = switch (item.ledgerType) {
      LedgerType.daily => palette.daily,
      LedgerType.joy => palette.joy,
      null => palette.daily,
    };

    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: item.isCompleted ? fillColor : Colors.transparent,
        border: Border.all(
          color: item.isCompleted ? fillColor : palette.borderDefault,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check,
        size: 16,
        color: item.isCompleted
            ? palette.card
            : palette.textTertiary.withValues(alpha: 0.4),
      ),
    );

    return Semantics(
      label: S.of(context).shoppingToggleComplete,
      button: true,
      checked: item.isCompleted,
      child: GestureDetector(
        // ValueKey for stable test targeting.
        key: ValueKey('toggle-${item.id}'),
        onTap: reorderMode
            ? null
            : () =>
                ref.read(toggleItemCompletedUseCaseProvider).execute(item.id),
        behavior: HitTestBehavior.opaque,
        // ≥44px hit target (WCAG 2.1 SC 2.5.5)
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: circle),
        ),
      ),
    );
  }

  /// 日常 / 悦己 ledger identity badge shown under the item title.
  ///
  /// Reuses the existing `listLedgerDaily` / `listLedgerJoy` strings and the
  /// dual-ledger palette tokens (daily green / joy — joyText, never raw joy,
  /// to satisfy WCAG AA). Renders nothing for a null ledger type.
  Widget _buildLedgerBadge(BuildContext context, AppPalette palette) {
    final l10n = S.of(context);
    final (String label, Color bg, Color fg) = switch (item.ledgerType) {
      LedgerType.daily => (
          l10n.listLedgerDaily,
          palette.dailyLight,
          palette.dailyText,
        ),
      LedgerType.joy => (
          l10n.listLedgerJoy,
          palette.joyLight,
          palette.joyText,
        ),
      null => ('', palette.card, palette.textSecondary),
    };
    if (item.ledgerType == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Text(label, style: AppTextStyles.micro.copyWith(color: fg)),
    );
  }

  /// Trailing cluster (EC2 D-1 / D-2):
  /// - quantity badge — shown whenever `item.quantity >= 1` (always, since the
  ///   column is NOT NULL with a default of 1; user opted to display every
  ///   quantity rather than gate on > 1)
  /// - drag handle — only in reorder mode AND for active items
  Widget _buildTrailingCluster(
    BuildContext context,
    AppPalette palette,
    bool reorderMode,
  ) {
    final children = <Widget>[];

    // Quantity badge on the right edge (EC2 D-1) — shown for every item
    // (quantity is always >= 1; user opted to always display the entered count).
    if (item.quantity >= 1) {
      children.add(
        Text(
          '${item.quantity}×',
          style: AppTextStyles.amountSmall.copyWith(
            color: palette.textSecondary,
          ),
        ),
      );
    }

    // Drag handle — reorder mode only, active items only (EC2 D-2).
    if (reorderMode && isActive) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: 8));
      }
      children.add(
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
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../../domain/models/shopping_item.dart';
import '../providers/repository_providers.dart';
import '../screens/shopping_item_form_screen.dart';
import '../../../home/presentation/providers/state_shadow_books.dart';

/// Shopping list item tile — v15 warm-Japanese port (D-02, ADR-019).
///
/// Faithful to the mockup `shopItem()`: a check circle (ledger-coloured hollow
/// ring → filled + white tick when done), the item name + meta copy, a ledger
/// badge (日常/ときめき), and a drag affordance. The dual-ledger accent is now
/// carried by the check circle and the badge — the old 4px left accent bar and
/// the 私有 lock marker were removed to match the mockup.
///
/// Interaction model:
/// - DONE-01: tapping the leading circle calls [ToggleItemCompletedUseCase].
/// - EC2 D-domain#3: tapping the tile body opens [ShoppingItemFormScreen].
/// - MGMT-01: swipe-delete with [showSoftConfirmDialog]; feedback BEFORE the
///   use-case call.
/// - Long-pressing the body opens edit / top / bottom / delete actions.
/// - Long-pressing the trailing handle starts reorder directly; there is no
///   batch-selection or separate reorder mode.
/// - SYNC-04: attribution chip on public tiles when the shadow book resolves.
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
  /// Active items expose a delayed drag handle. Completed items keep the V15
  /// faded drag glyph as a non-interactive visual affordance.
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
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
      child: _buildTileContent(context, ref, palette),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ShoppingItemFormScreen(listType: item.listType, item: item),
      ),
    );
  }

  Future<void> _showItemActions(BuildContext context, WidgetRef ref) async {
    final palette = context.palette;
    final action = await showModalBottomSheet<_ShoppingItemAction>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _ShoppingItemActionSheet(
        showReorderActions: isActive,
        onSelected: (selected) => Navigator.pop(sheetContext, selected),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _ShoppingItemAction.edit:
        _openEdit(context);
      case _ShoppingItemAction.moveToTop:
        _moveToEdge(ref, moveToTop: true);
      case _ShoppingItemAction.moveToBottom:
        _moveToEdge(ref, moveToTop: false);
      case _ShoppingItemAction.delete:
        final l10n = S.of(context);
        final confirmed = await showSoftConfirmDialog(
          context,
          title: l10n.shoppingDeleteConfirmTitle,
          body: l10n.shoppingDeleteConfirmBody,
          confirmLabel: l10n.shoppingDeleteConfirmButton,
          cancelLabel: l10n.shoppingDeleteCancelButton,
        );
        if (!confirmed || !context.mounted) return;
        showSuccessFeedback(context, l10n.shoppingDeletedSnackBar);
        await ref.read(deleteShoppingItemUseCaseProvider).execute(item.id);
    }
  }

  void _moveToEdge(WidgetRef ref, {required bool moveToTop}) {
    if (!isActive) return;
    final items = ref.read(filteredShoppingItemsProvider).value ?? const [];
    final ids = items
        .where((candidate) => !candidate.isCompleted)
        .map((candidate) => candidate.id)
        .toList(growable: true);
    if (!ids.remove(item.id)) return;
    if (moveToTop) {
      ids.insert(0, item.id);
    } else {
      ids.add(item.id);
    }
    ref.read(reorderShoppingItemsUseCaseProvider).applyOrder(ids);
  }

  Widget _buildTileContent(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
  ) {
    final locale = Localizations.localeOf(context);

    // Meta line (mockup `.row-copy small`) — "{category} · {quantity}".
    // Category resolves via CategoryLocalizationService (the SAME path the list
    // tile uses; it returns the raw id unchanged for user-created categories).
    // A null / empty categoryId degrades to the bare quantity number. The
    // estimated price is intentionally dropped — the v15 tile shows no price.
    final categoryId = item.categoryId;
    final categoryName = (categoryId != null && categoryId.isNotEmpty)
        ? CategoryLocalizationService.resolveFromId(categoryId, locale)
        : null;
    final metaText = categoryName != null
        ? '$categoryName · ${item.quantity}'
        : '${item.quantity}';

    return Container(
      key: const Key('shopping_item_content'),
      // v15 rows sit inside the shopping-list-card; the tile itself is
      // transparent so the card fill + rounded corners show through.
      color: Colors.transparent,
      constraints: const BoxConstraints(minHeight: 68),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                key: ValueKey('shopping-item-body-${item.id}'),
                onTap: () => _openEdit(context),
                onLongPress: () => _showItemActions(context, ref),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    // Leading circular completion toggle (DONE-01).
                    _buildCompletionToggle(context, ref, palette),
                    const SizedBox(width: 10),
                    // The completed card owns the single .58 opacity layer so
                    // every visual element fades by the same amount.
                    Expanded(
                      child: KeyedSubtree(
                        key: ValueKey('shopping-copy-${item.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              style: AppTextStyles.itemTitle.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: palette.textPrimary,
                              ),
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              metaText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.supporting.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Attribution chip — public-list tiles only (SYNC-04).
                    if (item.listType == 'public' && item.addedByBookId != null)
                      _buildAttributionChip(context, ref, palette),
                    _buildLedgerBadge(context, palette),
                  ],
                ),
              ),
            ),
            // The trailing lane is deliberately outside the body detector so
            // its long press can only start a drag and never open the menu.
            _buildTrailingHandle(context, palette),
          ],
        ),
      ),
    );
  }

  /// Attribution chip — public-list tiles only (SYNC-04 / T-38-04-01).
  Widget _buildAttributionChip(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
  ) {
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
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            child: Text(
              '${tag.memberAvatarEmoji} ${tag.memberDisplayName}',
              style: AppTextStyles.compact.copyWith(color: palette.sharedText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Ledger badge (日常 / ときめき) — mockup `.badge.shopping-ledger-badge`.
  ///
  /// daily → `dailyLight` fill + `dailyText`; joy → `joyLight` + `joyText`
  /// (never raw `joy`/`daily` on text — WCAG AA). Completed-state fading is
  /// applied once by the surrounding card. Null ledger renders nothing.
  Widget _buildLedgerBadge(BuildContext context, AppPalette palette) {
    final l10n = S.of(context);
    final (Color bg, Color fg, String label) = switch (item.ledgerType) {
      LedgerType.daily => (
        palette.dailyLight,
        palette.dailyText,
        l10n.listLedgerDaily,
      ),
      LedgerType.joy => (palette.joyLight, palette.joyText, l10n.listLedgerJoy),
      null => (palette.backgroundMuted, palette.textSecondary, ''),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    final badgeBackground = item.isCompleted ? palette.backgroundMuted : bg;
    final badgeForeground = item.isCompleted ? palette.textSecondary : fg;

    return KeyedSubtree(
      key: ValueKey('shopping-ledger-badge-${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTextStyles.compact.copyWith(
            color: badgeForeground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Leading circular completion toggle (DONE-01).
  ///
  /// Unchecked: hollow ring in the item's ledger colour (daily/joy; null falls
  /// back to daily). Checked: matching ledger-colour fill + white tick, then
  /// the whole completed card is muted uniformly. Tapping toggles completion via
  /// [ToggleItemCompletedUseCase]; suppressed in reorder mode.
  Widget _buildCompletionToggle(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
  ) {
    final ledgerColor = switch (item.ledgerType) {
      LedgerType.daily => palette.daily,
      LedgerType.joy => palette.joy,
      null => palette.daily,
    };
    final checkColor = ledgerColor;

    final circle = AnimatedContainer(
      key: ValueKey('shopping-check-${item.id}'),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: item.isCompleted ? checkColor : Colors.transparent,
        border: Border.all(color: checkColor, width: 2),
      ),
      child: item.isCompleted
          ? Transform.translate(
              key: ValueKey('shopping-check-icon-${item.id}'),
              // Material's Flutter check is optically centred by default,
              // while the V15 reference places the painted mark lower-right.
              offset: const Offset(5, 2),
              child: Icon(Icons.check, size: 18, color: palette.card),
            )
          : null,
    );

    return Semantics(
      label: S.of(context).shoppingToggleComplete,
      button: true,
      checked: item.isCompleted,
      child: GestureDetector(
        // ValueKey for stable test targeting.
        key: ValueKey('toggle-${item.id}'),
        onTap: () =>
            ref.read(toggleItemCompletedUseCaseProvider).execute(item.id),
        behavior: HitTestBehavior.opaque,
        // Keep the 44px vertical tap lane without reserving 44px horizontally;
        // V15 places copy 10px after the 23px circle.
        child: SizedBox(width: 28, height: 44, child: Center(child: circle)),
      ),
    );
  }

  /// Active rows reserve a 44px trailing lane for delayed drag. Completed rows
  /// preserve the same V15 glyph but remain fixed below the completed divider;
  /// the surrounding completed card applies the uniform visual fade.
  Widget _buildTrailingHandle(BuildContext context, AppPalette palette) {
    final glyph = SizedBox(
      width: 44,
      height: 48,
      child: Center(
        child: Icon(
          Icons.drag_indicator,
          size: 20,
          color: isActive ? palette.textTertiary : palette.textPrimary,
        ),
      ),
    );

    if (!isActive) {
      return KeyedSubtree(
        key: ValueKey('shopping-drag-glyph-${item.id}'),
        child: glyph,
      );
    }

    return Semantics(
      label: S.of(context).shoppingReorderItem,
      button: true,
      child: ReorderableDelayedDragStartListener(
        key: ValueKey('shopping-drag-handle-${item.id}'),
        index: index,
        child: glyph,
      ),
    );
  }
}

enum _ShoppingItemAction { edit, moveToTop, moveToBottom, delete }

class _ShoppingItemActionSheet extends StatelessWidget {
  const _ShoppingItemActionSheet({
    required this.showReorderActions,
    required this.onSelected,
  });

  final bool showReorderActions;
  final ValueChanged<_ShoppingItemAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionRow(
            key: const Key('shopping_action_edit'),
            label: l10n.shoppingActionEdit,
            color: palette.textPrimary,
            onTap: () => onSelected(_ShoppingItemAction.edit),
          ),
          if (showReorderActions) ...[
            _actionRow(
              key: const Key('shopping_action_top'),
              label: l10n.shoppingMoveToTop,
              color: palette.textPrimary,
              onTap: () => onSelected(_ShoppingItemAction.moveToTop),
            ),
            _actionRow(
              key: const Key('shopping_action_bottom'),
              label: l10n.shoppingMoveToBottom,
              color: palette.textPrimary,
              onTap: () => onSelected(_ShoppingItemAction.moveToBottom),
            ),
          ],
          _actionRow(
            key: const Key('shopping_action_delete'),
            label: l10n.shoppingDeleteConfirmButton,
            color: palette.error,
            onTap: () => onSelected(_ShoppingItemAction.delete),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required Key key,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

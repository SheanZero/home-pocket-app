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

/// Shopping list item tile — v15 warm-Japanese port (D-02, ADR-019).
///
/// Faithful to the mockup `shopItem()`: a check circle (ledger-coloured hollow
/// ring → filled + white tick when done), the item name + meta copy, a ledger
/// badge (日常/ときめき), and a drag affordance. The dual-ledger accent is now
/// carried by the check circle and the badge — the old 4px left accent bar and
/// the 私有 lock marker were removed to match the mockup.
///
/// Interaction model is UNCHANGED:
/// - DONE-01: tapping the leading circle calls [ToggleItemCompletedUseCase].
/// - EC2 D-domain#3: tapping the tile body opens [ShoppingItemFormScreen].
/// - MGMT-01: swipe-delete with [showSoftConfirmDialog]; feedback BEFORE the
///   use-case call.
/// - MGMT-02: long-press enters batch mode.
/// - MGMT-03 / EC2 D-2: swipe + toggle are suppressed in batch/reorder mode; in
///   reorder mode the move-to-top/bottom buttons + drag handle appear.
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

    // Meta line (mockup `.row-copy small`) — estimated price when set.
    final metaText = item.estimatedPrice != null
        ? NumberFormatter.formatCurrency(item.estimatedPrice!, 'JPY', locale)
        : null;

    return Container(
      // v15 rows sit inside the shopping-list-card; the tile itself is
      // transparent so the card fill + rounded corners show through.
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            // Leading circular completion toggle (DONE-01).
            _buildCompletionToggle(context, ref, palette, reorderMode),
            const SizedBox(width: 10),
            // Copy: item name (strong) + meta (small).
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      opacity: item.isCompleted ? 0.58 : 1.0,
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (metaText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      metaText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.amountSmall.copyWith(
                        color: item.isCompleted
                            ? palette.textTertiary
                            : palette.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Attribution chip — public-list tiles only (SYNC-04 / T-38-04-01)
            if (item.listType == 'public' && item.addedByBookId != null)
              _buildAttributionChip(context, ref, palette),
            // Ledger badge (日常 / ときめき) — mockup `.shopping-ledger-badge`.
            _buildLedgerBadge(context, palette),
            // Trailing cluster: quantity + reorder controls / drag affordance.
            _buildTrailingCluster(context, ref, palette, reorderMode),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 1,
            ),
            child: Text(
              '${tag.memberAvatarEmoji} ${tag.memberDisplayName}',
              style: AppTextStyles.micro.copyWith(color: palette.sharedText),
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
  /// (never raw `joy`/`daily` on text — WCAG AA). Fades to .58 opacity when
  /// the item is completed. Null ledger renders nothing.
  Widget _buildLedgerBadge(BuildContext context, AppPalette palette) {
    final l10n = S.of(context);
    final (Color bg, Color fg, String label) = switch (item.ledgerType) {
      LedgerType.daily => (
          palette.dailyLight,
          palette.dailyText,
          l10n.listLedgerDaily,
        ),
      LedgerType.joy => (
          palette.joyLight,
          palette.joyText,
          l10n.listLedgerJoy,
        ),
      null => (palette.backgroundMuted, palette.textSecondary, ''),
    };
    if (label.isEmpty) return const SizedBox.shrink();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: item.isCompleted ? 0.58 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTextStyles.micro.copyWith(
            color: fg,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  /// Leading circular completion toggle (DONE-01).
  ///
  /// Unchecked: hollow ring in the item's ledger colour (daily/joy; null falls
  /// back to daily). Checked: ledger-colour fill + white tick. Tapping toggles
  /// completion via [ToggleItemCompletedUseCase]; suppressed in reorder mode.
  Widget _buildCompletionToggle(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
    bool reorderMode,
  ) {
    final ledgerColor = switch (item.ledgerType) {
      LedgerType.daily => palette.daily,
      LedgerType.joy => palette.joy,
      null => palette.daily,
    };

    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: item.isCompleted ? ledgerColor : Colors.transparent,
        border: Border.all(color: ledgerColor, width: 2),
      ),
      child: item.isCompleted
          ? Icon(Icons.check, size: 15, color: palette.card)
          : null,
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

  /// Trailing cluster:
  /// - quantity — number only (no ×), shown for every item.
  /// - normal mode (active item) — a decorative `drag_indicator` glyph; the
  ///   whole active row is long-press draggable in the parent list.
  /// - reorder mode (active item) — move-to-top / move-to-bottom + drag handle.
  Widget _buildTrailingCluster(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
    bool reorderMode,
  ) {
    final children = <Widget>[];

    // Quantity on the right edge — number only (no ×), shown for every item.
    if (item.quantity >= 1) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            '${item.quantity}',
            style: AppTextStyles.amountSmall.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ),
      );
    }

    if (reorderMode && isActive) {
      // Move-to-top button (Fix 4): re-sequence the whole active list with this
      // item moved to the front, persisting a contiguous 0..N-1 order.
      children.add(
        Semantics(
          label: S.of(context).shoppingMoveToTop,
          button: true,
          child: Tooltip(
            message: S.of(context).shoppingMoveToTop,
            child: InkWell(
              onTap: () {
                final items =
                    ref.read(filteredShoppingItemsProvider).value ?? const [];
                final ids = items
                    .where((i) => !i.isCompleted)
                    .map((i) => i.id)
                    .toList(growable: true);
                ids.remove(item.id);
                ids.insert(0, item.id);
                ref
                    .read(reorderShoppingItemsUseCaseProvider)
                    .applyOrder(ids);
              },
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 36,
                height: 44,
                child: Center(
                  child: Icon(
                    Icons.vertical_align_top,
                    size: 20,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Move-to-bottom button (Fix 4).
      children.add(
        Semantics(
          label: S.of(context).shoppingMoveToBottom,
          button: true,
          child: Tooltip(
            message: S.of(context).shoppingMoveToBottom,
            child: InkWell(
              onTap: () {
                final items =
                    ref.read(filteredShoppingItemsProvider).value ?? const [];
                final ids = items
                    .where((i) => !i.isCompleted)
                    .map((i) => i.id)
                    .toList(growable: true);
                ids.remove(item.id);
                ids.add(item.id);
                ref
                    .read(reorderShoppingItemsUseCaseProvider)
                    .applyOrder(ids);
              },
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 36,
                height: 44,
                child: Center(
                  child: Icon(
                    Icons.vertical_align_bottom,
                    size: 20,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Drag handle — instant drag affordance (Icons.reorder, no Tooltip:
      // a Tooltip fires on long-press, which is the drag gesture).
      children.add(
        Semantics(
          label: S.of(context).shoppingReorderItem,
          button: true,
          child: ReorderableDragStartListener(
            index: index,
            child: SizedBox(
              width: 56,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.reorder,
                  size: 24,
                  color: palette.textTertiary,
                ),
              ),
            ),
          ),
        ),
      );
    } else if (isActive) {
      // Normal mode, active row: decorative drag glyph (mockup `drag_indicator`).
      // The row is long-press draggable via the parent list's listener.
      children.add(
        Icon(
          Icons.drag_indicator,
          size: 20,
          color: palette.textTertiary,
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

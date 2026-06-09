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
/// - EC2 D-1: quantity at the trailing edge — number only (no ×), shown for
///   every item; the edit chevron is gone
/// - G8Z2 FIX-3: 私有 marker to the right of the title for private items only
///   (the 日常/悦己 ledger badge was removed); public items show no marker
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

    // Left-border accent colour per SHOP-03. 悦己 (joy) shows its accent bar
    // again (G8Z2 FIX-1, restored from the earlier transparent treatment).
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
            // Title + 日常/悦己 badge inline. The badge sits to the RIGHT of
            // the title; the Row's default center cross-axis alignment keeps the
            // title vertically centred now that nothing stacks below it.
            Expanded(
              child: Row(
                children: [
                  // Primary: animated strikethrough + fade (DONE-01). Flexible
                  // so a long name ellipsizes before crowding the badge.
                  Flexible(
                    child: AnimatedDefaultTextStyle(
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
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  // 私有 marker — right of the title, private items only
                  // (G8Z2 FIX-3). Public items render nothing here.
                  if (item.listType == 'private') ...[
                    const SizedBox(width: 8),
                    _buildPrivateMarker(context, palette),
                  ],
                  // Estimated price (when set) trails the badge.
                  if (item.estimatedPrice != null) ...[
                    const SizedBox(width: 8),
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
            // move-to-top/bottom buttons + drag handle (active items only).
            _buildTrailingCluster(context, ref, palette, reorderMode),
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

  /// 私有 marker shown to the right of the item title for private (local-only)
  /// items (G8Z2 FIX-3). Public items render nothing.
  ///
  /// Mirrors the removed ledger badge's container shape but uses the shared
  /// (steel-blue) scope palette and a small lock glyph — consistent with the
  /// filter-bar 私有 chip. Label reuses `shoppingSegmentPrivate`.
  Widget _buildPrivateMarker(BuildContext context, AppPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.sharedLight,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 11, color: palette.sharedText),
          const SizedBox(width: 3),
          Text(
            S.of(context).shoppingSegmentPrivate,
            style: AppTextStyles.micro.copyWith(color: palette.sharedText),
          ),
        ],
      ),
    );
  }

  /// Trailing cluster (EC2 D-1 / D-2 / Fix 4):
  /// - quantity — number only (no ×), shown for every item with a right margin
  /// - move-to-top / move-to-bottom buttons — only in reorder mode, active items only
  /// - drag handle — only in reorder mode AND for active items
  Widget _buildTrailingCluster(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
    bool reorderMode,
  ) {
    final children = <Widget>[];

    // Quantity on the right edge — number only (no ×), shown for every item.
    // Right padding gives the count margin from the screen edge (and from the
    // drag handle when it appears in reorder mode).
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

    // Move-to-top + move-to-bottom + drag handle — reorder mode only, active items only.
    if (reorderMode && isActive) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: 4));
      }

      // Move-to-top button (Fix 4): re-sequence the whole active list with this
      // item moved to the front, persisting a contiguous 0..N-1 order. This is
      // collision-free for repeated taps AND keeps the persisted order contiguous
      // so a subsequent drag still lands correctly (quick-260609-pmc-04).
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

      // Move-to-bottom button (Fix 4): re-sequence the whole active list with this
      // item moved to the back, persisting a contiguous 0..N-1 order (same
      // rationale as move-to-top; quick-260609-pmc-04).
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

      // Drag handle — instant drag affordance for users targeting the handle.
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

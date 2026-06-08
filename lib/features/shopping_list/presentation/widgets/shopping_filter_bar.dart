import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/list/presentation/widgets/list_category_filter_sheet.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/state_shopping_filter.dart';

/// Shopping-specific chip filter bar (FILT-01, FILT-02, FILT-03, D38-04).
///
/// Reuses the visual style of [list_sort_filter_bar.dart] but is an
/// independent widget that reads from [shoppingFilterProvider] — NOT
/// [listFilterProvider] (L3 fix enforced by [onApply] callback).
///
/// Chip order (left-to-right):
/// All / 日常 / 悦己 → Category → Status → [Clear-all (conditional)]
class ShoppingFilterBar extends ConsumerWidget {
  const ShoppingFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(shoppingFilterProvider);
    final palette = context.palette;
    final l10n = S.of(context);

    // Clear-all chip visibility (FILT-03)
    final anyFilterActive = filter.ledgerType != null ||
        filter.categoryIds.isNotEmpty ||
        filter.statusFilter != 'all';

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(
          bottom: BorderSide(color: palette.borderDivider, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ledger: All chip ──────────────────────────────────────────
            ActionChip(
              label: Text(
                l10n.shoppingFilterLedgerAll,
                style: AppTextStyles.labelMedium.copyWith(
                  color: filter.ledgerType == null
                      ? palette.borderInputActive
                      : palette.textSecondary,
                ),
              ),
              backgroundColor: filter.ledgerType == null
                  ? palette.dailyLight
                  : palette.card,
              side: BorderSide(
                color: filter.ledgerType == null
                    ? palette.borderInputActive
                    : palette.borderDefault,
                width: 1,
              ),
              onPressed: () => ref
                  .read(shoppingFilterProvider.notifier)
                  .setLedgerFilter(null),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),

            // ── Ledger: 日常 chip ─────────────────────────────────────────
            ActionChip(
              label: Text(
                l10n.listLedgerDaily,
                style: AppTextStyles.labelMedium.copyWith(
                  color: filter.ledgerType == LedgerType.daily
                      ? palette.daily
                      : palette.textSecondary,
                ),
              ),
              backgroundColor: filter.ledgerType == LedgerType.daily
                  ? palette.dailyLight
                  : palette.card,
              side: BorderSide(
                color: filter.ledgerType == LedgerType.daily
                    ? palette.daily
                    : palette.borderDefault,
                width: 1,
              ),
              onPressed: () => ref
                  .read(shoppingFilterProvider.notifier)
                  .setLedgerFilter(
                    filter.ledgerType == LedgerType.daily
                        ? null
                        : LedgerType.daily,
                  ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),

            // ── Ledger: 悦己 chip ─────────────────────────────────────────
            ActionChip(
              label: Text(
                l10n.listLedgerJoy,
                style: AppTextStyles.labelMedium.copyWith(
                  color: filter.ledgerType == LedgerType.joy
                      ? palette.joy
                      : palette.textSecondary,
                ),
              ),
              backgroundColor: filter.ledgerType == LedgerType.joy
                  ? palette.joyLight
                  : palette.card,
              side: BorderSide(
                color: filter.ledgerType == LedgerType.joy
                    ? palette.joy
                    : palette.borderDefault,
                width: 1,
              ),
              onPressed: () => ref
                  .read(shoppingFilterProvider.notifier)
                  .setLedgerFilter(
                    filter.ledgerType == LedgerType.joy
                        ? null
                        : LedgerType.joy,
                  ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),

            // ── Category chip ─────────────────────────────────────────────
            ActionChip(
              label: Text(
                l10n.shoppingFilterCategory,
                style: AppTextStyles.labelMedium.copyWith(
                  color: filter.categoryIds.isNotEmpty
                      ? palette.borderInputActive
                      : palette.textSecondary,
                ),
              ),
              backgroundColor: filter.categoryIds.isNotEmpty
                  ? palette.dailyLight
                  : palette.card,
              side: BorderSide(
                color: filter.categoryIds.isNotEmpty
                    ? palette.borderInputActive
                    : palette.borderDefault,
                width: 1,
              ),
              onPressed: () {
                // L3 fix: use onApply callback so the sheet writes to
                // shoppingFilterProvider — NOT listFilterProvider (Pitfall 1)
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CategoryFilterSheet(
                    initialSelected: filter.categoryIds,
                    onApply: (ids) => ref
                        .read(shoppingFilterProvider.notifier)
                        .setCategoryIds(ids),
                  ),
                );
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),

            // ── Status chip ───────────────────────────────────────────────
            ActionChip(
              label: Text(
                filter.statusFilter == 'active'
                    ? l10n.shoppingFilterStatusActive
                    : l10n.shoppingFilterStatusAll,
                style: AppTextStyles.labelMedium.copyWith(
                  color: filter.statusFilter == 'active'
                      ? palette.borderInputActive
                      : palette.textSecondary,
                ),
              ),
              backgroundColor: filter.statusFilter == 'active'
                  ? palette.dailyLight
                  : palette.card,
              side: BorderSide(
                color: filter.statusFilter == 'active'
                    ? palette.borderInputActive
                    : palette.borderDefault,
                width: 1,
              ),
              onPressed: () => ref
                  .read(shoppingFilterProvider.notifier)
                  .setStatusFilter(
                    filter.statusFilter == 'active' ? 'all' : 'active',
                  ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),

            // ── Clear-all chip (conditional — FILT-03) ────────────────────
            if (anyFilterActive) ...[
              const SizedBox(width: 8),
              Semantics(
                label: l10n.listClearAll,
                child: ActionChip(
                  avatar: Icon(
                    Icons.clear_all,
                    size: 14,
                    color: palette.textSecondary,
                  ),
                  label: Text(
                    l10n.listClearAll,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: palette.textSecondary),
                  ),
                  backgroundColor: palette.backgroundMuted,
                  side: BorderSide(color: palette.borderDefault, width: 1),
                  onPressed: () =>
                      ref.read(shoppingFilterProvider.notifier).clearAll(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/state_shopping_filter.dart';
import 'shopping_category_filter_sheet.dart';

/// Shopping-specific filter bar (FILT-01, D-1, D-2, D-3).
///
/// Reads from [shoppingFilterProvider] — NOT [listFilterProvider] (the category
/// sheet writes back via its [onApply] callback).
///
/// Layout (left-to-right):
///   [全部 reset] → [日常 | 悦己 segmented control] → [Category chip]
///
/// - 全部 is a standalone reset control (the global clear entry, not part of the
///   segmented control). It highlights ONLY when nothing is filtered
///   (`ledgerType == null && categoryIds.isEmpty`) and tapping it calls
///   `clearAll()` (D-2). The old conditional clear-all ActionChip is gone.
/// - 日常 | 悦己 is a SINGLE connected segmented control with two
///   mutually-exclusive, re-tappable-to-deselect segments (D-1).
/// - Category opens the shopping-only [ShoppingCategoryFilterSheet] (D-3).
class ShoppingFilterBar extends ConsumerWidget {
  const ShoppingFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(shoppingFilterProvider);
    final palette = context.palette;
    final l10n = S.of(context);

    // 全部 highlights only when nothing is filtered (D-2).
    final noneActive =
        filter.ledgerType == null && filter.categoryIds.isEmpty;

    final dailySelected = filter.ledgerType == LedgerType.daily;
    final joySelected = filter.ledgerType == LedgerType.joy;

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
            // ── 全部 standalone reset control (D-2) ───────────────────────
            ActionChip(
              label: Text(
                l10n.shoppingFilterLedgerAll,
                style: AppTextStyles.labelMedium.copyWith(
                  color: noneActive
                      ? palette.borderInputActive
                      : palette.textSecondary,
                ),
              ),
              backgroundColor:
                  noneActive ? palette.dailyLight : palette.card,
              side: BorderSide(
                color: noneActive
                    ? palette.borderInputActive
                    : palette.borderDefault,
                width: 1,
              ),
              onPressed: () =>
                  ref.read(shoppingFilterProvider.notifier).clearAll(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),

            // ── 日常 | 悦己 connected segmented control (D-1) ─────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.borderDefault, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 日常 segment
                    _SegmentButton(
                      label: l10n.listLedgerDaily,
                      selected: dailySelected,
                      selectedBackground: palette.dailyLight,
                      selectedLabelColor: palette.daily,
                      idleLabelColor: palette.textSecondary,
                      onTap: () => ref
                          .read(shoppingFilterProvider.notifier)
                          .setLedgerFilter(
                            dailySelected ? null : LedgerType.daily,
                          ),
                    ),
                    // 1px vertical divider — reads as one connected control
                    Container(
                      width: 1,
                      height: 32,
                      color: palette.borderDefault,
                    ),
                    // 悦己 segment
                    _SegmentButton(
                      label: l10n.listLedgerJoy,
                      selected: joySelected,
                      selectedBackground: palette.joyLight,
                      selectedLabelColor: palette.joy,
                      idleLabelColor: palette.textSecondary,
                      onTap: () => ref
                          .read(shoppingFilterProvider.notifier)
                          .setLedgerFilter(
                            joySelected ? null : LedgerType.joy,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Category chip (D-3) ───────────────────────────────────────
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
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ShoppingCategoryFilterSheet(
                    initialSelected: filter.categoryIds,
                    onApply: (ids) => ref
                        .read(shoppingFilterProvider.notifier)
                        .setCategoryIds(ids),
                  ),
                );
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

/// One tappable segment within the connected 日常 | 悦己 control (D-1).
///
/// Renders a [Text] label so it stays findable via `find.text` in widget tests.
class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.selectedBackground,
    required this.selectedLabelColor,
    required this.idleLabelColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedBackground;
  final Color selectedLabelColor;
  final Color idleLabelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        color: selected ? selectedBackground : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? selectedLabelColor : idleLabelColor,
          ),
        ),
      ),
    );
  }
}

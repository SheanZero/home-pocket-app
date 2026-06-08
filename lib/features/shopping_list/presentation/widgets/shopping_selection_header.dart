import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/state_shopping_batch.dart';

/// Top selection header for batch-selection mode (D38-03, MGMT-02).
///
/// Displays the count of selected items, a Cancel button to exit batch mode,
/// and a Select-all button that selects every active item ID.
///
/// The [allItemIds] parameter must be provided by [ShoppingListScreen] — it
/// contains the IDs of all currently active (non-completed) items so that
/// "Select All" can select them all at once.
class ShoppingSelectionHeader extends ConsumerWidget {
  const ShoppingSelectionHeader({
    super.key,
    required this.allItemIds,
  });

  /// IDs of all active (non-completed) items in the current view.
  /// Used by the "Select All" button.
  final List<String> allItemIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = S.of(context);
    final batch = ref.watch(batchSelectModeProvider);

    return Container(
      height: 48,
      color: palette.backgroundMuted,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Cancel — exits batch mode
          TextButton(
            onPressed: () => ref.read(batchSelectModeProvider.notifier).exit(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.shoppingBatchCancel,
              style: AppTextStyles.titleSmall.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          // Selection count
          Text(
            l10n.shoppingSelectionCount(batch.selectedIds.length),
            style: AppTextStyles.titleLarge,
          ),
          const Spacer(),
          // Select All
          TextButton(
            onPressed: () => ref
                .read(batchSelectModeProvider.notifier)
                .selectAll(allItemIds),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.shoppingBatchSelectAll,
              style: AppTextStyles.titleSmall.copyWith(
                color: palette.borderInputActive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

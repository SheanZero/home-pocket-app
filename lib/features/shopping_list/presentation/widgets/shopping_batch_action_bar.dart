import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../providers/repository_providers.dart';
import '../providers/state_shopping_batch.dart';

/// Floating bottom action bar shown during batch-selection mode (D38-03, MGMT-02).
///
/// Displays the count of selected items and a destructive batch-delete button.
///
/// CRITICAL ordering (T-38-06-02): [showSuccessFeedback] is called BEFORE the
/// delete loop to ensure context is still valid when the overlay is inserted.
/// [batchSelectModeProvider.notifier.exit()] is called AFTER all use-case calls
/// complete so the selection state is cleared last.
class ShoppingBatchActionBar extends ConsumerWidget {
  const ShoppingBatchActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = S.of(context);
    final batch = ref.watch(batchSelectModeProvider);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(
          top: BorderSide(color: palette.borderDivider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.borderDefault.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '${batch.selectedIds.length} 件選択中',
            style: AppTextStyles.titleSmall.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const Spacer(),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: palette.errorSurface,
            ),
            onPressed: batch.selectedIds.isEmpty
                ? null
                : () async {
                    final confirmed = await showSoftConfirmDialog(
                      context,
                      title: l10n.shoppingBatchDeleteTitle,
                      body: l10n.shoppingBatchDeleteBody(
                        batch.selectedIds.length,
                      ),
                      confirmLabel: l10n.shoppingBatchDeleteConfirm,
                      cancelLabel: l10n.shoppingDeleteCancelButton,
                    );
                    if (!confirmed) return;
                    // CRITICAL: show feedback BEFORE delete loop (context validity rule, T-38-06-02)
                    if (context.mounted) {
                      showSuccessFeedback(
                        context,
                        l10n.shoppingBatchDeletedSnackBar,
                      );
                    }
                    final idsToDelete = List<String>.from(batch.selectedIds);
                    for (final id in idsToDelete) {
                      await ref
                          .read(deleteShoppingItemUseCaseProvider)
                          .execute(id);
                    }
                    ref.read(batchSelectModeProvider.notifier).exit();
                  },
            child: Text(
              l10n.shoppingBatchDeleteAction,
              style: AppTextStyles.titleSmall.copyWith(color: palette.error),
            ),
          ),
        ],
      ),
    );
  }
}

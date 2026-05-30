import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart'
    show deleteTransactionUseCaseProvider;
import '../../domain/models/tagged_transaction.dart';

/// List tile wrapping the transaction row in a [Dismissible] for swipe-to-delete
/// and adding [onTap] for tap-to-edit navigation (ROW-01 / ROW-02).
///
/// Pure data-driven: all display values computed from [TaggedTransaction] by caller.
/// Replicates [HomeTransactionTile] layout verbatim with the addition of a time
/// sub-label (D-09: date is in the day-group header, tile shows HH:mm only).
///
/// Navigation on tap is handled by the [onTap] callback injected by the parent,
/// which pushes the edit screen and invalidates the list on save. Provider
/// invalidation after delete is delegated to [onDeleted] (parent owns the
/// filter context needed for the calendar totals provider).
class ListTransactionTile extends ConsumerWidget {
  const ListTransactionTile({
    super.key,
    required this.taggedTx,
    required this.bookId,
    required this.onTap,
    required this.onDeleted,
    required this.tagText,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.category,
    required this.categoryColor,
    required this.formattedAmount,
    required this.formattedTime,
    this.satisfactionIcon,
  });

  final TaggedTransaction taggedTx;
  final String bookId;

  /// Tap callback injected by parent (pushes the edit screen + reactive refresh).
  final VoidCallback onTap;

  /// Called after a confirmed swipe-delete fires, so the parent can invalidate
  /// the providers that need filter context — the transaction list AND the
  /// calendar daily totals (the tile lacks the active year/month). Without this
  /// the calendar header would show stale totals until the month is changed.
  final VoidCallback onDeleted;

  // Pre-formatted display values injected by parent (pure-UI contract)
  final String tagText;
  final Color tagBgColor;
  final Color tagTextColor;
  final String category;
  final Color categoryColor;
  final String formattedAmount;

  /// Time-only string (D-09: e.g. "14:32"); date is in [ListDayGroupHeader].
  final String formattedTime;

  /// Optional satisfaction icon for soul-ledger rows (ADR-014 mapping).
  final IconData? satisfactionIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(taggedTx.transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: AppColors.card, size: 20),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            S.of(context).listDeleteConfirmTitle,
            style: AppTextStyles.titleSmall,
          ),
          content: Text(
            S.of(context).listDeleteConfirmBody,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                S.of(context).listDeleteCancelButton,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                S.of(context).listDeleteConfirmButton,
                style: AppTextStyles.titleSmall.copyWith(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        // CRITICAL order: ScaffoldMessenger BEFORE any provider calls (context still valid here)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).listDeletedSnackBar),
          ),
        );
        // Fire-and-forget: do NOT await inside onDismissed
        ref
            .read(deleteTransactionUseCaseProvider)
            .execute(taggedTx.transaction.id);
        // Parent invalidates list + calendar totals (needs active year/month).
        onDeleted();
      },
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(
            children: [
              // Tag badge
              Container(
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Text(
                  tagText,
                  style: AppTextStyles.micro.copyWith(color: tagTextColor),
                ),
              ),
              const SizedBox(width: 8),
              // Info column: merchant + category/time row
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taggedTx.transaction.merchant ??
                          taggedTx.transaction.note ??
                          '—',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    // Category + satisfactionIcon on left, time on right (D-09)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category,
                              style: AppTextStyles.caption.copyWith(
                                color: categoryColor,
                              ),
                            ),
                            if (satisfactionIcon != null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                satisfactionIcon,
                                size: 14,
                                color: AppColors.soul,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          formattedTime,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount — amountSmall with tabular figures (SC#1)
              Text(
                formattedAmount,
                style: AppTextStyles.amountSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formats transaction timestamp to time-only string (HH:mm) per D-09.
///
/// Used by parent (ListScreen) when building [ListTransactionTile.formattedTime].
/// Uses [intl.DateFormat] directly — [DateFormatter.formatDateTime] includes date.
String formatTransactionTime(DateTime timestamp, Locale locale) {
  return DateFormat('HH:mm', locale.toString()).format(timestamp);
}

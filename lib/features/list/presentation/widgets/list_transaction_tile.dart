import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart'
    show deleteTransactionUseCaseProvider;
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../domain/models/tagged_transaction.dart';

/// List tile wrapping the transaction row in a [Dismissible] for swipe-to-delete
/// and adding [onTap] for tap-to-edit navigation (ROW-01 / ROW-02).
///
/// Pure data-driven: all display values computed from [TaggedTransaction] by caller.
///
/// Layout:
/// - LEADING: enlarged, vertically-centered L1 category icon
/// - LEFT primary row: L2 category name + optional joy emoji
/// - LEFT secondary row: ledger type badge (background pill) + optional merchant
/// - RIGHT: amount only (no time label)
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
    required this.l1Icon,
    required this.locale,
    this.merchant,
    this.satisfactionIcon,
    this.showDate = false,
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

  /// L1 category icon resolved by parent (static icon map in list_screen.dart).
  final IconData l1Icon;

  /// Optional merchant name to display on the secondary row.
  final String? merchant;

  /// Locale used for date formatting when [showDate] is true.
  final Locale locale;

  /// Optional satisfaction icon for joy-ledger rows (ADR-014 mapping).
  final IconData? satisfactionIcon;

  /// When true, the tile title shows "short date + L2 category" (amount-sort
  /// flat mode). When false (default), the title shows the L2 category only.
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return Dismissible(
      key: ValueKey(taggedTx.transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: palette.card, size: 20),
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
              color: palette.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                S.of(context).listDeleteCancelButton,
                style: AppTextStyles.titleSmall.copyWith(
                  color: palette.textSecondary,
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
          SnackBar(content: Text(S.of(context).listDeletedSnackBar)),
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
              // Leading: enlarged, vertically-centered L1 category icon
              Icon(l1Icon, size: 28, color: categoryColor),
              const SizedBox(width: 12),
              // Left info column (title + ledger badge aligned to title)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary: L2 category name + optional joy emoji
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            showDate
                                ? '${DateFormatter.formatShortMonthDay(taggedTx.transaction.timestamp, locale)} $category'
                                : category,
                            style: AppTextStyles.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (satisfactionIcon != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            satisfactionIcon,
                            size: 14,
                            color: palette.joy,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Secondary: ledger badge (background pill) + optional merchant
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: tagBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          child: Text(
                            tagText,
                            style: AppTextStyles.micro.copyWith(
                              color: tagTextColor,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        if (merchant != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              merchant!,
                              style: AppTextStyles.micro.copyWith(
                                color: palette.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Member attribution chip — second trailing element, only for shadow-book rows (D-01/SC#3)
              // taggedTx.memberTag is null for own-book rows; no isOwn branch needed
              if (taggedTx.memberTag case final tag?) ...[
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
                      '${tag.emoji} ${tag.name}',
                      style: AppTextStyles.micro.copyWith(
                        color: palette.sharedText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Amount — amountSmall with tabular figures (SC#1)
              // Uses palette.textPrimary (general text, not ledger-coloured amount context)
              Text(
                formattedAmount,
                style: AppTextStyles.amountSmall.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

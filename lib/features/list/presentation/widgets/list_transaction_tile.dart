import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/satisfaction_face_icon.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
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
    this.satisfactionValue,
    this.showDate = false,
    this.foreignAnnotation,
    this.readOnly = false,
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

  /// Optional satisfaction value (1–10) for joy-ledger rows; null hides the
  /// face. Rendered as the shared [SatisfactionFaceIcon] (ADR-014 mapping).
  final int? satisfactionValue;

  /// When true, the tile title shows "short date + L2 category" (amount-sort
  /// flat mode). When false (default), the title shows the L2 category only.
  final bool showDate;

  /// DISP-02: pre-formatted original-currency annotation for FOREIGN rows
  /// (e.g. "USD 50.00"), computed by the parent (pure-UI contract — the tile
  /// never fetches or formats). Null for JPY/domestic rows, which renders the
  /// amount block byte-identically to before (CURR-04 regression protection).
  final String? foreignAnnotation;

  /// D-B3 (Phase 46): when true the tile renders READ-ONLY — no [Dismissible]
  /// swipe-to-delete wrapper and the [onTap] is suppressed. Used by the
  /// analytics category drill-down (a descriptive "where the money went" list;
  /// mutations stay on the List/entry tab). Defaults to false so the List tab
  /// behaviour is byte-identical (ROW-01/ROW-02 unchanged).
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;

    if (readOnly) {
      // No Dismissible, no tap-to-edit — pure descriptive row (D-B3). The
      // trailing chevron affordance is dropped since there is nothing to open.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: _buildRow(context, palette, showChevron: false),
      );
    }

    return Dismissible(
      key: ValueKey(taggedTx.transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: palette.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: palette.card, size: 20),
      ),
      confirmDismiss: (_) => showSoftConfirmDialog(
        context,
        title: S.of(context).listDeleteConfirmTitle,
        body: S.of(context).listDeleteConfirmBody,
        confirmLabel: S.of(context).listDeleteConfirmButton,
        cancelLabel: S.of(context).listDeleteCancelButton,
      ),
      onDismissed: (_) {
        // CRITICAL order: feedback toast BEFORE any provider calls (context still valid here)
        showSuccessFeedback(context, S.of(context).listDeletedSnackBar);
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: _buildRow(context, palette, showChevron: true),
        ),
      ),
    );
  }

  /// Shared row content used by both the swipe-enabled (List tab) and the
  /// read-only (analytics drill-down, D-B3) variants. [showChevron] gates the
  /// trailing tap affordance — false when the row is non-interactive.
  Widget _buildRow(
    BuildContext context,
    AppPalette palette, {
    required bool showChevron,
  }) {
    return Row(
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
                          ? '${DateFormatter.formatSlashMonthDay(taggedTx.transaction.timestamp, locale)} $category'
                          : category,
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (satisfactionValue != null) ...[
                    const SizedBox(width: 6),
                    SatisfactionFaceIcon(
                      value: satisfactionValue!,
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
                      style: AppTextStyles.micro.copyWith(color: tagTextColor),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              child: Text(
                '${tag.emoji} ${tag.name}',
                style: AppTextStyles.micro.copyWith(color: palette.sharedText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Amount — amountSmall with tabular figures (SC#1)
        // Uses palette.textPrimary (general text, not ledger-coloured amount context)
        //
        // DISP-02: foreign rows show a small secondary original-currency
        // annotation (labelMedium / textSecondary) under the JPY amount.
        // JPY/domestic rows render the bare Text unchanged (CURR-04 —
        // byte-identical golden, no Column wrapper introduced).
        if (foreignAnnotation == null)
          Text(
            formattedAmount,
            style: AppTextStyles.amountSmall.copyWith(
              color: palette.textPrimary,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedAmount,
                style: AppTextStyles.amountSmall.copyWith(
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                foreignAnnotation!,
                style: AppTextStyles.labelMedium.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        // 260603-nr1 #4: static tap affordance after the amount. Coexists
        // with the Dismissible swipe (it does not intercept the gesture).
        // Suppressed in read-only mode (nothing to open — D-B3).
        if (showChevron) ...[
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, size: 18, color: palette.textSecondary),
        ],
      ],
    );
  }
}

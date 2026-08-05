import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/family_transaction_attribution.dart';
import '../../../../shared/widgets/satisfaction_face_icon.dart';
import '../../../../shared/widgets/transaction_ledger_detail.dart';

/// Read-only home recent-transaction row mirroring the monthly list tile
/// (`ListTransactionTile`) layout: a leading L1 category icon, an info column
/// (L2 category name + optional joy icon over a ledger badge + optional
/// merchant), and a trailing pre-formatted amount.
///
/// Differs from the list tile by omitting the list-only affordances: no
/// swipe-to-delete (Dismissible). In family mode it shares the same payer chip
/// and avatar/category-badge treatment as the full transaction list.
///
/// Pure UI component -- all data injected via constructor.
/// Amount should be pre-formatted by the parent (e.g. "¥3,280").
class HomeTransactionTile extends StatelessWidget {
  const HomeTransactionTile({
    super.key,
    required this.l1Icon,
    required this.tagText,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.category,
    required this.categoryColor,
    required this.formattedAmount,
    required this.amountColor,
    this.merchant,
    this.satisfactionValue,
    this.foreignAnnotation,
    this.payerName,
    this.payerTone = FamilyPayerTone.primary,
    this.payerAvatarEmoji,
    this.payerAvatarImagePath,
    this.onTap,
  });

  /// Resolved L1 (parent) category icon shown as the leading glyph.
  final IconData l1Icon;

  /// Short label for the ledger badge (ledger type indicator).
  final String tagText;

  /// Background colour of the ledger badge.
  final Color tagBgColor;

  /// Text colour inside the ledger badge.
  final Color tagTextColor;

  /// L2 category name displayed as the primary line.
  final String category;

  /// Colour driving the leading icon tint (ledger accent).
  final Color categoryColor;

  /// Pre-formatted amount string (e.g. "¥3,480").
  final String formattedAmount;

  /// Colour of the amount text.
  final Color amountColor;

  /// Optional merchant / payee name shown beside the ledger badge.
  final String? merchant;

  /// Optional satisfaction value (1–10) for joy-ledger rows; null hides the
  /// face. Rendered as the shared [SatisfactionFaceIcon] (ADR-014 mapping).
  final int? satisfactionValue;

  /// Optional pre-formatted original-currency annotation for FOREIGN rows
  /// (e.g. "$12,211"), computed by the parent — mirrors `ListTransactionTile`
  /// so Home recent items show the foreign amount under the JPY amount. Null
  /// for JPY/domestic rows → the bare amount Text renders unchanged.
  final String? foreignAnnotation;

  /// Family-mode attribution. When present, the row uses the payer avatar as
  /// its leading visual and keeps the category icon as a small corner badge.
  final String? payerName;
  final FamilyPayerTone payerTone;
  final String? payerAvatarEmoji;
  final String? payerAvatarImagePath;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        key: const Key('home-transaction-row-size'),
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              if (payerName == null)
                SizedBox(
                  width: 28,
                  child: Center(
                    child: Icon(l1Icon, size: 25, color: categoryColor),
                  ),
                )
              else
                FamilyTransactionAvatar(
                  avatarEmoji: payerAvatarEmoji ?? '',
                  avatarImagePath: payerAvatarImagePath,
                  categoryIcon: l1Icon,
                  badgeColor: satisfactionValue == null
                      ? palette.daily
                      : palette.joy,
                  badgeKey: const Key('home-family-category-badge'),
                ),
              const SizedBox(width: 12),
              // Left info column (title + ledger badge aligned to title)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary: L2 category name + optional joy icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            category,
                            style: AppTextStyles.itemTitle.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
                    const SizedBox(height: 4),
                    // Secondary: member identity + merchant in family mode;
                    // personal mode keeps the existing ledger badge.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (payerName != null) ...[
                          FamilyPayerChip(
                            key: const Key('family-payer-chip'),
                            label: payerName!,
                            tone: payerTone,
                          ),
                          const SizedBox(width: 6),
                          if (merchant != null)
                            Flexible(
                              child: Text(
                                merchant!,
                                style: AppTextStyles.supporting.copyWith(
                                  color: palette.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ] else
                          TransactionLedgerDetail(
                            tagText: tagText,
                            tagBackgroundColor: tagBgColor,
                            tagTextColor: tagTextColor,
                            supportingTextColor: palette.textSecondary,
                            merchant: merchant,
                            tagFontWeight: FontWeight.w700,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount — amountSmall with tabular figures.
              //
              // Foreign rows show a small secondary original-currency annotation
              // (labelMedium / textSecondary) under the JPY amount, mirroring
              // ListTransactionTile (DISP-02). JPY/domestic rows render the bare
              // Text unchanged.
              if (foreignAnnotation == null)
                Text(
                  formattedAmount,
                  style: AppTextStyles.numerals(
                    AppTextStyles.amountSmall.copyWith(color: amountColor),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedAmount,
                      style: AppTextStyles.numerals(
                        AppTextStyles.amountSmall.copyWith(color: amountColor),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      foreignAnnotation!,
                      style: AppTextStyles.numerals(
                        AppTextStyles.supporting.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Read-only home recent-transaction row mirroring the monthly list tile
/// (`ListTransactionTile`) layout: a leading L1 category icon, an info column
/// (L2 category name + optional joy icon over a ledger badge + optional
/// merchant), and a trailing pre-formatted amount.
///
/// Differs from the list tile by omitting the list-only affordances: no
/// swipe-to-delete (Dismissible) and no member-attribution chip — the home
/// preview is read-only.
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
    this.satisfactionIcon,
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

  /// Optional satisfaction icon for joy-ledger rows (ADR-014 mapping).
  final IconData? satisfactionIcon;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
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
                  // Primary: L2 category name + optional joy icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          category,
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
            // Amount — amountSmall with tabular figures
            Text(
              formattedAmount,
              style: AppTextStyles.amountSmall.copyWith(color: amountColor),
            ),
          ],
        ),
      ),
    );
  }
}

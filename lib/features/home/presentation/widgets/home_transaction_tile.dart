import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Individual transaction row showing a colored tag, merchant, category,
/// and formatted amount.
///
/// Pure UI component -- all data injected via constructor.
/// Amount should be pre-formatted by the parent (e.g. "\u00a53,280").
class HomeTransactionTile extends StatelessWidget {
  const HomeTransactionTile({
    super.key,
    required this.tagText,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.merchant,
    required this.category,
    required this.categoryColor,
    required this.formattedAmount,
    required this.amountColor,
    this.satisfactionIcon,
    this.onTap,
  });

  /// Short label for the tag (person initial or ledger type indicator).
  final String tagText;

  /// Background colour of the tag container.
  final Color tagBgColor;

  /// Text colour inside the tag.
  final Color tagTextColor;

  /// Merchant / payee name.
  final String merchant;

  /// Category label displayed below the merchant.
  final String category;

  /// Colour of the category label.
  final Color categoryColor;

  /// Pre-formatted amount string (e.g. "\u00a53,480").
  final String formattedAmount;

  /// Colour of the amount text.
  final Color amountColor;

  /// Optional satisfaction icon for joy-ledger rows (ADR-014 mapping).
  final IconData? satisfactionIcon;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            // Tag
            Container(
              decoration: BoxDecoration(
                color: tagBgColor,
                borderRadius: BorderRadius.circular(3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              child: Text(
                tagText,
                style: AppTextStyles.micro.copyWith(color: tagTextColor),
              ),
            ),
            const SizedBox(width: 8),
            // Info column — satisfactionIcon is inline-right of category text
            // (not after amount) to keep joy and daily row heights identical.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
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
                        Icon(satisfactionIcon, size: 14, color: context.palette.joy),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Amount only — icon has moved to the category row above
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

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';

/// Individual transaction row showing a colored tag, merchant, category,
/// and formatted amount.
///
/// Pure UI component -- all data injected via constructor.
/// Amount should be pre-formatted by the parent (e.g. "-\u00a53,280").
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

  /// Pre-formatted amount string (e.g. "-\u00a53,480").
  final String formattedAmount;

  /// Colour of the amount text.
  final Color amountColor;

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
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.wmTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: AppTextStyles.caption.copyWith(color: categoryColor),
                  ),
                ],
              ),
            ),
            // Amount
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

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../accounting/domain/models/transaction.dart';

/// Individual transaction row showing icon, merchant, tag, and amount.
///
/// Pure UI component -- data injected via constructor.
/// Amount should be pre-formatted by the parent (e.g. "-\u00a53,280").
class HomeTransactionTile extends StatelessWidget {
  const HomeTransactionTile({
    super.key,
    required this.merchant,
    required this.categoryLabel,
    required this.formattedAmount,
    required this.ledgerType,
    required this.iconData,
    this.onTap,
  });

  final String merchant;
  final String categoryLabel;
  final String formattedAmount;
  final LedgerType ledgerType;
  final IconData iconData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSoul = ledgerType == LedgerType.soul;
    final metaColor = isSoul ? AppColors.soul : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.survivalLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(iconData, size: 18, color: AppColors.survival),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(merchant, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    categoryLabel,
                    style: AppTextStyles.bodySmall.copyWith(color: metaColor),
                  ),
                ],
              ),
            ),
            // Amount
            Text(formattedAmount, style: AppTextStyles.amountMedium),
          ],
        ),
      ),
    );
  }
}

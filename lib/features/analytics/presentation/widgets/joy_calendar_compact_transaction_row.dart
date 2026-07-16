import 'package:flutter/material.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../accounting/domain/models/transaction.dart';

/// Readable compact transaction row for the expanded Joy calendar day.
class JoyCalendarCompactTransactionRow extends StatelessWidget {
  const JoyCalendarCompactTransactionRow({
    super.key,
    required this.transaction,
    required this.locale,
  });

  final Transaction transaction;
  final Locale locale;

  static const double rowHeight = 52;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final category = CategoryLocalizationService.resolveFromId(
      transaction.categoryId,
      locale,
    );
    final merchant = transaction.merchant?.trim();
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Icon(
              _resolveL1IconForCategory(transaction.categoryId),
              size: 18,
              color: palette.joyText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                if (merchant != null && merchant.isNotEmpty)
                  Text(
                    merchant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.supporting.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            NumberFormatter.formatCurrency(transaction.amount, 'JPY', locale),
            style: AppTextStyles.amountSmall.copyWith(
              fontSize: AppTypography.label,
              height: AppTypography.labelLineHeight / AppTypography.label,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _resolveL1IconForCategory(String categoryId) {
    const iconMap = <String, IconData>{
      'cat_food': Icons.restaurant,
      'cat_daily': Icons.local_mall,
      'cat_transport': Icons.directions_bus,
      'cat_hobbies': Icons.sports_esports,
      'cat_clothing': Icons.checkroom,
      'cat_social': Icons.people,
      'cat_health': Icons.local_hospital,
      'cat_education': Icons.school,
      'cat_utilities': Icons.flash_on,
      'cat_communication': Icons.phone_iphone,
      'cat_housing': Icons.home,
      'cat_car': Icons.directions_car,
      'cat_tax': Icons.account_balance,
      'cat_insurance': Icons.security,
      'cat_special': Icons.star,
      'cat_savings': Icons.savings,
      'cat_other': Icons.more_horiz,
    };
    if (!categoryId.startsWith('cat_')) return Icons.category;
    final withoutPrefix = categoryId.substring(4);
    final parts = withoutPrefix.split('_');
    return iconMap['cat_${parts.first}'] ?? Icons.category;
  }
}

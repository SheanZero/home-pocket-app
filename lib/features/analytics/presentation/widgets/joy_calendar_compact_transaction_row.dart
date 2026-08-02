import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../accounting/domain/models/category.dart';
import '../../../accounting/domain/models/transaction.dart';
import '../../../accounting/presentation/utils/category_display_utils.dart';

/// Readable compact transaction row for the expanded Joy calendar day.
class JoyCalendarCompactTransactionRow extends StatelessWidget {
  const JoyCalendarCompactTransactionRow({
    super.key,
    required this.transaction,
    required this.locale,
    this.category,
    this.parentCategory,
  });

  final Transaction transaction;
  final Locale locale;
  final Category? category;
  final Category? parentCategory;

  static const double rowHeight = 52;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final categoryName = categoryNameForDisplay(
      categoryId: transaction.categoryId,
      category: category,
      locale: locale,
    );
    final merchant = transaction.merchant?.trim();
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Icon(
              parentCategory != null
                  ? resolveCategoryIcon(parentCategory!.icon)
                  : category != null
                  ? parentCategoryIconForCategory(category!)
                  : parentCategoryIconFromId(transaction.categoryId),
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
                  categoryName,
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
}

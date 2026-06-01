import 'package:flutter/material.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../domain/models/analytics_aggregate.dart';

/// STATSUI-06 story card for the largest total-ledger expense this month.
class LargestExpenseStoryCard extends StatelessWidget {
  const LargestExpenseStoryCard({
    super.key,
    required this.expense,
    required this.currencyCode,
    required this.locale,
    this.onTap,
  });

  final LargestMonthlyExpense? expense;
  final String currencyCode;
  final Locale locale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final expense = this.expense;

    return Card(
      color: AppColors.daily.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.daily.withValues(alpha: 0.20)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: expense == null ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.analyticsCardTitleLargestExpense,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.daily,
                ),
              ),
              const SizedBox(height: 8),
              if (expense == null)
                Text(
                  l10n.analyticsCardEmptyLargestExpense,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.wmTextSecondary,
                  ),
                )
              else
                _LargestExpenseBody(
                  expense: expense,
                  currencyCode: currencyCode,
                  locale: locale,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargestExpenseBody extends StatelessWidget {
  const _LargestExpenseBody({
    required this.expense,
    required this.currencyCode,
    required this.locale,
  });

  final LargestMonthlyExpense expense;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    const formatter = FormatterService();
    final categoryName = CategoryLocalizationService.resolveFromId(
      expense.categoryId,
      locale,
    );
    final amountText = formatter.formatCurrency(
      expense.amount,
      currencyCode,
      locale,
    );
    final dateLabel = DateFormatter.formatShortMonthDay(
      expense.timestamp,
      locale,
    );

    return Semantics(
      label: '$categoryName $amountText $dateLabel',
      child: Text(
        l10n.analyticsCardLargestExpenseBody(
          categoryName,
          amountText,
          dateLabel,
        ),
        style: AppTextStyles.bodyMedium.copyWith(color: context.wmTextPrimary),
      ),
    );
  }
}

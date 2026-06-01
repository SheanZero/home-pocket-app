import 'package:flutter/material.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/monthly_report.dart';

/// STATSUI-07 — 総支出 KPI tile for the mini-hero strip.
class TotalSpendingKpiTile extends StatelessWidget {
  const TotalSpendingKpiTile({
    super.key,
    required this.report,
    required this.currencyCode,
    required this.locale,
  });

  final MonthlyReport report;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final amountText = const FormatterService().formatCurrency(
      report.totalExpenses,
      currencyCode,
      locale,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.wmSurvivalTagBg,
        border: Border.all(color: AppColors.daily.withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.analyticsKpiTotalLabel,
            style: AppTextStyles.caption.copyWith(color: AppColors.daily),
          ),
          const SizedBox(height: 4),
          Text(
            amountText,
            style: AppTextStyles.amountLarge.copyWith(
              color: context.wmTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Displays the monthly expense total with a trend badge showing
/// month-over-month change, and a last-month summary row.
///
/// Pure UI component -- all data injected via constructor.
class MonthOverviewCard extends StatelessWidget {
  const MonthOverviewCard({
    super.key,
    required this.totalExpense,
    required this.previousMonthTotal,
    this.onLastMonthTap,
  });

  final int totalExpense;
  final int previousMonthTotal;
  final VoidCallback? onLastMonthTap;

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      symbol: '\u00a5',
      decimalDigits: 0,
    ).format(totalExpense);

    final prevFormatted = NumberFormat.currency(
      symbol: '\u00a5',
      decimalDigits: 0,
    ).format(previousMonthTotal);

    final trend = previousMonthTotal > 0
        ? ((totalExpense - previousMonthTotal) / previousMonthTotal * 100)
              .round()
        : 0;
    final trendText = trend <= 0 ? '$trend%' : '+$trend%';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          _buildTopRow(formatted, trendText, trend),
          const SizedBox(height: 16),
          _buildLastMonthRow(prevFormatted),
        ],
      ),
    );
  }

  Widget _buildTopRow(String formatted, String trendText, int trend) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(formatted, style: AppTextStyles.amountLarge),
        _buildTrendBadge(trendText, trend),
      ],
    );
  }

  Widget _buildTrendBadge(String trendText, int trend) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.oliveLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trend <= 0 ? Icons.trending_down : Icons.trending_up,
            size: 14,
            color: AppColors.olive,
          ),
          const SizedBox(width: 4),
          Text(
            trendText,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.olive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastMonthRow(String prevFormatted) {
    return GestureDetector(
      onTap: onLastMonthTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundSubtle,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '\u5148\u6708: $prevFormatted',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

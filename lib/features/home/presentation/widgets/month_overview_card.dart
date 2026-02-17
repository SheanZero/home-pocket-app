import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Displays the monthly expense overview with survival/soul breakdown
/// and a month-over-month comparison bar chart.
///
/// Pure UI component -- all data injected via constructor.
class MonthOverviewCard extends StatelessWidget {
  const MonthOverviewCard({
    super.key,
    required this.totalExpense,
    required this.survivalExpense,
    required this.soulExpense,
    required this.previousMonthTotal,
    required this.currentMonthNumber,
    required this.previousMonthNumber,
    required this.modeBadgeText,
    this.child,
  });

  final int totalExpense;
  final int survivalExpense;
  final int soulExpense;
  final int previousMonthTotal;
  final int currentMonthNumber;
  final int previousMonthNumber;
  final String modeBadgeText;

  /// Optional child widget rendered below the comparison section (e.g. SoulFullnessCard).
  final Widget? child;

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      symbol: '\u00a5',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 8),
            _buildMetrics(l10n),
            const SizedBox(height: 8),
            _buildComparison(l10n),
            if (child != null) ...[
              const SizedBox(height: 12),
              child!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(S l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l10n.homeMonthlyExpense, style: AppTextStyles.titleMedium),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.modeBadgeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            modeBadgeText,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.survival,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics(S l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_formatCurrency(totalExpense), style: AppTextStyles.amountLarge),
        const SizedBox(height: 6),
        _buildMetricRow(l10n.homeSurvivalExpense, survivalExpense),
        const SizedBox(height: 6),
        _buildMetricRow(l10n.homeSoulExpense, soulExpense),
      ],
    );
  }

  Widget _buildMetricRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          _formatCurrency(amount),
          style: AppTextStyles.amountMedium.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildComparison(S l10n) {
    final maxAmount = totalExpense > previousMonthTotal
        ? totalExpense
        : previousMonthTotal;
    final delta = previousMonthTotal > 0
        ? ((totalExpense - previousMonthTotal) / previousMonthTotal * 100)
        : 0.0;
    final deltaStr = delta <= 0
        ? '${delta.toStringAsFixed(1)}%'
        : '+${delta.toStringAsFixed(1)}%';

    return Column(
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.homeMonthComparison, style: AppTextStyles.labelMedium),
            Row(
              children: [
                Icon(
                  delta <= 0 ? Icons.trending_down : Icons.trending_up,
                  size: 12,
                  color: AppColors.comparisonPositive,
                ),
                const SizedBox(width: 4),
                Text(
                  deltaStr,
                  style: AppTextStyles.comparisonDelta.copyWith(
                    fontFeatures: AppTextStyles.amountLarge.fontFeatures,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Current month bar
        _buildBarRow(
          l10n.homeMonthLabel(currentMonthNumber),
          survivalExpense,
          soulExpense,
          totalExpense,
          maxAmount,
          isCurrent: true,
        ),
        const SizedBox(height: 6),
        // Previous month bar
        _buildBarRow(
          l10n.homeMonthLabel(previousMonthNumber),
          // For previous month, show the total as the bar
          previousMonthTotal,
          0,
          previousMonthTotal,
          maxAmount,
          isCurrent: false,
        ),
        const SizedBox(height: 6),
        // Legend
        _buildLegend(l10n),
      ],
    );
  }

  Widget _buildBarRow(
    String label,
    int survivalPart,
    int soulPart,
    int total,
    int maxTotal, {
    required bool isCurrent,
  }) {
    final fraction = maxTotal > 0 ? total / maxTotal : 0.0;
    final survivalFraction = total > 0
        ? survivalPart / total
        : (isCurrent ? 1.0 : 1.0);

    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(label, style: AppTextStyles.labelSmall),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * fraction;
              final survivalWidth = barWidth * survivalFraction;
              final soulWidth = barWidth - survivalWidth;

              return Container(
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.survivalBarBg,
                  borderRadius: BorderRadius.circular(3),
                ),
                clipBehavior: Clip.hardEdge,
                child: Row(
                  children: [
                    Container(
                      width: survivalWidth.clamp(0, constraints.maxWidth),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.survival
                            : AppColors.previousBarSurvival,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          bottomLeft: Radius.circular(3),
                        ),
                      ),
                    ),
                    if (soulWidth > 0)
                      Container(
                        width: soulWidth.clamp(0, constraints.maxWidth),
                        color: isCurrent
                            ? AppColors.currentBarSoul
                            : AppColors.previousBarSoul,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _formatCurrency(total),
          style: isCurrent
              ? AppTextStyles.amountSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                )
              : AppTextStyles.amountSmall,
        ),
      ],
    );
  }

  Widget _buildLegend(S l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _legendDot(AppColors.survival, l10n.homeSurvivalExpense),
        const SizedBox(width: 10),
        _legendDot(AppColors.soul, l10n.homeSoulExpense),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.legendLabel),
      ],
    );
  }
}

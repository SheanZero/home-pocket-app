import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';

/// Displays soul spending satisfaction, happiness ROI, and recent soul amount.
///
/// Pure UI component -- no providers, no navigation.
class SoulFullnessCard extends StatelessWidget {
  const SoulFullnessCard({
    super.key,
    required this.satisfactionPercent,
    required this.happinessROI,
    required this.recentSoulAmount,
    this.onTap,
  });

  final int satisfactionPercent;
  final double happinessROI;
  final int recentSoulAmount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.wmCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.wmBorderDefault),
        ),
        child: Column(
          children: [
            _buildTitleRow(context),
            const SizedBox(height: 12),
            _buildMetricRow(context),
            const SizedBox(height: 12),
            Container(height: 1, color: context.wmBackgroundDivider),
            const SizedBox(height: 12),
            _buildRecentSpendingRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '灵魂の充実度',
          style: AppTextStyles.bodyLarge.copyWith(color: context.wmTextPrimary),
        ),
        Icon(Icons.chevron_right, size: 14, color: context.wmTextTertiary),
      ],
    );
  }

  Widget _buildMetricRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildSatisfactionTile(context)),
        const SizedBox(width: 8),
        Expanded(child: _buildROITile(context)),
      ],
    );
  }

  Widget _buildSatisfactionTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
      decoration: BoxDecoration(
        color: context.wmSatisfactionBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.wmSatisfactionBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 14,
                color: AppColors.accentPrimary,
              ),
              const SizedBox(height: 2),
              Text(
                '満足度',
                style: AppTextStyles.micro.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.accentPrimary,
                ),
              ),
            ],
          ),
          Text(
            '$satisfactionPercent%',
            style: AppTextStyles.amountMedium.copyWith(
              color: AppColors.accentPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildROITile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
      decoration: BoxDecoration(
        color: context.wmRoiBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.wmRoiBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const Icon(Icons.bolt, size: 14, color: AppColors.olive),
              const SizedBox(height: 2),
              Text(
                '幸福ROI',
                style: AppTextStyles.micro.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.olive,
                ),
              ),
            ],
          ),
          Text(
            '${happinessROI}x',
            style: AppTextStyles.amountMedium.copyWith(color: AppColors.olive),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSpendingRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '最近の灵魂支出',
          style: AppTextStyles.caption.copyWith(color: context.wmTextSecondary),
        ),
        Text(
          NumberFormat.currency(
            symbol: '\u00a5',
            decimalDigits: 0,
          ).format(recentSoulAmount),
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.survival,
          ),
        ),
      ],
    );
  }
}

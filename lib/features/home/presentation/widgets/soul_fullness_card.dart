import 'package:flutter/material.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';

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
    final l10n = S.of(context);
    final locale = Localizations.localeOf(context);

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
            _buildTitleRow(context, l10n),
            const SizedBox(height: 12),
            _buildMetricRow(context, l10n),
            const SizedBox(height: 12),
            Container(height: 1, color: context.wmBackgroundDivider),
            const SizedBox(height: 12),
            _buildRecentSpendingRow(context, l10n, locale),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, S l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.homeSoulFullness,
          style: AppTextStyles.bodyLarge.copyWith(color: context.wmTextPrimary),
        ),
        Icon(Icons.chevron_right, size: 14, color: context.wmTextTertiary),
      ],
    );
  }

  Widget _buildMetricRow(BuildContext context, S l10n) {
    return Row(
      children: [
        Expanded(child: _buildSatisfactionTile(context, l10n)),
        const SizedBox(width: 8),
        Expanded(child: _buildROITile(context, l10n)),
      ],
    );
  }

  Widget _buildSatisfactionTile(BuildContext context, S l10n) {
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
                l10n.satisfactionLevel,
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

  Widget _buildROITile(BuildContext context, S l10n) {
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
                l10n.homeHappinessROI,
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

  Widget _buildRecentSpendingRow(BuildContext context, S l10n, Locale locale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          l10n.homeRecentSoulExpense,
          style: AppTextStyles.caption.copyWith(color: context.wmTextSecondary),
        ),
        Text(
          const FormatterService().formatCurrency(
            recentSoulAmount,
            'JPY',
            locale,
          ),
          style: AppTextStyles.amountMedium.copyWith(color: AppColors.survival),
        ),
      ],
    );
  }
}

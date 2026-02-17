import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Displays the soul spending ratio, happiness ROI, progress bar,
/// and recent soul transaction.
///
/// Pure UI component -- no providers, no navigation.
class SoulFullnessCard extends StatelessWidget {
  const SoulFullnessCard({
    super.key,
    required this.soulPercentage,
    required this.happinessROI,
    required this.fullnessLevel,
    required this.recentMerchant,
    required this.recentAmount,
    required this.recentQuote,
  });

  final int soulPercentage;
  final double happinessROI;
  final int fullnessLevel;
  final String recentMerchant;
  final int recentAmount;
  final String recentQuote;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.soulCardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n),
          const SizedBox(height: 6),
          _buildChargeCard(l10n),
          const SizedBox(height: 6),
          _buildMetricRow(l10n),
          const SizedBox(height: 6),
          _buildRecentTransaction(l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(S l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.homeSoulFullness,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.soulTextDark,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.soulBadgeBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            l10n.homeMonthBadge(fullnessLevel),
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.soulTextDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChargeCard(S l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.soulLight, AppColors.soulBadgeBg],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.battery_charging_full,
                size: 20,
                color: AppColors.soul,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.homeSoulChargeStatus(fullnessLevel, happinessROI),
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.soulTextDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.soulProgressBg,
              borderRadius: BorderRadius.circular(999),
            ),
            clipBehavior: Clip.hardEdge,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (fullnessLevel / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.soul,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(S l10n) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.soulMetricBg1,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeSoulPercentLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.soulTextMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$soulPercentage%',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.soul,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.soulMetricBg2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeHappinessROI,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.soulTextMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${happinessROI}x',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.soul,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransaction(S l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeRecentSoulTransaction(recentMerchant, recentAmount),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.soulTextDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"$recentQuote"',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.soulQuoteText,
            ),
          ),
        ],
      ),
    );
  }
}

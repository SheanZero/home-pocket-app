import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/happiness_report.dart';
import '../../domain/models/metric_result.dart';

/// STATSUI-03/STATSUI-07 — 悦己平均 KPI tile for the mini-hero strip.
class JoyHeadlineKpiTile extends StatelessWidget {
  const JoyHeadlineKpiTile({
    super.key,
    required this.report,
    required this.locale,
  });

  final HappinessReport report;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final (
      :primaryText,
      :ratedCount,
      :hasAverage,
    ) = switch (report.avgSatisfaction) {
      Empty() => (
        primaryText: l10n.analyticsKpiJoyEmptyCaption,
        ratedCount: 0,
        hasAverage: false,
      ),
      Value(:final data, :final sampleSize) => (
        primaryText: data.toStringAsFixed(1),
        ratedCount: sampleSize,
        hasAverage: true,
      ),
    };
    final medianText = switch (report.medianSatisfaction) {
      Empty() => '—',
      Value(:final data) => data.toStringAsFixed(1),
    };

    return Semantics(
      label:
          '悦己 ${l10n.analyticsKpiJoyLabel} $primaryText n=$ratedCount/${report.totalSoulTx}',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.wmSoulTagBg,
          border: Border.all(color: AppColors.soul.withValues(alpha: 0.20)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.analyticsKpiJoyLabel,
              style: AppTextStyles.caption.copyWith(color: AppColors.soul),
            ),
            const SizedBox(height: 4),
            Text(
              primaryText,
              style:
                  (hasAverage
                          ? AppTextStyles.amountLarge
                          : AppTextStyles.caption)
                      .copyWith(color: context.wmTextPrimary),
            ),
            if (hasAverage || report.totalSoulTx > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.analyticsKpiJoySubMedianCoverage(
                  medianText,
                  ratedCount,
                  report.totalSoulTx,
                ),
                style: AppTextStyles.caption.copyWith(
                  color: context.wmTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

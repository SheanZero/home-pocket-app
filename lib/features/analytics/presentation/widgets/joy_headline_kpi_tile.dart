import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/joy_cumulative_formatter.dart';
import '../../domain/models/happiness_report.dart';
import '../../domain/models/metric_result.dart';

/// STATSUI-03/STATSUI-07 — 悦己平均 KPI tile for the mini-hero strip.
class JoyHeadlineKpiTile extends StatelessWidget {
  const JoyHeadlineKpiTile({
    super.key,
    required this.report,
    required this.currencyCode,
    required this.locale,
  });

  final HappinessReport report;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final (
      :primaryText,
      :ratedCount,
      :hasJoyContribution,
    ) = switch (report.joyContribution) {
      Empty() => (
        primaryText: l10n.analyticsKpiJoyIndexEmptyCaption,
        ratedCount: 0,
        hasJoyContribution: false,
      ),
      Value(:final data, :final sampleSize) => (
        primaryText: formatJoyCumulative(data, currencyCode),
        ratedCount: sampleSize,
        hasJoyContribution: true,
      ),
    };
    final medianText = switch (report.medianSatisfaction) {
      Empty() => '—',
      Value(:final data) => data.toStringAsFixed(1),
    };

    return Semantics(
      label: l10n.analyticsKpiJoyIndexSemantics(
        l10n.analyticsKpiJoyIndexLabel,
        primaryText,
        ratedCount,
        report.totalSoulTx,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.palette.joyLight,
          border: Border.all(color: context.palette.joy.withValues(alpha: 0.20)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.analyticsKpiJoyIndexLabel,
              style: AppTextStyles.caption.copyWith(color: context.palette.joy),
            ),
            const SizedBox(height: 4),
            Text(
              primaryText,
              style:
                  (hasJoyContribution
                          ? AppTextStyles.amountLarge
                          : AppTextStyles.caption)
                      .copyWith(color: context.palette.textPrimary),
            ),
            if (hasJoyContribution || report.totalSoulTx > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.analyticsKpiJoyIndexSubMedianCoverage(
                  medianText,
                  ratedCount,
                  report.totalSoulTx,
                ),
                style: AppTextStyles.caption.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

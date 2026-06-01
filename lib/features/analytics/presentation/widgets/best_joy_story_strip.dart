import 'package:flutter/material.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../domain/models/best_joy_moment_row.dart';
import '../../domain/models/metric_result.dart';

/// STATSUI-02 Best Joy story strip.
///
/// D-14: this is intentionally separate from HomeHeroCard's Best Joy strip.
class BestJoyStoryStrip extends StatelessWidget {
  const BestJoyStoryStrip({
    super.key,
    required this.bestJoy,
    required this.currencyCode,
    required this.locale,
    this.onTap,
  });

  final MetricResult<BestJoyMomentRow> bestJoy;
  final String currencyCode;
  final Locale locale;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Card(
      color: AppColors.soul.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.soul.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsCardTitleBestJoy,
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.soul),
            ),
            const SizedBox(height: 8),
            switch (bestJoy) {
              Empty<BestJoyMomentRow>() => _buildEmpty(context, l10n),
              Value<BestJoyMomentRow>(:final data)
                  when data.joyFullness <= 2 =>
                _buildEmpty(context, l10n),
              Value<BestJoyMomentRow>(:final data) => _BestJoyValue(
                row: data,
                currencyCode: currencyCode,
                locale: locale,
                onTap: onTap,
              ),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, S l10n) {
    return Text(
      l10n.analyticsCardEmptyBestJoy,
      style: AppTextStyles.bodyMedium.copyWith(color: context.wmTextSecondary),
    );
  }
}

class _BestJoyValue extends StatelessWidget {
  const _BestJoyValue({
    required this.row,
    required this.currencyCode,
    required this.locale,
    required this.onTap,
  });

  final BestJoyMomentRow row;
  final String currencyCode;
  final Locale locale;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    const formatter = FormatterService();
    final categoryName = CategoryLocalizationService.resolveFromId(
      row.categoryId,
      locale,
    );
    final dateLabel = DateFormatter.formatShortMonthDay(row.timestamp, locale);
    final amountText = formatter.formatCurrency(
      row.amount,
      currencyCode,
      locale,
    );

    return Semantics(
      label: '$categoryName ${row.joyFullness}/10 $amountText $dateLabel',
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(row.transactionId),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.analyticsCardBestJoyBig(categoryName, dateLabel),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.wmTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.analyticsCardSmallBestJoy(
                  amountText,
                  row.joyFullness,
                ),
                style: AppTextStyles.caption.copyWith(
                  color: context.wmTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

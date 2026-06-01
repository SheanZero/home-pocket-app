import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/time_window.dart';
import '../providers/state_time_window.dart';
import 'time_window_picker_sheet.dart';

/// AppBar action chip for the AnalyticsScreen active time window.
class TimeWindowChip extends ConsumerWidget {
  const TimeWindowChip({super.key, required this.locale, this.earliestData});

  final Locale locale;
  final DateTime? earliestData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final window = ref.watch(selectedTimeWindowProvider);
    final label = _labelFor(window, l10n, locale);

    return Tooltip(
      message: l10n.analyticsTimeWindowChipTooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => TimeWindowPickerSheet.show(
            context,
            ref,
            earliestData: earliestData,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.palette.card,
                border: Border.all(color: context.palette.borderDefault),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.palette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '▼',
                      style: AppTextStyles.caption.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _labelFor(TimeWindow window, S l10n, Locale locale) {
    const fmt = FormatterService();

    return switch (window) {
      MonthWindow(:final year, :final month) => fmt.formatMonthYear(
        DateTime(year, month),
        locale,
      ),
      YearWindow(:final year) => l10n.analyticsTimeWindowChipLabelYear(
        year.toString(),
      ),
      QuarterWindow(:final year, :final quarter) =>
        l10n.analyticsTimeWindowChipLabelQuarter(
          quarter.toString(),
          year.toString(),
        ),
      WeekWindow(:final mondayStart) => l10n.analyticsTimeWindowChipLabelWeek(
        fmt.formatShortMonthDay(mondayStart, locale),
      ),
      CustomWindow(:final startDate, :final endDate) =>
        l10n.analyticsTimeWindowChipLabelCustom(
          fmt.formatShortMonthDay(startDate, locale),
          fmt.formatShortMonthDay(endDate, locale),
        ),
    };
  }
}

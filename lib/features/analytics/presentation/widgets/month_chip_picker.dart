import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/time_window.dart';
import '../providers/state_time_window.dart';

/// STATSUI-07 — AppBar trailing month chip.
///
/// The widget accepts [earliestMonth] as an optional boundary because this leaf
/// widget must not reach into DAOs. Callers that know the earliest transaction
/// month can pass it; otherwise the picker exposes a bounded 12-month window.
class MonthChipPicker extends ConsumerWidget {
  const MonthChipPicker({
    super.key,
    required this.locale,
    this.earliestMonth,
    this.currentMonth,
  });

  final Locale locale;
  final DateTime? earliestMonth;
  final DateTime? currentMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final selectedWindow = ref.watch(selectedTimeWindowProvider);
    final selectedRange = selectedWindow.range;
    final selectedMonth = _monthOnly(selectedRange.end);
    final label = const FormatterService().formatMonthYear(
      selectedMonth,
      locale,
    );

    return Tooltip(
      message: l10n.analyticsTimeWindowChipTooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _openPicker(context, ref, selectedMonth),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.wmCard,
                border: Border.all(color: context.wmBorderDefault),
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
                        color: context.wmTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '▼',
                      style: AppTextStyles.caption.copyWith(
                        color: context.wmTextSecondary,
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

  Future<void> _openPicker(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedMonth,
  ) async {
    final latest = _monthOnly(currentMonth ?? DateTime.now());
    final earliest = _monthOnly(
      earliestMonth ?? DateTime(latest.year, latest.month - 12),
    );
    final months = _boundedMonths(earliest: earliest, latest: latest);

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final month in months.reversed)
                ListTile(
                  title: Text(
                    const FormatterService().formatMonthYear(month, locale),
                  ),
                  selected: _sameMonth(month, selectedMonth),
                  onTap: () => Navigator.of(sheetContext).pop(month),
                ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      ref
          .read(selectedTimeWindowProvider.notifier)
          .setWindow(TimeWindow.month(year: picked.year, month: picked.month));
    }
  }

  static DateTime _monthOnly(DateTime date) => DateTime(date.year, date.month);

  static bool _sameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static List<DateTime> _boundedMonths({
    required DateTime earliest,
    required DateTime latest,
  }) {
    final months = <DateTime>[];
    var cursor = earliest;
    while (!cursor.isAfter(latest)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }
}

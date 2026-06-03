import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../domain/models/time_window.dart';
import '../providers/state_time_window.dart';

enum _TimeWindowType { week, month, quarter, year, custom }

/// Bottom-sheet entry point for choosing the AnalyticsScreen time window.
class TimeWindowPickerSheet {
  const TimeWindowPickerSheet._();

  /// Shows the selector sheet.
  ///
  /// [pickRangeOverride] is a widget-test seam for the Material date-range
  /// picker. Production callers leave it null.
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    DateTime? earliestData,
    Future<DateTimeRange?> Function(BuildContext, DateTime, DateTime)?
    pickRangeOverride,
  }) async {
    final selectedWindow = ref.read(selectedTimeWindowProvider);
    final picked = await showModalBottomSheet<TimeWindow>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _SheetBody(
          selectedWindow: selectedWindow,
          earliestData: earliestData,
          pickRangeOverride: pickRangeOverride,
        );
      },
    );

    if (picked != null) {
      ref.read(selectedTimeWindowProvider.notifier).setWindow(picked);
    }
  }
}

class _SheetBody extends StatefulWidget {
  const _SheetBody({
    required this.selectedWindow,
    required this.earliestData,
    required this.pickRangeOverride,
  });

  final TimeWindow selectedWindow;
  final DateTime? earliestData;
  final Future<DateTimeRange?> Function(BuildContext, DateTime, DateTime)?
  pickRangeOverride;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  late _TimeWindowType _type = _typeFor(widget.selectedWindow);

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsTimeWindowSheetTitle,
              style: AppTextStyles.titleSmall.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _TimeWindowTypeRow(
              selectedType: _type,
              onSelected: (type) => setState(() => _type = type),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 360, child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return switch (_type) {
      _TimeWindowType.week => _buildWeekList(context),
      _TimeWindowType.month => _buildMonthList(context),
      _TimeWindowType.quarter => _buildQuarterList(context),
      _TimeWindowType.year => _buildYearList(context),
      _TimeWindowType.custom => _buildCustomBody(context),
    };
  }

  Widget _buildWeekList(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final l10n = S.of(context);
    const fmt = FormatterService();
    final weeks = _weekStarts();

    return ListView.builder(
      itemCount: weeks.length,
      itemBuilder: (context, index) {
        final monday = weeks[index];
        final window = TimeWindow.week(mondayStart: monday);
        final selected = _sameWindow(window, widget.selectedWindow);
        return _WindowListTile(
          selected: selected,
          title: l10n.analyticsTimeWindowChipLabelWeek(
            fmt.formatShortMonthDay(monday, locale),
          ),
          onTap: () => Navigator.of(context).pop(window),
        );
      },
    );
  }

  Widget _buildMonthList(BuildContext context) {
    final locale = Localizations.localeOf(context);
    const fmt = FormatterService();
    final months = _months();

    return ListView.builder(
      itemCount: months.length,
      itemBuilder: (context, index) {
        final month = months[index];
        final window = TimeWindow.month(year: month.year, month: month.month);
        final selected = _sameWindow(window, widget.selectedWindow);
        return _WindowListTile(
          selected: selected,
          title: fmt.formatMonthYear(month, locale),
          onTap: () => Navigator.of(context).pop(window),
        );
      },
    );
  }

  Widget _buildQuarterList(BuildContext context) {
    final l10n = S.of(context);
    final quarters = _quarters();

    return ListView.builder(
      itemCount: quarters.length,
      itemBuilder: (context, index) {
        final quarter = quarters[index];
        final window = TimeWindow.quarter(
          year: quarter.year,
          quarter: quarter.quarter,
        );
        final selected = _sameWindow(window, widget.selectedWindow);
        return _WindowListTile(
          selected: selected,
          title: l10n.analyticsTimeWindowChipLabelQuarter(
            quarter.quarter.toString(),
            quarter.year.toString(),
          ),
          onTap: () => Navigator.of(context).pop(window),
        );
      },
    );
  }

  Widget _buildYearList(BuildContext context) {
    final l10n = S.of(context);
    final years = _years();

    return ListView.builder(
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final window = TimeWindow.year(year: year);
        final selected = _sameWindow(window, widget.selectedWindow);
        return _WindowListTile(
          selected: selected,
          title: l10n.analyticsTimeWindowChipLabelYear(year.toString()),
          onTap: () => Navigator.of(context).pop(window),
        );
      },
    );
  }

  Widget _buildCustomBody(BuildContext context) {
    final l10n = S.of(context);

    return Center(
      child: ElevatedButton(
        onPressed: () => _pickCustomRange(context),
        child: Text(l10n.analyticsTimeWindowCustomCta),
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = _today();
    final firstDate = _firstDate(now);
    final picker =
        widget.pickRangeOverride ??
        (BuildContext ctx, DateTime first, DateTime last) {
          return showDateRangePicker(
            context: ctx,
            firstDate: first,
            lastDate: last,
          );
        };
    final result = await picker(context, firstDate, now);
    if (result == null || !context.mounted) {
      return;
    }

    final start = result.start;
    final end = result.end;
    final l10n = S.of(context);
    if (start.isAfter(end)) {
      _showError(context, l10n.analyticsTimeWindowErrorInverted);
      return;
    }

    final months = (end.year - start.year) * 12 + (end.month - start.month);
    if (months > 12 || (months == 12 && end.day > start.day)) {
      _showError(context, l10n.analyticsTimeWindowErrorTooLong);
      return;
    }

    if (end.isAfter(now)) {
      _showError(context, l10n.analyticsTimeWindowErrorFutureEnd);
      return;
    }

    Navigator.of(
      context,
    ).pop(TimeWindow.custom(startDate: start, endDate: end));
  }

  void _showError(BuildContext context, String message) {
    showErrorFeedback(context, message);
  }

  List<DateTime> _weekStarts() {
    final now = _today();
    final currentMonday = _mondayOf(now);
    final earliest = _mondayOf(widget.earliestData ?? DateTime(now.year - 1));
    final weeks = <DateTime>[];
    var cursor = currentMonday;
    while (!cursor.isBefore(earliest)) {
      weeks.add(cursor);
      cursor = cursor.subtract(const Duration(days: 7));
    }
    return weeks;
  }

  List<DateTime> _months() {
    final now = _today();
    final latest = DateTime(now.year, now.month);
    final earliest = _monthOnly(
      widget.earliestData ?? DateTime(latest.year, latest.month - 12),
    );
    final months = <DateTime>[];
    var cursor = latest;
    while (!cursor.isBefore(earliest)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month - 1);
    }
    return months;
  }

  List<({int year, int quarter})> _quarters() {
    final now = _today();
    final earliest = widget.earliestData ?? DateTime(now.year - 11);
    final earliestQuarter = _quarterOf(earliest.month);
    final quarters = <({int year, int quarter})>[];
    var year = now.year;
    var quarter = _quarterOf(now.month);
    while (year > earliest.year ||
        (year == earliest.year && quarter >= earliestQuarter)) {
      quarters.add((year: year, quarter: quarter));
      quarter -= 1;
      if (quarter == 0) {
        quarter = 4;
        year -= 1;
      }
    }
    return quarters;
  }

  List<int> _years() {
    final now = _today();
    final earliestYear = widget.earliestData?.year ?? now.year - 11;
    return [for (var year = now.year; year >= earliestYear; year--) year];
  }

  DateTime _firstDate(DateTime now) {
    final fallback = DateTime(2000);
    final candidate = widget.earliestData ?? fallback;
    final dateOnly = DateTime(candidate.year, candidate.month, candidate.day);
    return dateOnly.isAfter(now) ? now : dateOnly;
  }

  static _TimeWindowType _typeFor(TimeWindow window) {
    return switch (window) {
      WeekWindow() => _TimeWindowType.week,
      MonthWindow() => _TimeWindowType.month,
      QuarterWindow() => _TimeWindowType.quarter,
      YearWindow() => _TimeWindowType.year,
      CustomWindow() => _TimeWindowType.custom,
    };
  }

  static bool _sameWindow(TimeWindow a, TimeWindow b) => a == b;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _mondayOf(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime _monthOnly(DateTime date) => DateTime(date.year, date.month);

  static int _quarterOf(int month) => ((month - 1) ~/ 3) + 1;
}

class _TimeWindowTypeRow extends StatelessWidget {
  const _TimeWindowTypeRow({
    required this.selectedType,
    required this.onSelected,
  });

  final _TimeWindowType selectedType;
  final ValueChanged<_TimeWindowType> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final items = [
      (_TimeWindowType.week, l10n.analyticsTimeWindowTypeWeek),
      (_TimeWindowType.month, l10n.analyticsTimeWindowTypeMonth),
      (_TimeWindowType.quarter, l10n.analyticsTimeWindowTypeQuarter),
      (_TimeWindowType.year, l10n.analyticsTimeWindowTypeYear),
      (_TimeWindowType.custom, l10n.analyticsTimeWindowTypeCustom),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            ChoiceChip(
              label: Text(item.$2),
              selected: item.$1 == selectedType,
              selectedColor: context.palette.accentPrimary,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: context.palette.borderDefault),
              labelStyle: AppTextStyles.titleSmall.copyWith(
                color: item.$1 == selectedType
                    ? Colors.white
                    : context.palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => onSelected(item.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _WindowListTile extends StatelessWidget {
  const _WindowListTile({
    required this.selected,
    required this.title,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedColor: context.palette.accentPrimary,
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: selected ? context.palette.accentPrimary : context.palette.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

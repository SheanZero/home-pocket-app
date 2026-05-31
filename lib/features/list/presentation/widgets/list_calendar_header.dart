import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/settings/domain/models/app_settings.dart';
import '../../../../features/settings/presentation/providers/state_settings.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../providers/state_calendar_totals.dart';
import '../providers/state_list_filter.dart';

/// Normalizes a DateTime to date-only key (strips time-of-day).
///
/// Must agree with the _dayKey in state_calendar_totals.dart to ensure
/// provider map keys and cell lookup keys match.
DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar header widget showing a full-month grid with per-day expense
/// amounts and a summary row with month total + optional day subline.
///
/// Month navigation and the month label have moved to the [ListScreen]
/// AppBar (Task 1). This widget owns only the calendar grid and summary row.
///
/// Reads [calendarDailyTotalsProvider] for per-day totals and
/// [listFilterProvider] for month/day selection state.
///
/// Parameters are passed from [ListScreen] to avoid import-guard risk from
/// reading bookByIdProvider (analytics/home feature) inside the list feature.
class CalendarHeaderWidget extends ConsumerWidget {
  const CalendarHeaderWidget({
    super.key,
    required this.bookId,
    required this.currencyCode, // Phase 29: resolve from bookByIdProvider
    required this.locale,
  });

  final String bookId;
  final String currencyCode;
  final Locale locale;

  /// Weekend numeral/header colors by true weekday — explicitly specified.
  static const Color _saturdayColor = Color(0xFF1565C0); // Material Blue 800
  static const Color _sundayColor = Color(0xFFD32F2F); // Material Red 700

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final filter = ref.watch(listFilterProvider);
    // Read weekStartDay from persisted settings (default: monday).
    final settingsAsync = ref.watch(appSettingsProvider);
    final weekStartDay = settingsAsync.value?.weekStartDay ?? WeekStartDay.monday;
    final calendarAsync = ref.watch(
      calendarDailyTotalsProvider(
        bookId: bookId,
        year: filter.selectedYear,
        month: filter.selectedMonth,
      ),
    );

    // Pass value ?? {} so cells render date numerals during loading/error
    final dailyMap = calendarAsync.value ?? {};

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TableCalendar(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: DateTime(filter.selectedYear, filter.selectedMonth),
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: ''},
          headerVisible: false,
          rowHeight: 44,
          daysOfWeekHeight: 18,
          locale: locale.toLanguageTag(),
          startingDayOfWeek: weekStartDay == WeekStartDay.monday
              ? StartingDayOfWeek.monday
              : StartingDayOfWeek.sunday,
          selectedDayPredicate: (day) => isSameDay(day, filter.activeDayFilter),
          onDaySelected: (selectedDay, focusedDay) =>
              _onDayTapped(ref, selectedDay),
          onPageChanged: (focusedDay) {
            ref
                .read(listFilterProvider.notifier)
                .selectMonth(focusedDay.year, focusedDay.month);
          },
          calendarBuilders: CalendarBuilders(
            // Color the day-of-week header labels to match the date numerals:
            // Saturday blue, Sunday red, weekdays neutral (by true weekday).
            dowBuilder: (context, day) {
              final Color color = switch (day.weekday) {
                DateTime.saturday => _saturdayColor,
                DateTime.sunday => _sundayColor,
                _ => AppColors.textSecondary,
              };
              return Center(
                child: Text(
                  DateFormatter.formatShortWeekday(day, locale),
                  style: AppTextStyles.caption.copyWith(color: color),
                ),
              );
            },
            defaultBuilder: (context, day, focusedDay) =>
                _buildDayCell(day, dailyMap, filter.activeDayFilter, false),
            todayBuilder: (context, day, focusedDay) =>
                _buildDayCell(day, dailyMap, filter.activeDayFilter, false),
            selectedBuilder: (context, day, focusedDay) =>
                _buildDayCell(day, dailyMap, filter.activeDayFilter, false),
            outsideBuilder: (context, day, focusedDay) =>
                _buildDayCell(day, dailyMap, filter.activeDayFilter, true),
          ),
        ),
        _SummaryRow(
          l10n: l10n,
          calendarAsync: calendarAsync,
          dailyMap: dailyMap,
          activeDayFilter: filter.activeDayFilter,
          currencyCode: currencyCode,
          locale: locale,
        ),
      ],
    );
  }

  /// Builds a custom day cell widget.
  Widget _buildDayCell(
    DateTime day,
    Map<DateTime, int> dailyMap,
    DateTime? activeDayFilter,
    bool isOutside,
  ) {
    final isSelected =
        activeDayFilter != null && isSameDay(day, activeDayFilter);
    final isToday = !isOutside && isSameDay(day, DateTime.now());
    final dayTotal = isOutside ? 0 : (dailyMap[_dayKey(day)] ?? 0);

    // Decoration — only the actively selected day gets a filled chip.
    // No "today" frame/background (removed per request).
    final BoxDecoration? decoration = isSelected
        ? BoxDecoration(
            color: AppColors.accentPrimary,
            borderRadius: BorderRadius.circular(6),
          )
        : null;

    // Weekend colors by true weekday (not column position)
    final Color baseNumeralColor = switch (day.weekday) {
      DateTime.saturday => _saturdayColor,
      DateTime.sunday => _sundayColor,
      _ => AppColors.textPrimary,
    };
    final numeralColor = isSelected ? AppColors.card : baseNumeralColor;
    final amountColor = isSelected ? AppColors.card : AppColors.textSecondary;

    return Opacity(
      opacity: isOutside ? 0.35 : 1.0,
      child: Container(
        decoration: decoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              // Today: lightweight marker — bold numeral (+ dot below), no box.
              style: AppTextStyles.bodySmall.copyWith(
                color: numeralColor,
                fontWeight: isToday ? FontWeight.w700 : null,
              ),
            ),
            // Fixed-height sub-slot so numerals align across the row regardless
            // of whether a cell shows an amount / today dot / nothing.
            SizedBox(
              height: 14, // matches AppTextStyles.micro line height
              child: Center(
                child: dayTotal > 0 && !isOutside
                    ? Text(
                        NumberFormatter.formatCompact(dayTotal, locale),
                        style:
                            AppTextStyles.micro.copyWith(color: amountColor),
                      )
                    : isToday
                        ? Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.card
                                  : AppColors.accentPrimary,
                            ),
                          )
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles day tap with toggle logic (CAL-03).
  void _onDayTapped(WidgetRef ref, DateTime selectedDay) {
    final notifier = ref.read(listFilterProvider.notifier);
    final current = ref.read(listFilterProvider).activeDayFilter;
    if (current != null && isSameDay(current, selectedDay)) {
      notifier.selectDay(null);
    } else {
      notifier.selectDay(selectedDay);
    }
  }
}

/// Summary row below the calendar showing month total + optional day subline.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.l10n,
    required this.calendarAsync,
    required this.dailyMap,
    required this.activeDayFilter,
    required this.currencyCode,
    required this.locale,
  });

  final S l10n;
  final AsyncValue<Map<DateTime, int>> calendarAsync;
  final Map<DateTime, int> dailyMap;
  final DateTime? activeDayFilter;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderDivider, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month total line — always visible
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.calMonthTotal,
                  style: AppTextStyles.caption,
                ),
                calendarAsync.when(
                  loading: () => const SizedBox(
                    width: 60,
                    height: 15,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundMuted,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                  error: (e, st) => Text(
                    l10n.calLoadError,
                    style: AppTextStyles.caption,
                  ),
                  data: (map) => Text(
                    NumberFormatter.formatCurrency(
                      map.values.fold(0, (a, b) => a + b),
                      currencyCode,
                      locale,
                    ),
                    style: AppTextStyles.amountSmall,
                  ),
                ),
              ],
            ),
            // Day subline — animated, visible only when activeDayFilter != null
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: activeDayFilter != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormatter.formatShortMonthDay(
                              activeDayFilter!,
                              locale,
                            ),
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            NumberFormatter.formatCurrency(
                              dailyMap[_dayKey(activeDayFilter!)] ?? 0,
                              currencyCode,
                              locale,
                            ),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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

/// Calendar header widget showing month navigation, full-month grid with
/// per-day expense amounts, and a summary row with month total + optional
/// day subline.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final filter = ref.watch(listFilterProvider);
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
        _MonthNavBar(
          filter: filter,
          locale: locale,
          onPrevMonth: () {
            final prev = DateTime(filter.selectedYear, filter.selectedMonth - 1);
            ref
                .read(listFilterProvider.notifier)
                .selectMonth(prev.year, prev.month);
          },
          onNextMonth: () {
            final next = DateTime(filter.selectedYear, filter.selectedMonth + 1);
            ref
                .read(listFilterProvider.notifier)
                .selectMonth(next.year, next.month);
          },
          onLabelTap: () {
            final now = DateTime.now();
            ref
                .read(listFilterProvider.notifier)
                .selectMonth(now.year, now.month);
          },
        ),
        TableCalendar(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: DateTime(filter.selectedYear, filter.selectedMonth),
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: ''},
          headerVisible: false,
          rowHeight: 52,
          daysOfWeekHeight: 20,
          locale: locale.toLanguageTag(),
          startingDayOfWeek: _startingDay(locale),
          selectedDayPredicate: (day) => isSameDay(day, filter.activeDayFilter),
          onDaySelected: (selectedDay, focusedDay) =>
              _onDayTapped(ref, selectedDay),
          onPageChanged: (focusedDay) {
            ref
                .read(listFilterProvider.notifier)
                .selectMonth(focusedDay.year, focusedDay.month);
          },
          calendarBuilders: CalendarBuilders(
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

  /// Returns the locale-appropriate starting day of week.
  StartingDayOfWeek _startingDay(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return StartingDayOfWeek.monday;
      default:
        // ja + zh: Sunday-start by convention
        return StartingDayOfWeek.sunday;
    }
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
    final isToday = isSameDay(day, DateTime.now());
    final dayTotal = isOutside ? 0 : (dailyMap[_dayKey(day)] ?? 0);

    // Decoration
    BoxDecoration? decoration;
    if (isSelected) {
      decoration = BoxDecoration(
        color: AppColors.accentPrimary,
        borderRadius: BorderRadius.circular(6),
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        color: AppColors.accentPrimaryLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accentPrimaryBorder, width: 1),
      );
    }

    // Colors
    final numeralColor = isSelected ? AppColors.card : AppColors.textPrimary;
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
              style: AppTextStyles.bodySmall.copyWith(color: numeralColor),
            ),
            if (dayTotal > 0 && !isOutside)
              Text(
                NumberFormatter.formatCompact(dayTotal, locale),
                style: AppTextStyles.micro.copyWith(color: amountColor),
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

/// Month navigation bar: left chevron, centered month label, right chevron.
class _MonthNavBar extends StatelessWidget {
  const _MonthNavBar({
    required this.filter,
    required this.locale,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onLabelTap,
  });

  final dynamic filter;
  final Locale locale;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onLabelTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          label: S.of(context).listCalNavPrev,
          child: SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(Icons.chevron_left),
              iconSize: 24,
              color: AppColors.textTertiary,
              onPressed: onPrevMonth,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            label: S.of(context).listCalNavCurrentMonth,
            child: GestureDetector(
              onTap: onLabelTap,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Text(
                  DateFormatter.formatMonthYear(
                    DateTime(filter.selectedYear, filter.selectedMonth),
                    locale,
                  ),
                  style: AppTextStyles.titleMedium,
                ),
              ),
            ),
          ),
        ),
        Semantics(
          label: S.of(context).listCalNavNext,
          child: SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(Icons.chevron_right),
              iconSize: 24,
              color: AppColors.textTertiary,
              onPressed: onNextMonth,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart'
    show LedgerType;
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
/// Month navigation and the month label live in the custom [ListScreen]
/// header. This widget owns only the calendar grid and summary row.
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
    final palette = context.palette;
    final l10n = S.of(context);
    final filter = ref.watch(listFilterProvider);
    // Read weekStartDay from persisted settings (default: monday).
    final settingsAsync = ref.watch(appSettingsProvider);
    final weekStartDay =
        settingsAsync.value?.weekStartDay ?? WeekStartDay.monday;
    final calendarAsync = ref.watch(
      calendarDailyTotalsProvider(
        bookId: bookId,
        year: filter.selectedYear,
        month: filter.selectedMonth,
      ),
    );

    // Pass value ?? {} so cells render date numerals during loading/error
    final dailyMap = calendarAsync.value ?? {};

    // v15 `.list-calendar`: bordered, rounded card wrapping the grid + summary.
    return Container(
      key: const Key('list-calendar-card'),
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderDefault, width: 1),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? palette.navShadow.withValues(alpha: 0.18)
                : palette.navShadow.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 3),
            child: TableCalendar(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2030, 12, 31),
              focusedDay: DateTime(filter.selectedYear, filter.selectedMonth),
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: ''},
              headerVisible: false,
              rowHeight: 44,
              daysOfWeekHeight: 20,
              locale: locale.toLanguageTag(),
              startingDayOfWeek: weekStartDay == WeekStartDay.monday
                  ? StartingDayOfWeek.monday
                  : StartingDayOfWeek.sunday,
              selectedDayPredicate: (day) =>
                  isSameDay(day, filter.activeDayFilter),
              enabledDayPredicate: (day) =>
                  day.year == filter.selectedYear &&
                  day.month == filter.selectedMonth,
              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.year != filter.selectedYear ||
                    selectedDay.month != filter.selectedMonth) {
                  return;
                }
                _onDayTapped(ref, selectedDay);
              },
              onPageChanged: (focusedDay) {
                ref
                    .read(listFilterProvider.notifier)
                    .selectMonth(focusedDay.year, focusedDay.month);
              },
              calendarBuilders: CalendarBuilders(
                // Color the day-of-week header labels to match the date numerals:
                // weekends (Sat + Sun) blue, weekdays neutral (by true weekday).
                dowBuilder: (context, day) {
                  final bool isWeekend =
                      day.weekday == DateTime.saturday ||
                      day.weekday == DateTime.sunday;
                  final Color color = isWeekend
                      ? context.palette.info
                      : context.palette.textSecondary;
                  return Center(
                    child: Text(
                      DateFormatter.formatShortWeekday(day, locale),
                      style: AppTextStyles.compact.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) => _buildDayCell(
                  palette,
                  day,
                  dailyMap,
                  filter.activeDayFilter,
                  false,
                ),
                todayBuilder: (context, day, focusedDay) => _buildDayCell(
                  palette,
                  day,
                  dailyMap,
                  filter.activeDayFilter,
                  false,
                ),
                selectedBuilder: (context, day, focusedDay) => _buildDayCell(
                  palette,
                  day,
                  dailyMap,
                  filter.activeDayFilter,
                  false,
                ),
                // `table_calendar` resolves disabled cells before outside
                // cells. Reuse our day cell here so non-current-month dates
                // keep the same typography and geometry while remaining
                // non-interactive through enabledDayPredicate.
                disabledBuilder: (context, day, focusedDay) => _buildDayCell(
                  palette,
                  day,
                  dailyMap,
                  filter.activeDayFilter,
                  day.year != filter.selectedYear ||
                      day.month != filter.selectedMonth,
                ),
                outsideBuilder: (context, day, focusedDay) => _buildDayCell(
                  palette,
                  day,
                  dailyMap,
                  filter.activeDayFilter,
                  true,
                ),
              ),
            ),
          ),
          _SummaryRow(
            l10n: l10n,
            calendarAsync: calendarAsync,
            dailyMap: dailyMap,
            activeDayFilter: filter.activeDayFilter,
            ledgerType: filter.ledgerType,
            currencyCode: currencyCode,
            locale: locale,
          ),
        ],
      ),
    );
  }

  /// Builds a custom day cell widget.
  Widget _buildDayCell(
    AppPalette palette,
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
            color: palette.accentPrimary,
            borderRadius: BorderRadius.circular(6),
          )
        : null;

    // Weekend (Sat + Sun) numerals use palette.info (Bucket F → D-07).
    final bool isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final Color baseNumeralColor = isWeekend
        ? palette.info
        : palette.textPrimary;
    // Precedence: selected chip > today (error/red) > weekend (info/blue) > default.
    final numeralColor = isSelected
        ? palette.card
        : (isToday ? palette.error : baseNumeralColor);
    final amountColor = isSelected ? palette.card : palette.textSecondary;

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
              // Today: marked by bold red numeral (no box, no dot).
              style: AppTextStyles.compact.copyWith(
                color: numeralColor,
                fontWeight: isToday ? FontWeight.w700 : null,
              ),
            ),
            // Fixed-height sub-slot so numerals align across the row regardless
            // of whether a cell shows an amount.
            SizedBox(
              height: AppTypography.compactLineHeight,
              child: Center(
                child: dayTotal > 0 && !isOutside
                    ? Text(
                        NumberFormatter.formatCompact(dayTotal, locale),
                        style: AppTextStyles.compact.copyWith(
                          fontWeight: FontWeight.w500,
                          color: amountColor,
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
    required this.ledgerType,
    required this.currencyCode,
    required this.locale,
  });

  final S l10n;
  final AsyncValue<Map<DateTime, int>> calendarAsync;
  final Map<DateTime, int> dailyMap;
  final DateTime? activeDayFilter;
  final LedgerType? ledgerType;
  final String currencyCode;
  final Locale locale;

  /// Month-total label that swaps with the selected ledger (quick 260714-qit):
  /// null (すべて) → 今月の合計, daily → 日常の合計, joy → ときめきの合計.
  String get _summaryLabel => switch (ledgerType) {
    LedgerType.daily => l10n.calMonthTotalDaily,
    LedgerType.joy => l10n.calMonthTotalJoy,
    null => l10n.calMonthTotal,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.borderDivider, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month total line — always visible
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_summaryLabel, style: AppTextStyles.supporting),
                calendarAsync.when(
                  loading: () => SizedBox(
                    width: 60,
                    height: 15,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.backgroundMuted,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  error: (e, st) =>
                      Text(l10n.calLoadError, style: AppTextStyles.caption),
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
                            style: AppTextStyles.compact,
                          ),
                          Text(
                            NumberFormatter.formatCurrency(
                              dailyMap[_dayKey(activeDayFilter!)] ?? 0,
                              currencyCode,
                              locale,
                            ),
                            style: AppTextStyles.compact,
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

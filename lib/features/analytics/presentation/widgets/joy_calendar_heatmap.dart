import 'package:flutter/material.dart';

import '../../../../core/theme/analytics_category_palette.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// 小确幸日历 — a CUSTOM month heatmap grid (R-2, GATE-04).
///
/// NOT fl_chart: a 7-column [GridView] month grid. Each day cell's color is a
/// DISCRETE `f(per-day joy COUNT)` heat bucket (`AnalyticsCategoryPalette.heat`,
/// round-5 r5 §2d — 0→heat0, 1→heat1, 2→heat2, ≥3→heat3), explicitly NOT a streak
/// / consecutive-days indicator (ADR-016 §5). Days with 0 joy render heat0.
///
/// The grid leads with a Monday-first weekday header row and the correct weekday
/// offset for day 1 (transparent leading cells), then renders exactly the anchored
/// month's day count, with a discrete-heat legend + cal-cap below. Tapping a day
/// cell fires
/// [onDayTap]; the parent holds the [selectedDay] and renders the inline panel
/// (D-C1 — the card grows in place, NOT a sheet/route).
class JoyCalendarHeatmap extends StatelessWidget {
  const JoyCalendarHeatmap({
    super.key,
    required this.anchor,
    required this.countByDay,
    required this.onDayTap,
    this.selectedDay,
  });

  /// The month being shown (DateTime(year, month)).
  final DateTime anchor;

  /// Per day-of-month (1..31) → joy COUNT (笔数). Days absent = 0 joy.
  final Map<int, int> countByDay;

  /// Called with the tapped day (DateTime(year, month, day)).
  final ValueChanged<DateTime> onDayTap;

  /// The currently expanded day, if any (for the cell selection ring).
  final DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    final year = anchor.year;
    final month = anchor.month;
    // Days in the month: day 0 of next month = last day of this month.
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Leading blank cells = weekday of the 1st. DateTime.weekday is 1 (Mon)..7
    // (Sun); render a Monday-first grid → offset = weekday - 1.
    final firstWeekday = DateTime(year, month, 1).weekday;
    final leadingBlanks = firstWeekday - 1;

    // §2f: 本月有悦己的天数 = days with count > 0.
    final joyDays = countByDay.values.where((c) => c > 0).length;

    final cells = <Widget>[
      // §2c: leading slots are TRANSPARENT placeholders (NOT SizedBox.shrink,
      // which collapses and breaks the Monday-first column alignment). Keep them
      // keyless — a shared ValueKey across multiple GridView children collides in
      // the sliver child-element list and asserts.
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.expand(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          key: ValueKey('joy_day_$day'),
          day: day,
          count: countByDay[day] ?? 0,
          // §2d: discrete heat0..heat3 by count (NOT a continuous lerp).
          color: AnalyticsCategoryPalette.heatForCount(countByDay[day] ?? 0),
          selected:
              selectedDay != null &&
              selectedDay!.year == year &&
              selectedDay!.month == month &&
              selectedDay!.day == day,
          palette: palette,
          onTap: () => onDayTap(DateTime(year, month, day)),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // §2b: Monday-first weekday header row (mock `.wd`).
        Row(
          children: [
            for (final label in <String>[
              l10n.analyticsCalWeekdayMon,
              l10n.analyticsCalWeekdayTue,
              l10n.analyticsCalWeekdayWed,
              l10n.analyticsCalWeekdayThu,
              l10n.analyticsCalWeekdayFri,
              l10n.analyticsCalWeekdaySat,
              l10n.analyticsCalWeekdaySun,
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: palette.textTertiary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // §2c: square cells, gap 6.
          childAspectRatio: 1,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: cells,
        ),
        const SizedBox(height: 14),
        _CalLegend(palette: palette),
        // §2f: cal-cap below the legend (was previously in the deleted caption).
        const SizedBox(height: 10),
        Text(
          l10n.analyticsCalCap(joyDays),
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            height: 1.55,
            color: palette.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// A single day cell: a rounded color-depth square with the day number. Selected
/// → a contrast ring (no animation loop — D-D1 calm).
class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.day,
    required this.count,
    required this.color,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final int day;
  final int count;
  final Color color;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // §2d day-number colour: 0→tertiary; 1 (heat1)→joyText; ≥2 (heat2/heat3)→white.
    final Color dayNumberColor = count <= 0
        ? palette.textTertiary
        : count == 1
        ? palette.joyText
        : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: palette.joyText, width: 2)
              : null,
        ),
        // §2d: day number top-right (NOT centered).
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 3, right: 4),
            child: Text(
              '$day',
              style: AppTextStyles.caption.copyWith(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: dayNumberColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 淡 [4 swatches] 浓 + neutral-note heat legend below the calendar (round-5
/// r5 mock `.cal-legend`). The 4 swatches are the DISCRETE
/// `AnalyticsCategoryPalette.heat[0..3]` ramp (§2e), matching the day-cell heat
/// buckets exactly. The note says depth = per-day joy COUNT (not a streak).
class _CalLegend extends StatelessWidget {
  const _CalLegend({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    // §2e: discrete heat0..heat3 swatches (NOT a lerp).
    const swatches = AnalyticsCategoryPalette.heat;

    return Row(
      children: [
        Text(
          l10n.analyticsCalLegendLow,
          style: AppTextStyles.caption.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(width: 7),
        for (final color in swatches)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        const SizedBox(width: 7),
        Text(
          l10n.analyticsCalLegendHigh,
          style: AppTextStyles.caption.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.analyticsCalLegendNote,
            textAlign: TextAlign.end,
            style: AppTextStyles.caption.copyWith(color: palette.textTertiary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

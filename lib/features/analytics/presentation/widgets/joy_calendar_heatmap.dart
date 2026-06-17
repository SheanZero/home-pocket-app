import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 小确幸日历 — a CUSTOM month heatmap grid (R-2, GATE-04).
///
/// NOT fl_chart: a 7-column [GridView] month grid. Each day cell's color depth is
/// a CONTINUOUS `f(per-day joy COUNT)` ambient mapping (`Color.lerp(base, joy, t)`
/// — the same idiom as `satisfaction_distribution_histogram.dart`'s
/// `_colorForScore`), explicitly NOT a streak / consecutive-days indicator
/// (ADR-016 §5). Days with 0 joy render the base/empty color.
///
/// The grid leads with the correct weekday offset for day 1 (blank leading cells)
/// and renders exactly the anchored month's day count. Tapping a day cell fires
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

    final year = anchor.year;
    final month = anchor.month;
    // Days in the month: day 0 of next month = last day of this month.
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Leading blank cells = weekday of the 1st. DateTime.weekday is 1 (Mon)..7
    // (Sun); render a Monday-first grid → offset = weekday - 1.
    final firstWeekday = DateTime(year, month, 1).weekday;
    final leadingBlanks = firstWeekday - 1;
    final maxCount = countByDay.values.isEmpty
        ? 0
        : countByDay.values.reduce((a, b) => a > b ? a : b);

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          key: ValueKey('joy_day_$day'),
          day: day,
          count: countByDay[day] ?? 0,
          color: _depthColor(countByDay[day] ?? 0, maxCount, palette),
          selected:
              selectedDay != null &&
              selectedDay!.year == year &&
              selectedDay!.month == month &&
              selectedDay!.day == day,
          palette: palette,
          onTap: () => onDayTap(DateTime(year, month, day)),
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Slightly wider-than-tall cells keep the 6-row month grid compact so the
      // card stays a reasonable height (it lives inside the analytics scroll).
      childAspectRatio: 1.3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }

  /// Continuous ambient depth: 0 joy → base; more joy → toward the joy hue.
  /// NOT a streak (the depth is a per-day count function, not consecutive-days).
  Color _depthColor(int count, int maxCount, AppPalette palette) {
    if (count <= 0) return palette.backgroundMuted;
    if (maxCount <= 0) return palette.backgroundMuted;
    final t = count / maxCount;
    return Color.lerp(palette.joyLight, palette.joy, t)!;
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: selected
              ? Border.all(color: palette.joyText, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: AppTextStyles.caption.copyWith(
              color: count > 0 ? palette.joyText : palette.textSecondary,
              fontWeight: count > 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

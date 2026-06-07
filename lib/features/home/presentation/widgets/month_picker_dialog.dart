import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Shows a centered rounded-card month-grid picker.
///
/// Returns the chosen `(year, month)` record, or `null` if dismissed.
/// Future months (and the future-year nav arrow) are disabled so callers can
/// never select a month past the current real-world month — preserving the
/// `HomeSelectedMonth.nextMonth()` clamp semantics (quick 260607-jrz).
Future<({int year, int month})?> showMonthPickerDialog(
  BuildContext context, {
  required int selectedYear,
  required int selectedMonth,
}) {
  return showDialog<({int year, int month})>(
    context: context,
    builder: (_) => _MonthPickerDialog(
      selectedYear: selectedYear,
      selectedMonth: selectedMonth,
    ),
  );
}

/// Centered rounded-card month picker: `‹ YYYY年 ›` year nav + 3×4 month grid.
///
/// Pure UI — no provider reads. Pops with the chosen `(year, month)` record so
/// the caller decides what to do with the selection.
class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({
    required this.selectedYear,
    required this.selectedMonth,
  });

  final int selectedYear;
  final int selectedMonth;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _displayYear = widget.selectedYear;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final now = DateTime.now();
    final canGoNextYear = _displayYear < now.year;

    return Dialog(
      backgroundColor: palette.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Year nav row: ‹ YYYY年 › ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: palette.accentPrimary),
                  onPressed: () => setState(() => _displayYear--),
                ),
                Text(
                  l10n.analyticsTimeWindowChipLabelYear(_displayYear.toString()),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: palette.accentPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: canGoNextYear
                        ? palette.accentPrimary
                        : palette.textTertiary,
                  ),
                  onPressed: canGoNextYear
                      ? () => setState(() => _displayYear++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── 3×4 month grid ──
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: [
                for (var month = 1; month <= 12; month++)
                  _MonthCell(
                    label: l10n.homeMonthLabel(month),
                    isSelected:
                        _displayYear == widget.selectedYear &&
                        month == widget.selectedMonth,
                    isDisabled:
                        _displayYear == now.year && month > now.month,
                    onTap: () => Navigator.of(
                      context,
                    ).pop((year: _displayYear, month: month)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tappable month cell.
///
/// Selected → neutral pill (`backgroundMuted`). Disabled → greyed
/// (`textTertiary`), non-tappable. Normal → transparent, tappable.
class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Color textColor = isDisabled
        ? palette.textTertiary
        : palette.textPrimary;

    final cell = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? palette.backgroundMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(color: textColor),
      ),
    );

    if (isDisabled) return cell;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: cell,
    );
  }
}

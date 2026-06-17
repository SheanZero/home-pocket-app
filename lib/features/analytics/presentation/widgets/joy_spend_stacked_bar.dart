import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// One pre-resolved segment for the 悦己花在哪 horizontal stacked bar.
///
/// Pure-UI value carrier (the card pre-formats `label` + `amount` strings and
/// resolves the segment `color`), mirroring the donut card's pure-UI legend-row
/// contract — the bar widget never fetches, localizes, or formats.
@immutable
class JoySpendSegment {
  const JoySpendSegment({
    required this.label,
    required this.amount,
    required this.formattedAmount,
    required this.percent,
    required this.color,
  });

  /// Localized L1 category name (resolved by the card).
  final String label;

  /// Raw joy amount (minor units) — the `Flexible.flex` weight.
  final int amount;

  /// Pre-formatted ¥ amount string.
  final String formattedAmount;

  /// Whole-percent share of the joy total.
  final int percent;

  /// Distinct warm sakura-anchored segment hue (resolved by the card).
  final Color color;
}

/// 悦己花在哪 — a CUSTOM horizontal stacked segmented bar (R-1, GATE-04).
///
/// NOT fl_chart: the bar is a single horizontal [Row] of `Flexible(flex: amount)`
/// [DecoratedBox] segments, ordered largest→smallest by the caller. Below it a
/// single-column legend mirrors `category_spend_donut_chart.dart`'s dot+label
/// idiom (each row: swatch + category + ¥ + %).
///
/// Tapping a segment sets a LOCAL [selectedIndex] (no navigation, no provider
/// invalidation — D-C2 no drill) and highlights BOTH the tapped segment (raised
/// opacity / border) and its matching legend row (scaled / emphasized). Tapping
/// another segment moves the highlight; tapping the selected one clears it.
///
/// Ambient celebrate-past: amounts only — zero target/progress/streak/ranking/
/// cross-period (ADR-012 / ADR-016 §5).
class JoySpendStackedBar extends StatefulWidget {
  const JoySpendStackedBar({super.key, required this.segments});

  final List<JoySpendSegment> segments;

  @override
  State<JoySpendStackedBar> createState() => JoySpendStackedBarState();
}

class JoySpendStackedBarState extends State<JoySpendStackedBar> {
  /// The currently highlighted segment index (local-only). `null` = none.
  int? selectedIndex;

  void _onSegmentTap(int index) {
    setState(() {
      selectedIndex = selectedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final segments = widget.segments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The custom stacked bar — Row of Flexible(flex: amount) (R-1).
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 28,
            child: Row(
              children: [
                for (final entry in segments.asMap().entries)
                  Flexible(
                    key: ValueKey('joy_spend_segment_${entry.key}'),
                    flex: entry.value.amount,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onSegmentTap(entry.key),
                      child: _Segment(
                        color: entry.value.color,
                        selected: selectedIndex == entry.key,
                        dimmed:
                            selectedIndex != null &&
                            selectedIndex != entry.key,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Single-column legend (donut dot+label idiom).
        for (final entry in segments.asMap().entries)
          _LegendRow(
            key: ValueKey('joy_spend_legend_${entry.key}'),
            segment: entry.value,
            selected: selectedIndex == entry.key,
            palette: palette,
            onTap: () => _onSegmentTap(entry.key),
          ),
      ],
    );
  }
}

/// A single bar segment. Selected → full opacity + a subtle border; a non-selected
/// segment while another is selected → dimmed (ambient highlight, no animation
/// loop — D-D1 calm).
class _Segment extends StatelessWidget {
  const _Segment({
    required this.color,
    required this.selected,
    required this.dimmed,
  });

  final Color color;
  final bool selected;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dimmed ? color.withValues(alpha: 0.45) : color,
        border: selected
            ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2)
            : null,
      ),
    );
  }
}

/// A single legend row: swatch + category name + ¥ amount + %. When [selected]
/// the row scales/emphasizes (bolder label, raised contrast).
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    super.key,
    required this.segment,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final JoySpendSegment segment;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: segment.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                segment.label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? palette.textPrimary : palette.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              segment.formattedAmount,
              style: AppTextStyles.amountSmall.copyWith(
                color: selected ? palette.joyText : palette.textPrimary,
                fontWeight: selected ? FontWeight.w700 : null,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '${segment.percent}%',
                textAlign: TextAlign.end,
                style: AppTextStyles.caption.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

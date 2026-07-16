import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/joy_warm_palette.dart';

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
    required this.icon,
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

  /// TI1-ICON-01: L1 (top-level) category icon, resolved by the card via the
  /// shared `parentCategoryIconFromId` helper. Rendered before the legend-row
  /// label; the colored bar segment itself carries no icon.
  final IconData icon;
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
    // Pink bar border — same lerp the drawer uses for its border (mock .joybar
    // border:1px solid var(--joyBorder)).
    final barBorder = Color.lerp(palette.joy, palette.joyLight, 0.55)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The custom stacked bar — Row of Expanded(flex: amount). Expanded (TIGHT
        // fit) is the fix: Flexible was loose, so the zero-intrinsic-width segments
        // collapsed to 0 and the whole bar was invisible (root cause).
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: JoyWarmPalette.cream,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: barBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                for (final entry in segments.asMap().entries)
                  Expanded(
                    key: ValueKey('joy_spend_segment_${entry.key}'),
                    flex: entry.value.amount,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onSegmentTap(entry.key),
                      child: _Segment(
                        color: entry.value.color,
                        percent: entry.value.percent,
                        isLast: entry.key == segments.length - 1,
                        selected: selectedIndex == entry.key,
                        dimmed:
                            selectedIndex != null && selectedIndex != entry.key,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 13),
        // Single-column legend (donut dot+label idiom).
        for (final entry in segments.asMap().entries)
          _LegendRow(
            key: ValueKey('joy_spend_legend_${entry.key}'),
            segment: entry.value,
            selected: selectedIndex == entry.key,
            isLast: entry.key == segments.length - 1,
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
    required this.percent,
    required this.isLast,
    required this.selected,
    required this.dimmed,
  });

  final Color color;
  final int percent;
  final bool isLast;
  final bool selected;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    // 2px cream right divider on every segment except the last (mock
    // .seg{border-right:2px solid var(--cream)} / :last-child{border-right:0}).
    Border? border;
    if (selected) {
      border = Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2);
    } else if (!isLast) {
      border = const Border(
        right: BorderSide(color: JoyWarmPalette.cream, width: 2),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dimmed ? color.withValues(alpha: 0.45) : color,
        border: border,
      ),
      // Inline % label only on wide-enough segments (rounded percent >= 12),
      // matching the mock (.inpct shown on 25/22/19/13, hidden on 9/7/4).
      child: percent >= 12
          ? Center(
              child: Text(
                '$percent%',
                style: AppTextStyles.compact.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.02,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            )
          : null,
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
    required this.isLast,
    required this.palette,
    required this.onTap,
  });

  final JoySpendSegment segment;
  final bool selected;
  final bool isLast;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        // 1px divider under every row except the last (mock
        // .jl{border-bottom} + :last-child{border-bottom:0}). padding 垂直 7.
        decoration: isLast
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: palette.borderDivider),
                ),
              ),
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            // TI1-ICON-01: the swatch dot is dropped — the L1 category icon
            // itself now carries the segment colour (replacing the .jl .dot).
            Icon(segment.icon, size: 13, color: segment.color),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                segment.label,
                style: AppTextStyles.label.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              segment.formattedAmount,
              style: AppTextStyles.amountSmall.copyWith(
                fontSize: AppTypography.label,
                height: AppTypography.labelLineHeight / AppTypography.label,
                color: palette.joyText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              child: Text(
                '${segment.percent}%',
                textAlign: TextAlign.end,
                style: AppTextStyles.supporting.copyWith(
                  color: palette.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The active-tone of one [AnalyticsSegment] (v15 mock `.segmented-option`
/// variants). Drives the ACTIVE option's background / foreground / inset border:
///   - [primary] → solid leaf-green fill, surface text (mock default `.active`).
///   - [daily]   → daily-soft fill, daily text, 1.5px inset daily border
///     (mock `.daily.active`).
///   - [joy]     → joy-soft fill, joy text, 1.5px inset joy border
///     (mock `.joy.active`).
///   - [shared]  → solid steel-blue fill, surface text (mock `.shared.active`).
/// Inactive options are always transparent with muted text regardless of tone.
enum SegmentTone { primary, daily, joy, shared }

/// One option in an [AnalyticsSegmentedControl].
@immutable
class AnalyticsSegment<T> {
  const AnalyticsSegment({
    required this.value,
    required this.label,
    this.tone = SegmentTone.primary,
    this.optionKey,
  });

  /// The value selected when this option is tapped.
  final T value;

  /// Pre-localized option label (caller resolves via `S.of(context)`), so this
  /// control carries zero literal CJK (`hardcoded_cjk_ui_scan`).
  final String label;

  /// Active-state tinting (see [SegmentTone]).
  final SegmentTone tone;

  /// Optional key placed on the tappable option — preserved so existing widget
  /// tests that tap a specific segment (e.g. `trend_tab_daily`,
  /// `donut_dim_member`) keep resolving after the pill → segmented migration.
  final Key? optionKey;
}

/// A full-width segmented control (v15 mock `.segmented-control`).
///
/// Replaces the earlier per-tab outlined `_Pill` / `_DimPill` strips with the
/// mock's single pill-shaped container of equal-width options: a
/// `backgroundMuted` track + `borderDefault` hairline, each option pill-rounded,
/// only the ACTIVE one tinted by its [SegmentTone]. All colours resolve via
/// `context.palette` (`color_literal_scan` — the only bare literal is
/// `Colors.transparent` for inactive fills, which the scan permits) and amounts
/// are not involved. Presentation-only: selection state stays owned by the
/// caller ([selected] + [onChanged]).
class AnalyticsSegmentedControl<T> extends StatelessWidget {
  const AnalyticsSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<AnalyticsSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: 42,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: palette.backgroundMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.borderDefault),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: _SegmentOption<T>(
                key: segment.optionKey,
                segment: segment,
                active: segment.value == selected,
                palette: palette,
                onTap: () => onChanged(segment.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentOption<T> extends StatelessWidget {
  const _SegmentOption({
    super.key,
    required this.segment,
    required this.active,
    required this.palette,
    required this.onTap,
  });

  final AnalyticsSegment<T> segment;
  final bool active;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color? bg;
    final Color fg;
    final Color? insetBorder;

    if (!active) {
      bg = Colors.transparent;
      fg = palette.textSecondary;
      insetBorder = null;
    } else {
      switch (segment.tone) {
        case SegmentTone.primary:
          bg = palette.accentPrimary;
          fg = palette.card;
          insetBorder = null;
        case SegmentTone.daily:
          bg = palette.dailyLight;
          fg = palette.daily;
          insetBorder = palette.daily;
        case SegmentTone.joy:
          bg = palette.joyLight;
          fg = palette.joy;
          insetBorder = palette.joy;
        case SegmentTone.shared:
          bg = palette.shared;
          fg = palette.card;
          insetBorder = null;
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: insetBorder != null
              ? Border.all(color: insetBorder, width: 1.5)
              : null,
        ),
        child: Text(
          segment.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ),
    );
  }
}

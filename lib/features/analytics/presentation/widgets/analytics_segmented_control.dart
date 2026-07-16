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
/// Inactive options are transparent with the V15 primary text color.
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
/// mixed muted/paper track + `borderDefault` hairline, each option pill-rounded,
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

  /// Shared geometry for the readable 13px segmented label.
  static const double controlHeight = 46;
  static const double optionHeight = 40;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final trackColor = Color.alphaBlend(
      palette.backgroundMuted.withValues(alpha: 0.54),
      palette.card,
    );

    return Container(
      height: controlHeight,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.borderDefault),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 3),
            blurRadius: 12,
            color: palette.navShadow.withValues(alpha: 0.035),
          ),
        ],
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
    final List<BoxShadow> shadows;

    if (!active) {
      bg = Colors.transparent;
      fg = palette.textPrimary;
      insetBorder = null;
      shadows = const [];
    } else {
      switch (segment.tone) {
        case SegmentTone.primary:
          bg = palette.accentPrimary;
          fg = palette.card;
          insetBorder = null;
          shadows = [
            BoxShadow(
              offset: const Offset(0, 3),
              blurRadius: 10,
              color: palette.accentPrimary.withValues(alpha: 0.22),
            ),
          ];
        case SegmentTone.daily:
          bg = palette.dailyLight;
          fg = palette.daily;
          insetBorder = palette.daily;
          shadows = const [];
        case SegmentTone.joy:
          bg = palette.joyLight;
          fg = palette.joy;
          insetBorder = palette.joy;
          shadows = const [];
        case SegmentTone.shared:
          bg = Color.lerp(palette.joy, palette.shared, 0.58);
          fg = palette.card;
          insetBorder = null;
          shadows = [
            BoxShadow(
              offset: const Offset(0, 3),
              blurRadius: 10,
              color: palette.shared.withValues(alpha: 0.22),
            ),
          ];
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: AnalyticsSegmentedControl.optionHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: insetBorder != null
              ? Border.all(color: insetBorder, width: 1.5)
              : null,
          boxShadow: shadows,
        ),
        child: Text(
          segment.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Dual-ledger accent tone for a [ShoppingSegment].
///
/// Mirrors the v15 mockup `.segmented-option` tone modifiers:
/// - [accent] → active fill uses the primary leaf-green (nav/CTA tone).
/// - [daily]  → active fill `dailyLight` + `daily` text + inset ring.
/// - [joy]    → active fill `joyLight` + `joy` text + inset ring.
enum SegmentTone { accent, daily, joy }

/// A single option inside a [ShoppingSegmentedControl].
class ShoppingSegment<T> {
  const ShoppingSegment({
    required this.value,
    required this.label,
    this.tone = SegmentTone.accent,
  });

  final T value;
  final String label;
  final SegmentTone tone;
}

/// v15 warm-Japanese `.segmented-control` pill (ADR-019 桜餅×若葉).
///
/// A full-width rounded track holding N equal-width options. The selected
/// option fills with its [SegmentTone] surface; daily/joy tones add a 1.5px
/// inset ring to echo the mockup's `box-shadow: inset 0 0 0 1.5px`.
///
/// All colours resolve via `context.palette`, so the single widget renders
/// correctly under both the A1 light and A3 dark themes.
class ShoppingSegmentedControl<T> extends StatelessWidget {
  const ShoppingSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<ShoppingSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        // Muted track — mockup `color-mix(surface-muted 54%, surface)`.
        color: palette.backgroundMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.borderDefault, width: 1),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: _SegmentOption<T>(
                segment: segment,
                isSelected: segment.value == selected,
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
    required this.segment,
    required this.isSelected,
    required this.onTap,
  });

  final ShoppingSegment<T> segment;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Color background = Colors.transparent;
    Color foreground = palette.textSecondary;
    Color? ring;

    if (isSelected) {
      switch (segment.tone) {
        case SegmentTone.accent:
          background = palette.accentPrimary;
          foreground = palette.card;
        case SegmentTone.daily:
          background = palette.dailyLight;
          foreground = palette.daily;
          ring = palette.daily;
        case SegmentTone.joy:
          background = palette.joyLight;
          foreground = palette.joy;
          ring = palette.joy;
      }
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: ring != null ? Border.all(color: ring, width: 1.5) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          segment.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelMedium.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_palette.dart';

/// Presentational 4-dot PIN indicator with a shake-and-clear error animation
/// (sketch 002 tone B, D-12).
///
/// [filledCount] dots (of [length]) render filled; the rest render as outlined
/// rings. There is NO text — the indicator is the only feedback the tone-B PIN
/// page shows. To signal a wrong PIN the consuming screen increments
/// [errorTrigger]; the widget then plays a horizontal shake and fires
/// [HapticFeedback.mediumImpact]. The consumer clears the entered digits in the
/// same frame (so the dots also empty) — this widget carries no entry state.
///
/// Theming is via [AppPaletteContext.palette] (ADR-019 v1.6); no hardcoded
/// theme colours.
class PinDots extends StatefulWidget {
  const PinDots({
    super.key,
    required this.filledCount,
    this.length = 4,
    this.errorTrigger = 0,
  });

  /// Number of filled dots (0..[length]).
  final int filledCount;

  /// Total dot count (default 4 — the standard PIN length).
  final int length;

  /// Monotonic error counter. Incrementing it (vs the previous build) plays the
  /// shake-and-clear animation and fires a medium-impact haptic.
  final int errorTrigger;

  @override
  State<PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<PinDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(PinDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorTrigger != oldWidget.errorTrigger) {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// Decaying horizontal oscillation: a few cycles that taper to rest.
  double get _dx {
    final t = _shake.value;
    if (t == 0) {
      return 0;
    }
    return math.sin(t * math.pi * 4) * 12 * (1 - t);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_dx, 0), child: child),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: _dot(palette, filled: i < widget.filledCount, index: i),
            ),
        ],
      ),
    );
  }

  Widget _dot(AppPalette palette, {required bool filled, required int index}) {
    return Container(
      key: ValueKey(
        filled ? 'pin-dot-filled-$index' : 'pin-dot-empty-$index',
      ),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? palette.accentPrimary : Colors.transparent,
        border: Border.all(color: palette.accentPrimary, width: 2),
      ),
    );
  }
}

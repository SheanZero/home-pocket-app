import 'dart:math' show pi;

import 'package:flutter/material.dart';

/// Renders 3 concentric gradient rings for HomeHeroCard.
///
/// **Mode-agnostic:** callers compute sweep ratios from `HappinessReport`
/// (single mode) or `FamilyHappiness` (group mode) and pass them as
/// `double?`. `null` ratio = Empty state (track only); non-null ratio in
/// `[0, 1]` = Value state (track + fill arc).
///
/// **Empty/Value semantics:**
///   - `Empty()` → null sweep ratio → only the gray track is rendered.
///   - `Value(data, n)` → caller computes a 0..1 ratio and passes it; the
///     painter clamps overflow to 1.0 (full circle).
///   - `0.0` (exact zero) is treated like Empty for fill rendering: the
///     `> 0` guard skips the fill arc so we never draw a zero-length stroke.
///
/// **Performance:** Wrap the [CustomPaint] widget in a [RepaintBoundary] so
/// rings don't re-rasterize when other parts of HomeHeroCard rebuild.
/// [shouldRepaint] returns false when input is value-equal — Freezed
/// aggregates have value equality, so callers benefit automatically.
///
/// Reference: RESEARCH §Pattern 3 — canonical Flutter Canvas.drawArc + SweepGradient
/// (Flutter API docs api.flutter.dev fetched 2026-05-02).
class HappinessRingsPainter extends CustomPainter {
  const HappinessRingsPainter({
    required this.outerSweepRatio,
    required this.middleSweepRatio,
    required this.innerSweepRatio,
    required this.outerGradient,
    required this.middleGradient,
    required this.innerGradient,
    required this.trackColor,
    this.strokeWidth = 8,
    this.ringGap = 4,
  });

  /// Outer-ring sweep ratio in `[0, 1]`; `null` = Empty (track only).
  final double? outerSweepRatio;

  /// Middle-ring sweep ratio in `[0, 1]`; `null` = Empty (track only).
  final double? middleSweepRatio;

  /// Inner-ring sweep ratio in `[0, 1]`; `null` = Empty (track only).
  final double? innerSweepRatio;

  /// Sweep gradient applied to the outer fill arc when ratio > 0.
  final SweepGradient outerGradient;

  /// Sweep gradient applied to the middle fill arc when ratio > 0.
  final SweepGradient middleGradient;

  /// Sweep gradient applied to the inner fill arc when ratio > 0.
  final SweepGradient innerGradient;

  /// Track color rendered behind every ring (always visible).
  final Color trackColor;

  /// Stroke width of each ring in logical pixels (CONTEXT spec: 8).
  final double strokeWidth;

  /// Gap between adjacent rings in logical pixels (CONTEXT spec: 4).
  final double ringGap;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radii = <double>[
      size.width / 2 - strokeWidth / 2,
      size.width / 2 - strokeWidth / 2 - (strokeWidth + ringGap),
      size.width / 2 - strokeWidth / 2 - 2 * (strokeWidth + ringGap),
    ];
    final ratios = <double?>[
      outerSweepRatio,
      middleSweepRatio,
      innerSweepRatio,
    ];
    final gradients = <SweepGradient>[
      outerGradient,
      middleGradient,
      innerGradient,
    ];

    for (var i = 0; i < 3; i++) {
      final r = radii[i];
      final rect = Rect.fromCircle(center: center, radius: r);

      // Track always renders behind the fill arc.
      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, 0, 2 * pi, false, trackPaint);

      // Fill arc only renders when ratio is a Value > 0.
      final ratio = ratios[i];
      if (ratio != null && ratio > 0) {
        final fillPaint = Paint()
          ..shader = gradients[i].createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        const startAngle = -pi / 2; // 12 o'clock
        final sweepAngle = ratio.clamp(0.0, 1.0) * 2 * pi;
        canvas.drawArc(rect, startAngle, sweepAngle, false, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(HappinessRingsPainter oldDelegate) =>
      outerSweepRatio != oldDelegate.outerSweepRatio ||
      middleSweepRatio != oldDelegate.middleSweepRatio ||
      innerSweepRatio != oldDelegate.innerSweepRatio ||
      trackColor != oldDelegate.trackColor;
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Namespace for the onboarding intro decor animation kill-switch.
///
/// The intro pages (Welcome A design) float their hero clusters and petals on
/// repeating tickers. Under `flutter_test` a repeating ticker never settles,
/// which would hang every `pumpAndSettle` that crosses the onboarding gate
/// (onboarding widget tests AND main_characterization_smoke_test). The global
/// test bootstrap (`test/flutter_test_config.dart`) flips this off so both
/// widgets render their frame-zero static transform instead. Mirrors the
/// repo's reversible `@visibleForTesting` flag pattern (cf. showConfidenceBand).
abstract final class OnboardingFloatDecor {
  /// Whether the repeating decor tickers run. On-device default: true.
  @visibleForTesting
  static bool animationsEnabled = true;
}

/// Smooth loop easing: 0 → 1 → 0 over one controller cycle with zero velocity
/// at both endpoints, so the loop has no visible restart snap.
double _loopEase(double t) => 0.5 * (1 - math.cos(2 * math.pi * t));

/// Wraps [child] in a gentle sinusoidal vertical float (design `floaty`
/// keyframes: translateY 0 → -7 → 0), looping every [period] with an optional
/// [phase] offset so sibling elements float out of phase.
class FloatyLoop extends StatefulWidget {
  const FloatyLoop({
    super.key,
    required this.child,
    this.period = const Duration(seconds: 6),
    this.phase = Duration.zero,
  });

  final Widget child;
  final Duration period;
  final Duration phase;

  @override
  State<FloatyLoop> createState() => _FloatyLoopState();
}

class _FloatyLoopState extends State<FloatyLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
    if (OnboardingFloatDecor.animationsEnabled) {
      _controller.value =
          (widget.phase.inMilliseconds % widget.period.inMilliseconds) /
          widget.period.inMilliseconds;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -7 * _loopEase(_controller.value)),
        child: child,
      ),
    );
  }
}

/// A small decorative petal (design `drift` keyframes: translateY 0 → -9 → 0
/// combined with rotation 45° → 60° → 45°). The petal geometry follows the
/// design's `border-radius: 62% 0 62% 0` — rounded top-left / bottom-right
/// corners inside a rotation. Colors always arrive via [color]; nothing is
/// hardcoded here.
class DriftPetal extends StatefulWidget {
  const DriftPetal({
    super.key,
    required this.size,
    required this.color,
    this.opacity = 1.0,
    this.period = const Duration(seconds: 5),
    this.phase = Duration.zero,
  });

  final double size;
  final Color color;
  final double opacity;
  final Duration period;
  final Duration phase;

  @override
  State<DriftPetal> createState() => _DriftPetalState();
}

class _DriftPetalState extends State<DriftPetal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const double _baseAngle = 45 * math.pi / 180;
  static const double _sweepAngle = 15 * math.pi / 180;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
    if (OnboardingFloatDecor.animationsEnabled) {
      _controller.value =
          (widget.phase.inMilliseconds % widget.period.inMilliseconds) /
          widget.period.inMilliseconds;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(widget.size * 0.62);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final eased = _loopEase(_controller.value);
        return Transform.translate(
          offset: Offset(0, -9 * eased),
          child: Transform.rotate(
            angle: _baseAngle + _sweepAngle * eased,
            child: Opacity(
              opacity: widget.opacity,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.only(
                    topLeft: radius,
                    bottomRight: radius,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

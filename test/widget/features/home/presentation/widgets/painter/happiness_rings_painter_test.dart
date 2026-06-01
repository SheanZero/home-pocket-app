import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/painter/happiness_rings_painter.dart';
import 'package:mocktail/mocktail.dart';

/// Unit tests for [HappinessRingsPainter].
///
/// The mock-canvas idiom mirrors the pattern in
/// `.planning/phases/10-homepage-joyfullnesscard-redesign/10-PATTERNS.md`
/// (lines 626-712): use `mocktail.Mock implements Canvas` and `verify(...)` to
/// assert the exact `drawArc` call counts + sweep angles instead of pixel
/// inspection.
class _MockCanvas extends Mock implements Canvas {}

class _FakeRect extends Fake implements Rect {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRect());
    // Paint is a final class in dart:ui and cannot be `implement`-ed via Fake.
    // Use a real Paint() as the fallback value instead.
    registerFallbackValue(Paint());
  });

  group('HappinessRingsPainter', () {
    test('Empty rings: 3 track arcs only, no fill arc', () {
      final canvas = _MockCanvas();
      const gradient = SweepGradient(
        colors: [Colors.green, Colors.greenAccent],
      );
      final painter = HappinessRingsPainter(
        outerSweepRatio: null,
        middleSweepRatio: null,
        innerSweepRatio: null,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      painter.paint(canvas, const Size(120, 120));
      verify(() => canvas.drawArc(any(), 0, 2 * pi, false, any())).called(3);
      verifyNever(() => canvas.drawArc(any(), -pi / 2, any(), false, any()));
    });

    test(
      'Mixed Empty/Value rings: 3 track arcs + 1 fill arc (only Value renders fill)',
      () {
        final canvas = _MockCanvas();
        const gradient = SweepGradient(
          colors: [Colors.green, Colors.greenAccent],
        );
        final painter = HappinessRingsPainter(
          outerSweepRatio: 0.5,
          middleSweepRatio: null,
          innerSweepRatio: null,
          outerGradient: gradient,
          middleGradient: gradient,
          innerGradient: gradient,
          trackColor: const Color(0xFFEFEFEF),
        );
        painter.paint(canvas, const Size(120, 120));
        // 3 track arcs (sweep = 2 * pi) + 1 fill arc (sweep = 0.5 * 2 * pi = pi)
        verify(() => canvas.drawArc(any(), 0, 2 * pi, false, any())).called(3);
        verify(
          () => canvas.drawArc(any(), -pi / 2, pi, false, any()),
        ).called(1);
      },
    );

    test('All Value rings: 3 track arcs + 3 fill arcs', () {
      final canvas = _MockCanvas();
      const gradient = SweepGradient(
        colors: [Colors.green, Colors.greenAccent],
      );
      final painter = HappinessRingsPainter(
        outerSweepRatio: 1.0,
        middleSweepRatio: 1.0,
        innerSweepRatio: 1.0,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      painter.paint(canvas, const Size(120, 120));
      // 3 track arcs + 3 fill arcs at full sweep = 6 total
      verify(() => canvas.drawArc(any(), any(), any(), false, any())).called(6);
    });

    test('Sweep ratio of 0.5 produces sweepAngle = pi (half circle)', () {
      final canvas = _MockCanvas();
      const gradient = SweepGradient(
        colors: [Colors.green, Colors.greenAccent],
      );
      final painter = HappinessRingsPainter(
        outerSweepRatio: 0.5,
        middleSweepRatio: null,
        innerSweepRatio: null,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      painter.paint(canvas, const Size(120, 120));
      verify(() => canvas.drawArc(any(), -pi / 2, pi, false, any())).called(1);
    });

    test(
      'Sweep ratio overflow (1.5) clamps to full circle (sweepAngle = 2 * pi)',
      () {
        final canvas = _MockCanvas();
        const gradient = SweepGradient(
          colors: [Colors.green, Colors.greenAccent],
        );
        final painter = HappinessRingsPainter(
          outerSweepRatio: 1.5, // overflow
          middleSweepRatio: null,
          innerSweepRatio: null,
          outerGradient: gradient,
          middleGradient: gradient,
          innerGradient: gradient,
          trackColor: const Color(0xFFEFEFEF),
        );
        painter.paint(canvas, const Size(120, 120));
        // Fill arc should sweep 2 * pi (clamped from 1.5 * 2 * pi)
        verify(
          () => canvas.drawArc(any(), -pi / 2, 2 * pi, false, any()),
        ).called(1);
      },
    );

    test('Sweep ratio of 0.0 (exact zero) skips fill arc', () {
      final canvas = _MockCanvas();
      const gradient = SweepGradient(
        colors: [Colors.green, Colors.greenAccent],
      );
      final painter = HappinessRingsPainter(
        outerSweepRatio: 0.0,
        middleSweepRatio: null,
        innerSweepRatio: null,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      painter.paint(canvas, const Size(120, 120));
      // Only 3 track arcs; the > 0 guard prevents the fill arc.
      verify(() => canvas.drawArc(any(), 0, 2 * pi, false, any())).called(3);
      verifyNever(() => canvas.drawArc(any(), -pi / 2, any(), false, any()));
    });

    test('shouldRepaint returns false when inputs equal', () {
      const gradient = SweepGradient(
        colors: [Colors.green, Colors.greenAccent],
      );
      final p1 = HappinessRingsPainter(
        outerSweepRatio: 0.5,
        middleSweepRatio: 0.5,
        innerSweepRatio: 0.5,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      final p2 = HappinessRingsPainter(
        outerSweepRatio: 0.5,
        middleSweepRatio: 0.5,
        innerSweepRatio: 0.5,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      expect(p1.shouldRepaint(p2), isFalse);
    });

    test('shouldRepaint returns true when outerSweepRatio differs', () {
      const gradient = SweepGradient(
        colors: [Colors.green, Colors.greenAccent],
      );
      final p1 = HappinessRingsPainter(
        outerSweepRatio: 0.5,
        middleSweepRatio: 0.5,
        innerSweepRatio: 0.5,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      final p2 = HappinessRingsPainter(
        outerSweepRatio: 0.7, // differs
        middleSweepRatio: 0.5,
        innerSweepRatio: 0.5,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('shouldRepaint returns true when trackColor differs', () {
      const gradient = SweepGradient(
        colors: [Colors.green, Colors.greenAccent],
      );
      final p1 = HappinessRingsPainter(
        outerSweepRatio: 0.5,
        middleSweepRatio: 0.5,
        innerSweepRatio: 0.5,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      final p2 = HappinessRingsPainter(
        outerSweepRatio: 0.5,
        middleSweepRatio: 0.5,
        innerSweepRatio: 0.5,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFF353845), // differs (dark theme)
      );
      expect(p1.shouldRepaint(p2), isTrue);
    });
  });
}

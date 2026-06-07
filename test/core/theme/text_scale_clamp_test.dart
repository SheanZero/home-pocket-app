import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/text_scale_clamp.dart';

void main() {
  group('clampTextScaling', () {
    testWidgets('pins an oversized ambient textScaler down to the locked factor', (
      tester,
    ) async {
      late TextScaler captured;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
          child: Builder(
            builder: (context) => clampTextScaling(
              context,
              Builder(
                builder: (inner) {
                  captured = MediaQuery.textScalerOf(inner);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      // 3.0x ambient is forced down to the 1.0x lock.
      expect(captured.scale(10), kLockedTextScaleFactor * 10);
    });

    testWidgets('pins an undersized ambient textScaler up to the locked factor', (
      tester,
    ) async {
      late TextScaler captured;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
          child: Builder(
            builder: (context) => clampTextScaling(
              context,
              Builder(
                builder: (inner) {
                  captured = MediaQuery.textScalerOf(inner);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      // 0.5x ambient is forced up to the 1.0x lock — the system setting is
      // fully ignored in both directions.
      expect(captured.scale(10), kLockedTextScaleFactor * 10);
    });

    testWidgets('renders without throwing when child is null', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) => clampTextScaling(context, null),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    test('locked factor is 1.0 (no scaling, per 260607 decision)', () {
      expect(kLockedTextScaleFactor, 1.0);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/text_scale_clamp.dart';

void main() {
  group('clampTextScaling', () {
    testWidgets('clamps an oversized ambient textScaler to kMaxTextScaleFactor', (
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

      // 3.0x ambient is capped to the 1.2x ceiling.
      expect(captured.scale(10), kMaxTextScaleFactor * 10);
    });

    testWidgets('passes through a textScaler below the ceiling unchanged', (
      tester,
    ) async {
      late TextScaler captured;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.0)),
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

      expect(captured.scale(10), 10);
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

    test('ceiling matches the quick 260604-fyd decision', () {
      expect(kMaxTextScaleFactor, 1.2);
    });
  });
}

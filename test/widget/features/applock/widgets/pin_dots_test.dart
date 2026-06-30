import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/applock/presentation/widgets/pin_dots.dart';

Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  group('PinDots — 4-dot indicator with shake-and-clear (D-12)', () {
    testWidgets('filledCount=2 renders 2 filled + 2 empty of 4', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const PinDots(filledCount: 2)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('pin-dot-filled-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-dot-filled-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-dot-empty-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-dot-empty-3')), findsOneWidget);
    });

    testWidgets('the error animation runs and settles without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const PinDots(filledCount: 4)),
      );
      await tester.pumpAndSettle();

      // Bump errorTrigger to fire the shake-and-clear animation; the State is
      // reused so didUpdateWidget detects the change and runs the controller.
      await tester.pumpWidget(
        _host(const PinDots(filledCount: 4, errorTrigger: 1)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // All four dots still render after the animation settles.
      expect(find.byKey(const ValueKey('pin-dot-filled-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-dot-filled-3')), findsOneWidget);
    });
  });
}

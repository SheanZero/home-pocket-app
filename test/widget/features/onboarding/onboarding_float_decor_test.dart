import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/onboarding/presentation/widgets/onboarding_float_decor.dart';

Widget _host() {
  return const Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatyLoop(
            period: Duration(seconds: 6),
            child: Text('floaty-child'),
          ),
          FloatyLoop(
            period: Duration(seconds: 5),
            phase: Duration(milliseconds: 300),
            child: Text('floaty-child-2'),
          ),
          DriftPetal(size: 12, color: Color(0xFF123456), opacity: 0.5),
          DriftPetal(
            size: 9,
            color: Color(0xFF654321),
            opacity: 0.4,
            period: Duration(milliseconds: 6500),
            phase: Duration(milliseconds: 600),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('OnboardingFloatDecor kill-switch', () {
    testWidgets(
      'animationsEnabled=false (global test default): pumpAndSettle '
      'terminates and children render statically',
      (tester) async {
        // flutter_test_config.dart forces the flag off suite-wide.
        expect(OnboardingFloatDecor.animationsEnabled, isFalse);

        await tester.pumpWidget(_host());
        await tester.pumpAndSettle();

        expect(find.text('floaty-child'), findsOneWidget);
        expect(find.text('floaty-child-2'), findsOneWidget);
        expect(find.byType(DriftPetal), findsNWidgets(2));
        // No repeating tickers left running.
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'animationsEnabled=true: repeating tickers actually run',
      (tester) async {
        OnboardingFloatDecor.animationsEnabled = true;
        addTearDown(() => OnboardingFloatDecor.animationsEnabled = false);

        await tester.pumpWidget(_host());
        await tester.pump(const Duration(milliseconds: 300));

        // The repeating controllers keep transient frame callbacks scheduled.
        expect(tester.binding.transientCallbackCount, greaterThan(0));

        // Tear the tree down so the tickers stop before the flag is restored.
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}

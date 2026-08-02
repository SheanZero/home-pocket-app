import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/app_gate_transition.dart';

void main() {
  testWidgets('cross-fades between keyed gate children', (tester) async {
    Widget current = const Text('Onboarding', key: ValueKey('onboarding'));
    late void Function(Widget child) show;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            show = (child) => setState(() => current = child);
            return AppGateTransition(child: current);
          },
        ),
      ),
    );

    show(const Text('Home', key: ValueKey('home')));
    await tester.pump();

    expect(find.text('Onboarding'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.pump(AppGateTransition.duration);
    await tester.pump();

    expect(find.text('Onboarding'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('switches immediately when animations are disabled', (
    tester,
  ) async {
    Widget current = const Text('Onboarding', key: ValueKey('onboarding'));
    late void Function(Widget child) show;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (context, setState) {
              show = (child) => setState(() => current = child);
              return AppGateTransition(child: current);
            },
          ),
        ),
      ),
    );

    show(const Text('Home', key: ValueKey('home')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Onboarding'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });
}

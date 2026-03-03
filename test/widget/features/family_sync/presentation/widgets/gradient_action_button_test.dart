import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/gradient_action_button.dart';

void main() {
  testWidgets('GradientActionButton shows label and responds to tap', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientActionButton(
            label: '参加する',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('参加する'), findsOneWidget);
    await tester.tap(find.text('参加する'));
    expect(tapped, isTrue);
  });

  testWidgets('GradientActionButton shows loading indicator when loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientActionButton(
            label: '参加する',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('参加する'), findsNothing);
  });

  testWidgets('GradientActionButton is disabled when onPressed is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GradientActionButton(label: 'Test', onPressed: null),
        ),
      ),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });
}

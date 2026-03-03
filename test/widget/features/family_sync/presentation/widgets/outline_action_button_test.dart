import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/outline_action_button.dart';

void main() {
  testWidgets('OutlineActionButton shows icon and label', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutlineActionButton(
            icon: Icons.share,
            label: 'シェア',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('シェア'), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
    await tester.tap(find.text('シェア'));
    expect(tapped, isTrue);
  });

  testWidgets('OutlineActionButton works without icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutlineActionButton(label: 'キャンセル', onPressed: () {}),
        ),
      ),
    );

    expect(find.text('キャンセル'), findsOneWidget);
  });
}

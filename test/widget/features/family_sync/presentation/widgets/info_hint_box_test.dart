import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/info_hint_box.dart';

void main() {
  testWidgets('InfoHintBox displays message text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: InfoHintBox(message: 'Test hint message')),
      ),
    );

    expect(find.text('Test hint message'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
}

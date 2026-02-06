import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/app.dart';

void main() {
  testWidgets('App initializes successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: HomePocketApp(),
      ),
    );

    // Allow the app to settle
    await tester.pumpAndSettle();

    // Verify app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

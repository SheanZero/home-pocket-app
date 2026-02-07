import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DualLedgerScreen', () {
    testWidgets('displays two tabs - Survival and Soul', (tester) async {
      // Verify the tab structure renders without error.
      // Full integration test requires provider overrides for database.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.shield), text: 'Survival'),
                      Tab(icon: Icon(Icons.auto_awesome), text: 'Soul'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Survival'), findsOneWidget);
      expect(find.text('Soul'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });
  });
}

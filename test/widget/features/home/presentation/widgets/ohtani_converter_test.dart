import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/ohtani_converter.dart';

void main() {
  group('OhtaniConverter', () {
    testWidgets('displays emoji and text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OhtaniConverter(
              emoji: '🍚',
              text: '6.6杯の牛丼を食べました',
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('🍚'), findsOneWidget);
      expect(find.text('6.6杯の牛丼を食べました'), findsOneWidget);
    });

    testWidgets('dismiss triggers callback', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OhtaniConverter(
              emoji: '🍚',
              text: '6.6杯の牛丼を食べました',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });

    testWidgets('shows close icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OhtaniConverter(
              emoji: '🍚',
              text: '6.6杯の牛丼を食べました',
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}

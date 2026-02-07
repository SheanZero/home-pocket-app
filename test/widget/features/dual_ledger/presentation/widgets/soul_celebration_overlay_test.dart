import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart';

void main() {
  group('SoulCelebrationOverlay', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SoulCelebrationOverlay())),
      );

      expect(find.byType(SoulCelebrationOverlay), findsOneWidget);
    });

    testWidgets('shows sparkle icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SoulCelebrationOverlay())),
      );

      // Pump a few frames to let animation start
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    testWidgets('calls onDismissed after animation completes', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoulCelebrationOverlay(onDismissed: () => dismissed = true),
          ),
        ),
      );

      // Advance past the animation duration (1.5 seconds)
      await tester.pump(const Duration(milliseconds: 1600));

      expect(dismissed, isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/soul_fullness_card.dart';

void main() {
  group('SoulFullnessCard', () {
    testWidgets('displays satisfaction percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SoulFullnessCard(
                satisfactionPercent: 60,
                happinessROI: 4.6,
                recentSoulAmount: 12800,
              ),
            ),
          ),
        ),
      );

      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('displays happiness ROI', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SoulFullnessCard(
                satisfactionPercent: 60,
                happinessROI: 4.6,
                recentSoulAmount: 12800,
              ),
            ),
          ),
        ),
      );

      expect(find.text('4.6x'), findsOneWidget);
    });

    testWidgets('displays recent soul spending amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SoulFullnessCard(
                satisfactionPercent: 60,
                happinessROI: 4.6,
                recentSoulAmount: 12800,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('12,800'), findsOneWidget);
    });

    testWidgets('displays title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SoulFullnessCard(
                satisfactionPercent: 60,
                happinessROI: 4.6,
                recentSoulAmount: 12800,
              ),
            ),
          ),
        ),
      );

      expect(find.text('\u7075\u9b42\u306e\u5145\u5b9f\u5ea6'), findsOneWidget);
    });

    testWidgets('invokes onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SoulFullnessCard(
                satisfactionPercent: 60,
                happinessROI: 4.6,
                recentSoulAmount: 12800,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SoulFullnessCard));
      expect(tapped, isTrue);
    });
  });
}

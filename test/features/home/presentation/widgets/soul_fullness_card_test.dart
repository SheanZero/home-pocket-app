import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/soul_fullness_card.dart';

void main() {
  testWidgets('SoulFullnessCard shows satisfaction and ROI', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SoulFullnessCard(
            satisfactionPercent: 78,
            happinessROI: 2.4,
            recentSoulAmount: 8500,
          ),
        ),
      ),
    );
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('2.4x'), findsOneWidget);
  });

  testWidgets('SoulFullnessCard shows recent amount', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SoulFullnessCard(
            satisfactionPercent: 78,
            happinessROI: 2.4,
            recentSoulAmount: 8500,
          ),
        ),
      ),
    );
    expect(find.textContaining('8,500'), findsOneWidget);
  });

  testWidgets('SoulFullnessCard has card border not shadow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SoulFullnessCard(
            satisfactionPercent: 50,
            happinessROI: 1.0,
            recentSoulAmount: 0,
          ),
        ),
      ),
    );
    expect(find.byType(SoulFullnessCard), findsOneWidget);
  });

  testWidgets('SoulFullnessCard title text is present', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SoulFullnessCard(
            satisfactionPercent: 78,
            happinessROI: 2.4,
            recentSoulAmount: 8500,
          ),
        ),
      ),
    );
    // Japanese title
    expect(find.text('\u7075\u9b42\u306e\u5145\u5b9f\u5ea6'), findsOneWidget);
  });
}

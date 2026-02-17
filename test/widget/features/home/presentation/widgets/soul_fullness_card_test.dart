import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/soul_fullness_card.dart';

import '../../helpers/test_localizations.dart';

void main() {
  group('SoulFullnessCard', () {
    testWidgets('displays soul percentage', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: SoulFullnessCard(
                soulPercentage: 60,
                happinessROI: 4.6,
                fullnessLevel: 78,
                recentMerchant: '书店',
                recentAmount: 128,
                recentQuote: '知识就是力量，也是快乐',
              ),
            ),
          ),
        ),
      );

      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('displays happiness ROI', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: SoulFullnessCard(
                soulPercentage: 60,
                happinessROI: 4.6,
                fullnessLevel: 78,
                recentMerchant: '书店',
                recentAmount: 128,
                recentQuote: '知识就是力量，也是快乐',
              ),
            ),
          ),
        ),
      );

      // ROI shown in metric box and in charge card
      expect(find.text('4.6x'), findsWidgets);
    });

    testWidgets('displays fullness level badge', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: SoulFullnessCard(
                soulPercentage: 60,
                happinessROI: 4.6,
                fullnessLevel: 78,
                recentMerchant: '书店',
                recentAmount: 128,
                recentQuote: '知识就是力量，也是快乐',
              ),
            ),
          ),
        ),
      );

      // ja locale: homeMonthBadge = "今月 {percent}%"
      expect(find.text('今月 78%'), findsOneWidget);
    });

    testWidgets('displays recent transaction and quote', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: SoulFullnessCard(
                soulPercentage: 60,
                happinessROI: 4.6,
                fullnessLevel: 78,
                recentMerchant: '书店',
                recentAmount: 128,
                recentQuote: '知识就是力量，也是快乐',
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('书店'), findsOneWidget);
      expect(find.textContaining('知识就是力量'), findsOneWidget);
    });

    testWidgets('contains progress bar', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: SoulFullnessCard(
                soulPercentage: 60,
                happinessROI: 4.6,
                fullnessLevel: 78,
                recentMerchant: '书店',
                recentAmount: 128,
                recentQuote: '知识就是力量，也是快乐',
              ),
            ),
          ),
        ),
      );

      // FractionallySizedBox is used for the progress bar
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });
  });
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/soul_fullness_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../helpers/test_localizations.dart';

void main() {
  group('SoulFullnessCard', () {
    Widget buildSubject({Locale locale = const Locale('ja')}) {
      return testLocalizedApp(
        locale: locale,
        child: const Scaffold(
          body: SingleChildScrollView(
            child: SoulFullnessCard(
              satisfactionPercent: 60,
              happinessROI: 4.6,
              recentSoulAmount: 12800,
            ),
          ),
        ),
      );
    }

    testWidgets('displays satisfaction percentage', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('displays happiness ROI', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('4.6x'), findsOneWidget);
    });

    testWidgets('displays recent soul spending amount', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.textContaining('12,800'), findsOneWidget);
    });

    testWidgets('displays Japanese localized title text', (tester) async {
      await tester.pumpWidget(buildSubject());

      final l10n = S.of(tester.element(find.byType(SoulFullnessCard)));

      expect(find.text(l10n.homeSoulFullness), findsOneWidget);
    });

    testWidgets('displays English localized title text', (tester) async {
      await tester.pumpWidget(buildSubject(locale: const Locale('en')));

      final l10n = S.of(tester.element(find.byType(SoulFullnessCard)));

      expect(find.text(l10n.homeSoulFullness), findsOneWidget);
    });

    testWidgets('renders recent soul amount with tabular figures', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      final amountText = tester.widget<Text>(find.textContaining('12,800'));

      expect(
        amountText.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
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

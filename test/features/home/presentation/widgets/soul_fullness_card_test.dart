import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/soul_fullness_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  Widget buildSubject({
    int satisfactionPercent = 78,
    double happinessROI = 2.4,
    int recentSoulAmount = 8500,
  }) {
    return MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: SoulFullnessCard(
          satisfactionPercent: satisfactionPercent,
          happinessROI: happinessROI,
          recentSoulAmount: recentSoulAmount,
        ),
      ),
    );
  }

  testWidgets('SoulFullnessCard shows satisfaction and ROI', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('2.4x'), findsOneWidget);
  });

  testWidgets('SoulFullnessCard shows recent amount', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.textContaining('8,500'), findsOneWidget);
  });

  testWidgets('SoulFullnessCard has card border not shadow', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        satisfactionPercent: 50,
        happinessROI: 1.0,
        recentSoulAmount: 0,
      ),
    );
    expect(find.byType(SoulFullnessCard), findsOneWidget);
  });

  testWidgets('SoulFullnessCard title text is present', (tester) async {
    await tester.pumpWidget(buildSubject());
    final l10n = S.of(tester.element(find.byType(SoulFullnessCard)));

    expect(find.text(l10n.homeSoulFullness), findsOneWidget);
  });
}

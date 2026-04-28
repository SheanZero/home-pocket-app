import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/soul_fullness_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Wraps the SoulFullnessCard in a fixed-size container for golden stability.
///
/// SoulFullnessCard is a pure StatelessWidget (no Riverpod / no providers),
/// so a plain MaterialApp wrapper is sufficient — no `createLocalizedWidget`
/// override list needed.
Widget _wrap({required Locale locale, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: SizedBox(width: 420, height: 200, child: child),
    ),
  );
}

void main() {
  group('SoulFullnessCard golden test', () {
    testWidgets(
      'Japanese (ja) — soul ledger localized header + mid-range fullness',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            locale: const Locale('ja'),
            // Mid-range fixture: 65% satisfaction, 1.8x ROI, ¥12,500 recent
            // soul spending. Avoids both empty (0) and full (100) edges so the
            // visual is informative against future regressions.
            child: const SoulFullnessCard(
              satisfactionPercent: 65,
              happinessROI: 1.8,
              recentSoulAmount: 12500,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(SoulFullnessCard),
          matchesGoldenFile('goldens/soul_fullness_card_ja.png'),
        );
      },
    );
  });
}

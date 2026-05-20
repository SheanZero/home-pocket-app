import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/soul_vs_survival_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Golden tests for SoulVsSurvivalCard (STATSUI-V2-01).
///
/// Captures 4 variants:
/// - solo + light + ja
/// - solo + dark + ja
/// - group + light + ja
/// - group + dark + ja

const _locale = Locale('ja');
const _currencyCode = 'JPY';
final _startDate = DateTime(2026, 5, 1);
final _endDate = DateTime(2026, 6, 1);
const _bookId = 'book-1';

SoulVsSurvivalSnapshot _youSnapshot() => const SoulVsSurvivalSnapshot(
  soul: SoulLedgerSnapshot(
    entryCount: 5,
    totalSpend: 1500,
    avgSatisfaction: 7.4,
  ),
  survival: SurvivalLedgerSnapshot(entryCount: 8, totalSpend: 12000),
);

SoulVsSurvivalSnapshot _familySnapshot() => const SoulVsSurvivalSnapshot(
  soul: SoulLedgerSnapshot(
    entryCount: 12,
    totalSpend: 3500,
    avgSatisfaction: 6.8,
  ),
  survival: SurvivalLedgerSnapshot(entryCount: 18, totalSpend: 24000),
);

Widget _wrap({
  required bool isGroupMode,
  required ThemeMode themeMode,
  double width = 360,
  double height = 360,
}) {
  return ProviderScope(
    overrides: [
      soulVsSurvivalSnapshotProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith((ref) async => Value(_youSnapshot(), 13)),
      if (isGroupMode)
        soulVsSurvivalSnapshotFamilyProvider(
          startDate: _startDate,
          endDate: _endDate,
        ).overrideWith((ref) async => Value(_familySnapshot(), 30)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: SingleChildScrollView(
              child: SoulVsSurvivalCard(
                bookId: _bookId,
                startDate: _startDate,
                endDate: _endDate,
                currencyCode: _currencyCode,
                locale: _locale,
                isGroupMode: isGroupMode,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SoulVsSurvivalCard golden', () {
    testWidgets('solo light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(isGroupMode: false, themeMode: ThemeMode.light),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SoulVsSurvivalCard),
        matchesGoldenFile('goldens/soul_vs_survival_card_light_ja.png'),
      );
    });

    testWidgets('solo dark ja', (tester) async {
      await tester.pumpWidget(
        _wrap(isGroupMode: false, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SoulVsSurvivalCard),
        matchesGoldenFile('goldens/soul_vs_survival_card_dark_ja.png'),
      );
    });

    testWidgets('group light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(isGroupMode: true, themeMode: ThemeMode.light, height: 500),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SoulVsSurvivalCard),
        matchesGoldenFile('goldens/soul_vs_survival_card_group_light_ja.png'),
      );
    });

    testWidgets('group dark ja', (tester) async {
      await tester.pumpWidget(
        _wrap(isGroupMode: true, themeMode: ThemeMode.dark, height: 500),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SoulVsSurvivalCard),
        matchesGoldenFile('goldens/soul_vs_survival_card_group_dark_ja.png'),
      );
    });
  });
}

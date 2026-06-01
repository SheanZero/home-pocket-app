import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/daily_vs_joy_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Golden tests for DailyVsJoyCard (STATSUI-V2-01).
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

DailyVsJoySnapshot _youSnapshot() => const DailyVsJoySnapshot(
  joy: JoyLedgerSnapshot(
    entryCount: 5,
    totalSpend: 1500,
    avgSatisfaction: 7.4,
  ),
  daily: DailyLedgerSnapshot(entryCount: 8, totalSpend: 12000),
);

DailyVsJoySnapshot _familySnapshot() => const DailyVsJoySnapshot(
  joy: JoyLedgerSnapshot(
    entryCount: 12,
    totalSpend: 3500,
    avgSatisfaction: 6.8,
  ),
  daily: DailyLedgerSnapshot(entryCount: 18, totalSpend: 24000),
);

Widget _wrap({
  required bool isGroupMode,
  required ThemeMode themeMode,
  double width = 360,
  double height = 360,
}) {
  return ProviderScope(
    overrides: [
      dailyVsJoySnapshotProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith((ref) async => Value(_youSnapshot(), 13)),
      if (isGroupMode)
        dailyVsJoySnapshotFamilyProvider(
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
              child: DailyVsJoyCard(
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
  group('DailyVsJoyCard golden', () {
    testWidgets('solo light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(isGroupMode: false, themeMode: ThemeMode.light),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DailyVsJoyCard),
        matchesGoldenFile('goldens/daily_vs_joy_card_light_ja.png'),
      );
    });

    testWidgets('solo dark ja', (tester) async {
      await tester.pumpWidget(
        _wrap(isGroupMode: false, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DailyVsJoyCard),
        matchesGoldenFile('goldens/daily_vs_joy_card_dark_ja.png'),
      );
    });

    testWidgets('group light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(isGroupMode: true, themeMode: ThemeMode.light, height: 500),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DailyVsJoyCard),
        matchesGoldenFile('goldens/daily_vs_joy_card_group_light_ja.png'),
      );
    });

    testWidgets('group dark ja', (tester) async {
      await tester.pumpWidget(
        _wrap(isGroupMode: true, themeMode: ThemeMode.dark, height: 500),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DailyVsJoyCard),
        matchesGoldenFile('goldens/daily_vs_joy_card_group_dark_ja.png'),
      );
    });
  });
}

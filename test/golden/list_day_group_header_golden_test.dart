// Golden tests for ListDayGroupHeader — 3 locales × light theme (D-01/D-02/D-03).
//
// Baselines: test/golden/goldens/list_day_group_header_{ja,zh,en}.png
// Run with: flutter test test/golden/list_day_group_header_golden_test.dart
// Update:   flutter test test/golden/list_day_group_header_golden_test.dart --update-goldens

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_day_group_header.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Fixed date — no DateTime.now() dependency; locale-specific formatting baked in.
final _date = DateTime(2026, 5, 15);

/// Wraps a widget for golden tests with a fixed-size SizedBox.
///
/// No ProviderScope needed — [ListDayGroupHeader] is a pure [StatelessWidget].
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
    theme: ThemeData.light(),
    home: Scaffold(
      body: Center(child: SizedBox(width: 390, height: 32, child: child)),
    ),
  );
}

void main() {
  group('ListDayGroupHeader golden', () {
    testWidgets('locale ja', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          child: ListDayGroupHeader(
            date: _date,
            locale: const Locale('ja'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListDayGroupHeader),
        matchesGoldenFile('goldens/list_day_group_header_ja.png'),
      );
    });

    testWidgets('locale zh', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('zh'),
          child: ListDayGroupHeader(
            date: _date,
            locale: const Locale('zh'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListDayGroupHeader),
        matchesGoldenFile('goldens/list_day_group_header_zh.png'),
      );
    });

    testWidgets('locale en', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          child: ListDayGroupHeader(
            date: _date,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListDayGroupHeader),
        matchesGoldenFile('goldens/list_day_group_header_en.png'),
      );
    });
  });
}

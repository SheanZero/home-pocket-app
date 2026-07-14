@Tags(['golden'])
library;

// Golden tests for ListSortFilterBar — 3 locales × light theme (D-01/D-02/D-03).
//
// Baselines: test/golden/goldens/list_sort_filter_bar_{ja,zh,en}.png
// Run with: flutter test test/golden/list_sort_filter_bar_golden_test.dart
// Update:   flutter test test/golden/list_sort_filter_bar_golden_test.dart --update-goldens

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_sort_filter_bar.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

/// Wraps a ListSortFilterBar inside a ProviderScope + MaterialApp.
///
/// Overrides [currentLocaleProvider] to a synchronous value to prevent pending
/// async timer issues from the settings-repository chain (same pattern as
/// list_sort_filter_bar_test.dart). isGroupMode defaults to false (no Mine-only chip).
Widget _wrap({required Locale locale, ThemeMode themeMode = ThemeMode.light}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider
          .overrideWith((_) async => locale),
    ],
    child: MaterialApp(
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
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: const Scaffold(
        body: SizedBox(
          width: 390,
          height: 60,
          child: ListSortFilterBar(bookId: 'book_golden'),
        ),
      ),
    ),
  );
}

void main() {
  group('ListSortFilterBar golden', () {
    testWidgets('locale ja', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('ja')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListSortFilterBar),
        matchesGoldenFile('goldens/list_sort_filter_bar_ja.png'),
      );
    });

    testWidgets('locale ja dark', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('ja'), themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListSortFilterBar),
        matchesGoldenFile('goldens/list_sort_filter_bar_dark_ja.png'),
      );
    });

    testWidgets('locale zh', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('zh')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListSortFilterBar),
        matchesGoldenFile('goldens/list_sort_filter_bar_zh.png'),
      );
    });

    testWidgets('locale zh dark', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('zh'), themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListSortFilterBar),
        matchesGoldenFile('goldens/list_sort_filter_bar_dark_zh.png'),
      );
    });

    testWidgets('locale en', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListSortFilterBar),
        matchesGoldenFile('goldens/list_sort_filter_bar_en.png'),
      );
    });

    testWidgets('locale en dark', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('en'), themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListSortFilterBar),
        matchesGoldenFile('goldens/list_sort_filter_bar_dark_en.png'),
      );
    });
  });
}

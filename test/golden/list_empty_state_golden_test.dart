@Tags(['golden'])
library;

// Golden tests for ListEmptyState — 9 cases (3 variants × 3 locales) light theme
// (D-01/D-02/D-03/D-04).
//
// Baselines: test/golden/goldens/list_empty_state_{noData,dayEmpty,filtered}_{ja,zh,en}.png
// Run with: flutter test test/golden/list_empty_state_golden_test.dart
// Update:   flutter test test/golden/list_empty_state_golden_test.dart --update-goldens

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_empty_state.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Wraps a ListEmptyState inside a ProviderScope + MaterialApp.
///
/// ProviderScope is required because [ListEmptyState] is a [ConsumerWidget]
/// (ref.read in onPressed callbacks). No provider overrides needed — button
/// callbacks only fire on tap, not during pumpAndSettle render.
Widget _wrap({required Locale locale, required ListEmptyVariant variant}) {
  return ProviderScope(
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
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            height: 300,
            child: ListEmptyState(variant: variant),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ListEmptyState golden', () {
    for (final locale in [
      const Locale('ja'),
      const Locale('zh'),
      const Locale('en'),
    ]) {
      for (final variant in ListEmptyVariant.values) {
        testWidgets('${variant.name} — ${locale.languageCode}', (tester) async {
          await tester.pumpWidget(_wrap(locale: locale, variant: variant));
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(ListEmptyState),
            matchesGoldenFile(
              'goldens/list_empty_state_${variant.name}_${locale.languageCode}.png',
            ),
          );
        });
      }
    }
  });
}

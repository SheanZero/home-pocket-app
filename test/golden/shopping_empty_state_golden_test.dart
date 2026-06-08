@Tags(['golden'])
library;

// Golden tests for ShoppingEmptyState — 18 cases (3 variants × 3 locales × 2 modes).
//
// Variants:
//   private_empty  — listType='private',  isGroupMode=false
//   public_solo    — listType='public',   isGroupMode=false
//   public_family  — listType='public',   isGroupMode=true
//
// Baselines: test/golden/goldens/shopping_empty_state_{variant}_{locale}.png
//            test/golden/goldens/shopping_empty_state_{variant}_dark_{locale}.png
// Run with: flutter test test/golden/shopping_empty_state_golden_test.dart --tags golden
// Update:   flutter test test/golden/shopping_empty_state_golden_test.dart --update-goldens --tags golden

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_empty_state.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Wraps a [ShoppingEmptyState] inside a ProviderScope + MaterialApp.
///
/// Overrides:
/// - [locale_providers.currentLocaleProvider] — prevents async settings-repo timer.
/// - [isGroupModeProvider] — controls the 3-way variant branch synchronously.
///
/// ThemeData.light() / ThemeData.dark() are sufficient: ShoppingEmptyState uses
/// context.palette which has a null-safe brightness fallback (app_palette.dart:607–617).
Widget _wrap({
  required Locale locale,
  required String listType,
  required bool isGroupMode,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      isGroupModeProvider.overrideWith((_) => isGroupMode),
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
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            height: 300,
            child: ShoppingEmptyState(listType: listType),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ShoppingEmptyState golden', () {
    for (final locale in [
      const Locale('ja'),
      const Locale('zh'),
      const Locale('en'),
    ]) {
      for (final (variantName, listType, isGroupMode) in [
        ('private_empty', 'private', false),
        ('public_solo', 'public', false),
        ('public_family', 'public', true),
      ]) {
        // Light mode
        testWidgets('$variantName — ${locale.languageCode}', (tester) async {
          await tester.pumpWidget(
            _wrap(
              locale: locale,
              listType: listType,
              isGroupMode: isGroupMode,
            ),
          );
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(ShoppingEmptyState),
            matchesGoldenFile(
              'goldens/shopping_empty_state_${variantName}_${locale.languageCode}.png',
            ),
          );
        });

        // Dark mode
        testWidgets('$variantName — ${locale.languageCode} dark', (tester) async {
          await tester.pumpWidget(
            _wrap(
              locale: locale,
              listType: listType,
              isGroupMode: isGroupMode,
              themeMode: ThemeMode.dark,
            ),
          );
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(ShoppingEmptyState),
            matchesGoldenFile(
              'goldens/shopping_empty_state_${variantName}_dark_${locale.languageCode}.png',
            ),
          );
        });
      }
    }
  });
}

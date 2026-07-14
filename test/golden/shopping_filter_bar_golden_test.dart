@Tags(['golden'])
library;

// Golden tests for ShoppingFilterBar — active-filter state (daily ledger chip active)
// 3 locales × 2 modes = 6 PNG baselines (D39-04, NAV-03 SC3).
//
// Baselines: test/golden/goldens/shopping_filter_bar_active_{ja,zh,en}.png
//            test/golden/goldens/shopping_filter_bar_active_dark_{ja,zh,en}.png
// Run with: flutter test test/golden/shopping_filter_bar_golden_test.dart --tags golden
// Update:   flutter test test/golden/shopping_filter_bar_golden_test.dart --update-goldens --tags golden

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_list_filter.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_filter.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_filter_bar.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

/// Fixed-state notifier that always returns [LedgerType.daily] as the active filter.
///
/// Subclassing [ShoppingFilter] is required to override [build] and return a stable
/// non-default state for golden rendering (avoids needing a Builder to access the
/// container post-pump — see PATTERNS.md §"active filter state").
class _FixedShoppingFilter extends ShoppingFilter {
  @override
  ShoppingListFilter build() =>
      const ShoppingListFilter(ledgerType: LedgerType.daily);
}

/// Wraps [ShoppingFilterBar] in a ProviderScope + MaterialApp for golden rendering.
///
/// Overrides:
/// - [currentLocaleProvider] — synchronous locale value (prevents settings-repo async timer)
/// - [shoppingFilterProvider] — [_FixedShoppingFilter] with daily ledger active
/// - [listTypeProvider] — default 'private' (fine for filter bar display)
Widget _wrap({required Locale locale, ThemeMode themeMode = ThemeMode.light}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      shoppingFilterProvider.overrideWith(() => _FixedShoppingFilter()),
      listTypeProvider.overrideWith(() => ListType()),
      isGroupModeProvider.overrideWith((_) => false),
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
          height: 150,
          child: ShoppingFilterBar(),
        ),
      ),
    ),
  );
}

void main() {
  group('ShoppingFilterBar golden', () {
    for (final locale in [
      const Locale('ja'),
      const Locale('zh'),
      const Locale('en'),
    ]) {
      testWidgets('filter_bar_active — ${locale.languageCode} light',
          (tester) async {
        await tester.pumpWidget(_wrap(locale: locale));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingFilterBar),
          matchesGoldenFile(
            'goldens/shopping_filter_bar_active_${locale.languageCode}.png',
          ),
        );
      });

      testWidgets('filter_bar_active — ${locale.languageCode} dark',
          (tester) async {
        await tester.pumpWidget(
          _wrap(locale: locale, themeMode: ThemeMode.dark),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingFilterBar),
          matchesGoldenFile(
            'goldens/shopping_filter_bar_active_dark_${locale.languageCode}.png',
          ),
        );
      });
    }
  });
}

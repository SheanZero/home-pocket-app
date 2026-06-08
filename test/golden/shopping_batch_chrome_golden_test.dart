@Tags(['golden'])
library;

// Golden tests for ShoppingSelectionHeader + ShoppingBatchActionBar
// 2 widgets × 3 locales × 2 modes = 12 PNG baselines (D39-04, NAV-03 SC3).
//
// Baselines:
//   test/golden/goldens/shopping_selection_header_{ja,zh,en}.png
//   test/golden/goldens/shopping_selection_header_dark_{ja,zh,en}.png
//   test/golden/goldens/shopping_batch_action_bar_{ja,zh,en}.png
//   test/golden/goldens/shopping_batch_action_bar_dark_{ja,zh,en}.png
//
// Run with: flutter test test/golden/shopping_batch_chrome_golden_test.dart --tags golden
// Update:   flutter test test/golden/shopping_batch_chrome_golden_test.dart --update-goldens --tags golden

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/delete_shopping_item_use_case.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_batch.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_selection_header.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

/// Fixed-state notifier that always returns the provided [BatchSelectModeState].
///
/// Avoids needing post-pump container access for stable golden rendering
/// (see PATTERNS.md §"_FixedBatchSelectMode notifier subclass").
class _FixedBatchSelectMode extends BatchSelectMode {
  _FixedBatchSelectMode(this._fixedState);
  final BatchSelectModeState _fixedState;

  @override
  BatchSelectModeState build() => _fixedState;
}

/// Mock [DeleteShoppingItemUseCase] — provider must be resolvable for
/// [ShoppingBatchActionBar] even though no delete is triggered during rendering.
class _MockDeleteShoppingItemUseCase extends Mock
    implements DeleteShoppingItemUseCase {}

late _MockDeleteShoppingItemUseCase _mockDelete;

/// Wraps [ShoppingSelectionHeader] in a ProviderScope + MaterialApp for golden rendering.
///
/// Overrides:
/// - [currentLocaleProvider] — synchronous locale (prevents settings-repo async timer)
/// - [batchSelectModeProvider] — 2 items selected, batch mode active
Widget _wrapHeader({
  required Locale locale,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      batchSelectModeProvider.overrideWith(
        () => _FixedBatchSelectMode(
          const BatchSelectModeState(
            isActive: true,
            selectedIds: {'id-1', 'id-2'},
          ),
        ),
      ),
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
        body: SizedBox(
          width: 390,
          height: 48,
          child: ShoppingSelectionHeader(allItemIds: const ['id-1', 'id-2']),
        ),
      ),
    ),
  );
}

/// Wraps [ShoppingBatchActionBar] in a ProviderScope + MaterialApp for golden rendering.
///
/// Overrides:
/// - [currentLocaleProvider] — synchronous locale
/// - [batchSelectModeProvider] — 1 item selected (delete button enabled; not greyed)
/// - [deleteShoppingItemUseCaseProvider] — mock (prevents real DB calls)
Widget _wrapBar({
  required Locale locale,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      batchSelectModeProvider.overrideWith(
        () => _FixedBatchSelectMode(
          const BatchSelectModeState(
            isActive: true,
            selectedIds: {'id-1'},
          ),
        ),
      ),
      deleteShoppingItemUseCaseProvider.overrideWithValue(_mockDelete),
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
          height: 56,
          child: ShoppingBatchActionBar(),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    _mockDelete = _MockDeleteShoppingItemUseCase();
    when(() => _mockDelete.execute(any()))
        .thenAnswer((_) async => Result.success(null));
  });

  group('ShoppingSelectionHeader golden', () {
    for (final locale in [
      const Locale('ja'),
      const Locale('zh'),
      const Locale('en'),
    ]) {
      testWidgets('selection_header — ${locale.languageCode} light',
          (tester) async {
        await tester.pumpWidget(_wrapHeader(locale: locale));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingSelectionHeader),
          matchesGoldenFile(
            'goldens/shopping_selection_header_${locale.languageCode}.png',
          ),
        );
      });

      testWidgets('selection_header — ${locale.languageCode} dark',
          (tester) async {
        await tester.pumpWidget(
          _wrapHeader(locale: locale, themeMode: ThemeMode.dark),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingSelectionHeader),
          matchesGoldenFile(
            'goldens/shopping_selection_header_dark_${locale.languageCode}.png',
          ),
        );
      });
    }
  });

  group('ShoppingBatchActionBar golden', () {
    for (final locale in [
      const Locale('ja'),
      const Locale('zh'),
      const Locale('en'),
    ]) {
      testWidgets('batch_action_bar — ${locale.languageCode} light',
          (tester) async {
        await tester.pumpWidget(_wrapBar(locale: locale));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingBatchActionBar),
          matchesGoldenFile(
            'goldens/shopping_batch_action_bar_${locale.languageCode}.png',
          ),
        );
      });

      testWidgets('batch_action_bar — ${locale.languageCode} dark',
          (tester) async {
        await tester.pumpWidget(
          _wrapBar(locale: locale, themeMode: ThemeMode.dark),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingBatchActionBar),
          matchesGoldenFile(
            'goldens/shopping_batch_action_bar_dark_${locale.languageCode}.png',
          ),
        );
      });
    }
  });
}

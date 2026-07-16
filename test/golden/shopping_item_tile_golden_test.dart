@Tags(['golden'])
library;

// Golden tests for ShoppingItemTile — 3 variants × 3 locales × 2 modes = 18 PNGs.
//
// Variants:
//   active:       daily-ledger item, not completed (daily green left border)
//   completed:    joy-ledger item, completed (soft Joy check + neutral badge + strikethrough)
//   attribution:  daily-ledger item, public list, with family attribution chip
//
// Baselines: test/golden/goldens/shopping_item_tile_{variant}[_dark]_{locale}.png
// Run:       flutter test test/golden/shopping_item_tile_golden_test.dart --tags golden
// Update:    flutter test test/golden/shopping_item_tile_golden_test.dart --update-goldens --tags golden

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/delete_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/toggle_item_completed_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_item_tile.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

class MockDeleteShoppingItemUseCase extends Mock
    implements DeleteShoppingItemUseCase {}

class MockToggleItemCompletedUseCase extends Mock
    implements ToggleItemCompletedUseCase {}

late MockDeleteShoppingItemUseCase mockDelete;
late MockToggleItemCompletedUseCase mockToggle;

/// Fixed fixture — stable item for golden rendering.
ShoppingItem _makeItem({
  String id = 'item-golden',
  String listType = 'private',
  LedgerType? ledgerType = LedgerType.daily,
  bool isCompleted = false,
  String? addedByBookId,
}) {
  final now = DateTime(2026, 6, 8, 10, 0);
  return ShoppingItem(
    id: id,
    deviceId: 'device-1',
    listType: listType,
    name: 'Milk',
    ledgerType: ledgerType,
    isCompleted: isCompleted,
    addedByBookId: addedByBookId,
    quantity: 1,
    createdAt: now,
  );
}

/// Minimal Book fixture — only id is accessed by the attribution chip lookup.
Book _makeBook(String id) => Book(
  id: id,
  name: 'Alice Book',
  currency: 'JPY',
  deviceId: 'device-x',
  createdAt: DateTime(2026),
  ownerDeviceId: 'device-x',
  ownerDeviceName: 'Alice Device',
);

/// Wraps a [ShoppingItemTile] inside a ProviderScope + MaterialApp with a
/// mandatory [SliverReorderableList] ancestor so the delayed trailing handle
/// is satisfied (no "Reorderable ancestor not found" error).
Widget _wrap({
  required ShoppingItem item,
  required bool isActive,
  required Locale locale,
  ThemeMode themeMode = ThemeMode.light,
  List<ShadowBookInfo> shadowBooks = const [],
}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      deleteShoppingItemUseCaseProvider.overrideWithValue(mockDelete),
      toggleItemCompletedUseCaseProvider.overrideWithValue(mockToggle),
      shadowBooksProvider.overrideWith((_) async => shadowBooks),
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
          height: 80,
          child: CustomScrollView(
            slivers: [
              SliverReorderableList(
                onReorderItem: (_, _) {},
                itemCount: 1,
                itemBuilder: (ctx, i) => ShoppingItemTile(
                  key: ValueKey('tile-$i'),
                  item: item,
                  index: i,
                  isActive: isActive,
                ),
              ),
            ],
          ),
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
    mockDelete = MockDeleteShoppingItemUseCase();
    mockToggle = MockToggleItemCompletedUseCase();

    when(
      () => mockDelete.execute(any()),
    ).thenAnswer((_) async => Result.success(null));
    when(
      () => mockToggle.execute(any()),
    ).thenAnswer((_) async => Result.success(_makeItem()));
  });

  group('ShoppingItemTile golden', () {
    for (final locale in [
      const Locale('ja'),
      const Locale('zh'),
      const Locale('en'),
    ]) {
      final lang = locale.languageCode;

      // --- active variant: daily-ledger, not completed, private list ---

      testWidgets('active — $lang light', (tester) async {
        final item = _makeItem(
          ledgerType: LedgerType.daily,
          isCompleted: false,
          listType: 'private',
        );
        await tester.pumpWidget(
          _wrap(item: item, isActive: true, locale: locale),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingItemTile),
          matchesGoldenFile('goldens/shopping_item_tile_active_$lang.png'),
        );
      });

      testWidgets('active — $lang dark', (tester) async {
        final item = _makeItem(
          ledgerType: LedgerType.daily,
          isCompleted: false,
          listType: 'private',
        );
        await tester.pumpWidget(
          _wrap(
            item: item,
            isActive: true,
            locale: locale,
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingItemTile),
          matchesGoldenFile('goldens/shopping_item_tile_active_dark_$lang.png'),
        );
      });

      // --- completed variant: joy-ledger, completed, private list (DONE-01) ---

      testWidgets('completed — $lang light', (tester) async {
        final item = _makeItem(
          ledgerType: LedgerType.joy,
          isCompleted: true,
          listType: 'private',
        );
        await tester.pumpWidget(
          _wrap(item: item, isActive: false, locale: locale),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingItemTile),
          matchesGoldenFile('goldens/shopping_item_tile_completed_$lang.png'),
        );
      });

      testWidgets('completed — $lang dark', (tester) async {
        final item = _makeItem(
          ledgerType: LedgerType.joy,
          isCompleted: true,
          listType: 'private',
        );
        await tester.pumpWidget(
          _wrap(
            item: item,
            isActive: false,
            locale: locale,
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingItemTile),
          matchesGoldenFile(
            'goldens/shopping_item_tile_completed_dark_$lang.png',
          ),
        );
      });

      // --- attribution variant: public list + addedByBookId + shadowBooks override (SYNC-04) ---

      testWidgets('attribution — $lang light', (tester) async {
        final item = _makeItem(
          ledgerType: LedgerType.daily,
          isCompleted: false,
          listType: 'public',
          addedByBookId: 'shadow-book-42',
        );
        await tester.pumpWidget(
          _wrap(
            item: item,
            isActive: true,
            locale: locale,
            shadowBooks: [
              ShadowBookInfo(
                book: _makeBook('shadow-book-42'),
                memberDisplayName: 'Alice',
                memberAvatarEmoji: '🐱',
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingItemTile),
          matchesGoldenFile('goldens/shopping_item_tile_attribution_$lang.png'),
        );
      });

      testWidgets('attribution — $lang dark', (tester) async {
        final item = _makeItem(
          ledgerType: LedgerType.daily,
          isCompleted: false,
          listType: 'public',
          addedByBookId: 'shadow-book-42',
        );
        await tester.pumpWidget(
          _wrap(
            item: item,
            isActive: true,
            locale: locale,
            themeMode: ThemeMode.dark,
            shadowBooks: [
              ShadowBookInfo(
                book: _makeBook('shadow-book-42'),
                memberDisplayName: 'Alice',
                memberAvatarEmoji: '🐱',
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ShoppingItemTile),
          matchesGoldenFile(
            'goldens/shopping_item_tile_attribution_dark_$lang.png',
          ),
        );
      });
    }
  });
}

# Phase 39: i18n + Golden Re-baseline + Smoke Test — Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 8 new/modified files
**Analogs found:** 8 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/golden/shopping_empty_state_golden_test.dart` | test (golden) | request-response | `test/golden/list_empty_state_golden_test.dart` | exact |
| `test/golden/shopping_item_tile_golden_test.dart` | test (golden) | request-response | `test/golden/list_transaction_tile_golden_test.dart` | exact |
| `test/golden/shopping_filter_bar_golden_test.dart` | test (golden) | request-response | `test/golden/list_sort_filter_bar_golden_test.dart` | exact |
| `test/golden/shopping_batch_chrome_golden_test.dart` | test (golden) | request-response | `test/golden/list_sort_filter_bar_golden_test.dart` | role-match |
| `test/integration/presentation/shopping_provider_smoke_test.dart` | test (integration) | streaming | `test/integration/sync/shopping_sync_round_trip_test.dart` | role-match (layer differs) |
| `lib/l10n/app_ja.arb` / `app_zh.arb` / `app_en.arb` | config (i18n) | transform | `lib/l10n/app_ja.arb` (self) | exact |
| `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` | component | request-response | self (line 45 only) | exact |
| `test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart` | test (widget) | request-response | self (lines 9/27/46) | exact |

---

## Pattern Assignments

### `test/golden/shopping_empty_state_golden_test.dart` (test/golden, request-response)

**Analog:** `test/golden/list_empty_state_golden_test.dart`

**Key resolved finding — `context.palette` null-safe fallback (lines 607–617 of `lib/core/theme/app_palette.dart`):**

```dart
extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);
}
```

`ThemeData.light()` / `ThemeData.dark()` do NOT carry the `AppPalette` extension, but the null-safe fallback resolves to `AppPalette.light` / `AppPalette.dark` based on brightness. Bare `ThemeData.light()` / `ThemeData.dark()` therefore works correctly for all shopping widgets that use `context.palette`. No `copyWith(extensions: [...])` is required.

**File header pattern** (lines 1–2 of `list_empty_state_golden_test.dart`):
```dart
@Tags(['golden'])
library;
```

**Imports pattern** (lines 10–18 of `list_empty_state_golden_test.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_empty_state.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';
```

**`_wrap` helper pattern** (adapted from `list_empty_state_golden_test.dart` lines 23–53, adding `currentLocaleProvider` override and `isGroupModeProvider` override):
```dart
Widget _wrap({
  required Locale locale,
  required String listType,
  required bool isGroupMode,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      // Synchronous override — prevents settings-repo async timer pending
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
      theme: ThemeData.light(),     // context.palette fallback resolves correctly
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
```

**Loop-based test structure** (lines 57–93 of `list_empty_state_golden_test.dart`):
```dart
void main() {
  group('ShoppingEmptyState golden', () {
    for (final locale in [const Locale('ja'), const Locale('zh'), const Locale('en')]) {
      for (final (variantName, listType, isGroupMode) in [
        ('private_empty', 'private', false),
        ('public_solo',   'public',  false),
        ('public_family', 'public',  true),
      ]) {
        testWidgets('$variantName — ${locale.languageCode}', (tester) async {
          await tester.pumpWidget(
            _wrap(locale: locale, listType: listType, isGroupMode: isGroupMode));
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(ShoppingEmptyState),
            matchesGoldenFile(
              'goldens/shopping_empty_state_${variantName}_${locale.languageCode}.png'),
          );
        });

        testWidgets('$variantName — ${locale.languageCode} dark', (tester) async {
          await tester.pumpWidget(
            _wrap(locale: locale, listType: listType, isGroupMode: isGroupMode,
                  themeMode: ThemeMode.dark));
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(ShoppingEmptyState),
            matchesGoldenFile(
              'goldens/shopping_empty_state_${variantName}_dark_${locale.languageCode}.png'),
          );
        });
      }
    }
  });
}
```

**Golden file naming convention** (from `list_empty_state_golden_test.dart` line 69):
```
goldens/shopping_empty_state_{variant}_{locale}.png
goldens/shopping_empty_state_{variant}_dark_{locale}.png
```
Total: 3 variants × 3 locales × 2 modes = **18 PNGs**

---

### `test/golden/shopping_item_tile_golden_test.dart` (test/golden, request-response)

**Analog:** `test/golden/list_transaction_tile_golden_test.dart`

**Critical structural requirement — `SliverReorderableList` wrapper** (confirmed in `shopping_item_tile_test.dart` lines 84–121):

`ShoppingItemTile` uses `ReorderableDragStartListener` (for the drag handle). Without a `SliverReorderableList` ancestor, `pumpAndSettle` throws "Reorderable ancestor not found". Wrap as:

```dart
CustomScrollView(
  slivers: [
    SliverReorderableList(
      onReorderItem: (_, _) {},
      itemCount: 1,
      itemBuilder: (ctx, i) => ReorderableDelayedDragStartListener(
        key: ValueKey('tile-$i'),
        index: i,
        child: ShoppingItemTile(item: item, index: i, isActive: isActive),
      ),
    ),
  ],
)
```

**Fixture pattern** (from `shopping_item_tile_test.dart` lines 33–66):
```dart
ShoppingItem _makeItem({
  String id = 'item-golden',
  String listType = 'public',
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

Book _makeBook(String id) => Book(
      id: id, name: 'Alice Book', currency: 'JPY',
      deviceId: 'device-x', createdAt: DateTime(2026),
      ownerDeviceId: 'device-x', ownerDeviceName: 'Alice Device',
    );
```

**Provider overrides for tile variants** (from `shopping_item_tile_test.dart` lines 84–121):
```dart
overrides: [
  locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
  deleteShoppingItemUseCaseProvider.overrideWithValue(mockDelete),
  toggleItemCompletedUseCaseProvider.overrideWithValue(mockToggle),
  shadowBooksProvider.overrideWith((_) async => const <ShadowBookInfo>[]),
  // For attribution chip variant only — populate with one member:
  // shadowBooksProvider.overrideWith((_) async => [
  //   ShadowBookInfo(book: _makeBook(bookId), memberDisplayName: 'Alice',
  //                  memberAvatarEmoji: '🐱'),
  // ]),
]
```

**Mock setup pattern** (from `shopping_item_tile_test.dart` lines 132–148):
```dart
class MockDeleteShoppingItemUseCase extends Mock
    implements DeleteShoppingItemUseCase {}
class MockToggleItemCompletedUseCase extends Mock
    implements ToggleItemCompletedUseCase {}

late MockDeleteShoppingItemUseCase mockDelete;
late MockToggleItemCompletedUseCase mockToggle;

setUp(() {
  mockDelete = MockDeleteShoppingItemUseCase();
  mockToggle = MockToggleItemCompletedUseCase();
  when(() => mockDelete.execute(any()))
      .thenAnswer((_) async => Result.success(null));
  when(() => mockToggle.execute(any()))
      .thenAnswer((_) async => Result.success(_makeItem()));
});
setUpAll(() { registerFallbackValue(''); });
```

**D39-05 ledger assignments (planner discretion):**
- `active` tile → `LedgerType.daily` (daily green border, `palette.daily`)
- `completed` tile → `LedgerType.joy` (joy sakura-pink border, `palette.joy`)
- `attribution chip` tile → `LedgerType.daily`, `listType: 'public'`, `addedByBookId: 'shadow-book-42'`

**Dark mode — tile uses `context.palette` (not explicit params):** No explicit `AppPalette.dark.*` params needed (unlike `ListTransactionTile`). `themeMode: ThemeMode.dark` in `_wrap` suffices because the fallback in `context.palette` returns `AppPalette.dark` when brightness is dark.

**Golden file naming (3 variants × 3 locales × 2 modes = 18 PNGs):**
```
goldens/shopping_item_tile_active_{locale}.png
goldens/shopping_item_tile_active_dark_{locale}.png
goldens/shopping_item_tile_completed_{locale}.png
goldens/shopping_item_tile_completed_dark_{locale}.png
goldens/shopping_item_tile_attribution_{locale}.png
goldens/shopping_item_tile_attribution_dark_{locale}.png
```

**SizedBox dimensions:** 390×80 (matches `list_transaction_tile` tile height convention from `list_transaction_tile_golden_test.dart` line 81).

---

### `test/golden/shopping_filter_bar_golden_test.dart` (test/golden, request-response)

**Analog:** `test/golden/list_sort_filter_bar_golden_test.dart`

**`_wrap` pattern** (from `list_sort_filter_bar_golden_test.dart` lines 24–52, adapted for `ShoppingFilterBar`):
```dart
Widget _wrap({required Locale locale, ThemeMode themeMode = ThemeMode.light}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      // "active" state: override with daily ledger filter active
      shoppingFilterProvider.overrideWith(() {
        final n = ShoppingFilter();
        // Initial state is set via container.read(shoppingFilterProvider.notifier)
        // after pump, or use a FixedShoppingFilter notifier subclass.
        return n;
      }),
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
          height: 44,
          child: ShoppingFilterBar(),
        ),
      ),
    ),
  );
}
```

**"Active" filter state — must inject non-default filter** (from `shopping_filter_bar_test.dart` lines 58–77):
```dart
// After pumpWidget, set ledger filter to daily to make a chip active:
final container = ProviderScope.containerOf(ctx);
container.read(shoppingFilterProvider.notifier).setLedgerFilter(LedgerType.daily);
await tester.pumpAndSettle();
```
OR use a fixed-state notifier subclass for stable golden rendering (avoids needing `Builder` to access the container):
```dart
class _FixedShoppingFilter extends ShoppingFilter {
  @override
  ShoppingListFilter build() => const ShoppingListFilter(ledgerType: LedgerType.daily);
}
// In overrides:
shoppingFilterProvider.overrideWith(() => _FixedShoppingFilter()),
```

**Provider dependency:** `ShoppingFilterBar` reads `shoppingFilterProvider` + `listTypeProvider` (both `keepAlive: true` — `state_shopping_filter.dart` lines 15–28). Override both for golden stability:
```dart
listTypeProvider.overrideWith(() => ListType()),  // default 'private' is fine
shoppingFilterProvider.overrideWith(() => _FixedShoppingFilter()),
```

**Golden file naming (1 state × 3 locales × 2 modes = 6 PNGs):**
```
goldens/shopping_filter_bar_active_{locale}.png
goldens/shopping_filter_bar_active_dark_{locale}.png
```

---

### `test/golden/shopping_batch_chrome_golden_test.dart` (test/golden, request-response)

**Analog:** `test/golden/list_sort_filter_bar_golden_test.dart` (role-match; closest single-widget fixed-size golden)

**Two widgets in one file** — `ShoppingSelectionHeader` (height 48) and `ShoppingBatchActionBar` (height 56). Each gets its own `group` block.

**`ShoppingSelectionHeader` provider override** (from `shopping_selection_header.dart` lines 28–31 and `state_shopping_batch.dart` lines 32–61):
```dart
// Fixed batch state: 2 items selected, batch mode active
class _FixedBatchSelectMode extends BatchSelectMode {
  _FixedBatchSelectMode(this._state);
  final BatchSelectModeState _state;
  @override
  BatchSelectModeState build() => _state;
}

// In overrides:
batchSelectModeProvider.overrideWith(
  () => _FixedBatchSelectMode(
    const BatchSelectModeState(
      isActive: true,
      selectedIds: {'id-1', 'id-2'},
    ),
  ),
),
```

**`ShoppingBatchActionBar` provider override** (must show non-greyed delete button; `shopping_batch_action_bar.dart` line 58 — `selectedIds.isEmpty ? null` guard):
```dart
batchSelectModeProvider.overrideWith(
  () => _FixedBatchSelectMode(
    const BatchSelectModeState(isActive: true, selectedIds: {'id-1'}),
  ),
),
// Also override deleteShoppingItemUseCaseProvider to prevent real DB calls
// (ShoppingBatchActionBar reads it on confirm dialog — not triggered during render,
// but provider must be resolvable)
deleteShoppingItemUseCaseProvider.overrideWithValue(mockDelete),
```

**`ShoppingSelectionHeader` requires `allItemIds` param** (constructor param, line 25):
```dart
ShoppingSelectionHeader(allItemIds: const ['id-1', 'id-2'])
```

**`_wrap` helper pattern** (adapted from `list_sort_filter_bar_golden_test.dart`):
```dart
Widget _wrapHeader({required Locale locale, ThemeMode themeMode = ThemeMode.light}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      batchSelectModeProvider.overrideWith(
        () => _FixedBatchSelectMode(
          const BatchSelectModeState(isActive: true, selectedIds: {'id-1', 'id-2'}),
        ),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [...],
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
```

**Golden file naming (2 widgets × 3 locales × 2 modes = 12 PNGs):**
```
goldens/shopping_selection_header_{locale}.png
goldens/shopping_selection_header_dark_{locale}.png
goldens/shopping_batch_action_bar_{locale}.png
goldens/shopping_batch_action_bar_dark_{locale}.png
```

---

### `test/integration/presentation/shopping_provider_smoke_test.dart` (test/integration, streaming)

**Analog:** `test/integration/sync/shopping_sync_round_trip_test.dart` (role-match; that test covers application layer, this covers presentation/Riverpod layer)

**CRITICAL distinction from Phase 37 test:** The Phase 37 test calls `shoppingItemRepo.watchByListType()` directly. This new test subscribes to `filteredShoppingItemsProvider` (the Riverpod `StreamProvider<List<ShoppingItem>>` in `repository_providers.dart` lines 109–130) — the presentation-layer provider that MUST NOT be `ref.invalidate`'d.

**`waitForFirstValue` helper** (from `test/helpers/test_provider_scope.dart` lines 34–45):
```dart
Future<AsyncValue<T>> waitForFirstValue<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
) {
  final completer = Completer<AsyncValue<T>>();
  final sub = container.listen<AsyncValue<T>>(provider, (_, next) {
    if ((next.hasError || next.hasValue) && !completer.isCompleted) {
      completer.complete(next);
    }
  }, fireImmediately: true);
  return completer.future.whenComplete(sub.close);
}
```

**Dependency wiring pattern** (from `shopping_sync_round_trip_test.dart` lines 29–68):
```dart
late AppDatabase db;
late ShoppingItemRepositoryImpl shoppingItemRepo;
late ApplySyncOperationsUseCase applyOps;
late _MockFieldEncryptionService mockEncryption;
late _MockGroupRepository mockGroupRepository;

setUp(() async {
  db = AppDatabase.forTesting();
  mockEncryption = _MockFieldEncryptionService();
  mockGroupRepository = _MockGroupRepository();

  when(() => mockEncryption.encryptField(any()))
      .thenAnswer((i) async => i.positionalArguments.first as String);
  when(() => mockEncryption.decryptField(any()))
      .thenAnswer((i) async => i.positionalArguments.first as String);
  when(() => mockGroupRepository.getPendingGroup()).thenAnswer((_) async => null);

  final shoppingItemDao = ShoppingItemDao(db);
  shoppingItemRepo = ShoppingItemRepositoryImpl(
    dao: shoppingItemDao, encryptionService: mockEncryption);

  final bookDao = BookDao(db);
  final txDao = TransactionDao(db);
  final bookRepo = BookRepositoryImpl(dao: bookDao);
  final txRepo = TransactionRepositoryImpl(
    dao: txDao, encryptionService: mockEncryption);
  final shadowBookService = ShadowBookService(
    bookRepository: bookRepo, transactionRepository: txRepo);

  applyOps = ApplySyncOperationsUseCase(
    transactionRepository: txRepo,
    shoppingItemRepository: shoppingItemRepo,
    shadowBookService: shadowBookService,
    groupRepository: mockGroupRepository,
  );
});

tearDown(() async { await db.close(); });
```

**Presentation-layer container pattern** (CLAUDE.md Riverpod 3 conventions — `ProviderContainer.test()`):
```dart
// Must override appDatabaseProvider and encryption so filteredShoppingItemsProvider
// resolves through shoppingItemRepositoryProvider → ShoppingItemRepositoryImpl → DAO
final container = ProviderContainer.test(
  overrides: [
    appDatabaseProvider.overrideWithValue(db),
    appFieldEncryptionServiceProvider.overrideWithValue(mockEncryption),
    // listTypeProvider default is 'private' — override to 'public' for public test
    listTypeProvider.overrideWith(() {
      final n = ListType();
      return n;  // then call .setListType('public') after pump
    }),
  ],
);
```

**SC4 reactive test pattern** (D39-06 assertion 1 — subscribe BEFORE write):
```dart
test('SC4: public item via ApplySync → filteredShoppingItemsProvider emits reactively', () async {
  // Subscribe BEFORE the write — Riverpod 3 disposes orphan reads
  // Use container.listen to hold a subscription, then waitForFirstValue
  final sub = container.listen(
    filteredShoppingItemsProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(sub.close);

  await applyOps.execute([{
    'op': 'create',
    'entityType': kShoppingItemEntityType,
    'entityId': 'item-smoke',
    'fromDeviceId': 'partner-device',
    'data': {
      'id': 'item-smoke', 'listType': 'public', 'name': 'Milk',
      'quantity': 1, 'isCompleted': false,
      'createdAt': '2026-06-08T10:00:00.000Z',
    },
  }]);

  // waitForFirstValue settles the Drift stream through Riverpod provider graph
  final result = await waitForFirstValue(container, filteredShoppingItemsProvider);
  expect(result.hasValue, isTrue);
  expect(result.value!.any((i) => i.id == 'item-smoke'), isTrue,
    reason: 'filteredShoppingItemsProvider MUST emit reactively — no ref.invalidate (SC4)');
});
```

**D39-06 privacy re-assertion pattern** (assertion 2 — private item excluded):
```dart
test('D39-06: private item never appears in public filteredShoppingItemsProvider', () async {
  // listTypeProvider set to 'public'
  final sub = container.listen(filteredShoppingItemsProvider, (_, __) {},
    fireImmediately: true);
  addTearDown(sub.close);

  await applyOps.execute([{
    'op': 'create',
    'entityType': kShoppingItemEntityType,
    'entityId': 'private-smoke',
    'fromDeviceId': 'partner-device',
    'data': {
      'id': 'private-smoke', 'listType': 'private', 'name': 'Secret Gift',
      'quantity': 1, 'isCompleted': false,
      'createdAt': '2026-06-08T10:00:00.000Z',
    },
  }]);

  final result = await waitForFirstValue(container, filteredShoppingItemsProvider);
  expect(result.hasValue, isTrue);
  expect(result.value!.any((i) => i.id == 'private-smoke'), isFalse,
    reason: 'Private item must never appear in public stream (D39-06, presentation layer)');
});
```

**Import requirements** (from `shopping_sync_round_trip_test.dart` lines 1–15 + presentation providers):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/shopping_item_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/shopping_item_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_filter.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/test_provider_scope.dart';
```

---

### `lib/l10n/app_ja.arb` / `app_zh.arb` / `app_en.arb` (config/i18n, transform)

**Analog:** Self — the current content of these files as of Phase 38 (1077 non-`@` keys each).

**ARB key structure to change** (confirmed via direct inspection — `home_bottom_nav_bar.dart` line 45 and ARB lines 709/1624):

Current state in all three ARB files:
```json
// Line 709 of each ARB (to RENAME key + UPDATE value):
"homeTabTodo": "買い物リスト",           // ja — becomes: "homeTabShopping": "買い物"
"@homeTabTodo": {
  "description": "Bottom nav todo tab label"
},

// Line 1624 of each ARB (to DELETE entirely — key + metadata):
"todoTab": "やること",                   // ja — DELETE
"@todoTab": {
  "description": "Todo tab label in bottom navigation"
},
```

**Target state after D39-01/02 (all three files, simultaneously):**
```json
// RENAMED + NEW VALUE:
"homeTabShopping": "買い物",     // ja
"homeTabShopping": "购物",       // zh
"homeTabShopping": "Shopping",   // en

"@homeTabShopping": {
  "description": "Bottom nav shopping tab label"
},

// DELETED (both key and metadata):
// "todoTab" — removed entirely
// "@todoTab" — removed entirely
```

**SC1 parity verification command** (after edits):
```bash
jq 'keys | length' lib/l10n/app_ja.arb
jq 'keys | length' lib/l10n/app_zh.arb
jq 'keys | length' lib/l10n/app_en.arb
# All three must output the same integer (expected: 585 non-@ keys × 2 = 1170 total JSON entries)
```

**SC2 zero-hits command:**
```bash
grep -rn 'homeTabTodo\|todoTab\|待办\|Todo' lib/l10n/
# Must return 0 lines
```

**Post-edit command:**
```bash
flutter gen-l10n
# Regenerates lib/generated/app_localizations_ja.dart, ..._zh.dart, ..._en.dart
# Do NOT edit generated files
```

---

### `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` (component, line 45 only)

**Analog:** Self — single call site.

**Current line 45** (`home_bottom_nav_bar.dart`, confirmed by direct inspection):
```dart
l10n.homeTabTodo,   // line 45, inside labels list
```

**Target line 45:**
```dart
l10n.homeTabShopping,
```

No other changes to this file. Icons on lines 28/35 (`shopping_bag_outlined` / `shopping_bag`) are already correct from Phase 38/NAV-02.

---

### `test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart` (test/widget)

**Analog:** Self — update three stale `find.text(...)` assertions.

**Current stale assertions** (lines 9, 27, 46 of the test — confirmed by direct inspection):
```dart
expect(find.text('買い物リスト'), findsOneWidget);    // line 23 — ja
expect(find.text('购物清单'), findsOneWidget);         // line 38 — zh
expect(find.text('Shopping List'), findsOneWidget);   // line 52 — en
```

**Target assertions after D39-01:**
```dart
expect(find.text('買い物'), findsOneWidget);    // ja — shortened per D39-01
expect(find.text('购物'), findsOneWidget);       // zh — shortened
expect(find.text('Shopping'), findsOneWidget);   // en — shortened
```

The `find.text('やること')`/`'待办事项'`/`'Todo'` negation assertions on lines 25/40/55 remain unchanged (they will still correctly return `findsNothing` after deletion of `todoTab`).

---

## Shared Patterns

### Golden Harness — `@Tags(['golden'])` Library Tag
**Source:** All 11 existing golden files, e.g., `test/golden/list_sort_filter_bar_golden_test.dart` lines 1–2
**Apply to:** All 4 new `test/golden/shopping_*_golden_test.dart` files
```dart
@Tags(['golden'])
library;
```
This tag enables `flutter test --tags golden` to run only golden tests.

### Synchronous Locale Override (anti-async-timer)
**Source:** `test/golden/list_sort_filter_bar_golden_test.dart` lines 26–28
**Apply to:** All 4 new golden test files
```dart
// In ProviderScope overrides:
locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
```
Import alias required: `import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart' as locale_providers;`

### `context.palette` null-safe fallback — bare `ThemeData.light()` works
**Source:** `lib/core/theme/app_palette.dart` lines 607–617
**Apply to:** All 4 new golden test files
**Summary:** All shopping widgets use `context.palette`. The `AppPaletteContext` extension has a brightness-aware null-safe fallback: if `ThemeData.extension<AppPalette>()` is null (as with bare `ThemeData.light()`), it returns `AppPalette.light` for light themes and `AppPalette.dark` for dark themes. No `copyWith(extensions: [...])` is needed.

### `ProviderContainer.test()` (Riverpod 3)
**Source:** CLAUDE.md Riverpod 3 conventions section
**Apply to:** `shopping_provider_smoke_test.dart`
```dart
// Use ProviderContainer.test() — NOT ProviderContainer() + addTearDown
final container = ProviderContainer.test(overrides: [...]);
```

### `waitForFirstValue<T>` helper (Riverpod 3 async settlement)
**Source:** `test/helpers/test_provider_scope.dart` lines 34–45
**Apply to:** `shopping_provider_smoke_test.dart`
```dart
import '../../../../helpers/test_provider_scope.dart';
// Usage:
final result = await waitForFirstValue(container, filteredShoppingItemsProvider);
```
NEVER use bare `await container.read(provider.future)` — Riverpod 3 disposes auto-dispose providers before the future resolves.

### `_FixedBatchSelectMode` notifier subclass
**Source:** `test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart` lines 124–130
**Apply to:** `shopping_batch_chrome_golden_test.dart`, and optionally `shopping_item_tile_golden_test.dart`
```dart
class _FixedBatchSelectMode extends BatchSelectMode {
  _FixedBatchSelectMode(this._fixedState);
  final BatchSelectModeState _fixedState;

  @override
  BatchSelectModeState build() => _fixedState;
}
```

### `kShoppingItemEntityType` constant
**Source:** `test/integration/sync/shopping_sync_round_trip_test.dart` line 2 import and line 78
**Apply to:** `shopping_provider_smoke_test.dart`
```dart
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
// Used as: entityType: kShoppingItemEntityType
```

### MaterialApp localization delegates (all golden tests)
**Source:** `test/golden/list_sort_filter_bar_golden_test.dart` lines 33–38
**Apply to:** All 4 new golden test files
```dart
localizationsDelegates: const [
  S.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
supportedLocales: S.supportedLocales,
```

---

## No Analog Found

No files in this phase lack a close analog. All 8 new/modified files have exact or role-match analogs in the existing codebase.

---

## Metadata

**Analog search scope:** `test/golden/`, `test/integration/sync/`, `test/widget/features/shopping_list/`, `lib/features/shopping_list/presentation/`, `lib/features/home/presentation/`, `lib/core/theme/`, `test/helpers/`, `lib/l10n/`
**Files scanned:** 17 source files read directly
**Key insight:** `context.palette` has a null-safe brightness fallback (`app_palette.dart` lines 607–617), so bare `ThemeData.light()` / `ThemeData.dark()` produces correct palette resolution for all shopping widgets — no `AppTheme` import or `.copyWith(extensions: [...])` required.
**Pattern extraction date:** 2026-06-08

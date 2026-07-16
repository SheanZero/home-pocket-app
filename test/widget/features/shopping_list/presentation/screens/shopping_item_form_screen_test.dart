// Widget tests for ShoppingItemFormScreen.
//
// Covers: ITEM-01 (name required validation), ITEM-02 (D4 optional fields),
//         ITEM-04 (edit mode pre-population), G8Z2 (list-type selector fixes),
//         STEPPER-01 (quantity default), LEDGER-NO-NULL-01 (no null toggle),
//         TAGS-D2-01 (edit save passes original item.tags).
//
// Run: flutter test test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/create_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/update_shopping_item_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider, deviceIdentityRepositoryProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart'
    show isGroupModeProvider;
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/screens/shopping_item_form_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:home_pocket/shared/widgets/ledger_type_selector.dart';
import 'package:home_pocket/shared/widgets/list_type_selector.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class _MockCreateShoppingItemUseCase extends Mock
    implements CreateShoppingItemUseCase {}

class _MockUpdateShoppingItemUseCase extends Mock
    implements UpdateShoppingItemUseCase {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

// Fallback values needed by Mocktail for any() matching
class _FakeCreateShoppingItemParams extends Fake
    implements CreateShoppingItemParams {}

class _FakeUpdateShoppingItemParams extends Fake
    implements UpdateShoppingItemParams {}

// ── Fixtures ─────────────────────────────────────────────────────────────────

ShoppingItem _makeItem({
  String id = 'item-1',
  String name = 'Bread',
  String listType = 'private',
  LedgerType? ledgerType,
  String? categoryId,
  int quantity = 2,
  int? estimatedPrice = 350,
  String? note = 'from the bakery',
  List<String> tags = const [],
}) {
  return ShoppingItem(
    id: id,
    deviceId: 'device-1',
    listType: listType,
    name: name,
    ledgerType: ledgerType,
    categoryId: categoryId,
    quantity: quantity,
    estimatedPrice: estimatedPrice,
    note: note,
    tags: tags,
    createdAt: DateTime(2026, 6, 8),
  );
}
// ── Pump helper ──────────────────────────────────────────────────────────────

Future<void> _pumpForm(
  WidgetTester tester, {
  required _MockCreateShoppingItemUseCase createUseCase,
  required _MockUpdateShoppingItemUseCase updateUseCase,
  required _MockDeviceIdentityRepository deviceIdentityRepo,
  _MockCategoryRepository? categoryRepo,
  String listType = 'public',
  ShoppingItem? item,
  bool isGroupMode = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        createShoppingItemUseCaseProvider.overrideWithValue(createUseCase),
        updateShoppingItemUseCaseProvider.overrideWithValue(updateUseCase),
        deviceIdentityRepositoryProvider.overrideWithValue(deviceIdentityRepo),
        isGroupModeProvider.overrideWith((_) => isGroupMode),
        if (categoryRepo != null)
          categoryRepositoryProvider.overrideWithValue(categoryRepo),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: ShoppingItemFormScreen(listType: listType, item: item),
      ),
    ),
  );
  await tester.pump();
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _MockCreateShoppingItemUseCase mockCreate;
  late _MockUpdateShoppingItemUseCase mockUpdate;
  late _MockDeviceIdentityRepository mockDeviceIdentityRepo;

  setUpAll(() {
    registerFallbackValue(_FakeCreateShoppingItemParams());
    registerFallbackValue(_FakeUpdateShoppingItemParams());
  });

  setUp(() {
    mockCreate = _MockCreateShoppingItemUseCase();
    mockUpdate = _MockUpdateShoppingItemUseCase();
    mockDeviceIdentityRepo = _MockDeviceIdentityRepository();

    // Default stubs — override per test as needed
    when(
      () => mockCreate.execute(any()),
    ).thenAnswer((_) async => Result.success(_makeItem()));
    when(
      () => mockUpdate.execute(any()),
    ).thenAnswer((_) async => Result.success(_makeItem()));
    when(
      () => mockDeviceIdentityRepo.getDeviceId(),
    ).thenAnswer((_) async => 'test-device-id');
  });

  // ── ITEM-01: Name field required validation ─────────────────────────────

  group('ITEM-01 — name required validation', () {
    testWidgets(
      'tapping Save with empty name shows validation error; use case NOT called',
      (tester) async {
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
        );
        final nameCard = find.byKey(const Key('shopping_form_name_card'));
        final errorSlot = find.byKey(
          const Key('shopping_form_name_error_slot'),
        );
        final nameHeightBeforeValidation = tester.getSize(nameCard).height;
        final slotHeightBeforeValidation = tester.getSize(errorSlot).height;

        // Tap Save button without entering a name
        await tester.tap(find.text('Save'));
        await tester.pump();

        // Validation error should appear (ITEM-01)
        expect(find.text('Name is required'), findsOneWidget);
        expect(tester.getSize(nameCard).height, nameHeightBeforeValidation);
        expect(tester.getSize(errorSlot).height, slotHeightBeforeValidation);
        expect(slotHeightBeforeValidation, 22);

        // CreateShoppingItemUseCase must NOT have been called
        verifyNever(() => mockCreate.execute(any()));
      },
    );

    testWidgets(
      'entering a name and tapping Save calls CreateShoppingItemUseCase once',
      (tester) async {
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
        );

        // Enter a non-empty name
        await tester.enterText(
          find.byKey(const Key('shopping_form_name_field')),
          'Test Item',
        );
        await tester.pump();

        // Tap Save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // CreateShoppingItemUseCase must have been called exactly once
        verify(() => mockCreate.execute(any())).called(1);
        // UpdateShoppingItemUseCase must NOT be called in create mode
        verifyNever(() => mockUpdate.execute(any()));
      },
    );
  });

  // ── ITEM-02: D4 optional fields present ────────────────────────────────

  group('ITEM-02 — D4 optional fields present', () {
    testWidgets('LedgerTypeSelector widget is present', (tester) async {
      await _pumpForm(
        tester,
        createUseCase: mockCreate,
        updateUseCase: mockUpdate,
        deviceIdentityRepo: mockDeviceIdentityRepo,
      );

      // LedgerTypeSelector must be rendered (ITEM-02)
      expect(
        find.byKey(const Key('shopping_form_ledger_selector')),
        findsOneWidget,
      );
    });

    testWidgets('quantity and estimated price fields are present', (
      tester,
    ) async {
      await _pumpForm(
        tester,
        createUseCase: mockCreate,
        updateUseCase: mockUpdate,
        deviceIdentityRepo: mockDeviceIdentityRepo,
      );

      // Scroll down to ensure quantity and price fields are visible
      // (form is taller now that the list-type selector is always shown).
      await tester.scrollUntilVisible(
        find.byKey(const Key('shopping_form_quantity_field')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(const Key('shopping_form_quantity_field')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('shopping_form_price_field')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(const Key('shopping_form_price_field')),
        findsOneWidget,
      );
    });

    testWidgets('note field is present; tags field is hidden (D-2)', (
      tester,
    ) async {
      await _pumpForm(
        tester,
        createUseCase: mockCreate,
        updateUseCase: mockUpdate,
        deviceIdentityRepo: mockDeviceIdentityRepo,
      );

      // Note field must be present
      expect(find.byKey(const Key('shopping_form_note_field')), findsOneWidget);

      // Tags field hidden per D-2; data passes through transparently.
      expect(find.byKey(const Key('shopping_form_tags_field')), findsNothing);
    });

    testWidgets('category row (InkWell with label) is present', (tester) async {
      await _pumpForm(
        tester,
        createUseCase: mockCreate,
        updateUseCase: mockUpdate,
        deviceIdentityRepo: mockDeviceIdentityRepo,
      );

      // Old OutlinedButton replaced by full-row InkWell.
      // Verify via label text presence instead of the old button key.
      expect(find.text('Category'), findsOneWidget);
    });
  });

  // ── ITEM-04: Edit mode pre-population ──────────────────────────────────

  group('ITEM-04 — edit mode pre-population', () {
    testWidgets('name field pre-populated from item.name', (tester) async {
      final editItem = _makeItem(name: 'Bread');

      await _pumpForm(
        tester,
        createUseCase: mockCreate,
        updateUseCase: mockUpdate,
        deviceIdentityRepo: mockDeviceIdentityRepo,
        item: editItem,
      );

      // Name field should show the item's name (ITEM-04)
      expect(
        find.descendant(
          of: find.byKey(const Key('shopping_form_name_field')),
          matching: find.text('Bread'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('AppBar title says "Edit item" in edit mode', (tester) async {
      final editItem = _makeItem();

      await _pumpForm(
        tester,
        createUseCase: mockCreate,
        updateUseCase: mockUpdate,
        deviceIdentityRepo: mockDeviceIdentityRepo,
        item: editItem,
      );

      expect(find.text('Edit item'), findsOneWidget);
    });

    testWidgets('AppBar title says "Add item" in create mode', (tester) async {
      await _pumpForm(
        tester,
        createUseCase: mockCreate,
        updateUseCase: mockUpdate,
        deviceIdentityRepo: mockDeviceIdentityRepo,
      );

      expect(find.text('Add item'), findsOneWidget);
    });

    testWidgets(
      'save in edit mode calls UpdateShoppingItemUseCase not Create',
      (tester) async {
        final editItem = _makeItem(name: 'Bread');

        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          item: editItem,
        );

        // Tap Save — name is already pre-populated, form is valid
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // UpdateShoppingItemUseCase must be called (ITEM-04)
        verify(() => mockUpdate.execute(any())).called(1);
        // CreateShoppingItemUseCase must NOT be called in edit mode
        verifyNever(() => mockCreate.execute(any()));
      },
    );
  });

  // ── List-type selector (G8Z / G8Z2) ──────────────────────────────────────

  group('List-type selector', () {
    // FORM-SELECTOR-01: selector renders in create mode — solo.
    testWidgets(
      'FORM-SELECTOR-01: selector renders as ListTypeSelector in create mode (isGroupMode=false)',
      (tester) async {
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'public',
          isGroupMode: false,
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('shopping_form_list_type_selector')),
          findsOneWidget,
          reason: 'ListTypeSelector must render in create mode (solo)',
        );
        // Must be a ListTypeSelector widget (not SegmentedButton)
        expect(find.byType(ListTypeSelector), findsOneWidget);
      },
    );

    // FORM-SELECTOR-02: selector renders in create mode — group.
    testWidgets(
      'FORM-SELECTOR-02: selector renders as ListTypeSelector in create mode (isGroupMode=true)',
      (tester) async {
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'public',
          isGroupMode: true,
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('shopping_form_list_type_selector')),
          findsOneWidget,
          reason: 'ListTypeSelector must render in create mode (group)',
        );
        expect(find.byType(ListTypeSelector), findsOneWidget);
      },
    );

    // FORM-SELECTOR-03: selector present but DISABLED in edit mode.
    testWidgets(
      'FORM-SELECTOR-03: selector present but disabled in edit mode (reflects stored listType, tap is no-op)',
      (tester) async {
        final editItem = _makeItem(listType: 'public');

        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'public',
          item: editItem,
        );
        await tester.pumpAndSettle();

        // a) Selector present as ListTypeSelector
        expect(
          find.byKey(const Key('shopping_form_list_type_selector')),
          findsOneWidget,
          reason: 'Selector must be present in edit mode',
        );

        // b) Reflects stored listType: public chip is visually selected
        final widget = tester.widget<ListTypeSelector>(
          find.byKey(const Key('shopping_form_list_type_selector')),
        );
        expect(
          widget.selected,
          equals('public'),
          reason: 'Edit mode must show stored listType as selected',
        );
        expect(
          widget.enabled,
          isFalse,
          reason: 'Edit mode must disable the selector',
        );

        // c) Non-interactive: tap 'Private' chip, selection unchanged
        // (IgnorePointer absorbs the tap — no onChanged fired)
        await tester.tap(
          find.byKey(const ValueKey('list_type_private_chip')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Widget still reflects 'public' (no state change from tap)
        final widgetAfter = tester.widget<ListTypeSelector>(
          find.byKey(const Key('shopping_form_list_type_selector')),
        );
        expect(
          widgetAfter.selected,
          equals('public'),
          reason:
              'Selection must remain public after tapping disabled selector',
        );
      },
    );

    // FORM-SELECTOR-04: v16 uses neutral create guidance and an error-toned
    // immutable hint only in edit mode.
    testWidgets(
      'FORM-SELECTOR-04: create hint is neutral while edit hint is locked',
      (tester) async {
        final editItem = _makeItem(listType: 'private');

        // Edit mode
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'private',
          item: editItem,
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Cannot be changed after creation'),
          findsOneWidget,
          reason: 'Locked-hint caption must be present in edit mode',
        );

        // Create mode — the warning remains informative, not error-toned.
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'public',
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Type cannot be changed after saving'),
          findsOneWidget,
          reason: 'Create mode must explain immutability before first save',
        );
      },
    );

    // FORM-SELECTOR-05: default selection in create mode is 'public'.
    testWidgets(
      'FORM-SELECTOR-05: create mode default selection is public; tapping private then saving submits listType=private',
      (tester) async {
        late CreateShoppingItemParams capturedParams;
        when(() => mockCreate.execute(any())).thenAnswer((inv) async {
          capturedParams =
              inv.positionalArguments.first as CreateShoppingItemParams;
          return Result.success(_makeItem(listType: 'private'));
        });

        // Create mode with default listType='public'
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'public',
          isGroupMode: false,
        );
        await tester.pumpAndSettle();

        // Default selection: 'public'
        final selectorBefore = tester.widget<ListTypeSelector>(
          find.byKey(const Key('shopping_form_list_type_selector')),
        );
        expect(
          selectorBefore.selected,
          equals('public'),
          reason: 'Default selection in create mode must be "public"',
        );

        // Tap 'Private' chip to switch
        await tester.tap(find.byKey(const ValueKey('list_type_private_chip')));
        await tester.pump();

        // Enter a name and save
        await tester.enterText(
          find.byKey(const Key('shopping_form_name_field')),
          'Test Item',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        verify(() => mockCreate.execute(any())).called(1);
        expect(
          capturedParams.listType,
          equals('private'),
          reason:
              'After tapping private, createUseCase must be called with listType=private',
        );
      },
    );

    // FORM-SELECTOR-06: saving without changing list type submits listType='public'.
    testWidgets(
      'FORM-SELECTOR-06: saving in create mode without changing selector submits listType=public',
      (tester) async {
        late CreateShoppingItemParams capturedParams;
        when(() => mockCreate.execute(any())).thenAnswer((inv) async {
          capturedParams =
              inv.positionalArguments.first as CreateShoppingItemParams;
          return Result.success(_makeItem(listType: 'public'));
        });

        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'public',
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('shopping_form_name_field')),
          'Default Item',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        verify(() => mockCreate.execute(any())).called(1);
        expect(
          capturedParams.listType,
          equals('public'),
          reason: 'Default save (no tap) must submit listType=public',
        );
      },
    );
  });

  // ── Ledger default (G8Z2) ─────────────────────────────────────────────────

  group('Ledger default', () {
    testWidgets(
      'LEDGER-DEFAULT-01: create mode ledger chip daily is pre-selected',
      (tester) async {
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'public',
        );
        await tester.pumpAndSettle();

        // LedgerTypeSelector must exist and have daily pre-selected
        final ledgerSelector = tester.widget<LedgerTypeSelector>(
          find.byKey(const Key('shopping_form_ledger_selector')),
        );
        expect(
          ledgerSelector.selected,
          equals(LedgerType.daily),
          reason: 'Create mode must pre-select daily ledger',
        );
      },
    );

    testWidgets(
      'LEDGER-DEFAULT-02: save without changing ledger calls createUseCase with ledgerType=daily',
      (tester) async {
        late CreateShoppingItemParams capturedParams;
        when(() => mockCreate.execute(any())).thenAnswer((inv) async {
          capturedParams =
              inv.positionalArguments.first as CreateShoppingItemParams;
          return Result.success(_makeItem());
        });

        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'public',
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('shopping_form_name_field')),
          'Milk',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        verify(() => mockCreate.execute(any())).called(1);
        expect(
          capturedParams.ledgerType,
          equals(LedgerType.daily),
          reason: 'Default save must submit ledgerType=daily',
        );
      },
    );
  });

  // ── Selector ordering (G8Z2) ──────────────────────────────────────────────

  group('Selector ordering', () {
    testWidgets(
      'ORDER-01: ListTypeSelector appears after LedgerTypeSelector in the form',
      (tester) async {
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'public',
        );
        await tester.pumpAndSettle();

        final ledgerOffset = tester.getTopLeft(
          find.byKey(const Key('shopping_form_ledger_selector')),
        );
        final listTypeOffset = tester.getTopLeft(
          find.byKey(const Key('shopping_form_list_type_selector')),
        );
        expect(
          ledgerOffset.dy,
          lessThan(listTypeOffset.dy),
          reason: 'Ledger selector must appear above the list-type selector',
        );
      },
    );
  });

  // ── New tests for redesigned UI ───────────────────────────────────────────

  group('Stepper', () {
    testWidgets('STEPPER-01: create mode quantity defaults to 1', (
      tester,
    ) async {
      await _pumpForm(
        tester,
        createUseCase: mockCreate,
        updateUseCase: mockUpdate,
        deviceIdentityRepo: mockDeviceIdentityRepo,
      );
      await tester.pumpAndSettle();

      final qField = tester.widget<TextField>(
        find.byKey(const Key('shopping_form_quantity_field')),
      );
      expect(qField.controller?.text, equals('1'));
    });
  });

  group('Ledger non-null invariant', () {
    testWidgets(
      'LEDGER-NO-NULL-01: tapping active daily chip keeps ledger = daily (no null toggle)',
      (tester) async {
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
        );
        await tester.pumpAndSettle();

        // Tap daily chip (already selected)
        await tester.tap(find.byKey(const ValueKey('ledger_type_daily_chip')));
        await tester.pump();

        final sel = tester.widget<LedgerTypeSelector>(
          find.byKey(const Key('shopping_form_ledger_selector')),
        );
        expect(
          sel.selected,
          equals(LedgerType.daily),
          reason: 'Tapping active chip must not toggle to null',
        );
      },
    );
  });

  group('Tags D-2 passthrough', () {
    testWidgets('TAGS-D2-01: edit save passes original item.tags through', (
      tester,
    ) async {
      late UpdateShoppingItemParams capturedParams;
      when(() => mockUpdate.execute(any())).thenAnswer((inv) async {
        capturedParams =
            inv.positionalArguments.first as UpdateShoppingItemParams;
        return Result.success(_makeItem());
      });

      // Use an item with a non-empty tags list for a meaningful assertion.
      final editItem = _makeItem(name: 'Bread', tags: ['organic', 'bakery']);
      await _pumpForm(
        tester,
        createUseCase: mockCreate,
        updateUseCase: mockUpdate,
        deviceIdentityRepo: mockDeviceIdentityRepo,
        item: editItem,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockUpdate.execute(any())).called(1);
      expect(
        capturedParams.tags,
        equals(editItem.tags),
        reason: 'Edit save must pass original item.tags through (D-2)',
      );
    });
  });

  // ── Category display — localized name, NOT the raw key/id ─────────────────
  group('Category display localization', () {
    testWidgets(
      'CATEGORY-DISPLAY-01: built-in category renders localized name, not the raw key',
      (tester) async {
        // A system category stores a localization KEY in `name` (e.g.
        // 'category_food'); the form must resolve it via
        // CategoryLocalizationService — never render the raw key/id (the bug).
        final mockCategoryRepo = _MockCategoryRepository();
        when(() => mockCategoryRepo.findById('cat_food')).thenAnswer(
          (_) async => Category(
            id: 'cat_food',
            name: 'category_food', // localization key, not display text
            icon: 'restaurant',
            color: '#FF5722',
            level: 1,
            isSystem: true,
            createdAt: DateTime(2026, 6, 8),
          ),
        );

        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          categoryRepo: mockCategoryRepo,
          item: _makeItem(categoryId: 'cat_food'),
        );
        await tester.pumpAndSettle();

        // Default test locale is ja → 'category_food' resolves to '食費'.
        // L1 category has no parent → path is just the child name.
        expect(
          find.text('食費'),
          findsOneWidget,
          reason: 'Category must show the localized display name',
        );
        expect(
          find.text('category_food'),
          findsNothing,
          reason: 'Raw localization key/id must NEVER be rendered',
        );
      },
    );

    testWidgets(
      'CATEGORY-DISPLAY-02: L2 category renders full "parent > child" path',
      (tester) async {
        // L2 category: parent resolved from parentId → "食費 > 食料品" (ja).
        final mockCategoryRepo = _MockCategoryRepository();
        when(() => mockCategoryRepo.findById('cat_food_groceries')).thenAnswer(
          (_) async => Category(
            id: 'cat_food_groceries',
            name: 'category_food_groceries', // ja → 食料品
            icon: 'shopping_basket',
            color: '#FF5722',
            parentId: 'cat_food',
            level: 2,
            isSystem: true,
            createdAt: DateTime(2026, 6, 8),
          ),
        );
        when(() => mockCategoryRepo.findById('cat_food')).thenAnswer(
          (_) async => Category(
            id: 'cat_food',
            name: 'category_food', // ja → 食費
            icon: 'restaurant',
            color: '#FF5722',
            level: 1,
            isSystem: true,
            createdAt: DateTime(2026, 6, 8),
          ),
        );

        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          categoryRepo: mockCategoryRepo,
          item: _makeItem(categoryId: 'cat_food_groceries'),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('食費 > 食料品'),
          findsOneWidget,
          reason: 'L2 category must render the full parent > child path',
        );
      },
    );
  });
}

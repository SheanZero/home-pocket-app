// Widget tests for ShoppingItemFormScreen.
//
// Covers: ITEM-01 (name required validation), ITEM-02 (D4 optional fields),
//         ITEM-04 (edit mode pre-population).
//
// Run: flutter test test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/create_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/update_shopping_item_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show deviceIdentityRepositoryProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart'
    show isGroupModeProvider;
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/screens/shopping_item_form_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class _MockCreateShoppingItemUseCase extends Mock
    implements CreateShoppingItemUseCase {}

class _MockUpdateShoppingItemUseCase extends Mock
    implements UpdateShoppingItemUseCase {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

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
    createdAt: DateTime(2026, 6, 8),
  );
}

// ── Pump helper ──────────────────────────────────────────────────────────────

Future<void> _pumpForm(
  WidgetTester tester, {
  required _MockCreateShoppingItemUseCase createUseCase,
  required _MockUpdateShoppingItemUseCase updateUseCase,
  required _MockDeviceIdentityRepository deviceIdentityRepo,
  String listType = 'private',
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
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: ShoppingItemFormScreen(
          listType: listType,
          item: item,
        ),
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
    when(() => mockCreate.execute(any()))
        .thenAnswer((_) async => Result.success(_makeItem()));
    when(() => mockUpdate.execute(any()))
        .thenAnswer((_) async => Result.success(_makeItem()));
    when(() => mockDeviceIdentityRepo.getDeviceId())
        .thenAnswer((_) async => 'test-device-id');
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

      // Tap Save button without entering a name
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Validation error should appear (ITEM-01)
      expect(find.text('Name is required'), findsOneWidget);

      // CreateShoppingItemUseCase must NOT have been called
      verifyNever(() => mockCreate.execute(any()));
    });

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
      await tester.enterText(find.byKey(const Key('shopping_form_name_field')), 'Test Item');
      await tester.pump();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // CreateShoppingItemUseCase must have been called exactly once
      verify(() => mockCreate.execute(any())).called(1);
      // UpdateShoppingItemUseCase must NOT be called in create mode
      verifyNever(() => mockUpdate.execute(any()));
    });
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

    testWidgets('quantity and estimated price fields are present', (tester) async {
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

    testWidgets('note and tags fields are present', (tester) async {
      await _pumpForm(
        tester,
        createUseCase: mockCreate,
        updateUseCase: mockUpdate,
        deviceIdentityRepo: mockDeviceIdentityRepo,
      );

      expect(
        find.byKey(const Key('shopping_form_note_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopping_form_tags_field')),
        findsOneWidget,
      );
    });

    testWidgets('category picker button is present', (tester) async {
      await _pumpForm(
        tester,
        createUseCase: mockCreate,
        updateUseCase: mockUpdate,
        deviceIdentityRepo: mockDeviceIdentityRepo,
      );

      expect(
        find.byKey(const Key('shopping_form_category_button')),
        findsOneWidget,
      );
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

    testWidgets('save in edit mode calls UpdateShoppingItemUseCase not Create',
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
    });
  });

  // ── List-type selector (G8Z) ──────────────────────────────────────────

  group('List-type selector', () {
    // FORM-SELECTOR-01: selector renders interactive in create mode — solo.
    testWidgets(
      'FORM-SELECTOR-01: selector renders interactive in create mode (isGroupMode=false)',
      (tester) async {
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'private',
          isGroupMode: false,
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('shopping_form_list_type_selector')),
          findsOneWidget,
          reason: 'Selector must render in create mode (solo)',
        );
      },
    );

    // FORM-SELECTOR-02: selector renders interactive in create mode — group.
    testWidgets(
      'FORM-SELECTOR-02: selector renders interactive in create mode (isGroupMode=true)',
      (tester) async {
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'private',
          isGroupMode: true,
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('shopping_form_list_type_selector')),
          findsOneWidget,
          reason: 'Selector must render in create mode (group)',
        );
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

        // a) Selector present
        expect(
          find.byKey(const Key('shopping_form_list_type_selector')),
          findsOneWidget,
          reason: 'Selector must be present in edit mode',
        );

        // b) Reflects stored listType: 'public' segment is selected
        final button = tester.widget<SegmentedButton<String>>(
          find.byKey(const Key('shopping_form_list_type_selector')),
        );
        expect(button.selected, contains('public'),
            reason: 'Edit mode must show stored listType as selected');

        // c) Non-interactive: tap 'Private' segment, selection unchanged
        await tester.tap(find.text('Private'));
        await tester.pumpAndSettle();

        final buttonAfterTap = tester.widget<SegmentedButton<String>>(
          find.byKey(const Key('shopping_form_list_type_selector')),
        );
        expect(buttonAfterTap.selected, contains('public'),
            reason: 'Selection must remain public after tapping disabled selector');
      },
    );

    // FORM-SELECTOR-04: locked-hint caption present in edit mode, absent in create mode.
    testWidgets(
      'FORM-SELECTOR-04: locked-hint caption present in edit mode, absent in create mode',
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

        // Create mode
        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'private',
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Cannot be changed after creation'),
          findsNothing,
          reason: 'Locked-hint caption must be absent in create mode',
        );
      },
    );

    // FORM-SELECTOR-05: tapping public segment in create mode calls createUseCase with listType=public.
    testWidgets(
      'FORM-SELECTOR-05: tapping public segment in create mode submits listType=public',
      (tester) async {
        late CreateShoppingItemParams capturedParams;
        when(() => mockCreate.execute(any())).thenAnswer((inv) async {
          capturedParams = inv.positionalArguments.first as CreateShoppingItemParams;
          return Result.success(_makeItem(listType: 'public'));
        });

        await _pumpForm(
          tester,
          createUseCase: mockCreate,
          updateUseCase: mockUpdate,
          deviceIdentityRepo: mockDeviceIdentityRepo,
          listType: 'private',
          isGroupMode: false,
        );
        await tester.pumpAndSettle();

        // Tap 'Public' segment
        await tester.tap(find.text('Public'));
        await tester.pumpAndSettle();

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
          equals('public'),
          reason: 'createUseCase must be called with listType=public',
        );
      },
    );
  });
}

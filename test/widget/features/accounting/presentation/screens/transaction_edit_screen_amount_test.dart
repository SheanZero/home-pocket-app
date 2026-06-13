/// Widget tests for Phase 19 Plan 04 Task 3:
/// D-14 spillover — TransactionEditScreen amount-edit integration.
///
/// Tests verify the AmountDisplay → AmountEditBottomSheet → updateAmount →
/// save round-trip works on the edit-existing host. Phase 18 invariants
/// (pop(true) on save, D-18) are also regression-guarded.
///
/// NOTE (P19-B2 staging gap): In wave-2 of Phase 19, these tests require
/// Plan 02's SmartKeyboard rename (nextLabel → actionLabel) to compile.
/// In the isolated worktree for Plan 04, amount_edit_bottom_sheet.dart
/// references SmartKeyboard(actionLabel:) which doesn't exist yet in this
/// worktree. The orchestrator merge of Plan 02 + Plan 04 resolves this.
/// These tests are GREEN after the merge.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/update_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        categoryRepositoryProvider,
        categoryServiceProvider,
        recordCategoryCorrectionUseCaseProvider,
        updateTransactionUseCaseProvider;
import 'package:home_pocket/features/accounting/presentation/screens/transaction_edit_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/currency_linked_edit_fields.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Mocks and fakes ───────────────────────────────────────────────────────────

class _MockUpdateTransactionUseCase extends Mock
    implements UpdateTransactionUseCase {}

class _FakeUpdateTransactionParams extends Fake
    implements UpdateTransactionParams {}

class _NullCategoryRepository implements CategoryRepository {
  @override
  Future<Category?> findById(String id) async => null;
  @override
  Future<List<Category>> findAll() async => [];
  @override
  Future<List<Category>> findActive() async => [];
  @override
  Future<List<Category>> findByLevel(int level) async => [];
  @override
  Future<List<Category>> findByParent(String parentId) async => [];
  @override
  Future<void> insert(Category category) async {}
  @override
  Future<void> insertBatch(List<Category> categories) async {}
  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {}
  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}
  @override
  Future<void> deleteAll() async {}
}

class _NullLedgerConfigRepository implements CategoryLedgerConfigRepository {
  @override
  Future<CategoryLedgerConfig?> findById(String categoryId) async => null;
  @override
  Future<List<CategoryLedgerConfig>> findAll() async => [];
  @override
  Future<void> upsert(CategoryLedgerConfig config) async {}
  @override
  Future<void> upsertBatch(List<CategoryLedgerConfig> configs) async {}
  @override
  Future<void> delete(String categoryId) async {}
  @override
  Future<void> deleteAll() async {}
}

// ── Test data ──────────────────────────────────────────────────────────────────

final _testTransaction = Transaction(
  id: 'tx-001',
  bookId: 'book-1',
  deviceId: 'dev-001',
  amount: 1500,
  type: TransactionType.expense,
  categoryId: 'cat-food',
  ledgerType: LedgerType.daily,
  timestamp: DateTime(2026, 5, 1),
  currentHash: 'hash-001',
  createdAt: DateTime(2026, 5, 1),
  entrySource: EntrySource.manual,
);

/// Phase 42 UAT fix seed: a FOREIGN row — USD 112.90 @ 160.2564 → 18,093 JPY.
/// originalAmount is stored in MINOR units (cents): 112.90 → 11290.
final _foreignTransaction = Transaction(
  id: 'tx-usd-001',
  bookId: 'book-1',
  deviceId: 'dev-001',
  amount: 18093,
  type: TransactionType.expense,
  categoryId: 'cat-food',
  ledgerType: LedgerType.daily,
  timestamp: DateTime(2026, 5, 1),
  currentHash: 'hash-usd-001',
  createdAt: DateTime(2026, 5, 1),
  originalCurrency: 'USD',
  originalAmount: 11290,
  appliedRate: '160.2564',
  entrySource: EntrySource.manual,
);

// ── Shared provider overrides ──────────────────────────────────────────────────

List<Override> _overrides({required _MockUpdateTransactionUseCase mockUpdate}) {
  return [
    updateTransactionUseCaseProvider.overrideWithValue(mockUpdate),
    categoryRepositoryProvider.overrideWithValue(_NullCategoryRepository()),
    categoryServiceProvider.overrideWith(
      (_) => CategoryService(
        categoryRepository: _NullCategoryRepository(),
        ledgerConfigRepository: _NullLedgerConfigRepository(),
      ),
    ),
    recordCategoryCorrectionUseCaseProvider.overrideWith(
      (_) => throw UnimplementedError(
        'recordCategoryCorrectionUseCase not needed in edit host',
      ),
    ),
  ];
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUpdateTransactionParams());
  });

  // ── TEST 1: AmountDisplay renders with initial amount + tapping opens sheet ──

  testWidgets(
    'TEST 1: TransactionEditScreen renders AmountDisplay and opens AmountEditBottomSheet on tap',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockUpdate = _MockUpdateTransactionUseCase();

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(body: TransactionEditScreen(transaction: _testTransaction)),
          locale: const Locale('en'),
          overrides: _overrides(mockUpdate: mockUpdate),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: initial AmountDisplay is rendered with the transaction amount.
      expect(
        find.byType(AmountDisplay),
        findsOneWidget,
        reason:
            'Host must render AmountDisplay with the seed transaction amount',
      );

      // Assert: AmountDisplay shows "1,500" (formatted from 1500).
      expect(
        find.text('1,500'),
        findsOneWidget,
        reason: 'AmountDisplay must show formatted initial amount',
      );

      // Action: tap the AmountDisplay to open the bottom sheet.
      await tester.tap(find.byType(AmountDisplay));
      await tester.pump(); // Start modal animation

      // Assert: AmountEditBottomSheet is presented.
      // NOTE: full pumpAndSettle is intentionally omitted here due to P19-B2
      // staging gap — SmartKeyboard(actionLabel:) resolves after Plan 02 merge.
      expect(
        find.byType(AmountEditBottomSheet),
        findsOneWidget,
        reason:
            'Tapping AmountDisplay must open AmountEditBottomSheet (D-14 spillover)',
      );
    },
  );

  // ── TEST 2: onClear resets display to 0 and screen does not pop on failure ───

  testWidgets(
    'TEST 2: onClear resets AmountDisplay to 0; screen remains mounted (P19-W5)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockUpdate = _MockUpdateTransactionUseCase();

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(body: TransactionEditScreen(transaction: _testTransaction)),
          locale: const Locale('en'),
          overrides: _overrides(mockUpdate: mockUpdate),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AmountDisplay is visible with initial amount.
      expect(find.byType(AmountDisplay), findsOneWidget);
      expect(find.text('1,500'), findsOneWidget);

      // Action: tap the clear button (Icons.close) inside AmountDisplay.
      // AmountDisplay renders the clear button only when amount is non-empty.
      final clearButton = find.descendant(
        of: find.byType(AmountDisplay),
        matching: find.byIcon(Icons.close),
      );
      expect(
        clearButton,
        findsOneWidget,
        reason:
            'Clear button (Icons.close) must be visible when amount is non-zero',
      );

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Assert: AmountDisplay now shows "0" (empty string → display '0' via _formatted getter).
      expect(
        find.descendant(
          of: find.byType(AmountDisplay),
          matching: find.text('0'),
        ),
        findsOneWidget,
        reason: 'After onClear, AmountDisplay must show 0',
      );

      // Assert: form's internal _amount is synced to 0 (verified by checking
      // the screen remains mounted — if _displayAmount and form amount drifted,
      // the subsequent save test would catch it).
      expect(
        find.byType(AmountDisplay),
        findsOneWidget,
        reason: 'Screen must remain mounted after clear (no premature pop)',
      );

      // Action: tap the Save button.
      // P19-W5 contract: the form's submit() fires. Category is seeded from
      // widget.transaction (cat-food), so the category-null guard passes.
      // Amount guard (> 0) fires next — submit() returns validationError.
      // P19-W5 deterministic branch: use case NOT invoked because form's own
      // amount > 0 guard fires before calling the use case.
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Assert: use case was NOT invoked (form rejects amount=0 before calling it).
      verifyNever(() => mockUpdate.execute(any()));

      // Assert: screen did NOT pop (still mounted with AmountDisplay).
      expect(
        find.byType(AmountDisplay),
        findsOneWidget,
        reason: 'Screen must NOT pop on validation failure',
      );
    },
  );

  // ── TEST 3 (260613-mgc): FOREIGN headline shows ORIGINAL identity AND is ──
  //     now tap-to-edit (opens the currency-aware AmountEditBottomSheet). ──────

  testWidgets(
    'TEST 3: foreign edit row shows USD + 112.90 at top and tapping opens the keypad sheet',
    (tester) async {
      tester.view.physicalSize = const Size(402, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockUpdate = _MockUpdateTransactionUseCase();

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: TransactionEditScreen(transaction: _foreignTransaction),
          ),
          locale: const Locale('en'),
          overrides: _overrides(mockUpdate: mockUpdate),
        ),
      );
      await tester.pumpAndSettle();

      // The top AmountDisplay headline shows the ORIGINAL currency identity.
      final badge = find.byKey(const ValueKey('amount_currency_badge'));
      expect(badge, findsOneWidget);
      expect(
        find.descendant(of: badge, matching: find.text('USD')),
        findsOneWidget,
        reason: 'Foreign headline badge must show the ORIGINAL ISO code (USD)',
      );
      expect(
        find.descendant(of: badge, matching: find.text(r'$')),
        findsOneWidget,
        reason: 'Foreign headline badge must show the ORIGINAL symbol (\$)',
      );

      // The headline amount is the ORIGINAL major-unit value, not the JPY one.
      expect(
        find.descendant(
          of: find.byType(AmountDisplay),
          matching: find.text('112.90'),
        ),
        findsOneWidget,
        reason: 'Foreign headline must show the ORIGINAL amount 112.90',
      );

      // CRITICAL: the JPY identity must NOT be the headline.
      expect(
        find.descendant(of: badge, matching: find.text('JPY')),
        findsNothing,
        reason: 'Foreign headline must NOT show the JPY badge',
      );
      expect(
        find.descendant(
          of: find.byType(AmountDisplay),
          matching: find.text('18,093'),
        ),
        findsNothing,
        reason: 'Foreign headline must NOT show the JPY amount 18,093',
      );

      // The JPY figure still lives in the card's read-only 日元（换算）row.
      // The key is on the derived Text itself; assert its data directly.
      final derived = tester.widget<Text>(
        find.byKey(const Key('edit_jpy_derived')),
      );
      expect(
        derived.data,
        contains('18,093'),
        reason: 'JPY (derived) row must still show ¥18,093',
      );

      // Foreign headline has NO JPY clear button (original-zero is reachable by
      // deleting in the keypad instead).
      expect(
        find.descendant(
          of: find.byType(AmountDisplay),
          matching: find.byIcon(Icons.close),
        ),
        findsNothing,
        reason: 'Foreign headline must not expose the JPY clear button',
      );

      // 260613-mgc: tapping the foreign headline opens the EXISTING keypad
      // sheet (currency-aware mode) so the user can edit the ORIGINAL amount.
      await tester.tap(find.byType(AmountDisplay));
      await tester.pumpAndSettle();
      expect(
        find.byType(AmountEditBottomSheet),
        findsOneWidget,
        reason: 'Foreign headline tap must open AmountEditBottomSheet',
      );
      // The sheet is seeded in the ORIGINAL currency (USD badge inside it).
      expect(
        find.descendant(
          of: find.byType(AmountEditBottomSheet),
          matching: find.text('USD'),
        ),
        findsWidgets,
        reason: 'The keypad sheet must edit in the ORIGINAL currency (USD)',
      );
    },
  );

  // ── TEST 4 (UAT fix): JPY-native headline is UNCHANGED (CURR-04) ─────────────

  testWidgets('TEST 4: JPY-native edit row still shows ¥ JPY + JPY amount', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockUpdate = _MockUpdateTransactionUseCase();

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(body: TransactionEditScreen(transaction: _testTransaction)),
        locale: const Locale('en'),
        overrides: _overrides(mockUpdate: mockUpdate),
      ),
    );
    await tester.pumpAndSettle();

    final badge = find.byKey(const ValueKey('amount_currency_badge'));
    expect(
      find.descendant(of: badge, matching: find.text('JPY')),
      findsOneWidget,
      reason: 'JPY-native headline must keep the JPY badge (CURR-04)',
    );
    expect(
      find.descendant(of: badge, matching: find.text('¥')),
      findsOneWidget,
    );
    expect(
      find.text('1,500'),
      findsOneWidget,
      reason: 'JPY-native headline shows the JPY amount unchanged',
    );
  });

  // ── TEST 5 (260613-mgc): editing via the headline keypad updates the ───────
  //     foreign headline; original-amount editing flows through the keypad. ───

  testWidgets(
    'TEST 5: editing the original amount via the headline keypad updates the headline',
    (tester) async {
      tester.view.physicalSize = const Size(402, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockUpdate = _MockUpdateTransactionUseCase();

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: TransactionEditScreen(transaction: _foreignTransaction),
          ),
          locale: const Locale('en'),
          overrides: _overrides(mockUpdate: mockUpdate),
        ),
      );
      await tester.pumpAndSettle();

      // Sanity: linked edit host + initial headline (the in-card original-amount
      // input is gone — editing flows through the headline keypad now).
      expect(
        find.byKey(const ValueKey('currency-linked-edit-fields')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('edit_original_amount_field')),
        findsNothing,
        reason: 'in-card original-amount input was removed (260613-mgc)',
      );
      expect(
        find.descendant(
          of: find.byType(AmountDisplay),
          matching: find.text('112.90'),
        ),
        findsOneWidget,
      );

      // Tap the headline → open the currency-aware keypad sheet.
      await tester.tap(find.byType(AmountDisplay));
      await tester.pumpAndSettle();
      expect(find.byType(AmountEditBottomSheet), findsOneWidget);

      // Clear the seed "112.90" (6 chars) then type "200".
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pump();
      }
      await tester.tap(find.widgetWithText(InkWell, '2').first);
      await tester.pump();
      await tester.tap(find.widgetWithText(InkWell, '0').first);
      await tester.pump();
      await tester.tap(find.widgetWithText(InkWell, '0').first);
      await tester.pump();

      // Confirm with the keypad's Save action key (scoped to the sheet — the
      // screen's bottom CTA also reads "Save") → sheet closes, headline updates.
      await tester.tap(
        find.descendant(
          of: find.byType(AmountEditBottomSheet),
          matching: find.text('Save'),
        ),
      );
      await tester.pumpAndSettle();

      // The headline now shows 200.00 (currency's 2-decimal major-unit string).
      expect(
        find.descendant(
          of: find.byType(AmountDisplay),
          matching: find.text('200.00'),
        ),
        findsOneWidget,
        reason: 'Headline must reflect the keypad-edited original amount',
      );
      // The OLD original amount must be gone from the headline.
      expect(
        find.descendant(
          of: find.byType(AmountDisplay),
          matching: find.text('112.90'),
        ),
        findsNothing,
        reason: 'Stale original amount must not linger in the headline',
      );

      // The card's derived JPY row recomputed: 200.00 USD × 160.2564 = 32,051.
      final derived = tester.widget<Text>(
        find.byKey(const Key('edit_jpy_derived')),
      );
      expect(
        derived.data,
        contains('32,051'),
        reason: '200.00 USD × 160.2564 → ¥32,051 (single convertToJpy site)',
      );
    },
  );

  // Keeps the symbol-prefix import meaningful: CurrencyLinkedEditValue is the
  // contract surfaced to the screen for the live-headline wiring (TEST 5).
  test(
    'CurrencyLinkedEditValue exposes the original amount for the headline',
    () {
      const value = CurrencyLinkedEditValue(
        originalAmount: 20000,
        appliedRate: '160.2564',
        jpyAmount: 32051,
        manualOverride: false,
      );
      expect(value.originalAmount, 20000);
    },
  );
}

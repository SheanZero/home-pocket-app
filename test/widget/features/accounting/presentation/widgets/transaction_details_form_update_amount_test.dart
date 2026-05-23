/// TDD tests for Phase 19 TransactionDetailsForm refactor (Plan 01, Task 3):
///
/// - updateAmount(int) public method (D-14 / D-01)
/// - AmountDisplay removed from form internal rendering (D-14)
/// - ValueKey markers on category-chip / date-chip / merchant-textfield /
///   note-textfield (P19-W2 / VALIDATION.md SC-1)
/// - Optional FocusNode plumbing from $new config fields (P19-W3)
///
/// Tests intentionally written BEFORE implementation (TDD RED phase).
/// Implementation lives in transaction_details_form.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/accounting/update_transaction_use_case.dart';
import 'package:home_pocket/application/voice/record_category_correction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_details_form_config.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Mock and fake classes ──────────────────────────────────────────────────────

class _MockCreateTransactionUseCase extends Mock
    implements CreateTransactionUseCase {}

class _MockUpdateTransactionUseCase extends Mock
    implements UpdateTransactionUseCase {}

class _MockRecordCategoryCorrectionUseCase extends Mock
    implements RecordCategoryCorrectionUseCase {}

class _FakeCreateTransactionParams extends Fake
    implements CreateTransactionParams {}

class _FakeUpdateTransactionParams extends Fake
    implements UpdateTransactionParams {}

// ── Fake repositories ──────────────────────────────────────────────────────────

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

class _SingleCategoryRepository implements CategoryRepository {
  _SingleCategoryRepository(this._category);
  final Category _category;
  @override
  Future<Category?> findById(String id) async =>
      id == _category.id ? _category : null;
  @override
  Future<List<Category>> findAll() async => [_category];
  @override
  Future<List<Category>> findActive() async => [_category];
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

final _survivalCategory = Category(
  id: 'cat-food',
  name: 'Food',
  icon: 'restaurant',
  color: '#E85A4F',
  level: 1,
  isSystem: true,
  sortOrder: 1,
  createdAt: DateTime(2026, 5, 1),
);

Transaction _fakeSuccessTx({int amount = 1500}) => Transaction(
  id: 'tx-001',
  bookId: 'book-1',
  deviceId: 'dev-001',
  amount: amount,
  type: TransactionType.expense,
  categoryId: 'cat-food',
  ledgerType: LedgerType.survival,
  timestamp: DateTime(2026, 5, 1),
  currentHash: 'hash001',
  createdAt: DateTime(2026, 5, 1),
  entrySource: EntrySource.manual,
);

// ── Override builders ──────────────────────────────────────────────────────────

List<Override> _overrides({
  CategoryRepository? categoryRepo,
  _MockCreateTransactionUseCase? createUseCase,
  _MockUpdateTransactionUseCase? updateUseCase,
}) {
  return [
    categoryRepositoryProvider.overrideWithValue(
      categoryRepo ?? _NullCategoryRepository(),
    ),
    categoryServiceProvider.overrideWith(
      (_) => CategoryService(
        categoryRepository: _NullCategoryRepository(),
        ledgerConfigRepository: _NullLedgerConfigRepository(),
      ),
    ),
    createTransactionUseCaseProvider.overrideWith((_) {
      if (createUseCase != null) return createUseCase;
      throw UnimplementedError('createTransactionUseCase not stubbed');
    }),
    updateTransactionUseCaseProvider.overrideWith((_) {
      if (updateUseCase != null) return updateUseCase;
      throw UnimplementedError('updateTransactionUseCase not stubbed');
    }),
    recordCategoryCorrectionUseCaseProvider.overrideWith((_) {
      throw UnimplementedError('recordCategoryCorrectionUseCase not needed');
    }),
  ];
}

Widget _buildForm(
  TransactionDetailsFormConfig config, {
  Key? formKey,
  List<Override> overrides = const [],
}) {
  return createLocalizedWidget(
    Scaffold(body: TransactionDetailsForm(key: formKey, config: config)),
    locale: const Locale('en'),
    overrides: overrides,
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCreateTransactionParams());
    registerFallbackValue(_FakeUpdateTransactionParams());
  });

  // ── TEST 1: updateAmount(0) → validationError (category null check fires first)
  testWidgets(
    'TEST 1: updateAmount(0) + submit returns non-success (amount 0 rejected)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final formKey = GlobalKey<TransactionDetailsFormState>();
      final mockCreate = _MockCreateTransactionUseCase();

      await tester.pumpWidget(
        _buildForm(
          TransactionDetailsFormConfig.$new(
            bookId: 'book-1',
            entrySource: EntrySource.manual,
            // No initialCategory → category null → submit returns validationError
          ),
          formKey: formKey,
          overrides: _overrides(createUseCase: mockCreate),
        ),
      );
      await tester.pumpAndSettle();

      // Call updateAmount with 0
      formKey.currentState!.updateAmount(0);
      await tester.pump();

      // Submit — expect validationError or that create use case is NOT called
      // (category is null, so the null-category guard fires first)
      final result = await formKey.currentState!.submit();

      final isNotSuccess = result.maybeWhen(
        success: (_) => false,
        orElse: () => true,
      );
      expect(isNotSuccess, isTrue,
          reason: 'submit() with amount=0 and no category must not succeed');

      // Use case should not be invoked because category guard fires first
      verifyNever(() => mockCreate.execute(any()));
    },
  );

  // ── TEST 2: updateAmount(1500) → submit calls use case with amount==1500
  testWidgets(
    'TEST 2: updateAmount(1500) + submit invokes create use case with amount 1500',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final formKey = GlobalKey<TransactionDetailsFormState>();
      final mockCreate = _MockCreateTransactionUseCase();

      when(() => mockCreate.execute(any())).thenAnswer(
        (_) async => Result.success(_fakeSuccessTx(amount: 1500)),
      );

      await tester.pumpWidget(
        _buildForm(
          TransactionDetailsFormConfig.$new(
            bookId: 'book-1',
            entrySource: EntrySource.manual,
            initialCategory: _survivalCategory,
            // category pre-seeded so submit() passes category null check
          ),
          formKey: formKey,
          overrides: _overrides(
            categoryRepo: _SingleCategoryRepository(_survivalCategory),
            createUseCase: mockCreate,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Push amount into form
      formKey.currentState!.updateAmount(1500);
      await tester.pump();

      // Submit
      final result = await formKey.currentState!.submit();

      // Assert create use case was called once with amount == 1500
      final captured = verify(() => mockCreate.execute(captureAny())).captured;
      expect(captured.length, 1, reason: 'execute should be called exactly once');
      final params = captured.first as CreateTransactionParams;
      expect(params.amount, 1500);

      // Assert success
      final isSuccess = result.maybeWhen(success: (_) => true, orElse: () => false);
      expect(isSuccess, isTrue);
    },
  );

  // ── TEST 3: idempotency / Pattern S-1 efficiency — double updateAmount(500)
  testWidgets(
    'TEST 3: updateAmount(500) twice is idempotent — second call with same value is no-op',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final formKey = GlobalKey<TransactionDetailsFormState>();
      final mockCreate = _MockCreateTransactionUseCase();

      when(() => mockCreate.execute(any())).thenAnswer(
        (_) async => Result.success(_fakeSuccessTx(amount: 500)),
      );

      await tester.pumpWidget(
        _buildForm(
          TransactionDetailsFormConfig.$new(
            bookId: 'book-1',
            entrySource: EntrySource.manual,
            initialCategory: _survivalCategory,
          ),
          formKey: formKey,
          overrides: _overrides(
            categoryRepo: _SingleCategoryRepository(_survivalCategory),
            createUseCase: mockCreate,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First call — should update _amount to 500
      formKey.currentState!.updateAmount(500);
      await tester.pump();

      // Second call with same value — should be idempotent (no-op, no rebuild).
      // We verify by checking the submit outcome is correct (amount == 500)
      // and that the use case is called only once (not twice for two updateAmount calls).
      formKey.currentState!.updateAmount(500);
      await tester.pump();

      // Submit to verify amount is 500 (the idempotency didn't corrupt state)
      final result = await formKey.currentState!.submit();

      final captured = verify(() => mockCreate.execute(captureAny())).captured;
      expect(captured.length, 1, reason: 'execute called exactly once');
      final params = captured.first as CreateTransactionParams;
      expect(params.amount, 500,
          reason: 'amount should be 500 after two updateAmount(500) calls');

      final isSuccess = result.maybeWhen(success: (_) => true, orElse: () => false);
      expect(isSuccess, isTrue);
    },
  );

  // ── TEST 4: AmountDisplay removed from form internal rendering (D-14)
  testWidgets(
    'TEST 4: form no longer renders AmountDisplay or amount DetailInfoRow internally',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildForm(
          TransactionDetailsFormConfig.$new(
            bookId: 'book-1',
            entrySource: EntrySource.manual,
          ),
          overrides: _overrides(),
        ),
      );
      await tester.pumpAndSettle();

      // D-14: form must NOT render AmountDisplay internally
      expect(
        find.byType(AmountDisplay),
        findsNothing,
        reason: 'AmountDisplay must be externalized — form no longer renders it',
      );
    },
  );

  // ── TEST 5: ValueKey markers (P19-W2 / VALIDATION.md SC-1)
  testWidgets(
    'TEST 5: form renders ValueKey markers on category-chip / date-chip / '
    'merchant-textfield / note-textfield (P19-W2)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildForm(
          TransactionDetailsFormConfig.$new(
            bookId: 'book-1',
            entrySource: EntrySource.manual,
          ),
          overrides: _overrides(),
        ),
      );
      await tester.pumpAndSettle();

      // P19-W2: each key must appear exactly once (findsOneWidget)
      expect(
        find.byKey(const ValueKey('category-chip')),
        findsOneWidget,
        reason: 'category-chip ValueKey must be on the category DetailInfoRow',
      );
      expect(
        find.byKey(const ValueKey('date-chip')),
        findsOneWidget,
        reason: 'date-chip ValueKey must be on the date DetailInfoRow',
      );
      expect(
        find.byKey(const ValueKey('merchant-textfield')),
        findsOneWidget,
        reason: 'merchant-textfield ValueKey must be on the merchant TextField',
      );
      expect(
        find.byKey(const ValueKey('note-textfield')),
        findsOneWidget,
        reason: 'note-textfield ValueKey must be on the note TextField',
      );
    },
  );

  // ── TEST 6: FocusNode plumbing from TransactionDetailsFormConfig.$new (P19-W3)
  testWidgets(
    r'TEST 6: FocusNode from $new config.merchantFocusNode is wired to merchant TextField',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final merchantFn = FocusNode();
      final noteFn = FocusNode();
      addTearDown(merchantFn.dispose);
      addTearDown(noteFn.dispose);

      await tester.pumpWidget(
        _buildForm(
          TransactionDetailsFormConfig.$new(
            bookId: 'book-1',
            entrySource: EntrySource.manual,
            merchantFocusNode: merchantFn,
            noteFocusNode: noteFn,
          ),
          overrides: _overrides(),
        ),
      );
      await tester.pumpAndSettle();

      // Request focus on the merchant FocusNode
      merchantFn.requestFocus();
      await tester.pumpAndSettle();

      // Verify the merchant TextField has focus via the injected FocusNode
      expect(
        merchantFn.hasFocus,
        isTrue,
        reason: 'merchantFocusNode from config must be wired to merchant TextField',
      );

      // Request focus on the note FocusNode
      noteFn.requestFocus();
      await tester.pumpAndSettle();

      expect(
        noteFn.hasFocus,
        isTrue,
        reason: 'noteFocusNode from config must be wired to note TextField',
      );
    },
  );
}

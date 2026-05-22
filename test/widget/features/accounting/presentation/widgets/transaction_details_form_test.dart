/// Widget tests for TransactionDetailsForm covering:
/// - SC-1: single shared form widget renders in both .new and .edit modes
/// - D-09: voice-correction gate (structural: .edit mode branch is unreachable)
/// - D-15: soul celebration shows only on .new soul saves, never on .edit
/// - D-02: submit() returns sealed-union result; validationError on null category
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
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';
import 'package:home_pocket/features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart';
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

/// Always returns null for findById — exercises the W3 orphan-category path.
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

/// Returns a specified category by id.
class _StubCategoryRepository implements CategoryRepository {
  _StubCategoryRepository(this._category);
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

/// Always returns null ledger config — no database required.
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

// ── Test data helpers ──────────────────────────────────────────────────────────

Transaction _makeSurvivalSeedTx({String bookId = 'book-1'}) => Transaction(
  id: 'tx-001',
  bookId: bookId,
  deviceId: 'dev-001',
  amount: 1234,
  type: TransactionType.expense,
  categoryId: 'cat-food',
  ledgerType: LedgerType.survival,
  timestamp: DateTime(2026, 5, 1),
  currentHash: 'hash-survival',
  createdAt: DateTime(2026, 5, 1),
  merchant: 'Café',
  note: 'Test note',
  entrySource: EntrySource.manual,
);

Transaction _makeSoulSeedTx() => Transaction(
  id: 'tx-002',
  bookId: 'book-1',
  deviceId: 'dev-001',
  amount: 2500,
  type: TransactionType.expense,
  categoryId: 'cat-hobby',
  ledgerType: LedgerType.soul,
  timestamp: DateTime(2026, 5, 1),
  currentHash: 'hash-soul',
  createdAt: DateTime(2026, 5, 1),
  soulSatisfaction: 7,
  entrySource: EntrySource.voice,
);

final _soulCategory = Category(
  id: 'cat-hobby',
  name: 'Hobby',
  icon: 'sports_tennis',
  color: '#9C27B0',
  level: 1,
  isSystem: false,
  sortOrder: 1,
  createdAt: DateTime(2026, 5, 1),
);

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

// ── Override builder helpers ───────────────────────────────────────────────────

List<Override> _baseOverrides({
  CategoryRepository? categoryRepo,
  _MockCreateTransactionUseCase? createUseCase,
  _MockUpdateTransactionUseCase? updateUseCase,
  _MockRecordCategoryCorrectionUseCase? correctionUseCase,
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
      if (correctionUseCase != null) return correctionUseCase;
      throw UnimplementedError('recordCategoryCorrectionUseCase not stubbed');
    }),
  ];
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCreateTransactionParams());
    registerFallbackValue(_FakeUpdateTransactionParams());
  });

  // Helper: wrap the form in a Scaffold (needed for ScaffoldMessenger) inside
  // createLocalizedWidget for consistent ProviderScope + l10n setup.
  Widget buildForm(
    TransactionDetailsFormConfig config, {
    List<Override> overrides = const [],
    Key? formKey,
  }) {
    return createLocalizedWidget(
      Scaffold(
        body: TransactionDetailsForm(key: formKey, config: config),
      ),
      locale: const Locale('en'),
      overrides: overrides,
    );
  }

  group('TransactionDetailsForm', () {
    // ── SC-1: both modes render correctly ────────────────────────────────────

    testWidgets('renders in .new mode with no initial values (SC-1)', (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildForm(
          TransactionDetailsFormConfig.$new(
            bookId: 'b1',
            entrySource: EntrySource.manual,
          ),
          overrides: _baseOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      // SC-1: form mounts in .new mode without errors
      expect(find.byType(TransactionDetailsForm), findsOneWidget);
    });

    testWidgets(
      'renders in .edit mode with seeded merchant and note pre-populated (SC-1)',
      (tester) async {
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final seed = _makeSurvivalSeedTx();
        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.edit(seed: seed),
            overrides: _baseOverrides(
              categoryRepo: _StubCategoryRepository(_survivalCategory),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // SC-1: form mounts in .edit mode
        expect(find.byType(TransactionDetailsForm), findsOneWidget);

        // Merchant and note are pre-populated from seed
        expect(find.text('Café'), findsOneWidget,
            reason: 'seed.merchant should appear in merchant TextField');
        expect(find.text('Test note'), findsOneWidget,
            reason: 'seed.note should appear in note TextField');
      },
    );

    testWidgets(
      '.new mode renders with a pre-seeded soul category (SC-1 initial config)',
      (tester) async {
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.$new(
              bookId: 'b1',
              entrySource: EntrySource.manual,
              initialCategory: _soulCategory,
            ),
            overrides: _baseOverrides(
              categoryRepo: _StubCategoryRepository(_soulCategory),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // SC-1: form mounts in .new mode with initialCategory provided
        expect(find.byType(TransactionDetailsForm), findsOneWidget);
      },
    );

    // ── D-15: soul celebration only on .new soul saves ───────────────────────

    testWidgets(
      '.new mode soul save shows SoulCelebrationOverlay (D-15 positive case)',
      (tester) async {
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockCreate = _MockCreateTransactionUseCase();
        final formKey = GlobalKey<TransactionDetailsFormState>();

        // Return a soul transaction on create
        final savedSoulTx = _makeSoulSeedTx();
        when(() => mockCreate.execute(any())).thenAnswer(
          (_) async => Result.success(savedSoulTx),
        );

        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.$new(
              bookId: 'book-1',
              entrySource: EntrySource.manual,
              // Soul category pre-seeded so _category is not null
              initialCategory: _soulCategory,
            ),
            overrides: _baseOverrides(
              categoryRepo: _StubCategoryRepository(_soulCategory),
              createUseCase: mockCreate,
            ),
            formKey: formKey,
          ),
        );
        await tester.pumpAndSettle();

        // Trigger submit — .new mode with soul result should show celebration
        await formKey.currentState!.submit();
        await tester.pump();

        // D-15: .new soul save MUST show SoulCelebrationOverlay
        expect(
          find.byType(SoulCelebrationOverlay),
          findsOneWidget,
          reason: '.new soul save must trigger SoulCelebrationOverlay (D-15)',
        );
      },
    );

    testWidgets(
      '.edit mode does NOT show SoulCelebrationOverlay on soul seed save (D-15 invariant)',
      (tester) async {
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockUpdate = _MockUpdateTransactionUseCase();
        final seed = _makeSoulSeedTx();
        final formKey = GlobalKey<TransactionDetailsFormState>();

        when(() => mockUpdate.execute(any())).thenAnswer(
          (_) async => Result.success(seed),
        );

        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.edit(seed: seed),
            overrides: _baseOverrides(
              categoryRepo: _StubCategoryRepository(_soulCategory),
              updateUseCase: mockUpdate,
            ),
            formKey: formKey,
          ),
        );
        // Let _loadCategoryFromSeed complete (async post-frame callback)
        await tester.pumpAndSettle();

        // Call submit — category was loaded from seed via stub repo
        await formKey.currentState!.submit();
        await tester.pump();

        // D-15: .edit mode must NEVER show SoulCelebrationOverlay
        expect(
          find.byType(SoulCelebrationOverlay),
          findsNothing,
          reason: 'SoulCelebrationOverlay must NOT appear in .edit mode (D-15)',
        );
      },
    );

    // ── D-09: voice-correction gate ─────────────────────────────────────────

    testWidgets(
      '.edit mode voice-correction branch is structurally unreachable (D-09)',
      (tester) async {
        // In .edit mode, the config has no voiceKeyword field (D-09 structural
        // enforcement). The _editCategory maybeWhen orElse branch handles .edit.
        // This test verifies the form mounts in .edit mode without errors and
        // that the form widget properly instantiates without voice-keyword dependency.

        final seed = _makeSurvivalSeedTx();
        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.edit(seed: seed),
            overrides: _baseOverrides(
              categoryRepo: _StubCategoryRepository(_survivalCategory),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // D-09: .edit mode mounts without requiring voice-correction infrastructure
        expect(find.byType(TransactionDetailsForm), findsOneWidget);
      },
    );

    // ── D-02: submit() sealed-union result ───────────────────────────────────

    testWidgets(
      'submit returns validationError when no category selected (D-02)',
      (tester) async {
        final formKey = GlobalKey<TransactionDetailsFormState>();

        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.$new(
              bookId: 'b1',
              entrySource: EntrySource.manual,
              // No initialCategory → _category is null → submit returns validationError
            ),
            overrides: _baseOverrides(),
            formKey: formKey,
          ),
        );
        await tester.pumpAndSettle();

        final result = await formKey.currentState!.submit();

        // D-02: sealed-union validationError without calling any use case
        final isValidationError = result.maybeWhen(
          validationError: (_) => true,
          orElse: () => false,
        );
        expect(isValidationError, isTrue,
            reason: 'submit with no category must return validationError (D-02)');
      },
    );

    testWidgets(
      'GlobalKey<TransactionDetailsFormState> provides access to submit() (D-02)',
      (tester) async {
        // This test verifies the GlobalKey pattern works as designed (D-02):
        // host screens invoke submit() via GlobalKey<TransactionDetailsFormState>.
        final formKey = GlobalKey<TransactionDetailsFormState>();

        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.$new(
              bookId: 'b1',
              entrySource: EntrySource.manual,
            ),
            overrides: _baseOverrides(),
            formKey: formKey,
          ),
        );
        await tester.pumpAndSettle();

        // GlobalKey must resolve to a non-null state
        expect(formKey.currentState, isNotNull,
            reason: 'GlobalKey<TransactionDetailsFormState> must resolve (D-02)');

        // submit() must be callable and return a TransactionDetailsFormResult
        final result = await formKey.currentState!.submit();
        expect(result, isA<TransactionDetailsFormResult>());
      },
    );
  });
}

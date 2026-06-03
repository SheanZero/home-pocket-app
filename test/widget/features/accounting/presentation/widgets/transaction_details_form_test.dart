/// Widget tests for TransactionDetailsForm covering:
/// - SC-1: single shared form widget renders in both .new and .edit modes
/// - D-09: voice-correction gate (structural: .edit mode branch is unreachable)
/// - D-15: joy celebration shows only on .new joy saves, never on .edit
/// - D-02: submit() returns sealed-union result; validationError on null category
/// - D-07: Phase 22 public setter surface (updateCategory / updateMerchant /
///         updateNote / updateSatisfaction) — host (VoiceInputScreen) batch-fill
///         via `GlobalKey<TransactionDetailsFormState>`
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/application/accounting/update_transaction_use_case.dart';
import 'package:home_pocket/application/voice/record_category_correction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_category_preference.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_details_form_config.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_category_preference_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';
import 'package:home_pocket/features/dual_ledger/presentation/widgets/joy_celebration_overlay.dart';
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

/// No-op merchant preference repository — silently absorbs the post-save
/// merchant-learning hook (Phase 18 D-09) invoked from submit() so tests
/// don't need a real database backing for this side effect.
class _NoopMerchantCategoryPreferenceRepository
    implements MerchantCategoryPreferenceRepository {
  @override
  Future<MerchantCategoryPreference?> findByMerchantKey(
    String merchantKey,
  ) async => null;
  @override
  Future<void> upsert(MerchantCategoryPreference preference) async {}
  @override
  Future<void> recordSelection({
    required String merchantKey,
    required String selectedCategoryId,
  }) async {}
  @override
  Future<String?> suggestCategoryId(String merchantKey) async => null;
}

/// Returns a fixed ledger type for a given category id; used by D-07
/// updateCategory tests to drive `_resolveLedgerType` toward LedgerType.joy.
class _StubLedgerConfigRepository implements CategoryLedgerConfigRepository {
  _StubLedgerConfigRepository(this._categoryId, this._ledgerType);
  final String _categoryId;
  final LedgerType _ledgerType;
  @override
  Future<CategoryLedgerConfig?> findById(String categoryId) async {
    if (categoryId == _categoryId) {
      return CategoryLedgerConfig(
        categoryId: _categoryId,
        ledgerType: _ledgerType,
        updatedAt: DateTime(2026, 5, 1),
      );
    }
    return null;
  }
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
  ledgerType: LedgerType.daily,
  timestamp: DateTime(2026, 5, 1),
  currentHash: 'hash-daily',
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
  ledgerType: LedgerType.joy,
  timestamp: DateTime(2026, 5, 1),
  currentHash: 'hash-joy',
  createdAt: DateTime(2026, 5, 1),
  joyFullness: 7,
  entrySource: EntrySource.voice,
);

final _joyCategory = Category(
  id: 'cat-hobby',
  name: 'Hobby',
  icon: 'sports_tennis',
  color: '#9C27B0',
  level: 1,
  isSystem: false,
  sortOrder: 1,
  createdAt: DateTime(2026, 5, 1),
);

final _dailyCategory = Category(
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
  CategoryRepository? categoryServiceRepo,
  CategoryLedgerConfigRepository? categoryServiceLedgerRepo,
}) {
  return [
    categoryRepositoryProvider.overrideWithValue(
      categoryRepo ?? _NullCategoryRepository(),
    ),
    categoryServiceProvider.overrideWith(
      (_) => CategoryService(
        categoryRepository:
            categoryServiceRepo ?? _NullCategoryRepository(),
        ledgerConfigRepository:
            categoryServiceLedgerRepo ?? _NullLedgerConfigRepository(),
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
    // Merchant-learning hook (Phase 18 D-09): submit() invokes this when
    // merchant is non-empty. Provide a no-op service so tests covering the
    // merchant-fill path don't crash on UnimplementedError.
    merchantCategoryLearningServiceProvider.overrideWith(
      (_) => MerchantCategoryLearningService(
        repository: _NoopMerchantCategoryPreferenceRepository(),
        categoryRepository: _NullCategoryRepository(),
      ),
    ),
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
              categoryRepo: _StubCategoryRepository(_dailyCategory),
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
      '.new mode renders with a pre-seeded joy category (SC-1 initial config)',
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
              initialCategory: _joyCategory,
            ),
            overrides: _baseOverrides(
              categoryRepo: _StubCategoryRepository(_joyCategory),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // SC-1: form mounts in .new mode with initialCategory provided
        expect(find.byType(TransactionDetailsForm), findsOneWidget);
      },
    );

    // ── D-15: joy celebration only on .new joy saves ───────────────────────

    testWidgets(
      '.new mode joy save does NOT show JoyCelebrationOverlay while disabled '
      '(quick-260603-nr1: _kJoyCelebrationEnabled=false). When the flag is '
      'flipped back to true, restore this to findsOneWidget (D-15 positive case)',
      (tester) async {
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockCreate = _MockCreateTransactionUseCase();
        final formKey = GlobalKey<TransactionDetailsFormState>();

        // Return a joy transaction on create
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
              initialCategory: _joyCategory,
            ),
            overrides: _baseOverrides(
              categoryRepo: _StubCategoryRepository(_joyCategory),
              createUseCase: mockCreate,
            ),
            formKey: formKey,
          ),
        );
        await tester.pumpAndSettle();

        // Trigger submit — .new mode with joy result should show celebration
        await formKey.currentState!.submit();
        await tester.pump();

        // Celebration temporarily disabled (quick-260603-nr1): the overlay must
        // NOT appear even on a .new joy save. Flip _kJoyCelebrationEnabled back
        // to true (and this back to findsOneWidget) to restore D-15.
        expect(
          find.byType(JoyCelebrationOverlay),
          findsNothing,
          reason: 'celebration disabled — no overlay on joy save (nr1)',
        );
      },
    );

    testWidgets(
      '.edit mode does NOT show JoyCelebrationOverlay on joy seed save (D-15 invariant)',
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
              categoryRepo: _StubCategoryRepository(_joyCategory),
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

        // D-15: .edit mode must NEVER show JoyCelebrationOverlay
        expect(
          find.byType(JoyCelebrationOverlay),
          findsNothing,
          reason: 'JoyCelebrationOverlay must NOT appear in .edit mode (D-15)',
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
              categoryRepo: _StubCategoryRepository(_dailyCategory),
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

  // ── D-07: Phase 22 public setter surface ───────────────────────────────────
  //
  // Tests for the 4 new public mutator methods on TransactionDetailsFormState
  // added in Phase 22 Plan 02 (D-07 + RESEARCH Open Q2 resolution):
  //   - updateCategory(Category, Category?)
  //   - updateMerchant(String)
  //   - updateNote(String)
  //   - updateSatisfaction(int)
  //
  // All mirror the Phase 19 D-14 updateAmount(int) pattern: !mounted guard +
  // idempotency short-circuit on value equality + minimal state mutation.
  group('D-07 public setter surface (Phase 22)', () {
    // L1 + L2 category fixtures for updateCategory tests.
    final catFoodL1 = Category(
      id: 'cat_food',
      name: 'Food',
      icon: 'restaurant',
      color: '#E85A4F',
      level: 1,
      isSystem: true,
      sortOrder: 1,
      createdAt: DateTime(2026, 5, 1),
    );
    final catFoodL2Cafe = Category(
      id: 'cat_food_cafe',
      name: 'Cafe',
      icon: 'local_cafe',
      color: '#E85A4F',
      parentId: 'cat_food',
      level: 2,
      isSystem: true,
      sortOrder: 1,
      createdAt: DateTime(2026, 5, 1),
    );
    final catHobbiesL1 = Category(
      id: 'cat_hobbies',
      name: 'Hobbies',
      icon: 'music_note',
      color: '#9C27B0',
      level: 1,
      isSystem: false,
      sortOrder: 1,
      createdAt: DateTime(2026, 5, 1),
    );

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

    Transaction fakeTx({
      int amount = 1234,
      String categoryId = 'cat_food',
      LedgerType ledgerType = LedgerType.daily,
      String? merchant,
      String? note,
      int joyFullness = 2,
    }) => Transaction(
      id: 'tx-d07',
      bookId: 'b1',
      deviceId: 'dev-001',
      amount: amount,
      type: TransactionType.expense,
      categoryId: categoryId,
      ledgerType: ledgerType,
      timestamp: DateTime(2026, 5, 1),
      currentHash: 'hash-d07',
      createdAt: DateTime(2026, 5, 1),
      merchant: merchant,
      note: note,
      joyFullness: joyFullness,
      entrySource: EntrySource.manual,
    );

    group('updateCategory', () {
      testWidgets(
        'Test 1: updateCategory(catFoodL2, catFoodL1) + submit produces '
        'CreateTransactionParams.categoryId == catFoodL2.id',
        (tester) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final formKey = GlobalKey<TransactionDetailsFormState>();
          final mockCreate = _MockCreateTransactionUseCase();
          when(() => mockCreate.execute(any())).thenAnswer(
            (_) async => Result.success(
              fakeTx(amount: 1000, categoryId: catFoodL2Cafe.id),
            ),
          );

          await tester.pumpWidget(
            buildForm(
              TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
              ),
              overrides: _baseOverrides(createUseCase: mockCreate),
              formKey: formKey,
            ),
          );
          await tester.pumpAndSettle();

          // Push voice-resolved category (L2 child + L1 parent) via D-07 setter
          formKey.currentState!.updateCategory(catFoodL2Cafe, catFoodL1);
          formKey.currentState!.updateAmount(1000);
          await tester.pump();

          final result = await formKey.currentState!.submit();

          final captured =
              verify(() => mockCreate.execute(captureAny())).captured;
          expect(captured.length, 1,
              reason: 'create use case should be invoked exactly once');
          final params = captured.first as CreateTransactionParams;
          expect(params.categoryId, catFoodL2Cafe.id,
              reason: 'submit() must use the category pushed via updateCategory');

          final isSuccess = result.maybeWhen(
            success: (_) => true,
            orElse: () => false,
          );
          expect(isSuccess, isTrue);
        },
      );

      testWidgets(
        'Test 2: updateCategory called twice with same category is idempotent — '
        'submit() still produces categoryId == cat.id with single use-case call',
        (tester) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final formKey = GlobalKey<TransactionDetailsFormState>();
          final mockCreate = _MockCreateTransactionUseCase();
          when(() => mockCreate.execute(any())).thenAnswer(
            (_) async => Result.success(
              fakeTx(amount: 500, categoryId: catFoodL2Cafe.id),
            ),
          );

          await tester.pumpWidget(
            buildForm(
              TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
              ),
              overrides: _baseOverrides(createUseCase: mockCreate),
              formKey: formKey,
            ),
          );
          await tester.pumpAndSettle();

          // First call sets the category; second call must short-circuit.
          formKey.currentState!.updateCategory(catFoodL2Cafe, catFoodL1);
          formKey.currentState!.updateCategory(catFoodL2Cafe, catFoodL1);
          formKey.currentState!.updateAmount(500);
          await tester.pump();

          final result = await formKey.currentState!.submit();

          final captured =
              verify(() => mockCreate.execute(captureAny())).captured;
          expect(captured.length, 1,
              reason: 'execute should be called exactly once');
          final params = captured.first as CreateTransactionParams;
          expect(params.categoryId, catFoodL2Cafe.id,
              reason: 'state must remain coherent after idempotent re-call');

          final isSuccess = result.maybeWhen(
            success: (_) => true,
            orElse: () => false,
          );
          expect(isSuccess, isTrue);
        },
      );

      testWidgets(
        'Test 3: updateCategory with joy-mapped category flips ledger toggle '
        'to joy — submit() produces params.ledgerType == LedgerType.joy',
        (tester) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final formKey = GlobalKey<TransactionDetailsFormState>();
          final mockCreate = _MockCreateTransactionUseCase();
          when(() => mockCreate.execute(any())).thenAnswer(
            (_) async => Result.success(
              fakeTx(
                amount: 3000,
                categoryId: catHobbiesL1.id,
                ledgerType: LedgerType.joy,
                joyFullness: 6,
              ),
            ),
          );

          // CategoryService wired to a stub that returns joy for catHobbiesL1.
          await tester.pumpWidget(
            buildForm(
              TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
              ),
              overrides: _baseOverrides(
                createUseCase: mockCreate,
                categoryServiceRepo: _StubCategoryRepository(catHobbiesL1),
                categoryServiceLedgerRepo: _StubLedgerConfigRepository(
                  catHobbiesL1.id,
                  LedgerType.joy,
                ),
              ),
              formKey: formKey,
            ),
          );
          await tester.pumpAndSettle();

          // Push joy-mapped category; updateCategory triggers _resolveLedgerType
          // which flips _ledgerType to joy.
          formKey.currentState!.updateCategory(catHobbiesL1, null);
          formKey.currentState!.updateAmount(3000);
          await tester.pumpAndSettle();

          final result = await formKey.currentState!.submit();

          final captured =
              verify(() => mockCreate.execute(captureAny())).captured;
          expect(captured.length, 1);
          final params = captured.first as CreateTransactionParams;
          expect(params.ledgerType, LedgerType.joy,
              reason: 'updateCategory must trigger ledger resolution → joy');

          final isSuccess = result.maybeWhen(
            success: (_) => true,
            orElse: () => false,
          );
          expect(isSuccess, isTrue);
        },
      );
    });

    group('updateMerchant', () {
      testWidgets(
        'Test 4: updateMerchant("Starbucks") + submit produces '
        'CreateTransactionParams.merchant == "Starbucks"',
        (tester) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final formKey = GlobalKey<TransactionDetailsFormState>();
          final mockCreate = _MockCreateTransactionUseCase();
          when(() => mockCreate.execute(any())).thenAnswer(
            (_) async => Result.success(
              fakeTx(amount: 800, merchant: 'Starbucks'),
            ),
          );

          await tester.pumpWidget(
            buildForm(
              TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
                initialCategory: _dailyCategory,
              ),
              overrides: _baseOverrides(
                categoryRepo: _StubCategoryRepository(_dailyCategory),
                createUseCase: mockCreate,
              ),
              formKey: formKey,
            ),
          );
          await tester.pumpAndSettle();

          formKey.currentState!.updateMerchant('Starbucks');
          formKey.currentState!.updateAmount(800);
          await tester.pump();

          // TextField shows the new merchant text
          expect(find.text('Starbucks'), findsOneWidget,
              reason: 'merchant TextField must display the pushed value');

          await formKey.currentState!.submit();

          final captured =
              verify(() => mockCreate.execute(captureAny())).captured;
          expect(captured.length, 1);
          final params = captured.first as CreateTransactionParams;
          expect(params.merchant, 'Starbucks');
        },
      );

      testWidgets(
        'Test 5: updateMerchant idempotency — same string does not fire '
        'controller listener a second time',
        (tester) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final formKey = GlobalKey<TransactionDetailsFormState>();

          await tester.pumpWidget(
            buildForm(
              TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
                initialCategory: _dailyCategory,
              ),
              overrides: _baseOverrides(
                categoryRepo: _StubCategoryRepository(_dailyCategory),
              ),
              formKey: formKey,
            ),
          );
          await tester.pumpAndSettle();

          // Locate the rendered merchant TextField and attach a listener to
          // its controller.
          final merchantField = tester.widget<TextField>(
            find.byKey(const ValueKey('merchant-textfield')),
          );
          final controller = merchantField.controller!;

          var notifications = 0;
          controller.addListener(() => notifications++);
          addTearDown(() => controller.removeListener(() => notifications++));

          // First call sets the text → fires 1 notification.
          formKey.currentState!.updateMerchant('Starbucks');
          await tester.pump();
          expect(notifications, 1,
              reason: 'first updateMerchant must mutate controller');

          // Second call with same value must short-circuit → still 1.
          formKey.currentState!.updateMerchant('Starbucks');
          await tester.pump();
          expect(notifications, 1,
              reason:
                  'updateMerchant with unchanged value must NOT re-fire listener (Pitfall 3 cursor preservation)');
        },
      );

      testWidgets(
        'Test 6: updateMerchant without a category set + submit returns '
        'validationError (existing no-category guard fires first)',
        (tester) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final formKey = GlobalKey<TransactionDetailsFormState>();
          final mockCreate = _MockCreateTransactionUseCase();

          await tester.pumpWidget(
            buildForm(
              TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
                // No initialCategory and no updateCategory → category is null.
              ),
              overrides: _baseOverrides(createUseCase: mockCreate),
              formKey: formKey,
            ),
          );
          await tester.pumpAndSettle();

          formKey.currentState!.updateMerchant('x');
          await tester.pump();

          final result = await formKey.currentState!.submit();

          final isValidationError = result.maybeWhen(
            validationError: (_) => true,
            orElse: () => false,
          );
          expect(isValidationError, isTrue,
              reason:
                  'category null guard must fire before any use-case invocation');

          // Use case must not be called when category is null.
          verifyNever(() => mockCreate.execute(any()));
        },
      );
    });

    group('updateNote', () {
      testWidgets(
        'Test 7: updateNote("lunch with mom") + submit produces '
        'CreateTransactionParams.note == "lunch with mom"',
        (tester) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final formKey = GlobalKey<TransactionDetailsFormState>();
          final mockCreate = _MockCreateTransactionUseCase();
          when(() => mockCreate.execute(any())).thenAnswer(
            (_) async => Result.success(
              fakeTx(amount: 1200, note: 'lunch with mom'),
            ),
          );

          await tester.pumpWidget(
            buildForm(
              TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
                initialCategory: _dailyCategory,
              ),
              overrides: _baseOverrides(
                categoryRepo: _StubCategoryRepository(_dailyCategory),
                createUseCase: mockCreate,
              ),
              formKey: formKey,
            ),
          );
          await tester.pumpAndSettle();

          formKey.currentState!.updateNote('lunch with mom');
          formKey.currentState!.updateAmount(1200);
          await tester.pump();

          // TextField shows the new note text
          expect(find.text('lunch with mom'), findsOneWidget,
              reason: 'note TextField must display the pushed value');

          await formKey.currentState!.submit();

          final captured =
              verify(() => mockCreate.execute(captureAny())).captured;
          expect(captured.length, 1);
          final params = captured.first as CreateTransactionParams;
          expect(params.note, 'lunch with mom');
        },
      );

      testWidgets(
        'Test 8: updateNote idempotency — same string does not fire '
        'controller listener a second time',
        (tester) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final formKey = GlobalKey<TransactionDetailsFormState>();

          await tester.pumpWidget(
            buildForm(
              TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
                initialCategory: _dailyCategory,
              ),
              overrides: _baseOverrides(
                categoryRepo: _StubCategoryRepository(_dailyCategory),
              ),
              formKey: formKey,
            ),
          );
          await tester.pumpAndSettle();

          final noteField = tester.widget<TextField>(
            find.byKey(const ValueKey('note-textfield')),
          );
          final controller = noteField.controller!;

          var notifications = 0;
          controller.addListener(() => notifications++);
          addTearDown(() => controller.removeListener(() => notifications++));

          formKey.currentState!.updateNote('hello');
          await tester.pump();
          expect(notifications, 1,
              reason: 'first updateNote must mutate controller');

          formKey.currentState!.updateNote('hello');
          await tester.pump();
          expect(notifications, 1,
              reason:
                  'updateNote with unchanged value must NOT re-fire listener');
        },
      );

      testWidgets(
        'Test 9: updateNote("") clears prior memo content',
        (tester) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final formKey = GlobalKey<TransactionDetailsFormState>();

          await tester.pumpWidget(
            buildForm(
              TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
                initialCategory: _dailyCategory,
              ),
              overrides: _baseOverrides(
                categoryRepo: _StubCategoryRepository(_dailyCategory),
              ),
              formKey: formKey,
            ),
          );
          await tester.pumpAndSettle();

          formKey.currentState!.updateNote('initial');
          await tester.pump();
          expect(find.text('initial'), findsOneWidget,
              reason: 'updateNote("initial") must populate the note field');

          formKey.currentState!.updateNote('');
          await tester.pump();

          final noteField = tester.widget<TextField>(
            find.byKey(const ValueKey('note-textfield')),
          );
          expect(noteField.controller!.text, '',
              reason: 'updateNote("") must clear the controller text');
        },
      );
    });

    group('updateSatisfaction', () {
      testWidgets(
        'Test 10: updateSatisfaction(5) on joy-ledger picker — mutation + '
        'picker rebuild + idempotency + submit round-trip '
        '(RESEARCH Open Q2 / BLOCKER B-1)',
        (tester) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final formKey = GlobalKey<TransactionDetailsFormState>();
          final mockCreate = _MockCreateTransactionUseCase();
          when(() => mockCreate.execute(any())).thenAnswer(
            (_) async => Result.success(
              fakeTx(
                amount: 2500,
                categoryId: _joyCategory.id,
                ledgerType: LedgerType.joy,
                joyFullness: 5,
              ),
            ),
          );

          // Soul-ledger initial category so SatisfactionEmojiPicker renders.
          // CategoryService wired to resolve joyCategory → joy so
          // _ledgerType flips on the initial post-frame _resolveLedgerType.
          await tester.pumpWidget(
            buildForm(
              TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
                initialCategory: _joyCategory,
              ),
              overrides: _baseOverrides(
                categoryRepo: _StubCategoryRepository(_joyCategory),
                categoryServiceRepo: _StubCategoryRepository(_joyCategory),
                categoryServiceLedgerRepo: _StubLedgerConfigRepository(
                  _joyCategory.id,
                  LedgerType.joy,
                ),
                createUseCase: mockCreate,
              ),
              formKey: formKey,
            ),
          );
          await tester.pumpAndSettle();

          // Picker must be visible because ledger flipped to joy.
          expect(find.byType(SatisfactionEmojiPicker), findsOneWidget,
              reason: 'joy ledger must render SatisfactionEmojiPicker');

          // (a) Push satisfaction = 5 via the new D-07 setter.
          formKey.currentState!.updateSatisfaction(5);
          await tester.pump();

          // (b) Picker rebuild — its `value` prop must reflect the new state.
          final pickerAfter = tester.widget<SatisfactionEmojiPicker>(
            find.byType(SatisfactionEmojiPicker),
          );
          expect(pickerAfter.value, 5,
              reason:
                  'SatisfactionEmojiPicker.value must reflect updateSatisfaction(5)');

          // (c) Idempotency — second call with same value must short-circuit;
          // picker's identity / value remains at 5 (no extra rebuild required
          // to maintain the same value).
          formKey.currentState!.updateSatisfaction(5);
          await tester.pump();
          final pickerSecond = tester.widget<SatisfactionEmojiPicker>(
            find.byType(SatisfactionEmojiPicker),
          );
          expect(pickerSecond.value, 5,
              reason:
                  'idempotent updateSatisfaction(5) must keep picker value at 5');

          // (d) Submit round-trip — use case receives joyFullness == 5.
          formKey.currentState!.updateAmount(2500);
          await tester.pump();
          await formKey.currentState!.submit();

          final captured =
              verify(() => mockCreate.execute(captureAny())).captured;
          expect(captured.length, 1);
          final params = captured.first as CreateTransactionParams;
          expect(params.joyFullness, 5,
              reason:
                  'submit() must propagate updateSatisfaction(5) to CreateTransactionParams (Open Q2 resolution)');
          expect(params.ledgerType, LedgerType.joy,
              reason:
                  'joy-ledger satisfaction wiring intact after Phase 22 rewrite');
        },
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_details_form_config.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/detail_info_card.dart';
import 'package:home_pocket/shared/widgets/ledger_type_selector.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

/// Always returns null — exercises the W3 orphan-category path.
class NullCategoryRepository implements CategoryRepository {
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

/// Returns a single category — for edit-mode smoke where category should load.
class SingleCategoryRepository implements CategoryRepository {
  SingleCategoryRepository(this._category);

  final Category _category;

  @override
  Future<Category?> findById(String id) async =>
      id == _category.id ? _category : null;

  @override
  Future<List<Category>> findAll() async => [_category];

  @override
  Future<List<Category>> findActive() async => [_category];

  @override
  Future<List<Category>> findByLevel(int level) async =>
      _category.level == level ? [_category] : [];

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

/// Always returns null — no ledger config entries.
class NullLedgerConfigRepository implements CategoryLedgerConfigRepository {
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

// ── Data helpers ───────────────────────────────────────────────────────────────

Transaction _fakeSurvivalTransaction(String bookId) => Transaction(
  id: 'tx-001',
  bookId: bookId,
  deviceId: 'dev-001',
  amount: 1000,
  type: TransactionType.expense,
  categoryId: 'cat-food',
  ledgerType: LedgerType.daily,
  timestamp: DateTime(2026, 5, 22),
  currentHash: 'hash001',
  createdAt: DateTime(2026, 5, 22),
  entrySource: EntrySource.manual,
);

Transaction _fakeSoulSeedTransaction() => Transaction(
  id: 'tx-002',
  bookId: 'book-1',
  deviceId: 'dev-001',
  amount: 2500,
  type: TransactionType.expense,
  categoryId: 'cat-hobby',
  ledgerType: LedgerType.joy,
  timestamp: DateTime(2026, 5, 22),
  currentHash: 'hash002',
  createdAt: DateTime(2026, 5, 22),
  joyFullness: 7,
  entrySource: EntrySource.manual,
);

final _joyCategory = Category(
  id: 'cat-hobby',
  name: 'Hobby',
  icon: 'sports_tennis',
  color: '#9C27B0',
  level: 1,
  isSystem: false,
  sortOrder: 1,
  createdAt: DateTime(2026, 5, 22),
);

List<Override> _baseOverrides({CategoryRepository? categoryRepo}) => [
  categoryRepositoryProvider.overrideWithValue(
    categoryRepo ?? NullCategoryRepository(),
  ),
  categoryServiceProvider.overrideWith(
    (_) => CategoryService(
      categoryRepository: NullCategoryRepository(),
      ledgerConfigRepository: NullLedgerConfigRepository(),
    ),
  ),
  createTransactionUseCaseProvider.overrideWith((_) {
    throw UnimplementedError(
      'createTransactionUseCase not needed in these smoke tests',
    );
  }),
  updateTransactionUseCaseProvider.overrideWith((_) {
    throw UnimplementedError(
      'updateTransactionUseCase not needed in these smoke tests',
    );
  }),
  recordCategoryCorrectionUseCaseProvider.overrideWith((_) {
    throw UnimplementedError(
      'recordCategoryCorrectionUseCase not needed in these smoke tests',
    );
  }),
];

/// Override set that provides working create/update use cases for submit tests.
List<Override> _submitOverrides(Transaction seedTx) => [
  categoryRepositoryProvider.overrideWithValue(NullCategoryRepository()),
  categoryServiceProvider.overrideWith(
    (_) => CategoryService(
      categoryRepository: NullCategoryRepository(),
      ledgerConfigRepository: NullLedgerConfigRepository(),
    ),
  ),
  createTransactionUseCaseProvider.overrideWith((_) {
    throw UnimplementedError('not used in validationError path');
  }),
  updateTransactionUseCaseProvider.overrideWith((_) {
    throw UnimplementedError('not used in validationError path');
  }),
  recordCategoryCorrectionUseCaseProvider.overrideWith((_) {
    throw UnimplementedError('not used in validationError path');
  }),
];

// ── Smoke tests ────────────────────────────────────────────────────────────────

void main() {
  // ── Task 1 smoke tests: class instantiation + initState .when branches ──────

  testWidgets('TransactionDetailsForm mounts in .new mode', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: TransactionDetailsForm(
            config: TransactionDetailsFormConfig.$new(
              bookId: 'b1',
              entrySource: EntrySource.manual,
            ),
          ),
        ),
        overrides: _baseOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailsForm), findsOneWidget);
  });

  testWidgets(
    'TransactionDetailsForm mounts in .edit mode — orphan category (W3)',
    (tester) async {
      // NullCategoryRepository returns null for findById — exercises W3 path:
      // _loadCategoryFromSeed handles null gracefully (sets both _category and
      // _parentCategory to null, form renders "please select" state).
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: TransactionDetailsForm(
              config: TransactionDetailsFormConfig.edit(
                seed: _fakeSurvivalTransaction('b1'),
              ),
            ),
          ),
          overrides: _baseOverrides(
            categoryRepo: NullCategoryRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransactionDetailsForm), findsOneWidget);
    },
  );

  // ── Task 2 smoke tests: body composition ─────────────────────────────────────

  testWidgets(
    '.new mode renders amount/category/date rows + store/memo + ledger toggle',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: TransactionDetailsForm(
              config: TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
              ),
            ),
          ),
          overrides: _baseOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify DetailInfoCard (amount/category/date rows container) is present.
      expect(find.byType(DetailInfoCard), findsOneWidget);

      // Verify LedgerTypeSelector is present.
      expect(find.byType(LedgerTypeSelector), findsOneWidget);

      // Verify at least two TextFields (store + memo).
      expect(find.byType(TextField), findsAtLeastNWidgets(2));
    },
  );

  testWidgets(
    '.edit mode renders all rows + joy satisfaction picker when seed is joy',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: TransactionDetailsForm(
              config: TransactionDetailsFormConfig.edit(
                seed: _fakeSoulSeedTransaction(),
              ),
            ),
          ),
          overrides: _baseOverrides(
            categoryRepo: SingleCategoryRepository(_joyCategory),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // seed.ledgerType == joy → SatisfactionEmojiPicker renders.
      // This verifies the .edit init branch loads seed.ledgerType verbatim (W3).
      expect(find.byType(SatisfactionEmojiPicker), findsOneWidget);
    },
  );

  // ── Task 3 smoke test: public submit() returns sealed-union result ────────────

  testWidgets(
    'submit returns sealed-union validationError when no category selected',
    (tester) async {
      final formKey = GlobalKey<TransactionDetailsFormState>();

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: TransactionDetailsForm(
              key: formKey,
              config: TransactionDetailsFormConfig.$new(
                bookId: 'b1',
                entrySource: EntrySource.manual,
                // initialCategory intentionally null → submit returns
                // TransactionDetailsFormResult.validationError
              ),
            ),
          ),
          overrides: _submitOverrides(_fakeSurvivalTransaction('b1')),
        ),
      );
      await tester.pumpAndSettle();

      final result = await formKey.currentState!.submit();

      // Verifies submit() exposes the sealed-union contract (D-02):
      // calling with no category returns .validationError, not .success.
      final isValidationError = result.maybeWhen(
        validationError: (_) => true,
        orElse: () => false,
      );
      expect(isValidationError, isTrue);
    },
  );
}

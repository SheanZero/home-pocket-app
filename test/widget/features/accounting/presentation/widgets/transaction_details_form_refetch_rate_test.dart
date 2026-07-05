/// Phase 42 GAP-CLOSURE — proves the edit host's date-change re-fetch consumes
/// the REAL `appGetExchangeRateUseCaseProvider` (no 160.00 stub).
///
/// Quick 260613-ufn (D-3/D-4): the in-card clickable `edit_date_change_trigger`
/// TextButton was REMOVED. The date-change re-fetch now fires from the DATE
/// PICKER flow — `TransactionDetailsForm.updateDate` (the same method the date
/// picker / voice push route through) calls `_onForeignDateChanged`, which runs
/// the card's retained ADR-022 D-02 dialog / D-03 toast logic via
/// `triggerDateChangeRefetch()`. These tests drive that path through `updateDate`
/// and assert the toast/undo are driven by the REAL fake-resolved rate.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/currency/get_exchange_rate_use_case.dart';
import 'package:home_pocket/features/currency/domain/models/rate_result.dart';
import 'package:home_pocket/application/currency/repository_providers.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_category_preference.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_details_form_config.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_category_preference_repository.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/currency_linked_edit_fields.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

/// Fake use case that ALWAYS returns a caller-supplied rate as a fresh fetch.
/// Captures whether `execute` was actually invoked so the test can assert the
/// REAL provider (not a stub) drove the re-fetch.
class _FakeGetExchangeRateUseCase implements GetExchangeRateUseCase {
  _FakeGetExchangeRateUseCase(this.rate);

  final String rate;
  bool wasCalled = false;
  GetExchangeRateParams? lastParams;

  @override
  Future<RateResultWithSignal> execute(GetExchangeRateParams params) async {
    wasCalled = true;
    lastParams = params;
    return RateResultWithSignal(
      result: RateFetched(
        rate: rate,
        currency: params.currency,
        rateDate: params.date,
        source: 'frankfurter',
      ),
    );
  }
}

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

// ── Test data ────────────────────────────────────────────────────────────────

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

/// Foreign-currency edit seed: USD 50.00 @ 148.30 → 7415 JPY.
Transaction _foreignSeedTx() => Transaction(
  id: 'tx-usd',
  bookId: 'book-1',
  deviceId: 'dev-001',
  amount: 7415,
  type: TransactionType.expense,
  categoryId: 'cat-food',
  ledgerType: LedgerType.daily,
  timestamp: DateTime(2026, 5, 1),
  currentHash: 'hash-usd',
  createdAt: DateTime(2026, 5, 1),
  originalCurrency: 'USD',
  originalAmount: 5000,
  appliedRate: '148.30',
  entrySource: EntrySource.manual,
);

List<Override> _overrides(_FakeGetExchangeRateUseCase fakeRate) => [
  categoryRepositoryProvider.overrideWithValue(
    _StubCategoryRepository(_dailyCategory),
  ),
  categoryServiceProvider.overrideWith(
    (_) => CategoryService(
      categoryRepository: _StubCategoryRepository(_dailyCategory),
      ledgerConfigRepository: _NullLedgerConfigRepository(),
    ),
  ),
  merchantCategoryLearningServiceProvider.overrideWith(
    (_) => MerchantCategoryLearningService(
      repository: _NoopMerchantCategoryPreferenceRepository(),
      categoryRepository: _StubCategoryRepository(_dailyCategory),
    ),
  ),
  // THE wiring under test: the edit host's re-fetch must read THIS provider.
  appGetExchangeRateUseCaseProvider.overrideWithValue(fakeRate),
];

void main() {
  Future<(_FakeGetExchangeRateUseCase, GlobalKey<TransactionDetailsFormState>)>
  pumpEditForm(WidgetTester tester, {required String fakeRate}) async {
    tester.view.physicalSize = const Size(402, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = _FakeGetExchangeRateUseCase(fakeRate);
    final formKey = GlobalKey<TransactionDetailsFormState>();
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: TransactionDetailsForm(
            key: formKey,
            config: TransactionDetailsFormConfig.edit(seed: _foreignSeedTx()),
          ),
        ),
        overrides: _overrides(fake),
      ),
    );
    await tester.pumpAndSettle();
    return (fake, formKey);
  }

  testWidgets(
    'foreign-row DATE PICKER change consumes the REAL rate provider for D-03 toast',
    (tester) async {
      // Fake returns 160.00 for the new date → 5000c USD: 7415 → 8000 (+7.9%).
      final (fake, formKey) = await pumpEditForm(tester, fakeRate: '160.00');

      // The edit host renders for the foreign seed (D-3: no clickable trigger).
      expect(find.byType(CurrencyLinkedEditFields), findsOneWidget);
      expect(
        find.byKey(const Key('edit_date_change_trigger')),
        findsNothing,
        reason: 'the clickable date-change TextButton is removed (ufn D-3)',
      );

      // A DATE-PICKER change routes through updateDate → _onForeignDateChanged →
      // the card's retained D-02/D-03 logic (ufn D-4).
      formKey.currentState!.updateDate(DateTime(2026, 5, 8));
      await tester.pumpAndSettle();

      // The REAL provider was consumed (not a stub constant).
      expect(fake.wasCalled, isTrue);
      expect(fake.lastParams?.currency, 'USD');

      // D-03: non-blocking toast driven by the fetched 160.00 → 8000 JPY.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('¥7,415 → ¥8,000'),
        findsOneWidget,
        reason: 'toast must reflect the real 160.00 re-fetch, not a stub',
      );
      // The derived JPY row also recomputed to the new 8,000.
      expect(find.byKey(const Key('edit_jpy_derived')), findsOneWidget);
    },
  );

  testWidgets(
    'toast Undo restores the OLD rate (JPY back to 7,415) using real provider',
    (tester) async {
      final (_, formKey) = await pumpEditForm(tester, fakeRate: '160.00');

      formKey.currentState!.updateDate(DateTime(2026, 5, 8));
      await tester.pumpAndSettle();

      final undo = find.byKey(const Key('toast_undo_button'));
      expect(undo, findsOneWidget);
      await tester.tap(undo);
      await tester.pumpAndSettle();

      // Undo restores the seed rate → derived JPY returns to 7,415.
      expect(find.textContaining('7,415'), findsOneWidget);
    },
  );
}

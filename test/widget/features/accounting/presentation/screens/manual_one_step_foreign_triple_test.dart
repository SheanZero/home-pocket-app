/// Phase 42 GAP-CLOSURE (WR-01 / WR-02) — proves `_pushForeignTriple`'s bail
/// and stale-amount guards on the manual one-step entry screen.
///
/// WR-01: a date change mid-fetch must NOT persist an OLD-date rate against the
///   NEW-date timestamp (the bail check now includes `date != _selectedDate`).
/// WR-02: when the rate becomes unavailable AFTER a successful push, the form
///   amount must reset to 0 so the create use case rejects the save instead of
///   persisting a stale converted JPY figure.
///
/// Both drive the REAL `appGetExchangeRateUseCaseProvider` via a controllable
/// fake, so the conversion path under test is the production one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/currency/get_exchange_rate_use_case.dart';
import 'package:home_pocket/features/currency/domain/models/rate_result.dart';
import 'package:home_pocket/application/currency/repository_providers.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        categoryRepositoryProvider,
        createTransactionUseCaseProvider,
        categoryServiceProvider;
import 'package:home_pocket/features/accounting/presentation/screens/manual_one_step_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Fakes / Mocks ────────────────────────────────────────────────────────────

class _MockCreateTransactionUseCase extends Mock
    implements CreateTransactionUseCase {}

class _FakeCreateTransactionParams extends Fake
    implements CreateTransactionParams {}

/// Controllable rate use case: each `execute` resolves to the CURRENT
/// [nextResult]. Tests flip [nextResult] between calls to simulate a rate that
/// becomes unavailable after a successful push (WR-02).
class _ControllableRateUseCase implements GetExchangeRateUseCase {
  _ControllableRateUseCase(this.nextResult);

  RateResult nextResult;
  bool wasCalled = false;

  @override
  Future<RateResultWithSignal> execute(GetExchangeRateParams params) async {
    wasCalled = true;
    return RateResultWithSignal(result: nextResult);
  }
}

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository(this.categories);
  final List<Category> categories;

  @override
  Future<List<Category>> findActive() async => categories;
  @override
  Future<Category?> findById(String id) async {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Category>> findAll() async => categories;
  @override
  Future<List<Category>> findByLevel(int level) async =>
      categories.where((c) => c.level == level).toList();
  @override
  Future<List<Category>> findByParent(String parentId) async =>
      categories.where((c) => c.parentId == parentId).toList();
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
  Future<void> deleteAll() async {}
  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}
}

class _MockCategoryService extends Mock implements CategoryService {}

// ── Fixtures ─────────────────────────────────────────────────────────────────

final _l1Category = Category(
  id: 'food',
  name: 'category_food',
  icon: 'restaurant',
  color: '#E85A4F',
  level: 1,
  isSystem: true,
  sortOrder: 1,
  createdAt: DateTime(2026, 4, 3),
);

final _l2Category = Category(
  id: 'dining',
  name: 'dining',
  icon: 'restaurant',
  color: '#E85A4F',
  parentId: 'food',
  level: 2,
  sortOrder: 1,
  createdAt: DateTime(2026, 4, 3),
);

final _successTx = Transaction(
  id: 'tx_001',
  bookId: 'book-1',
  deviceId: 'device_001',
  amount: 7415,
  type: TransactionType.expense,
  categoryId: 'dining',
  ledgerType: LedgerType.daily,
  timestamp: DateTime(2026, 5, 1),
  currentHash: 'hash_001',
  createdAt: DateTime(2026, 5, 1),
);

void main() {
  late _MockCreateTransactionUseCase mockCreate;
  late _MockCategoryService mockCategoryService;

  setUpAll(() {
    registerFallbackValue(_FakeCreateTransactionParams());
  });

  setUp(() {
    mockCreate = _MockCreateTransactionUseCase();
    mockCategoryService = _MockCategoryService();
    when(
      () => mockCategoryService.resolveLedgerType(any()),
    ).thenAnswer((_) async => LedgerType.daily);
    // Mirror the REAL CreateTransactionUseCase contract: amount <= 0 is
    // rejected (create_transaction_use_case.dart:90). This lets the WR-02 test
    // prove the stale-amount reset actually blocks the save.
    when(() => mockCreate.execute(any())).thenAnswer((inv) async {
      final params = inv.positionalArguments.first as CreateTransactionParams;
      if (params.amount <= 0) {
        return Result<Transaction>.error('amount must be greater than 0');
      }
      return Result.success(_successTx);
    });
  });

  Future<void> pump(WidgetTester tester, _ControllableRateUseCase rate) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createLocalizedWidget(
        ManualOneStepScreen(
          bookId: 'book-1',
          initialCategory: _l2Category,
          initialParentCategory: _l1Category,
          entrySource: EntrySource.manual,
        ),
        locale: const Locale('en'),
        overrides: [
          categoryRepositoryProvider.overrideWithValue(
            _FakeCategoryRepository([_l1Category, _l2Category]),
          ),
          createTransactionUseCaseProvider.overrideWithValue(mockCreate),
          categoryServiceProvider.overrideWithValue(mockCategoryService),
          appGetExchangeRateUseCaseProvider.overrideWithValue(rate),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectCurrency(WidgetTester tester, String code) async {
    // Open the currency selector via the SmartKeyboard currency tile, then
    // pick the requested code from the common-zone list.
    await tester.tap(find.byKey(const ValueKey('smart_keyboard_currency_key')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('currency-row-$code')));
    await tester.pumpAndSettle();
  }

  Future<void> selectUsd(WidgetTester tester) => selectCurrency(tester, 'USD');

  Future<void> tapDigit(WidgetTester tester, String d) async {
    await tester.tap(
      find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text(d),
      ),
    );
    await tester.pump();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('Record'),
      ),
    );
    await tester.pumpAndSettle();
  }

  RateResult fetched(String rate) => RateFetched(
    rate: rate,
    currency: 'USD',
    rateDate: DateTime(2026, 5, 1),
    source: 'frankfurter',
  );

  testWidgets(
    'WR-02: rate becomes unavailable after a successful push → save rejected '
    '(no stale JPY persisted)',
    (tester) async {
      // First fetch succeeds at 150.00 → 50.00 USD (5000c) → 7500 JPY.
      final rate = _ControllableRateUseCase(fetched('150.00'));
      await pump(tester, rate);
      await selectUsd(tester);

      // Enter 50.00 (USD has 2 decimals): 5,0,0,0 → 50.00.
      await tapDigit(tester, '5');
      await tapDigit(tester, '0');
      await tester.pumpAndSettle();

      // A successful triple was pushed: the create save now succeeds.
      // (Sanity — the push resolved against the good rate.)
      expect(rate.wasCalled, isTrue);

      // Now the rate becomes UNAVAILABLE for subsequent fetches.
      rate.nextResult = RateUnavailable(currency: 'EUR');

      // Quick 260613-wuv2: the rate provider is keyed on (currency, date), NOT
      // the entered amount — so appending a digit no longer re-resolves the rate
      // (it reuses the cached USD rate, which is the whole point: no per-keystroke
      // re-fetch / card flash). Switch currency to EUR to force a genuine
      // re-fetch that now returns RateUnavailable, exercising the same
      // `_pushForeignTriple` reset-to-0 guard the original test targeted.
      await selectCurrency(tester, 'EUR');
      await tester.pumpAndSettle();

      // WR-02: the stale JPY from the earlier 150.00 push must have been reset
      // to 0. If `submit()` reaches the create use case at all, it MUST carry
      // amount 0 (never the stale 7,500) — the real use case then rejects it.
      await tapSave(tester);
      final captured = verify(() => mockCreate.execute(captureAny())).captured;
      for (final c in captured) {
        final params = c as CreateTransactionParams;
        expect(
          params.amount,
          0,
          reason: 'stale converted JPY must be cleared to 0 (WR-02)',
        );
        // The triple must also be withheld (JPY-native), never partial.
        expect(params.originalCurrency, isNull);
        expect(params.appliedRate, isNull);
      }
    },
  );

  // WR-01's date guard lives in `foreignPushIsStale` and is unit-tested in
  // manual_one_step_screen_foreign_push_stale_test.dart. The screen's
  // `_selectedDate` is not mutated by in-foreign-entry UI on this screen, so a
  // realistic UI-driven mid-fetch date change is exercised at the pure-logic
  // level there rather than contrived through the widget tree here.
}

/// Widget test: home tile tap → TransactionEditScreen navigation seam (SC-2).
///
/// Per the W4 design decision, this test pumps HomeTransactionTile in isolation
/// rather than the full HomeScreen. The full home_screen.dart depends on 10+
/// providers (todayTransactionsProvider, currentBookIdProvider,
/// currentLocaleProvider, joy-metric providers, etc.) that are outside Phase 18's
/// blast radius (ADR-016 §3). The seam under test is the navigation contract:
/// tile.onTap → TransactionEditScreen.
///
/// The onTap callback is constructed inline — identical to the wiring added in
/// home_screen.dart Plan 07 — so the test verifies the correct screen is pushed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/update_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/transaction_edit_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_transaction_tile.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Fakes and mocks ────────────────────────────────────────────────────────────

class _MockUpdateTransactionUseCase extends Mock
    implements UpdateTransactionUseCase {}

class _FakeUpdateTransactionParams extends Fake
    implements UpdateTransactionParams {}

/// Always returns null — exercises the W3 orphan-category path safely.
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

// ── Test ───────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUpdateTransactionParams());
  });

  // Seed transaction matching the tile's display fields.
  final seedTx = Transaction(
    id: 'tx-1',
    bookId: 'book-1',
    deviceId: 'dev-1',
    amount: 2500,
    type: TransactionType.expense,
    categoryId: 'cat-1',
    ledgerType: LedgerType.joy,
    timestamp: DateTime(2026, 5, 1),
    merchant: 'TestCafe',
    joyFullness: 7,
    prevHash: 'p',
    currentHash: 'c',
    createdAt: DateTime(2026, 5, 1),
    entrySource: EntrySource.manual,
  );

  testWidgets(
    'home tile tap pushes TransactionEditScreen with seed visible (SC-2)',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockUpdate = _MockUpdateTransactionUseCase();

      // The mock update use case is defensive — never called in this test
      // (no submit happens), but the form resolves the provider on build.
      when(() => mockUpdate.execute(any())).thenAnswer(
        (_) async => Result.success(seedTx),
      );

      // Build the test host: a Scaffold wrapping a single HomeTransactionTile
      // whose onTap replicates the home_screen.dart Plan 07 wiring.
      // We use a Builder so Navigator.of(context) resolves inside the MaterialApp.
      final tileHost = Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: HomeTransactionTile(
              l1Icon: Icons.sports_esports,
              tagText: 'ときめき',
              tagBgColor: Colors.purple.shade100,
              tagTextColor: Colors.purple,
              merchant: seedTx.merchant!,
              category: 'TestCategory',
              categoryColor: Colors.purple,
              formattedAmount: '¥2,500',
              amountColor: Colors.purple,
              satisfactionValue: null,
              // onTap: reproduces only the navigation seam of home_screen.dart
              // (tile tap → push TransactionEditScreen). The await + provider
              // invalidation on pop-result==true (quick 260613-wjx) is covered
              // in home_screen_test.dart, which needs the real HomeScreen + ref.
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (_) => TransactionEditScreen(transaction: seedTx),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        createLocalizedWidget(
          tileHost,
          locale: const Locale('ja'),
          overrides: [
            // categoryRepositoryProvider: null repo exercises W3 orphan path
            // safely — _loadCategoryFromSeed returns null without crashing.
            categoryRepositoryProvider.overrideWithValue(
              _NullCategoryRepository(),
            ),
            categoryServiceProvider.overrideWith(
              (_) => CategoryService(
                categoryRepository: _NullCategoryRepository(),
                ledgerConfigRepository: _NullLedgerConfigRepository(),
              ),
            ),
            // updateTransactionUseCaseProvider: defensive mock — never called
            // during this test (no save is triggered), but the form widget
            // may resolve the provider during init.
            updateTransactionUseCaseProvider.overrideWith(
              (_) => mockUpdate,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Verify the tile is present before tapping
      expect(find.byType(HomeTransactionTile), findsOneWidget);

      // Tap the tile
      await tester.tap(find.byType(HomeTransactionTile));
      await tester.pumpAndSettle();

      // SC-2: TransactionEditScreen is on the navigation stack
      expect(
        find.byType(TransactionEditScreen),
        findsOneWidget,
        reason: 'Tapping the tile must push TransactionEditScreen (SC-2)',
      );

      // Form widget mounts inside the edit screen
      expect(
        find.byType(TransactionDetailsForm),
        findsOneWidget,
        reason: 'TransactionDetailsForm must be visible inside TransactionEditScreen',
      );

      // Seed merchant is visible — confirms .edit init populates fields
      expect(
        find.text('TestCafe'),
        findsOneWidget,
        reason: 'seed.merchant must be visible in the edit form',
      );
    },
  );
}

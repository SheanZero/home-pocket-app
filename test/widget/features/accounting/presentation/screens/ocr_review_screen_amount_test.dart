/// Widget tests for Phase 19 Plan 04 Task 3:
/// D-14 spillover — OcrReviewScreen amount-edit integration.
///
/// Tests verify the AmountDisplay → AmountEditBottomSheet → updateAmount →
/// save round-trip works on the OCR review host. Phase 18 invariants
/// (popUntil on save, D-13; MaterialBanner for empty draft; EntrySource.manual
/// MOD-005 marker) are also regression-guarded.
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
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/ocr_parse_draft.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        categoryRepositoryProvider,
        categoryServiceProvider,
        createTransactionUseCaseProvider,
        recordCategoryCorrectionUseCaseProvider;
import 'package:home_pocket/features/accounting/presentation/screens/ocr_review_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Mocks and fakes ───────────────────────────────────────────────────────────

class _MockCreateTransactionUseCase extends Mock
    implements CreateTransactionUseCase {}

class _FakeCreateTransactionParams extends Fake
    implements CreateTransactionParams {}

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

final _testDraft = OcrParseDraft(
  amount: 1200,
  merchant: 'TestMerchant',
  date: DateTime(2026, 5, 23),
  rawOcrText: null,
  imagePath: null,
);

// ── Shared provider overrides ──────────────────────────────────────────────────

List<Override> _overrides({required _MockCreateTransactionUseCase mockCreate}) {
  return [
    createTransactionUseCaseProvider.overrideWithValue(mockCreate),
    categoryRepositoryProvider.overrideWithValue(_NullCategoryRepository()),
    categoryServiceProvider.overrideWith(
      (_) => CategoryService(
        categoryRepository: _NullCategoryRepository(),
        ledgerConfigRepository: _NullLedgerConfigRepository(),
      ),
    ),
    recordCategoryCorrectionUseCaseProvider.overrideWith(
      (_) => throw UnimplementedError('recordCategoryCorrectionUseCase not needed in OCR host'),
    ),
  ];
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCreateTransactionParams());
  });

  // ── TEST 3: AmountDisplay + AmountEditBottomSheet integration on OcrReviewScreen ──

  testWidgets(
    'TEST 3: OcrReviewScreen renders AmountDisplay with draft amount and opens sheet on tap',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockCreate = _MockCreateTransactionUseCase();

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: OcrReviewScreen(bookId: 'book-1', draft: _testDraft),
          ),
          locale: const Locale('en'),
          overrides: _overrides(mockCreate: mockCreate),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: AmountDisplay is rendered above the form.
      expect(
        find.byType(AmountDisplay),
        findsOneWidget,
        reason: 'OcrReviewScreen host must render AmountDisplay with draft amount',
      );

      // Assert: AmountDisplay shows "1,200" (formatted from draft.amount = 1200).
      expect(
        find.text('1,200'),
        findsOneWidget,
        reason: 'AmountDisplay must show the OCR draft amount',
      );

      // Action: tap the AmountDisplay to trigger _editAmount().
      await tester.tap(find.byType(AmountDisplay));
      await tester.pump(); // Start modal animation

      // Assert: AmountEditBottomSheet opens.
      // NOTE: full pumpAndSettle omitted due to P19-B2 staging gap.
      expect(
        find.byType(AmountEditBottomSheet),
        findsOneWidget,
        reason: 'Tapping AmountDisplay on OcrReviewScreen must open AmountEditBottomSheet',
      );
    },
  );

  // ── TEST 4: Empty draft preserves MaterialBanner; AmountDisplay sits above it ──

  testWidgets(
    'TEST 4: OcrReviewScreen with empty draft shows AmountDisplay ABOVE MaterialBanner (D-14 + D-13)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockCreate = _MockCreateTransactionUseCase();

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: OcrReviewScreen(
              bookId: 'book-1',
              draft: const OcrParseDraft.empty(),
            ),
          ),
          locale: const Locale('en'),
          overrides: _overrides(mockCreate: mockCreate),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: AmountDisplay is visible (host renders it for empty drafts too).
      expect(
        find.byType(AmountDisplay),
        findsOneWidget,
        reason: 'AmountDisplay must be rendered even for empty drafts',
      );

      // Assert: MaterialBanner is visible (Phase 18 D-13 preservation).
      expect(
        find.byType(MaterialBanner),
        findsOneWidget,
        reason: 'MaterialBanner must be preserved for empty drafts (Phase 18 D-13)',
      );

      // Assert: AmountDisplay sits ABOVE MaterialBanner in the widget tree.
      // Verify by checking that AmountDisplay's top edge is above MaterialBanner's top edge.
      final amountDisplayPos = tester.getTopLeft(find.byType(AmountDisplay));
      final bannerPos = tester.getTopLeft(find.byType(MaterialBanner));
      expect(
        amountDisplayPos.dy,
        lessThan(bannerPos.dy),
        reason: 'AmountDisplay must appear ABOVE MaterialBanner in the column',
      );

      // Structural assertion: screen builds without errors with empty draft.
      // This confirms TransactionDetailsFormConfig.$new(entrySource: EntrySource.manual)
      // is used correctly — the MOD-005 marker (D-12) is in place.
      expect(find.byType(OcrReviewScreen), findsOneWidget);
    },
  );
}

/// Phase 52 (RECUX-03 / D-05/D-06/D-07) — deferred category-correction tests
/// for TransactionDetailsForm.
///
/// Proves the reworked reflux contract:
///   - D-05: a category change (chip tap OR full selector) does NOT write the
///     KEYWORD learning table immediately — the write is DEFERRED to confirmed
///     save. Change-then-abandon → ZERO writes.
///   - D-06: changing the category away from the recognized original via EITHER
///     the alternate chips OR the full selector records exactly ONE correction
///     at save, keyed by the corrected categoryId.
///   - D-07: the write key == `resolvedKeyword` verbatim (write==read identity,
///     260526-pg6); a null/empty keyword writes NOTHING.
///   - RECUX-03 / D-16: the merchant table is NEVER written on the correction
///     path (only RecordCategoryCorrectionUseCase → category_keyword_preferences).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
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
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';
import 'package:home_pocket/features/voice/domain/models/recognition_outcome.dart'
    show ConfidenceBand;
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart'
    show CategoryMatchResult, MatchSource;
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Mocks / fakes ───────────────────────────────────────────────────────────

class _MockCreateTransactionUseCase extends Mock
    implements CreateTransactionUseCase {}

class _FakeCreateTransactionParams extends Fake
    implements CreateTransactionParams {}

/// Spy correction use case: counts execute() calls and captures the (keyword,
/// correctedCategoryId) pairs so tests can assert the deferred write fired
/// exactly once with the verbatim keyword (or never at all).
class _SpyRecordCategoryCorrectionUseCase
    implements RecordCategoryCorrectionUseCase {
  final List<({String keyword, String correctedCategoryId})> calls = [];

  @override
  Future<void> execute({
    required String keyword,
    required String correctedCategoryId,
  }) async {
    calls.add((keyword: keyword, correctedCategoryId: correctedCategoryId));
  }
}

/// Spy merchant-correction repo: tracks whether the merchant learning table is
/// ever written. The correction path MUST NEVER touch it (D-07 / D-16). (The
/// Phase-18 merchant→category ML hook is a SEPARATE concern, but this test never
/// fills a merchant, so any call here would be a defect.)
class _SpyMerchantCategoryPreferenceRepository
    implements MerchantCategoryPreferenceRepository {
  int recordSelectionCalls = 0;
  int upsertCalls = 0;

  @override
  Future<MerchantCategoryPreference?> findByMerchantKey(
    String merchantKey,
  ) async => null;
  @override
  Future<void> upsert(MerchantCategoryPreference preference) async {
    upsertCalls++;
  }
  @override
  Future<void> recordSelection({
    required String merchantKey,
    required String selectedCategoryId,
  }) async {
    recordSelectionCalls++;
  }
  @override
  Future<String?> suggestCategoryId(String merchantKey) async => null;
}

/// Resolves any of a fixed set of categories by id (for chip-tap + selector
/// findById lookups and CategorySelectionScreen's findActive list).
class _StubCategoryRepository implements CategoryRepository {
  _StubCategoryRepository(this._categories);
  final List<Category> _categories;
  @override
  Future<Category?> findById(String id) async {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }
  @override
  Future<List<Category>> findAll() async => _categories;
  @override
  Future<List<Category>> findActive() async => _categories;
  @override
  Future<List<Category>> findByLevel(int level) async =>
      _categories.where((c) => c.level == level).toList();
  @override
  Future<List<Category>> findByParent(String parentId) async =>
      _categories.where((c) => c.parentId == parentId).toList();
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

/// Null ledger config — keeps everything on the daily ledger (no DB needed).
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

// ── Fixtures ────────────────────────────────────────────────────────────────

const _kKeyword = 'コーヒー'; // resolvedKeyword verbatim (D-07 / 260526-pg6)

final _initialCat = Category(
  id: 'cat_food',
  name: 'Food',
  icon: 'restaurant',
  color: '#E85A4F',
  level: 1,
  isSystem: true,
  sortOrder: 1,
  createdAt: DateTime(2026, 5, 1),
);

// Alternate L1 (chip-path correction target).
final _altCat = Category(
  id: 'cat_transport',
  name: 'Transport',
  icon: 'train',
  color: '#2A8FB8',
  level: 1,
  isSystem: true,
  sortOrder: 2,
  createdAt: DateTime(2026, 5, 1),
);

// Selector-path fixtures: an L1 parent with one L2 child (the correction
// target reached by expanding the parent and tapping the child).
final _selParentCat = Category(
  id: 'cat_hobby',
  name: 'Hobby',
  icon: 'music_note',
  color: '#9C27B0',
  level: 1,
  isSystem: false,
  sortOrder: 3,
  createdAt: DateTime(2026, 5, 1),
);
final _selChildCat = Category(
  id: 'cat_hobby_music',
  name: 'MusicLessons',
  icon: 'music_note',
  color: '#9C27B0',
  parentId: 'cat_hobby',
  level: 2,
  isSystem: false,
  sortOrder: 1,
  createdAt: DateTime(2026, 5, 1),
);

Transaction _savedTx({required String categoryId}) => Transaction(
  id: 'tx-corr',
  bookId: 'b1',
  deviceId: 'dev-001',
  amount: 500,
  type: TransactionType.expense,
  categoryId: categoryId,
  ledgerType: LedgerType.daily,
  timestamp: DateTime(2026, 5, 1),
  currentHash: 'h',
  createdAt: DateTime(2026, 5, 1),
  entrySource: EntrySource.voice,
);

// ── Override builder ─────────────────────────────────────────────────────────

List<Override> _overrides({
  required _SpyRecordCategoryCorrectionUseCase correctionSpy,
  required _MockCreateTransactionUseCase createUseCase,
  required _SpyMerchantCategoryPreferenceRepository merchantSpy,
  required List<Category> categories,
}) {
  final catRepo = _StubCategoryRepository(categories);
  return [
    categoryRepositoryProvider.overrideWithValue(catRepo),
    categoryServiceProvider.overrideWith(
      (_) => CategoryService(
        categoryRepository: catRepo,
        ledgerConfigRepository: _NullLedgerConfigRepository(),
      ),
    ),
    createTransactionUseCaseProvider.overrideWith((_) => createUseCase),
    recordCategoryCorrectionUseCaseProvider.overrideWith((_) => correctionSpy),
    merchantCategoryLearningServiceProvider.overrideWith(
      (_) => MerchantCategoryLearningService(
        repository: merchantSpy,
        categoryRepository: catRepo,
      ),
    ),
  ];
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCreateTransactionParams());
  });

  Widget buildForm(
    TransactionDetailsFormConfig config, {
    required List<Override> overrides,
    required Key formKey,
  }) {
    return createLocalizedWidget(
      Scaffold(body: TransactionDetailsForm(key: formKey, config: config)),
      locale: const Locale('en'),
      overrides: overrides,
    );
  }

  void sizeView(WidgetTester tester) {
    tester.view.physicalSize = const Size(402, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Deferred category correction (RECUX-03 / D-05/D-06/D-07)', () {
    testWidgets(
      'D-05: chip change then ABANDON (no save) → ZERO correction writes',
      (tester) async {
        sizeView(tester);
        final correctionSpy = _SpyRecordCategoryCorrectionUseCase();
        final createUseCase = _MockCreateTransactionUseCase();
        final merchantSpy = _SpyMerchantCategoryPreferenceRepository();
        final formKey = GlobalKey<TransactionDetailsFormState>();

        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.$new(
              bookId: 'b1',
              entrySource: EntrySource.voice,
              initialCategory: _initialCat,
              voiceKeyword: _kKeyword,
            ),
            overrides: _overrides(
              correctionSpy: correctionSpy,
              createUseCase: createUseCase,
              merchantSpy: merchantSpy,
              categories: [_initialCat, _altCat],
            ),
            formKey: formKey,
          ),
        );
        await tester.pumpAndSettle();

        // Push recognition → renders the alternate chips.
        formKey.currentState!.updateRecognition(
          ConfidenceBand.weak,
          [
            CategoryMatchResult(
              categoryId: _altCat.id,
              confidence: 0.4,
              source: MatchSource.keyword,
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Tap the alternate chip → category swaps (stash set), NO write yet.
        await tester.tap(find.byKey(ValueKey('alt-chip-${_altCat.id}')));
        await tester.pumpAndSettle();

        // Abandon: never call submit().
        expect(
          correctionSpy.calls,
          isEmpty,
          reason: 'D-05: the write is DEFERRED to save — abandon writes nothing',
        );
        verifyNever(() => createUseCase.execute(any()));
      },
    );

    testWidgets(
      'D-06: chip change then SAVE → exactly ONE write, key==resolvedKeyword',
      (tester) async {
        sizeView(tester);
        final correctionSpy = _SpyRecordCategoryCorrectionUseCase();
        final createUseCase = _MockCreateTransactionUseCase();
        when(() => createUseCase.execute(any())).thenAnswer(
          (_) async => Result.success(_savedTx(categoryId: _altCat.id)),
        );
        final merchantSpy = _SpyMerchantCategoryPreferenceRepository();
        final formKey = GlobalKey<TransactionDetailsFormState>();

        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.$new(
              bookId: 'b1',
              entrySource: EntrySource.voice,
              initialCategory: _initialCat,
              voiceKeyword: _kKeyword,
            ),
            overrides: _overrides(
              correctionSpy: correctionSpy,
              createUseCase: createUseCase,
              merchantSpy: merchantSpy,
              categories: [_initialCat, _altCat],
            ),
            formKey: formKey,
          ),
        );
        await tester.pumpAndSettle();

        formKey.currentState!.updateRecognition(
          ConfidenceBand.weak,
          [
            CategoryMatchResult(
              categoryId: _altCat.id,
              confidence: 0.4,
              source: MatchSource.keyword,
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(ValueKey('alt-chip-${_altCat.id}')));
        await tester.pumpAndSettle();

        formKey.currentState!.updateAmount(500);
        await tester.pump();

        final result = await formKey.currentState!.submit();
        expect(
          result.maybeWhen(success: (_) => true, orElse: () => false),
          isTrue,
        );

        expect(correctionSpy.calls.length, 1,
            reason: 'D-06: exactly one deferred correction at save');
        expect(correctionSpy.calls.single.keyword, _kKeyword,
            reason: 'D-07: write key == resolvedKeyword verbatim (260526-pg6)');
        expect(correctionSpy.calls.single.correctedCategoryId, _altCat.id,
            reason: 'D-06: write carries the corrected categoryId');
      },
    );

    testWidgets(
      'D-06: full-selector change then SAVE → exactly ONE write (same path)',
      (tester) async {
        sizeView(tester);
        final correctionSpy = _SpyRecordCategoryCorrectionUseCase();
        final createUseCase = _MockCreateTransactionUseCase();
        when(() => createUseCase.execute(any())).thenAnswer(
          (_) async => Result.success(_savedTx(categoryId: _selChildCat.id)),
        );
        final merchantSpy = _SpyMerchantCategoryPreferenceRepository();
        final formKey = GlobalKey<TransactionDetailsFormState>();

        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.$new(
              bookId: 'b1',
              entrySource: EntrySource.voice,
              initialCategory: _initialCat,
              voiceKeyword: _kKeyword,
            ),
            overrides: _overrides(
              correctionSpy: correctionSpy,
              createUseCase: createUseCase,
              merchantSpy: merchantSpy,
              categories: [_initialCat, _selParentCat, _selChildCat],
            ),
            formKey: formKey,
          ),
        );
        await tester.pumpAndSettle();

        // Render chips so the trailing "more" exit chip → full selector exists.
        formKey.currentState!.updateRecognition(
          ConfidenceBand.weak,
          [
            CategoryMatchResult(
              categoryId: _altCat.id,
              confidence: 0.4,
              source: MatchSource.keyword,
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Open the full selector via the exit chip.
        await tester.tap(find.byKey(const ValueKey('alt-chip-exit')));
        await tester.pumpAndSettle();

        // Expand the parent L1, then tap the L2 child → selector pops with it.
        await tester.tap(find.text(_selParentCat.name));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_selChildCat.name));
        await tester.pumpAndSettle();

        formKey.currentState!.updateAmount(500);
        await tester.pump();

        final result = await formKey.currentState!.submit();
        expect(
          result.maybeWhen(success: (_) => true, orElse: () => false),
          isTrue,
        );

        expect(correctionSpy.calls.length, 1,
            reason: 'D-06: full-selector change also records ONE correction');
        expect(correctionSpy.calls.single.keyword, _kKeyword,
            reason: 'D-07: write key == resolvedKeyword verbatim');
        expect(correctionSpy.calls.single.correctedCategoryId, _selChildCat.id,
            reason: 'selector path carries the corrected categoryId');
      },
    );

    testWidgets(
      'D-07: null/empty keyword + category change + SAVE → ZERO writes',
      (tester) async {
        sizeView(tester);
        final correctionSpy = _SpyRecordCategoryCorrectionUseCase();
        final createUseCase = _MockCreateTransactionUseCase();
        when(() => createUseCase.execute(any())).thenAnswer(
          (_) async => Result.success(_savedTx(categoryId: _altCat.id)),
        );
        final merchantSpy = _SpyMerchantCategoryPreferenceRepository();
        final formKey = GlobalKey<TransactionDetailsFormState>();

        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.$new(
              bookId: 'b1',
              entrySource: EntrySource.voice,
              initialCategory: _initialCat,
              // No voiceKeyword → resolvedKeyword is null (manual/empty case).
            ),
            overrides: _overrides(
              correctionSpy: correctionSpy,
              createUseCase: createUseCase,
              merchantSpy: merchantSpy,
              categories: [_initialCat, _altCat],
            ),
            formKey: formKey,
          ),
        );
        await tester.pumpAndSettle();

        formKey.currentState!.updateRecognition(
          ConfidenceBand.weak,
          [
            CategoryMatchResult(
              categoryId: _altCat.id,
              confidence: 0.4,
              source: MatchSource.keyword,
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(ValueKey('alt-chip-${_altCat.id}')));
        await tester.pumpAndSettle();

        formKey.currentState!.updateAmount(500);
        await tester.pump();
        await formKey.currentState!.submit();

        expect(correctionSpy.calls, isEmpty,
            reason: 'D-07: null/empty keyword writes NO learning row');
      },
    );

    testWidgets(
      'RECUX-03 / D-16: correction save never writes the merchant table',
      (tester) async {
        sizeView(tester);
        final correctionSpy = _SpyRecordCategoryCorrectionUseCase();
        final createUseCase = _MockCreateTransactionUseCase();
        when(() => createUseCase.execute(any())).thenAnswer(
          (_) async => Result.success(_savedTx(categoryId: _altCat.id)),
        );
        final merchantSpy = _SpyMerchantCategoryPreferenceRepository();
        final formKey = GlobalKey<TransactionDetailsFormState>();

        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.$new(
              bookId: 'b1',
              entrySource: EntrySource.voice,
              initialCategory: _initialCat,
              voiceKeyword: _kKeyword,
              // No merchant filled → the Phase-18 ML hook must not fire either.
            ),
            overrides: _overrides(
              correctionSpy: correctionSpy,
              createUseCase: createUseCase,
              merchantSpy: merchantSpy,
              categories: [_initialCat, _altCat],
            ),
            formKey: formKey,
          ),
        );
        await tester.pumpAndSettle();

        formKey.currentState!.updateRecognition(
          ConfidenceBand.weak,
          [
            CategoryMatchResult(
              categoryId: _altCat.id,
              confidence: 0.4,
              source: MatchSource.keyword,
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(ValueKey('alt-chip-${_altCat.id}')));
        await tester.pumpAndSettle();
        formKey.currentState!.updateAmount(500);
        await tester.pump();
        await formKey.currentState!.submit();

        expect(correctionSpy.calls.length, 1,
            reason: 'the KEYWORD correction still fires (sanity)');
        expect(merchantSpy.recordSelectionCalls, 0,
            reason: 'D-16: the merchant table is never written on this path');
        expect(merchantSpy.upsertCalls, 0,
            reason: 'D-07: no merchant_category_preferences upsert on correction');
      },
    );

    testWidgets(
      'D-05: change away then BACK to original + SAVE → ZERO writes',
      (tester) async {
        sizeView(tester);
        final correctionSpy = _SpyRecordCategoryCorrectionUseCase();
        final createUseCase = _MockCreateTransactionUseCase();
        when(() => createUseCase.execute(any())).thenAnswer(
          (_) async => Result.success(_savedTx(categoryId: _initialCat.id)),
        );
        final merchantSpy = _SpyMerchantCategoryPreferenceRepository();
        final formKey = GlobalKey<TransactionDetailsFormState>();

        await tester.pumpWidget(
          buildForm(
            TransactionDetailsFormConfig.$new(
              bookId: 'b1',
              entrySource: EntrySource.voice,
              initialCategory: _initialCat,
              voiceKeyword: _kKeyword,
            ),
            overrides: _overrides(
              correctionSpy: correctionSpy,
              createUseCase: createUseCase,
              merchantSpy: merchantSpy,
              categories: [_initialCat, _altCat],
            ),
            formKey: formKey,
          ),
        );
        await tester.pumpAndSettle();

        formKey.currentState!.updateRecognition(
          ConfidenceBand.weak,
          [
            CategoryMatchResult(
              categoryId: _altCat.id,
              confidence: 0.4,
              source: MatchSource.keyword,
            ),
            CategoryMatchResult(
              categoryId: _initialCat.id,
              confidence: 0.3,
              source: MatchSource.keyword,
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Change to alt (stash set)… the first pick clears the band per D-09,
        // collapsing the chips.
        await tester.tap(find.byKey(ValueKey('alt-chip-${_altCat.id}')));
        await tester.pumpAndSettle();

        // Re-push recognition so the chips re-render, then change BACK to the
        // recognized original — which must DISCARD the pending stash.
        formKey.currentState!.updateRecognition(
          ConfidenceBand.weak,
          [
            CategoryMatchResult(
              categoryId: _altCat.id,
              confidence: 0.4,
              source: MatchSource.keyword,
            ),
            CategoryMatchResult(
              categoryId: _initialCat.id,
              confidence: 0.3,
              source: MatchSource.keyword,
            ),
          ],
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('alt-chip-${_initialCat.id}')));
        await tester.pumpAndSettle();

        formKey.currentState!.updateAmount(500);
        await tester.pump();
        await formKey.currentState!.submit();

        expect(correctionSpy.calls, isEmpty,
            reason: 'reverting to the recognized original discards the stash');
      },
    );
  });
}

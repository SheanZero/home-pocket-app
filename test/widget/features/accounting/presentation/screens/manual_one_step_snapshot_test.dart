/// Quick task 260706-tm6 (voice-consolidation P0-5): direct tests for
/// ManualEntrySnapshot — the pre-speech form snapshot behind the voice modal's
/// 「重置·恢复账目」 restore path.
///
/// Coverage:
///   - capture(): all 15 fields (4 host-owned + 11 form-owned) are captured
///     from a live TransactionDetailsFormState.
///   - restoreForm(): a dirtied form rolls back to the snapshot values,
///     including clearing a voice-filled category when the snapshot has none.
///   - restoreHostAmount(): pure AmountInputController replay — clear, restore
///     the currency decimal cap, replay digits/dot, return the result string.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_details_form_config.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider, categoryServiceProvider;
import 'package:home_pocket/features/accounting/presentation/screens/manual_one_step_snapshot.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_input_controller.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/confidence_band_indicator.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';
import 'package:home_pocket/features/voice/domain/models/recognition_outcome.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';
import 'package:home_pocket/shared/utils/currency_conversion.dart'
    show currencyFractionDigitsFor;

import '../../../../../helpers/test_localizations.dart';

// ── Minimal fakes (no DB) ─────────────────────────────────────────────────────

class _EmptyCategoryRepository implements CategoryRepository {
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

class _EmptyLedgerConfigRepository implements CategoryLedgerConfigRepository {
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

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _catA = Category(
  id: 'cat-a',
  name: 'Category A',
  icon: 'restaurant',
  color: '#E85A4F',
  level: 2,
  parentId: 'parent-a',
  sortOrder: 1,
  createdAt: DateTime(2026, 7, 1),
);

final _parentA = Category(
  id: 'parent-a',
  name: 'Parent A',
  icon: 'restaurant',
  color: '#E85A4F',
  level: 1,
  isSystem: true,
  sortOrder: 1,
  createdAt: DateTime(2026, 7, 1),
);

final _catB = Category(
  id: 'cat-b',
  name: 'Category B',
  icon: 'sports_tennis',
  color: '#9C27B0',
  level: 1,
  sortOrder: 2,
  createdAt: DateTime(2026, 7, 1),
);

/// Snapshot builder for the pure restoreHostAmount cases — form-owned fields
/// are inert placeholders (restoreHostAmount never reads them).
ManualEntrySnapshot _hostAmountSnapshot({
  required String amountText,
  required String currency,
}) {
  return ManualEntrySnapshot(
    amountText: amountText,
    currency: currency,
    manualForeignRate: null,
    lastFillWasVoice: false,
    category: null,
    parentCategory: null,
    date: DateTime(2026, 7, 6),
    merchant: '',
    note: '',
    satisfaction: 2,
    ledgerType: LedgerType.daily,
    bookedJpyAmount: 0,
    originalCurrency: null,
    originalAmount: null,
    appliedRate: null,
  );
}

void main() {
  // ── restoreHostAmount: pure controller replay (no pump needed) ─────────────

  group('ManualEntrySnapshot.restoreHostAmount', () {
    test('replays a JPY integer amount digit-by-digit', () {
      final controller = AmountInputController(
        decimals: currencyFractionDigitsFor('JPY'),
      );
      final snapshot = _hostAmountSnapshot(amountText: '1234', currency: 'JPY');

      final result = snapshot.restoreHostAmount(controller);

      expect(result, '1234');
      expect(controller.text, '1234');
      expect(controller.decimals, 0, reason: 'JPY restores a 0-decimal cap');
    });

    test(
      'replays a 2-decimal foreign amount including the dot (onDot path)',
      () {
        final controller = AmountInputController(
          decimals: currencyFractionDigitsFor('USD'),
        );
        final snapshot = _hostAmountSnapshot(
          amountText: '12.50',
          currency: 'USD',
        );

        final result = snapshot.restoreHostAmount(controller);

        expect(result, '12.50');
        expect(controller.text, '12.50');
        expect(controller.decimals, 2);
      },
    );

    test('empty snapshot amount clears the controller and returns ""', () {
      final controller = AmountInputController(decimals: 0)
        ..onDigit('9')
        ..onDigit('9');
      expect(controller.text, '99', reason: 'precondition: dirty controller');

      final snapshot = _hostAmountSnapshot(amountText: '', currency: 'JPY');
      final result = snapshot.restoreHostAmount(controller);

      expect(result, '');
      expect(controller.text, '');
    });

    test(
      'a pre-dirtied controller is cleared BEFORE the replay (no concat)',
      () {
        final controller = AmountInputController(decimals: 0)
          ..onDigit('9')
          ..onDigit('9')
          ..onDigit('9');
        final snapshot = _hostAmountSnapshot(amountText: '42', currency: 'JPY');

        final result = snapshot.restoreHostAmount(controller);

        expect(result, '42', reason: 'must be 42, never 99942');
        expect(controller.text, '42');
      },
    );

    test('restoring a JPY snapshot onto a foreign-configured controller '
        'reverts the decimal cap', () {
      final controller = AmountInputController(decimals: 2)
        ..onDigit('9')
        ..onDot()
        ..onDigit('9');
      expect(controller.text, '9.9', reason: 'precondition: foreign decimals');

      final snapshot = _hostAmountSnapshot(amountText: '500', currency: 'JPY');
      final result = snapshot.restoreHostAmount(controller);

      expect(result, '500');
      expect(
        controller.decimals,
        0,
        reason: 'onCurrencyChange restores the snapshot currency cap',
      );
    });
  });

  // ── capture + restoreForm against a live TransactionDetailsFormState ───────

  group('ManualEntrySnapshot.capture / restoreForm', () {
    Future<GlobalKey<TransactionDetailsFormState>> pumpForm(
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final formKey = GlobalKey<TransactionDetailsFormState>();
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: TransactionDetailsForm(
              key: formKey,
              config: TransactionDetailsFormConfig.$new(
                bookId: 'book-1',
                entrySource: EntrySource.manual,
              ),
            ),
          ),
          locale: const Locale('en'),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              _EmptyCategoryRepository(),
            ),
            categoryServiceProvider.overrideWith(
              (_) => CategoryService(
                categoryRepository: _EmptyCategoryRepository(),
                ledgerConfigRepository: _EmptyLedgerConfigRepository(),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return formKey;
    }

    testWidgets(
      'capture records all 15 fields (4 host-owned + 11 form-owned)',
      (tester) async {
        final formKey = await pumpForm(tester);
        final form = formKey.currentState!;

        form.updateCategory(_catA, _parentA);
        form.updateMerchant('Store A');
        form.updateNote('note A');
        form.updateDate(DateTime(2026, 7, 1));
        form.updateSatisfaction(5);
        form.updateLedgerType(LedgerType.daily);
        form.updateAmount(1938);
        form.updateCurrencyTriple(
          originalCurrency: 'USD',
          originalAmount: 1250,
          appliedRate: '155.0',
        );
        await tester.pumpAndSettle();

        final snapshot = ManualEntrySnapshot.capture(
          amountText: '12.50',
          currency: 'USD',
          manualForeignRate: '155.0',
          lastFillWasVoice: true,
          form: form,
        );

        // Host-owned quadruple.
        expect(snapshot.amountText, '12.50');
        expect(snapshot.currency, 'USD');
        expect(snapshot.manualForeignRate, '155.0');
        expect(snapshot.lastFillWasVoice, isTrue);
        // Form-owned ten.
        expect(snapshot.category?.id, 'cat-a');
        expect(snapshot.parentCategory?.id, 'parent-a');
        expect(snapshot.date, DateTime(2026, 7, 1));
        expect(snapshot.merchant, 'Store A');
        expect(snapshot.note, 'note A');
        expect(snapshot.satisfaction, 5);
        expect(snapshot.ledgerType, LedgerType.daily);
        expect(snapshot.bookedJpyAmount, 1938);
        expect(snapshot.originalCurrency, 'USD');
        expect(snapshot.originalAmount, 1250);
        expect(snapshot.appliedRate, '155.0');
      },
    );

    testWidgets(
      'restoreForm rolls a dirtied form back to the snapshot values',
      (tester) async {
        final formKey = await pumpForm(tester);
        final form = formKey.currentState!;

        // Seed the pre-speech state and capture it.
        form.updateCategory(_catA, _parentA);
        form.updateMerchant('Store A');
        form.updateNote('note A');
        form.updateDate(DateTime(2026, 7, 1));
        form.updateSatisfaction(5);
        form.updateLedgerType(LedgerType.daily);
        form.updateAmount(1938);
        form.updateCurrencyTriple(
          originalCurrency: 'USD',
          originalAmount: 1250,
          appliedRate: '155.0',
        );
        await tester.pumpAndSettle();
        final snapshot = ManualEntrySnapshot.capture(
          amountText: '12.50',
          currency: 'USD',
          manualForeignRate: '155.0',
          lastFillWasVoice: false,
          form: form,
        );

        // Dirty every form-owned field (simulates a voice auto-fill).
        form.updateCategory(_catB, null);
        form.updateMerchant('dirty merchant');
        form.updateNote('dirty note');
        form.updateDate(DateTime(2026, 7, 4));
        form.updateSatisfaction(9);
        form.updateLedgerType(LedgerType.joy);
        form.updateAmount(777);
        form.updateRecognition(ConfidenceBand.weak, const [
          CategoryMatchResult(
            categoryId: 'cat-b',
            confidence: 0.4,
            source: MatchSource.fallback,
          ),
        ]);
        form.updateCurrencyTriple(
          originalCurrency: null,
          originalAmount: null,
          appliedRate: null,
        );
        await tester.pumpAndSettle();
        expect(
          form.currentCategory?.id,
          'cat-b',
          reason: 'precondition: form is dirty',
        );
        expect(find.byType(ConfidenceBandIndicator), findsNothing);

        snapshot.restoreForm(form);
        await tester.pumpAndSettle();

        expect(form.currentCategory?.id, 'cat-a');
        expect(form.currentParentCategory?.id, 'parent-a');
        expect(form.currentMerchant, 'Store A');
        expect(form.currentNote, 'note A');
        expect(form.currentDate, DateTime(2026, 7, 1));
        expect(form.currentSatisfaction, 5);
        expect(form.currentLedgerType, LedgerType.daily);
        expect(
          form.currentAmount,
          1938,
          reason: 'restore uses captured booked JPY, not USD text/minor units',
        );
        expect(form.currentOriginalCurrency, 'USD');
        expect(form.currentOriginalAmount, 1250);
        expect(form.currentAppliedRate, '155.0');
        expect(
          find.byType(ConfidenceBandIndicator),
          findsNothing,
          reason: 'discarded voice confidence must not survive restore',
        );
      },
    );

    testWidgets(
      'a null-category snapshot clears the voice category and restores its '
      'authoritative ledger type',
      (tester) async {
        final formKey = await pumpForm(tester);
        final form = formKey.currentState!;

        // Capture a fresh form: category is still null.
        final snapshot = ManualEntrySnapshot.capture(
          amountText: '',
          currency: 'JPY',
          manualForeignRate: null,
          lastFillWasVoice: false,
          form: form,
        );
        expect(
          snapshot.category,
          isNull,
          reason: 'precondition: pre-speech form had no category',
        );

        // Voice fill resolves a category + merchant.
        form.updateCategory(_catB, null);
        form.updateMerchant('voice merchant');
        form.updateLedgerType(LedgerType.joy);
        await tester.pumpAndSettle();
        expect(form.currentCategory?.id, 'cat-b');
        expect(form.currentLedgerType, LedgerType.joy);

        snapshot.restoreForm(form);
        await tester.pumpAndSettle();

        expect(
          form.currentCategory,
          isNull,
          reason: 'reset must clear the category added by voice',
        );
        expect(form.currentParentCategory, isNull);
        expect(
          form.currentLedgerType,
          snapshot.ledgerType,
          reason: 'snapshot ledger type wins over category inference',
        );
        expect(form.currentMerchant, '');
      },
    );
  });
}

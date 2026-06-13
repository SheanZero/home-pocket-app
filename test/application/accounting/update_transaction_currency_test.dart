// WAVE 0 RED SCAFFOLD — Phase 42, producing plan 42-03.
//
// This file references currency override fields on UpdateTransactionParams
// (originalCurrency / originalAmount / appliedRate) that DO NOT EXIST yet.
// It is therefore EXPECTED to fail to compile (RED) until plan 42-03 adds the
// currency-edit plumbing to UpdateTransactionUseCase.
//
// Locked behavior under test (DISP-04 / ADR-021 / ADR-020):
//   - Editing an existing foreign (USD) row's originalAmount or appliedRate
//     recomputes the JPY `amount` via convertToJpy() and persists the triple.
//   - The hash chain is NOT recomputed when only currency fields change
//     (ADR-021: the triple is excluded from the hash, so prevHash/currentHash
//      stay frozen on a currency-only edit).
//
// Do NOT weaken these assertions to make them pass. RED is the intended state.
//
// See: docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md,
//      docs/arch/03-adr/ADR-020_Exchange_Rate_Precision.md,
//      lib/shared/utils/currency_conversion.dart (convertToJpy single site).

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/update_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _FakeTransaction extends Fake implements Transaction {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTransaction());
  });

  late _MockTransactionRepository mockTransactionRepo;
  late UpdateTransactionUseCase useCase;

  /// A well-formed USD foreign-row seed: 5000 cents @ 148.30 → 7415 JPY.
  Transaction makeForeignSeed({
    int amount = 7415,
    String originalCurrency = 'USD',
    int originalAmount = 5000,
    String appliedRate = '148.30',
    String prevHash = 'prev-hash-abc',
    String currentHash = 'current-hash-xyz',
  }) {
    final now = DateTime(2026, 6, 1);
    return Transaction(
      id: 'tx-usd-001',
      bookId: 'book-001',
      deviceId: 'device-001',
      amount: amount,
      type: TransactionType.expense,
      categoryId: 'cat-food',
      ledgerType: LedgerType.daily,
      timestamp: now,
      prevHash: prevHash,
      currentHash: currentHash,
      createdAt: now,
      joyFullness: 2,
      entrySource: EntrySource.manual,
      originalCurrency: originalCurrency,
      originalAmount: originalAmount,
      appliedRate: appliedRate,
    );
  }

  setUp(() {
    mockTransactionRepo = _MockTransactionRepository();
    useCase = UpdateTransactionUseCase(
      transactionRepository: mockTransactionRepo,
    );
    when(() => mockTransactionRepo.update(any())).thenAnswer((_) async {});
  });

  group('currency-edit recompute (DISP-04 / ADR-021)', () {
    test(
      'editing appliedRate recomputes JPY amount via convertToJpy() and '
      'persists the triple',
      () async {
        final seed = makeForeignSeed();

        // Rate changes 148.30 → 150.00. 5000 / 100 × 150.00 = 7500 JPY.
        final result = await useCase.execute(
          UpdateTransactionParams(
            seed: seed,
            originalCurrency: 'USD',
            originalAmount: 5000,
            appliedRate: '150.00',
          ),
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        expect(result.data!.amount, 7500,
            reason: 'JPY must be recomputed via convertToJpy(), not left stale');
        expect(result.data!.appliedRate, '150.00');
        expect(result.data!.originalCurrency, 'USD');
        expect(result.data!.originalAmount, 5000);
      },
    );

    test(
      'editing originalAmount recomputes JPY amount via convertToJpy()',
      () async {
        final seed = makeForeignSeed();

        // originalAmount 5000 → 10000 cents (USD 100.00) @ 148.30 = 14830 JPY.
        final result = await useCase.execute(
          UpdateTransactionParams(
            seed: seed,
            originalCurrency: 'USD',
            originalAmount: 10000,
            appliedRate: '148.30',
          ),
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        expect(result.data!.amount, 14830);
        expect(result.data!.originalAmount, 10000);
      },
    );

    test(
      'currency-only edit does NOT recompute the hash chain (ADR-021 no-rehash): '
      'prevHash / currentHash stay frozen',
      () async {
        final seed = makeForeignSeed(
          prevHash: 'prev-hash-abc',
          currentHash: 'current-hash-xyz',
        );

        final result = await useCase.execute(
          UpdateTransactionParams(
            seed: seed,
            originalCurrency: 'USD',
            originalAmount: 5000,
            appliedRate: '150.00',
          ),
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        // ADR-021: the triple is excluded from the hash, so editing currency
        // fields must NOT mutate the chain links.
        expect(result.data!.prevHash, 'prev-hash-abc',
            reason: 'prevHash must stay frozen on a currency-only edit');
        expect(result.data!.currentHash, 'current-hash-xyz',
            reason: 'currentHash must stay frozen on a currency-only edit');
      },
    );
  });
}

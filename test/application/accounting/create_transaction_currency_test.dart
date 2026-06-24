// WAVE 0 RED SCAFFOLD — Phase 42, producing plan 42-03 (and SC-5 integration smoke).
//
// This file asserts the LOCKED SC-5 acceptance figure: USD 50 @ rate "148.30"
// must persist as Transaction.amount == 7415 JPY (ADR-020 .round(), D-09), with
// the full foreign-currency triple (originalCurrency='USD', originalAmount=5000
// minor units per ADR-021 Update 2026-06-12, appliedRate='148.30').
//
// It is EXPECTED to be RED until the implementation lands. The integration smoke
// is the acceptance contract — do NOT weaken these assertions to make them pass.
//
// See: .planning/phases/42-entry-ui-display-voice/42-VALIDATION.md (SC-5 row),
//      docs/arch/03-adr/ADR-020_Exchange_Rate_Precision.md,
//      docs/arch/03-adr/ADR-021_Hash_Chain_Scope.md.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

class _MockHashChainService extends Mock implements HashChainService {}

class _MockCategoryService extends Mock implements CategoryService {}

class _FakeTransaction extends Fake implements Transaction {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTransaction());
  });

  late _MockTransactionRepository mockTransactionRepo;
  late _MockCategoryRepository mockCategoryRepo;
  late _MockDeviceIdentityRepository mockDeviceIdentityRepo;
  late _MockHashChainService mockHashChainService;
  late _MockCategoryService mockCategoryService;
  late CreateTransactionUseCase useCase;

  final testCategory = Category(
    id: 'cat_food',
    name: 'Food',
    icon: 'restaurant',
    color: '#FF5722',
    level: 1,
    isSystem: true,
    sortOrder: 1,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockTransactionRepo = _MockTransactionRepository();
    mockCategoryRepo = _MockCategoryRepository();
    mockDeviceIdentityRepo = _MockDeviceIdentityRepository();
    mockHashChainService = _MockHashChainService();
    mockCategoryService = _MockCategoryService();

    useCase = CreateTransactionUseCase(
      transactionRepository: mockTransactionRepo,
      categoryRepository: mockCategoryRepo,
      deviceIdentityRepository: mockDeviceIdentityRepo,
      hashChainService: mockHashChainService,
      categoryService: mockCategoryService,
    );

    when(
      () => mockDeviceIdentityRepo.getDeviceId(),
    ).thenAnswer((_) async => 'device_test_001');
    when(
      () => mockCategoryService.resolveLedgerType(any()),
    ).thenAnswer((_) async => LedgerType.daily);
    when(
      () => mockCategoryRepo.findById('cat_food'),
    ).thenAnswer((_) async => testCategory);
    when(
      () => mockTransactionRepo.getLatestHash(any()),
    ).thenAnswer((_) async => null);
    when(
      () => mockHashChainService.calculateTransactionHash(
        transactionId: any(named: 'transactionId'),
        amount: any(named: 'amount'),
        timestamp: any(named: 'timestamp'),
        previousHash: any(named: 'previousHash'),
      ),
    ).thenReturn('computed_hash');
    when(() => mockTransactionRepo.insert(any())).thenAnswer((_) async {});
  });

  group('SC-5 integration smoke: USD 50 @ 148.30 → amount=7415', () {
    test(
      'persists JPY amount=7415 with full foreign triple (ADR-020 .round(), D-09)',
      () async {
        // USD 50.00 = 5000 minor units (cents). 5000 / 100 × 148.30 = 7415 JPY.
        const expectedJpy = 7415;
        const originalMinorUnits = 5000;
        const rate = '148.30';

        final result = await useCase.execute(
          CreateTransactionParams(
            bookId: 'book_001',
            amount: expectedJpy,
            type: TransactionType.expense,
            categoryId: 'cat_food',
            entrySource: EntrySource.manual,
            originalCurrency: 'USD',
            originalAmount: originalMinorUnits,
            appliedRate: rate,
          ),
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        expect(result.data, isNotNull);
        // SC-5 locked figure: the canonical conversion point produces 7415.
        expect(result.data!.amount, expectedJpy);
        expect(result.data!.originalCurrency, 'USD');
        // ADR-021 Update 2026-06-12: originalAmount is INTEGER minor units.
        expect(result.data!.originalAmount, originalMinorUnits);
        expect(result.data!.appliedRate, rate);

        final captured =
            verify(() => mockTransactionRepo.insert(captureAny())).captured;
        expect(captured, hasLength(1));
        final persisted = captured.single as Transaction;
        expect(persisted.amount, expectedJpy);
        expect(persisted.originalCurrency, 'USD');
        expect(persisted.originalAmount, originalMinorUnits);
        expect(persisted.appliedRate, rate);
      },
    );

    test('partial triple (currency set, amount null) → Result.error', () async {
      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 7415,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          entrySource: EntrySource.manual,
          originalCurrency: 'USD',
          // originalAmount intentionally omitted → partial triple.
          appliedRate: '148.30',
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, contains('partial foreign-currency data'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';

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

    // Default ledger derivation stub: daily (D-14 single source of truth).
    when(
      () => mockCategoryService.resolveLedgerType(any()),
    ).thenAnswer((_) async => LedgerType.daily);
    when(
      () => mockTransactionRepo.getLatestHash(any()),
    ).thenAnswer((_) async => null);
  });

  group('CreateTransactionUseCase', () {
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

    test('successfully creates a transaction with hash chain', () async {
      when(
        () => mockCategoryRepo.findById('cat_food'),
      ).thenAnswer((_) async => testCategory);
      when(
        () => mockTransactionRepo.getLatestHash('book_001'),
      ).thenAnswer((_) async => 'prev_hash_abc');
      when(
        () => mockHashChainService.calculateTransactionHash(
          transactionId: any(named: 'transactionId'),
          amount: any(named: 'amount'),
          timestamp: any(named: 'timestamp'),
          previousHash: any(named: 'previousHash'),
        ),
      ).thenReturn('computed_hash_xyz');
      when(() => mockTransactionRepo.insert(any())).thenAnswer((_) async {});

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 1500,
          type: TransactionType.expense,
          categoryId: 'cat_food',

          entrySource: EntrySource.manual,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.amount, 1500);
      expect(result.data!.categoryId, 'cat_food');
      expect(result.data!.deviceId, 'device_test_001');
      expect(result.data!.currentHash, 'computed_hash_xyz');
      expect(result.data!.prevHash, 'prev_hash_abc');
      verify(() => mockTransactionRepo.insert(any())).called(1);
    });

    test('uses genesis hash when no previous transactions', () async {
      when(
        () => mockCategoryRepo.findById('cat_food'),
      ).thenAnswer((_) async => testCategory);
      when(
        () => mockTransactionRepo.getLatestHash('book_001'),
      ).thenAnswer((_) async => null);
      when(
        () => mockHashChainService.calculateTransactionHash(
          transactionId: any(named: 'transactionId'),
          amount: any(named: 'amount'),
          timestamp: any(named: 'timestamp'),
          previousHash: any(named: 'previousHash'),
        ),
      ).thenReturn('genesis_hash');
      when(() => mockTransactionRepo.insert(any())).thenAnswer((_) async {});

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 1000,
          type: TransactionType.income,
          categoryId: 'cat_food',

          entrySource: EntrySource.manual,
        ),
      );

      expect(result.isSuccess, isTrue);
      verify(
        () => mockHashChainService.calculateTransactionHash(
          transactionId: any(named: 'transactionId'),
          amount: any(named: 'amount'),
          timestamp: any(named: 'timestamp'),
          previousHash: '0' * 64,
        ),
      ).called(1);
    });

    test('returns error when amount is zero', () async {
      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 0,
          type: TransactionType.expense,
          categoryId: 'cat_food',

          entrySource: EntrySource.manual,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, contains('amount'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test('returns error when category does not exist', () async {
      when(
        () => mockCategoryRepo.findById('invalid_cat'),
      ).thenAnswer((_) async => null);

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'invalid_cat',

          entrySource: EntrySource.manual,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, contains('category'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test('returns error when deviceId is unavailable', () async {
      when(
        () => mockCategoryRepo.findById('cat_food'),
      ).thenAnswer((_) async => testCategory);
      when(
        () => mockDeviceIdentityRepo.getDeviceId(),
      ).thenAnswer((_) async => null);

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'cat_food',

          entrySource: EntrySource.manual,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, contains('deviceId'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test('returns error when bookId is empty', () async {
      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: '',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'cat_food',

          entrySource: EntrySource.manual,
        ),
      );

      expect(result.isError, isTrue);
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test(
      'uses CategoryService.resolveLedgerType to determine ledgerType (joy)',
      () async {
        when(
          () => mockCategoryService.resolveLedgerType('cat_entertainment'),
        ).thenAnswer((_) async => LedgerType.joy);
        when(() => mockCategoryRepo.findById('cat_entertainment')).thenAnswer(
          (_) async => Category(
            id: 'cat_entertainment',
            name: 'Entertainment',
            icon: 'movie',
            color: '#9C27B0',
            level: 1,
            isSystem: true,
            sortOrder: 4,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        when(
          () => mockTransactionRepo.getLatestHash('book_001'),
        ).thenAnswer((_) async => null);
        when(
          () => mockHashChainService.calculateTransactionHash(
            transactionId: any(named: 'transactionId'),
            amount: any(named: 'amount'),
            timestamp: any(named: 'timestamp'),
            previousHash: any(named: 'previousHash'),
          ),
        ).thenReturn('hash_joy');
        when(() => mockTransactionRepo.insert(any())).thenAnswer((_) async {});

        final result = await useCase.execute(
          CreateTransactionParams(
            bookId: 'book_001',
            amount: 2000,
            type: TransactionType.expense,
            categoryId: 'cat_entertainment',

            entrySource: EntrySource.manual,
          ),
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.ledgerType, LedgerType.joy);
        verify(
          () => mockCategoryService.resolveLedgerType('cat_entertainment'),
        ).called(1);
      },
    );

    test(
      'D-16: resolveLedgerType returns null → ledger falls back to daily',
      () async {
        // The category exists but has no ledger config — the conservative
        // fallback (D-16) MUST classify it as daily, never joy.
        when(
          () => mockCategoryService.resolveLedgerType('cat_food'),
        ).thenAnswer((_) async => null);
        when(
          () => mockCategoryRepo.findById('cat_food'),
        ).thenAnswer((_) async => testCategory);
        when(
          () => mockTransactionRepo.getLatestHash('book_001'),
        ).thenAnswer((_) async => null);
        when(
          () => mockHashChainService.calculateTransactionHash(
            transactionId: any(named: 'transactionId'),
            amount: any(named: 'amount'),
            timestamp: any(named: 'timestamp'),
            previousHash: any(named: 'previousHash'),
          ),
        ).thenReturn('hash_daily_fallback');
        when(() => mockTransactionRepo.insert(any())).thenAnswer((_) async {});

        final result = await useCase.execute(
          CreateTransactionParams(
            bookId: 'book_001',
            amount: 1200,
            type: TransactionType.expense,
            categoryId: 'cat_food',

            entrySource: EntrySource.manual,
          ),
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.ledgerType, LedgerType.daily);
      },
    );

    test('user-supplied ledgerType overrides CategoryService derivation', () async {
      // When params.ledgerType is non-null, the use case must NOT call
      // resolveLedgerType — the form/user override wins.
      when(
        () => mockCategoryRepo.findById('cat_food'),
      ).thenAnswer((_) async => testCategory);
      when(
        () => mockHashChainService.calculateTransactionHash(
          transactionId: any(named: 'transactionId'),
          amount: any(named: 'amount'),
          timestamp: any(named: 'timestamp'),
          previousHash: any(named: 'previousHash'),
        ),
      ).thenReturn('hash_override');
      when(() => mockTransactionRepo.insert(any())).thenAnswer((_) async {});

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 2000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.joy,
          entrySource: EntrySource.manual,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.ledgerType, LedgerType.joy);
      verifyNever(() => mockCategoryService.resolveLedgerType(any()));
    });

    test('uses default joy satisfaction 2 for joy transactions', () async {
      when(
        () => mockCategoryService.resolveLedgerType('cat_food'),
      ).thenAnswer((_) async => LedgerType.joy);
      when(
        () => mockCategoryRepo.findById('cat_food'),
      ).thenAnswer((_) async => testCategory);
      when(
        () => mockHashChainService.calculateTransactionHash(
          transactionId: any(named: 'transactionId'),
          amount: any(named: 'amount'),
          timestamp: any(named: 'timestamp'),
          previousHash: any(named: 'previousHash'),
        ),
      ).thenReturn('hash_joy_default');
      when(() => mockTransactionRepo.insert(any())).thenAnswer((_) async {});

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 2000,
          type: TransactionType.expense,
          categoryId: 'cat_food',

          entrySource: EntrySource.manual,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.joyFullness, 2);
    });

    test('derives ledger from the final category id (passes categoryId)', () async {
      when(
        () => mockCategoryRepo.findById('cat_food'),
      ).thenAnswer((_) async => testCategory);
      when(
        () => mockTransactionRepo.getLatestHash('book_001'),
      ).thenAnswer((_) async => null);
      when(
        () => mockHashChainService.calculateTransactionHash(
          transactionId: any(named: 'transactionId'),
          amount: any(named: 'amount'),
          timestamp: any(named: 'timestamp'),
          previousHash: any(named: 'previousHash'),
        ),
      ).thenReturn('hash_123');
      when(() => mockTransactionRepo.insert(any())).thenAnswer((_) async {});

      await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 500,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          merchant: 'Lawson',
          note: 'Quick lunch',

          entrySource: EntrySource.manual,
        ),
      );

      verify(
        () => mockCategoryService.resolveLedgerType('cat_food'),
      ).called(1);
    });
  });

  // Helper to build base params without currency fields
  CreateTransactionParams makeParams({
    String? originalCurrency,
    int? originalAmount,
    String? appliedRate,
  }) {
    return CreateTransactionParams(
      bookId: 'book_001',
      amount: 1000,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      entrySource: EntrySource.manual,
      originalCurrency: originalCurrency,
      originalAmount: originalAmount,
      appliedRate: appliedRate,
    );
  }

  group('partial-triple invariant', () {
    test('only originalCurrency set → Result.error', () async {
      final result = await useCase.execute(
        makeParams(originalCurrency: 'USD'),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('partial foreign-currency data'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test('only originalAmount set → Result.error', () async {
      final result = await useCase.execute(
        makeParams(originalAmount: 5000),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('partial foreign-currency data'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test('only appliedRate set → Result.error', () async {
      final result = await useCase.execute(
        makeParams(appliedRate: '149.30'),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('partial foreign-currency data'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test('originalCurrency + originalAmount set, appliedRate null → Result.error',
        () async {
      final result = await useCase.execute(
        makeParams(originalCurrency: 'USD', originalAmount: 5000),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('partial foreign-currency data'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test('originalCurrency + appliedRate set, originalAmount null → Result.error',
        () async {
      final result = await useCase.execute(
        makeParams(originalCurrency: 'USD', appliedRate: '149.30'),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('partial foreign-currency data'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test('all three null → no error from partial-triple check (JPY-native)',
        () async {
      // No error from partial-triple; proceed to category lookup
      when(() => mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => null); // category not found — expected
      final result = await useCase.execute(makeParams());
      // Should reach category check (error is 'category not found', not partial-triple)
      expect(result.isError, isTrue);
      expect(result.error, contains('category'));
    });

    test(
        'all three non-null with valid appliedRate → no error from partial-triple or appliedRate check',
        () async {
      // No error from partial-triple or appliedRate; proceed to category lookup
      when(() => mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => null); // category not found — expected
      final result = await useCase.execute(
        // WR-04: amount (1000) must equal convertToJpy of the triple —
        // 5000 cents / 100 × 20.00 = 1000 JPY.
        makeParams(
          originalCurrency: 'USD',
          originalAmount: 5000,
          appliedRate: '20.00',
        ),
      );
      // Should reach category check (error is 'category not found', not validation)
      expect(result.isError, isTrue);
      expect(result.error, contains('category'));
    });
  });

  group('appliedRate validity (D-05)', () {
    test("all three non-null, appliedRate='NaN' → Result.error (isNaN path)",
        () async {
      // 'NaN' is not a plain decimal literal — rejected by the D-05 shape
      // check in validateAppliedRate (currency_conversion.dart).
      final result = await useCase.execute(
        makeParams(
          originalCurrency: 'USD',
          originalAmount: 5000,
          appliedRate: 'NaN',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('positive number'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test("all three non-null, appliedRate='-1.5' → Result.error (rate <= 0)",
        () async {
      final result = await useCase.execute(
        makeParams(
          originalCurrency: 'USD',
          originalAmount: 5000,
          appliedRate: '-1.5',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('positive number'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test("all three non-null, appliedRate='0' → Result.error (rate <= 0)",
        () async {
      final result = await useCase.execute(
        makeParams(
          originalCurrency: 'USD',
          originalAmount: 5000,
          appliedRate: '0',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('positive number'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test(
        "appliedRate='1.493e2' (scientific notation) → Result.error (D-05 shape check)",
        () async {
      final result = await useCase.execute(
        makeParams(
          originalCurrency: 'USD',
          originalAmount: 5000,
          appliedRate: '1.493e2',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('plain decimal'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test(
        "appliedRate=' 149.30 ' (untrimmed) → Result.error (D-05 trim requirement)",
        () async {
      final result = await useCase.execute(
        makeParams(
          originalCurrency: 'USD',
          originalAmount: 5000,
          appliedRate: ' 149.30 ',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('plain decimal'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test("appliedRate='abc' → Result.error (non-numeric)", () async {
      final result = await useCase.execute(
        makeParams(
          originalCurrency: 'USD',
          originalAmount: 5000,
          appliedRate: 'abc',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('plain decimal'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test("appliedRate='' → Result.error (empty string)", () async {
      final result = await useCase.execute(
        makeParams(
          originalCurrency: 'USD',
          originalAmount: 5000,
          appliedRate: '',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('plain decimal'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test(
        "all three non-null, appliedRate='0.001' → passes validity check (small positive rate)",
        () async {
      // Passes validation; proceeds to category lookup
      when(() => mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => null); // category not found — expected
      final result = await useCase.execute(
        // WR-04: amount (1000) must equal convertToJpy of the triple —
        // 1000000 × 0.001 = 1000 JPY (JPY subunitToUnit = 1).
        makeParams(
          originalCurrency: 'JPY',
          originalAmount: 1000000,
          appliedRate: '0.001',
        ),
      );
      // Should reach category check (not a validation error)
      expect(result.isError, isTrue);
      expect(result.error, contains('category'));
    });

    test(
        'amount inconsistent with foreign-currency triple → Result.error (WR-04)',
        () async {
      final result = await useCase.execute(
        // makeParams amount is 1000, but USD 5000 cents at 149.30 = 7465 JPY.
        makeParams(
          originalCurrency: 'USD',
          originalAmount: 5000,
          appliedRate: '149.30',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('does not match convertToJpy'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });
  });

  group('originalAmount / originalCurrency validity (WR-03)', () {
    test('originalAmount=0 → Result.error', () async {
      final result = await useCase.execute(
        makeParams(
          originalCurrency: 'USD',
          originalAmount: 0,
          appliedRate: '149.30',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('originalAmount'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test('originalAmount=-5000 → Result.error', () async {
      final result = await useCase.execute(
        makeParams(
          originalCurrency: 'USD',
          originalAmount: -5000,
          appliedRate: '149.30',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('originalAmount'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test("originalCurrency='' → Result.error", () async {
      final result = await useCase.execute(
        makeParams(
          originalCurrency: '',
          originalAmount: 5000,
          appliedRate: '149.30',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('ISO 4217'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });

    test("originalCurrency='usd' (lowercase) → Result.error", () async {
      final result = await useCase.execute(
        makeParams(
          originalCurrency: 'usd',
          originalAmount: 5000,
          appliedRate: '149.30',
        ),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('ISO 4217'));
      verifyNever(() => mockTransactionRepo.insert(any()));
    });
  });
}

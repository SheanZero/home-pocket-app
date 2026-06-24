import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/voice/domain/models/merchant_candidate.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mocktail/mocktail.dart';

/// Phase 51 D-21 (LEDGER-02) — merchant `ledgerHint` is NEVER read for the
/// transaction ledger.
///
/// The merchant `ledger_hint` column is KEPT (no schema change this phase), but
/// it is NON-authoritative (Phase 49 D-09): the transaction ledger is a pure
/// function of the FINAL reconciled category via `CategoryService.resolveLedgerType`.
///
/// This test constructs a [MerchantCandidate] whose `ledgerHint` CONTRADICTS the
/// ledger that the candidate's category resolves to, then drives a create via
/// the use case using ONLY the candidate's `categoryId` (the post-reconciliation
/// selected category). It asserts the persisted ledger follows the category, NOT
/// the contradictory hint — proving the derivation never reads `ledgerHint`.

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockCategoryLedgerConfigRepository extends Mock
    implements CategoryLedgerConfigRepository {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

class _FakeTransaction extends Fake implements Transaction {}

const _dailyCatId = 'cat_food';

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTransaction());
  });

  late CreateTransactionUseCase useCase;
  late CategoryService categoryService;
  late _MockTransactionRepository transactionRepository;
  late _MockCategoryRepository categoryRepository;
  late _MockCategoryLedgerConfigRepository ledgerConfigRepository;
  late _MockDeviceIdentityRepository deviceIdentityRepository;

  setUp(() {
    transactionRepository = _MockTransactionRepository();
    categoryRepository = _MockCategoryRepository();
    ledgerConfigRepository = _MockCategoryLedgerConfigRepository();
    deviceIdentityRepository = _MockDeviceIdentityRepository();

    when(() => categoryRepository.findById(_dailyCatId)).thenAnswer(
      (_) async => Category(
        id: _dailyCatId,
        name: 'Food',
        icon: 'restaurant',
        color: '#47B88A',
        level: 1,
        createdAt: DateTime.utc(2026, 1),
      ),
    );
    // cat_food resolves to DAILY — deliberately the OPPOSITE of the merchant
    // candidate's joy hint constructed below.
    when(() => ledgerConfigRepository.findById(_dailyCatId)).thenAnswer(
      (_) async => CategoryLedgerConfig(
        categoryId: _dailyCatId,
        ledgerType: LedgerType.daily,
        updatedAt: DateTime.utc(2026, 1),
      ),
    );
    when(
      () => deviceIdentityRepository.getDeviceId(),
    ).thenAnswer((_) async => 'device-local');
    when(
      () => transactionRepository.getLatestHash(any()),
    ).thenAnswer((_) async => null);
    when(
      () => transactionRepository.insert(any()),
    ).thenAnswer((_) async {});

    categoryService = CategoryService(
      categoryRepository: categoryRepository,
      ledgerConfigRepository: ledgerConfigRepository,
    );
    useCase = CreateTransactionUseCase(
      transactionRepository: transactionRepository,
      categoryRepository: categoryRepository,
      deviceIdentityRepository: deviceIdentityRepository,
      hashChainService: HashChainService(),
      categoryService: categoryService,
    );
  });

  test(
    'merchant ledgerHint contradicting the category is ignored — ledger '
    'follows the category, never the hint (D-21)',
    () async {
      // A merchant candidate whose stored ledgerHint says JOY, while its
      // category (cat_food) authoritatively resolves to DAILY.
      const candidate = MerchantCandidate(
        merchantId: 'm-izakaya',
        displayName: 'Izakaya',
        score: 0.9,
        categoryId: _dailyCatId,
        ledgerHint: 'joy', // contradicts the category-derived daily ledger
      );

      // Sanity: the category genuinely resolves to daily, opposite the hint.
      final resolved = await categoryService.resolveLedgerType(
        candidate.categoryId,
      );
      expect(resolved, LedgerType.daily);
      expect(candidate.ledgerHint, 'joy');

      // Drive a create using ONLY the candidate's categoryId (the
      // post-reconciliation selected category). ledgerType is null so the use
      // case derives it — and it must derive solely from the category.
      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book-main',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: candidate.categoryId,
          entrySource: EntrySource.voice,
        ),
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final tx = result.data!;
      // The persisted ledger follows the category (daily), NOT the joy hint.
      expect(
        tx.ledgerType,
        LedgerType.daily,
        reason:
            'transaction ledger must derive from resolveLedgerType(categoryId) '
            '(daily), never from merchant.ledgerHint (joy) — D-21',
      );
      expect(tx.ledgerType, resolved);
    },
  );
}

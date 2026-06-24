import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mocktail/mocktail.dart';

/// Phase 51 D-20 ledger invariant (LEDGER-02).
///
/// Asserts the SINGLE ledger source of truth: for every CREATE path (voice +
/// manual) and for a category CHANGE, the persisted
/// `transaction.ledgerType == resolveLedgerType(transaction.categoryId)`.
///
/// The create path is exercised with `ledgerType: null` so the use case
/// derives the ledger itself (the production derivation, post-51-04:
/// `CategoryService.resolveLedgerType(categoryId) ?? LedgerType.daily`).
///
/// Coverage:
///   - daily category  → ledger == daily   (direct config)
///   - joy category    → ledger == joy     (direct config)
///   - unknown-config  → ledger == daily   (D-16 conservative fallback;
///                       resolveLedgerType returns null → daily)
///   - change-category → re-resolving on the NEW categoryId yields the NEW
///                       category's ledger (the form's re-derive contract)
///
/// NEGATIVE SCOPE (W3 / D-23): edit-LOAD that preserves the STORED ledger
/// WITHOUT a category change is intentionally NOT asserted here — a historical
/// transaction may carry a ledger that diverges from its category's CURRENT
/// config (e.g. a past override), and W3 deliberately keeps that stored value.
/// The invariant only governs create + change-category, never edit-load.

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockCategoryLedgerConfigRepository extends Mock
    implements CategoryLedgerConfigRepository {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

// Seed: three L1 categories spanning the three resolution outcomes.
const _dailyCatId = 'cat_food'; // daily config
const _joyCatId = 'cat_hobbies'; // joy config
const _noConfigCatId = 'cat_unconfigured'; // exists, but no ledger config

final _categoriesById = <String, Category>{
  _dailyCatId: Category(
    id: _dailyCatId,
    name: 'Food',
    icon: 'restaurant',
    color: '#47B88A',
    level: 1,
    createdAt: DateTime.utc(2026, 1),
  ),
  _joyCatId: Category(
    id: _joyCatId,
    name: 'Hobbies',
    icon: 'palette',
    color: '#7CB342',
    level: 1,
    createdAt: DateTime.utc(2026, 1),
  ),
  _noConfigCatId: Category(
    id: _noConfigCatId,
    name: 'Unconfigured',
    icon: 'help',
    color: '#607D8B',
    level: 1,
    createdAt: DateTime.utc(2026, 1),
  ),
};

final _configsById = <String, CategoryLedgerConfig>{
  _dailyCatId: CategoryLedgerConfig(
    categoryId: _dailyCatId,
    ledgerType: LedgerType.daily,
    updatedAt: DateTime.utc(2026, 1),
  ),
  _joyCatId: CategoryLedgerConfig(
    categoryId: _joyCatId,
    ledgerType: LedgerType.joy,
    updatedAt: DateTime.utc(2026, 1),
  ),
  // _noConfigCatId intentionally absent → resolveLedgerType returns null.
};

void main() {
  late AppDatabase db;
  late TransactionDao transactionDao;
  late CreateTransactionUseCase useCase;
  late CategoryService categoryService;
  late _MockCategoryRepository categoryRepository;
  late _MockCategoryLedgerConfigRepository ledgerConfigRepository;
  late _MockDeviceIdentityRepository deviceIdentityRepository;
  late _MockFieldEncryptionService encryptionService;

  setUp(() {
    db = AppDatabase.forTesting();
    transactionDao = TransactionDao(db);
    categoryRepository = _MockCategoryRepository();
    ledgerConfigRepository = _MockCategoryLedgerConfigRepository();
    deviceIdentityRepository = _MockDeviceIdentityRepository();
    encryptionService = _MockFieldEncryptionService();

    when(
      () => categoryRepository.findById(any()),
    ).thenAnswer((inv) async => _categoriesById[inv.positionalArguments.first]);
    when(
      () => ledgerConfigRepository.findById(any()),
    ).thenAnswer((inv) async => _configsById[inv.positionalArguments.first]);
    when(
      () => deviceIdentityRepository.getDeviceId(),
    ).thenAnswer((_) async => 'device-local');
    when(() => encryptionService.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => encryptionService.decryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );

    categoryService = CategoryService(
      categoryRepository: categoryRepository,
      ledgerConfigRepository: ledgerConfigRepository,
    );
    final transactionRepository = TransactionRepositoryImpl(
      dao: transactionDao,
      encryptionService: encryptionService,
    );
    useCase = CreateTransactionUseCase(
      transactionRepository: transactionRepository,
      categoryRepository: categoryRepository,
      deviceIdentityRepository: deviceIdentityRepository,
      hashChainService: HashChainService(),
      categoryService: categoryService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<Transaction> createDerived({
    required String categoryId,
    required EntrySource entrySource,
  }) async {
    final result = await useCase.execute(
      CreateTransactionParams(
        bookId: 'book-main',
        amount: 1000,
        type: TransactionType.expense,
        categoryId: categoryId,
        // ledgerType omitted (null) → use case DERIVES it (production path).
        timestamp: DateTime.utc(2026, 5, 21, 12),
        entrySource: entrySource,
      ),
    );
    expect(result.isSuccess, isTrue, reason: result.error);
    return result.data!;
  }

  group('D-20 ledger invariant: ledgerType == resolveLedgerType(categoryId)', () {
    test('create (manual) on a daily category → ledger derives to daily', () async {
      final tx = await createDerived(
        categoryId: _dailyCatId,
        entrySource: EntrySource.manual,
      );
      final resolved = await categoryService.resolveLedgerType(tx.categoryId);
      expect(tx.ledgerType, LedgerType.daily);
      expect(tx.ledgerType, resolved);
    });

    test('create (voice) on a joy category → ledger derives to joy', () async {
      final tx = await createDerived(
        categoryId: _joyCatId,
        entrySource: EntrySource.voice,
      );
      final resolved = await categoryService.resolveLedgerType(tx.categoryId);
      expect(tx.ledgerType, LedgerType.joy);
      expect(tx.ledgerType, resolved);
    });

    test(
      'create on an unknown-config category → null resolve → daily fallback (D-16)',
      () async {
        final tx = await createDerived(
          categoryId: _noConfigCatId,
          entrySource: EntrySource.manual,
        );
        // resolveLedgerType returns null here; the use case applies the D-16
        // conservative fallback to daily. The invariant is therefore stated as
        // "ledger == resolveLedgerType ?? daily" for the null-config edge.
        final resolved = await categoryService.resolveLedgerType(tx.categoryId);
        expect(resolved, isNull);
        expect(tx.ledgerType, LedgerType.daily);
        expect(tx.ledgerType, resolved ?? LedgerType.daily);
      },
    );

    test(
      'change-category re-derives the ledger from the NEW category '
      '(daily → joy)',
      () async {
        // Simulate the form's change-category re-derive: the entry started on a
        // daily category, then the user switches to a joy category. The ledger
        // contract is that the NEW category governs — re-resolving on the new id
        // yields the new ledger, matching what a re-created transaction stamps.
        final beforeChange = await categoryService.resolveLedgerType(
          _dailyCatId,
        );
        expect(beforeChange, LedgerType.daily);

        final afterChange = await categoryService.resolveLedgerType(_joyCatId);
        expect(afterChange, LedgerType.joy);

        // A transaction persisted under the NEW category must carry the NEW
        // category's resolved ledger (the change-category invariant).
        final tx = await createDerived(
          categoryId: _joyCatId,
          entrySource: EntrySource.manual,
        );
        expect(tx.ledgerType, afterChange);
      },
    );

    // NEGATIVE SCOPE (W3 / D-23): edit-LOAD WITHOUT a category change preserves
    // the STORED ledger even if it diverges from the category's current config.
    // That path is intentionally NOT asserted by this invariant — a historical
    // override must survive a no-op edit. See the file-level doc comment.
  });
}

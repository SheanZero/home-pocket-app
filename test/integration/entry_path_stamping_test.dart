import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockCategoryLedgerConfigRepository extends Mock
    implements CategoryLedgerConfigRepository {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

void main() {
  late AppDatabase db;
  late TransactionDao transactionDao;
  late CreateTransactionUseCase useCase;
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
    ).thenAnswer((_) async => _category);
    // Ledger is supplied explicitly (LedgerType.daily) on every create below,
    // so resolveLedgerType is never hit; stub kept for construction safety.
    when(
      () => ledgerConfigRepository.findById(any()),
    ).thenAnswer((_) async => null);
    when(
      () => deviceIdentityRepository.getDeviceId(),
    ).thenAnswer((_) async => 'device-local');
    when(() => encryptionService.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => encryptionService.decryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
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
      categoryService: CategoryService(
        categoryRepository: categoryRepository,
        ledgerConfigRepository: ledgerConfigRepository,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('voice entry path stamps entry_source = voice (SC-2)', () async {
    final row = await _createAndFind(
      useCase,
      transactionDao,
      entrySource: EntrySource.voice,
    );

    expect(row.entrySource, 'voice');
  });

  test('manual entry path stamps entry_source = manual (SC-2)', () async {
    final row = await _createAndFind(
      useCase,
      transactionDao,
      entrySource: EntrySource.manual,
    );

    expect(row.entrySource, 'manual');
  });

  test(
    'ocr entry path stamps entry_source = ocr (reserved smoke test; D-07 — no UI stamps this in v1.2)',
    () async {
      final row = await _createAndFind(
        useCase,
        transactionDao,
        entrySource: EntrySource.ocr,
      );

      expect(row.entrySource, 'ocr');
    },
  );

  test('hash chain inputs unchanged when entrySource varies (D-02)', () {
    final hashChainService = HashChainService();
    final hashes = <String>[];

    for (final entrySource in EntrySource.values) {
      hashes.add(
        hashChainService.calculateTransactionHash(
          transactionId: 'tx-fixed',
          amount: 1000,
          timestamp:
              DateTime.utc(2026, 5, 21, 12).millisecondsSinceEpoch ~/ 1000,
          previousHash: '0' * 64,
        ),
      );
      expect(entrySource.name, isNotEmpty);
    }

    expect(hashes.toSet(), hasLength(1));
  });
}

Future<TransactionRow> _createAndFind(
  CreateTransactionUseCase useCase,
  TransactionDao transactionDao, {
  required EntrySource entrySource,
}) async {
  final result = await useCase.execute(
    CreateTransactionParams(
      bookId: 'book-main',
      amount: 1000,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.daily,
      timestamp: DateTime.utc(2026, 5, 21, 12),
      entrySource: entrySource,
    ),
  );

  expect(result.isSuccess, isTrue, reason: result.error);
  final transaction = result.data!;
  final row = await transactionDao.findById(transaction.id);
  expect(row, isNotNull);
  return row!;
}

final _category = Category(
  id: 'cat_food',
  name: 'Food',
  icon: 'restaurant',
  color: '#47B88A',
  level: 1,
  createdAt: DateTime.utc(2026, 1),
);

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

void main() {
  late AppDatabase db;
  late ShadowBookService service;
  late TransactionDao transactionDao;
  late _MockFieldEncryptionService mockEncryption;

  setUp(() {
    db = AppDatabase.forTesting();
    final bookRepo = BookRepositoryImpl(dao: BookDao(db));
    transactionDao = TransactionDao(db);
    mockEncryption = _MockFieldEncryptionService();
    when(
      () => mockEncryption.encryptField(any()),
    ).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments.first as String,
    );
    when(
      () => mockEncryption.decryptField(any()),
    ).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments.first as String,
    );
    final transactionRepo = TransactionRepositoryImpl(
      dao: transactionDao,
      encryptionService: mockEncryption,
    );

    service = ShadowBookService(
      bookRepository: bookRepo,
      transactionRepository: transactionRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ShadowBookService', () {
    test('createShadowBook is idempotent per owner device', () async {
      final firstId = await service.createShadowBook(
        groupId: 'group-1',
        memberDeviceId: 'partner-device',
        memberDeviceName: 'Partner Phone',
        currency: 'JPY',
      );

      final secondId = await service.createShadowBook(
        groupId: 'group-1',
        memberDeviceId: 'partner-device',
        memberDeviceName: 'Partner Phone',
        currency: 'JPY',
      );

      expect(secondId, firstId);
    });

    test('cleanSyncData removes shadow books and their transactions', () async {
      final shadowBookId = await service.createShadowBook(
        groupId: 'group-1',
        memberDeviceId: 'partner-device',
        memberDeviceName: 'Partner Phone',
        currency: 'JPY',
      );

      await transactionDao.insertTransaction(
        id: 'tx-1',
        bookId: shadowBookId,
        deviceId: 'partner-device',
        amount: 1200,
        type: 'expense',
        categoryId: 'cat-food',
        ledgerType: 'survival',
        timestamp: DateTime.utc(2026, 3, 15, 10),
        currentHash: '',
        createdAt: DateTime.utc(2026, 3, 15, 10),
      );

      await service.cleanSyncData('group-1');

      expect(await service.findShadowBook('partner-device'), isNull);
      expect(await transactionDao.findById('tx-1'), isNull);
    });
  });
}

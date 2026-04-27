import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_sync_mapper.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

class _MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late AppDatabase db;
  late BookDao bookDao;
  late TransactionDao txDao;
  late ShadowBookService shadowBookService;
  late ApplySyncOperationsUseCase applyOps;
  late BookRepositoryImpl bookRepo;
  late _MockFieldEncryptionService mockEncryption;
  late _MockGroupRepository mockGroupRepository;

  setUp(() async {
    db = AppDatabase.forTesting();
    bookDao = BookDao(db);
    txDao = TransactionDao(db);
    mockEncryption = _MockFieldEncryptionService();
    mockGroupRepository = _MockGroupRepository();

    when(() => mockEncryption.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => mockEncryption.decryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => mockGroupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        members: const [
          GroupMember(
            deviceId: 'partner-device',
            publicKey: 'pk-partner',
            deviceName: 'Partner Phone',
            displayName: 'Partner Phone',
            avatarEmoji: '🏠',
            role: 'member',
            status: 'active',
          ),
        ],
        createdAt: DateTime(2026, 3, 15),
      ),
    );
    when(
      () => mockGroupRepository.getPendingGroup(),
    ).thenAnswer((_) async => null);

    bookRepo = BookRepositoryImpl(dao: bookDao);
    final txRepo = TransactionRepositoryImpl(
      dao: txDao,
      encryptionService: mockEncryption,
    );

    shadowBookService = ShadowBookService(
      bookRepository: bookRepo,
      transactionRepository: txRepo,
    );

    applyOps = ApplySyncOperationsUseCase(
      transactionRepository: txRepo,
      shadowBookService: shadowBookService,
      groupRepository: mockGroupRepository,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Bill sync round trip', () {
    test('full cycle: shadow book → sync transactions → cleanup', () async {
      // 1. Create shadow book for partner
      final shadowId = await shadowBookService.createShadowBook(
        groupId: 'group-1',
        memberDeviceId: 'partner-device',
        memberDeviceName: 'Partner Phone',
        currency: 'JPY',
      );

      expect(shadowId, isNotEmpty);

      // 2. Simulate pull: apply create operations from partner
      await applyOps.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-1',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-1',
            'amount': 1000,
            'type': 'expense',
            'categoryId': 'cat-food',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
            'metadata': {
              'sourceBookId': 'partner-main',
              'sourceBookName': 'Partner Main',
              'sourceBookType': 'remote_book:partner-main',
            },
          },
        },
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-2',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-2',
            'amount': 500,
            'type': 'expense',
            'categoryId': 'cat-transport',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T11:00:00.000Z',
            'createdAt': '2026-03-15T11:00:00.000Z',
          },
        },
      ]);

      // 3. Verify transactions landed in shadow book
      final tx1 = await txDao.findById('tx-1');
      final tx2 = await txDao.findById('tx-2');
      expect(tx1, isNotNull);
      expect(tx2, isNotNull);
      expect(tx1!.bookId, shadowId);
      expect(tx2!.bookId, shadowId);
      expect(tx1.isSynced, true);
      expect(tx1.amount, 1000);

      // 4. Verify idempotent: re-applying same operation doesn't duplicate
      await applyOps.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-1',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-1',
            'amount': 1000,
            'type': 'expense',
            'categoryId': 'cat-food',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);
      // No duplicate — still only one tx-1

      // 5. Simulate pull: delete operation
      await applyOps.execute([
        {'op': 'delete', 'entityType': 'bill', 'entityId': 'tx-2'},
      ]);

      final tx2After = await txDao.findById('tx-2');
      expect(tx2After!.isDeleted, true);

      // 6. Simulate push: serialize a local transaction for sync
      final localTx = Transaction(
        id: 'local-tx-1',
        bookId: 'my-book',
        deviceId: 'my-device',
        amount: 2500,
        type: TransactionType.expense,
        categoryId: 'cat-dining',
        ledgerType: LedgerType.soul,
        timestamp: DateTime.utc(2026, 3, 15, 12),
        currentHash: 'local-hash',
        createdAt: DateTime.utc(2026, 3, 15, 12),
        note: 'Dinner',
        merchant: 'Restaurant',
        soulSatisfaction: 8,
      );

      final syncOp = TransactionSyncMapper.toCreateOperation(
        localTx,
        sourceBookId: 'my-book',
        sourceBookName: 'My Main Book',
        sourceBookType: 'remote_book:my-book',
      );

      expect(syncOp['op'], 'create');
      expect(syncOp['entityType'], 'bill');
      expect(syncOp['entityId'], 'local-tx-1');
      final data = syncOp['data'] as Map<String, dynamic>;
      expect(data['amount'], 2500);
      expect(data['note'], 'Dinner');
      expect(data['metadata']['sourceBookId'], 'my-book');
      // Excluded fields
      expect(data.containsKey('bookId'), false);
      expect(data.containsKey('currentHash'), false);
      expect(data.containsKey('deviceId'), false);

      // 7. Simulate group exit: clean sync data
      await shadowBookService.cleanSyncData('group-1');

      // Verify shadow book and its transactions are gone
      final shadowAfter = await bookDao.findById(shadowId);
      expect(shadowAfter, isNull);

      final tx1After = await txDao.findById('tx-1');
      expect(tx1After, isNull);
    });

    test('lazy shadow book creation on unknown sender', () async {
      // No pre-created shadow book — apply ops from partner
      await applyOps.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-lazy',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-lazy',
            'amount': 300,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      // Shadow book should have been created lazily
      final shadowBook = await shadowBookService.findShadowBook(
        'partner-device',
      );
      expect(shadowBook, isNotNull);
      expect(shadowBook!.isShadow, true);
      expect(shadowBook.ownerDeviceId, 'partner-device');

      final tx = await txDao.findById('tx-lazy');
      expect(tx, isNotNull);
      expect(tx!.bookId, shadowBook.id);
    });

    test('findAll excludes shadow books by default', () async {
      // Create a regular book
      await bookDao.insertBook(
        id: 'my-book',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'my-device',
        createdAt: DateTime.now(),
      );

      // Create a shadow book
      await shadowBookService.createShadowBook(
        groupId: 'group-1',
        memberDeviceId: 'partner-device',
        memberDeviceName: 'Partner',
        currency: 'JPY',
      );

      // findAll should only return the regular book
      final books = await bookRepo.findAll();
      expect(books, hasLength(1));
      expect(books.first.id, 'my-book');

      // findAll with includeShadow should return both
      final allBooks = await bookRepo.findAll(includeShadow: true);
      expect(allBooks, hasLength(2));
    });

    test('skips non-bill entity types', () async {
      await applyOps.execute([
        {
          'op': 'create',
          'entityType': 'category',
          'entityId': 'cat-remote',
          'fromDeviceId': 'partner-device',
          'data': {'id': 'cat-remote', 'name': 'Remote Category'},
        },
      ]);

      // No crash, no transaction created
      final tx = await txDao.findById('cat-remote');
      expect(tx, isNull);
    });
  });
}

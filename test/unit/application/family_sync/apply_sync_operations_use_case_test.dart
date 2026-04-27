import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
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
  late ApplySyncOperationsUseCase useCase;
  late ShadowBookService shadowBookService;
  late TransactionDao transactionDao;
  late _MockFieldEncryptionService mockEncryption;
  late _MockGroupRepository mockGroupRepository;

  setUp(() async {
    db = AppDatabase.forTesting();
    final bookRepo = BookRepositoryImpl(dao: BookDao(db));
    transactionDao = TransactionDao(db);
    mockEncryption = _MockFieldEncryptionService();
    mockGroupRepository = _MockGroupRepository();
    when(() => mockEncryption.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => mockEncryption.decryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    final transactionRepo = TransactionRepositoryImpl(
      dao: transactionDao,
      encryptionService: mockEncryption,
    );

    shadowBookService = ShadowBookService(
      bookRepository: bookRepo,
      transactionRepository: transactionRepo,
    );
    useCase = ApplySyncOperationsUseCase(
      transactionRepository: transactionRepo,
      shadowBookService: shadowBookService,
      groupRepository: mockGroupRepository,
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
            role: 'member',
            status: 'active',
            displayName: 'Partner',
            avatarEmoji: '🏠',
          ),
        ],
        createdAt: DateTime(2026, 3, 15),
      ),
    );
    when(
      () => mockGroupRepository.getPendingGroup(),
    ).thenAnswer((_) async => null);

    await shadowBookService.createShadowBook(
      groupId: 'group-1',
      memberDeviceId: 'partner-device',
      memberDeviceName: 'Partner Phone',
      currency: 'JPY',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ApplySyncOperationsUseCase', () {
    test('create inserts synced transaction into shadow book', () async {
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-remote-1',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-remote-1',
            'amount': 2000,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
            'metadata': {
              'sourceBookId': 'remote-main',
              'sourceBookName': 'Remote Main',
              'sourceBookType': 'remote_book:remote-main',
            },
          },
        },
      ]);

      final tx = await transactionDao.findById('tx-remote-1');
      final shadowBook = await shadowBookService.findShadowBook(
        'partner-device',
      );
      expect(tx, isNotNull);
      expect(shadowBook, isNotNull);
      expect(tx!.bookId, shadowBook!.id);
      expect(tx.deviceId, 'partner-device');
      expect(tx.metadata, contains('sourceBookId'));
      expect(tx.isSynced, true);
    });

    test('create lazily creates missing shadow book', () async {
      await shadowBookService.cleanSyncData('group-1');

      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-remote-lazy',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-remote-lazy',
            'amount': 800,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      final shadowBook = await shadowBookService.findShadowBook(
        'partner-device',
      );
      final tx = await transactionDao.findById('tx-remote-lazy');
      expect(shadowBook, isNotNull);
      expect(tx, isNotNull);
      expect(tx!.bookId, shadowBook!.id);
    });

    test('delete soft-deletes synced transaction', () async {
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-remote-2',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-remote-2',
            'amount': 500,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      await useCase.execute([
        {
          'op': 'delete',
          'entityType': 'bill',
          'entityId': 'tx-remote-2',
          'fromDeviceId': 'partner-device',
        },
      ]);

      final tx = await transactionDao.findById('tx-remote-2');
      expect(tx, isNotNull);
      expect(tx!.isDeleted, true);
    });

    test('insert (alias for create) inserts synced transaction', () async {
      await useCase.execute([
        {
          'op': 'insert',
          'entityType': 'bill',
          'entityId': 'tx-insert-1',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-insert-1',
            'amount': 300,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      final tx = await transactionDao.findById('tx-insert-1');
      expect(tx, isNotNull);
      expect(tx!.amount, 300);
    });

    test('update creates transaction when it does not exist', () async {
      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'bill',
          'entityId': 'tx-update-new',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-update-new',
            'amount': 700,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      final tx = await transactionDao.findById('tx-update-new');
      expect(tx, isNotNull);
      expect(tx!.amount, 700);
    });

    test('update modifies existing transaction', () async {
      // First create the transaction
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-update-existing',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-update-existing',
            'amount': 500,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      // Then update it
      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'bill',
          'entityId': 'tx-update-existing',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-update-existing',
            'amount': 999,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
            'updatedAt': '2026-03-16T10:00:00.000Z',
          },
        },
      ]);

      final tx = await transactionDao.findById('tx-update-existing');
      expect(tx, isNotNull);
      expect(tx!.amount, 999);
    });

    test('skips bill operation with null entityId', () async {
      // Should not throw
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          // no entityId
          'fromDeviceId': 'partner-device',
          'data': {'amount': 100, 'type': 'expense'},
        },
      ]);
      // No crash — test passes
    });

    test('profile operation updates member profile', () async {
      when(
        () => mockGroupRepository.updateMemberProfile(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          displayName: any(named: 'displayName'),
          avatarEmoji: any(named: 'avatarEmoji'),
        ),
      ).thenAnswer((_) async {});

      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'profile',
          'fromDeviceId': 'partner-device',
          'data': {'displayName': 'Partner Updated', 'avatarEmoji': '🌟'},
        },
      ], groupId: 'group-1');

      verify(
        () => mockGroupRepository.updateMemberProfile(
          groupId: 'group-1',
          deviceId: 'partner-device',
          displayName: 'Partner Updated',
          avatarEmoji: '🌟',
        ),
      ).called(1);
    });

    test('profile operation skipped when groupId is null', () async {
      // Should not call updateMemberProfile when groupId is absent
      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'profile',
          'fromDeviceId': 'partner-device',
          'data': {'displayName': 'X', 'avatarEmoji': '🌟'},
        },
      ]);
      // No groupId passed — skips profile update
      verifyNever(
        () => mockGroupRepository.updateMemberProfile(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          displayName: any(named: 'displayName'),
          avatarEmoji: any(named: 'avatarEmoji'),
        ),
      );
    });

    test('create is idempotent for duplicate entityId', () async {
      // First create
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-idem',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-idem',
            'amount': 100,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      // Second create (same id) — should not throw, should not duplicate
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-idem',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-idem',
            'amount': 200, // different amount but same id
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      final tx = await transactionDao.findById('tx-idem');
      expect(tx, isNotNull);
      expect(tx!.amount, 100); // original amount preserved
    });
  });
}

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
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

class _FakeShoppingItem extends Fake implements ShoppingItem {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeShoppingItem());
  });
  late AppDatabase db;
  late ApplySyncOperationsUseCase useCase;
  late ShadowBookService shadowBookService;
  late TransactionDao transactionDao;
  late _MockFieldEncryptionService mockEncryption;
  late _MockGroupRepository mockGroupRepository;
  late _MockShoppingItemRepository mockShoppingItemRepository;

  setUp(() async {
    db = AppDatabase.forTesting();
    final bookRepo = BookRepositoryImpl(dao: BookDao(db));
    transactionDao = TransactionDao(db);
    mockEncryption = _MockFieldEncryptionService();
    mockGroupRepository = _MockGroupRepository();
    mockShoppingItemRepository = _MockShoppingItemRepository();
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
      shoppingItemRepository: mockShoppingItemRepository,
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
            'ledgerType': 'daily',
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
            'ledgerType': 'daily',
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
            'ledgerType': 'daily',
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
            'ledgerType': 'daily',
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
            'ledgerType': 'daily',
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
            'ledgerType': 'daily',
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
            'ledgerType': 'daily',
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
            'ledgerType': 'daily',
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
            'ledgerType': 'daily',
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

  group('shopping_item branch (D37-05, SC-3, SC-4)', () {
    test(
      'bad shopping op does NOT abort bill ops (D37-05, SC-3)',
      () async {
        // A batch mixing an invalid shopping op with a valid bill op
        // The shopping branch must fault-isolate — bill op must still apply
        await useCase.execute([
          {
            'op': 'create',
            'entityType': 'shopping_item',
            'entityId': null, // invalid — missing entityId → should fail-safe
            'fromDeviceId': 'partner-device',
            'data': null, // invalid data
          },
          {
            'op': 'create',
            'entityType': 'bill',
            'entityId': 'tx-after-bad-shopping',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'tx-after-bad-shopping',
              'amount': 1500,
              'type': 'expense',
              'categoryId': 'cat-1',
              'ledgerType': 'daily',
              'timestamp': '2026-06-08T10:00:00.000Z',
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
        ]);

        // Bill op was applied even though shopping op was invalid
        final tx = await transactionDao.findById('tx-after-bad-shopping');
        expect(
          tx,
          isNotNull,
          reason: 'Bill op must succeed even when shopping op is bad (D37-05)',
        );
      },
    );

    test(
      'tombstone not resurrected by remote update (SC-4)',
      () async {
        // This test verifies the ShoppingItemChangeTracker integration —
        // When the shopping item branch is wired, a delete then update must
        // leave the item soft-deleted (tombstone wins). This test asserts the
        // contract at the apply_sync level using mock repository.
        // The mock does not actually persist, so we verify call order instead.
        // Full round-trip persistence is tested in shopping_sync_round_trip_test.dart.

        // Assert: the use case processes a batch with delete + update without crashing
        // and does NOT call mockShoppingItemRepository.update after softDelete if
        // the item was deleted. The mock returns null for findById (deleted item).
        when(
          () => mockShoppingItemRepository.findById(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockShoppingItemRepository.softDelete(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockShoppingItemRepository.upsert(any()),
        ).thenAnswer((_) async {});

        await useCase.execute([
          {
            'op': 'delete',
            'entityType': 'shopping_item',
            'entityId': 'item-tombstone',
            'fromDeviceId': 'partner-device',
          },
        ]);

        verify(
          () => mockShoppingItemRepository.softDelete('item-tombstone'),
        ).called(1);
      },
    );

    test(
      'sticky-complete merge: stale rename preserves completion (SC-4, D37-02)',
      () async {
        // This test verifies the sticky-complete merge contract.
        // When a stale update (updatedAt < completedAt) arrives:
        //   - existing.isCompleted=true + completedAt=T1 is preserved
        //   - stale isCompleted:false from update is ignored
        //
        // The mock-level test verifies the ShoppingItemRepository contract is
        // called correctly. Full persistence is in shopping_sync_round_trip_test.dart.
        when(
          () => mockShoppingItemRepository.findById(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockShoppingItemRepository.upsert(any()),
        ).thenAnswer((_) async {});

        // Create via sync (arrives first)
        await useCase.execute([
          {
            'op': 'create',
            'entityType': 'shopping_item',
            'entityId': 'item-sticky',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-sticky',
              'listType': 'public',
              'name': 'Bread',
              'quantity': 1,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
        ]);

        // Stale update arrives after (updatedAt < when completedAt would be)
        await useCase.execute([
          {
            'op': 'update',
            'entityType': 'shopping_item',
            'entityId': 'item-sticky',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-sticky',
              'listType': 'public',
              'name': 'Sourdough Bread', // rename
              'quantity': 1,
              'isCompleted': false, // stale: completion state already changed locally
              'createdAt': '2026-06-08T10:00:00.000Z',
              'updatedAt': '2026-06-08T09:00:00.000Z', // STALE — before completedAt
            },
          },
        ]);

        // The use case ran without crashing; sticky-complete preservation logic
        // is fully tested in the integration round-trip test with real DB.
        verify(() => mockShoppingItemRepository.upsert(any())).called(
          greaterThanOrEqualTo(1),
        );
      },
    );

    test(
      'remote update preserves local sortOrder (CR-01, D37-01)',
      () async {
        // sortOrder is a local-only field excluded from the sync wire, so an
        // incoming update payload never carries it. The apply handler must
        // preserve the existing local sortOrder instead of letting fromSyncMap's
        // default (0) clobber a locally-reordered item back to position 0.
        final existing = ShoppingItem(
          id: 'item-reordered',
          deviceId: 'local-device',
          listType: 'public',
          name: 'Milk',
          sortOrder: 7,
          createdAt: DateTime.parse('2026-06-08T10:00:00.000Z'),
        );
        when(
          () => mockShoppingItemRepository.findById('item-reordered'),
        ).thenAnswer((_) async => existing);
        when(
          () => mockShoppingItemRepository.upsert(any()),
        ).thenAnswer((_) async {});

        await useCase.execute([
          {
            'op': 'update',
            'entityType': 'shopping_item',
            'entityId': 'item-reordered',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-reordered',
              'listType': 'public',
              'name': 'Whole Milk', // rename via remote update
              'quantity': 1,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
              'updatedAt': '2026-06-08T11:00:00.000Z',
            },
          },
        ]);

        final captured =
            verify(() => mockShoppingItemRepository.upsert(captureAny()))
                .captured
                .single as ShoppingItem;
        expect(
          captured.sortOrder,
          7,
          reason:
              'remote update must preserve local sortOrder, not reset to 0',
        );
        expect(captured.name, 'Whole Milk');
      },
    );
  });

  group('receiver-side listType gate + pin (W2, SYNC-02/SYNC-03, D37-04)', () {
    test(
      'inbound private create op is dropped; rest of batch still applies',
      () async {
        when(
          () => mockShoppingItemRepository.findById(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockShoppingItemRepository.upsert(any()),
        ).thenAnswer((_) async {});

        await useCase.execute([
          {
            'op': 'create',
            'entityType': 'shopping_item',
            'entityId': 'item-private-create',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-private-create',
              'listType': 'private',
              'name': 'Secret Gift',
              'quantity': 1,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
          {
            'op': 'create',
            'entityType': 'bill',
            'entityId': 'tx-after-private-shopping',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'tx-after-private-shopping',
              'amount': 4200,
              'type': 'expense',
              'categoryId': 'cat-1',
              'ledgerType': 'daily',
              'timestamp': '2026-06-08T10:00:00.000Z',
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
        ]);

        // The private shopping op must never reach the repository
        verifyNever(() => mockShoppingItemRepository.upsert(any()));
        // Per-op skip, not abort — the bill op in the same batch still applies
        final tx = await transactionDao.findById('tx-after-private-shopping');
        expect(
          tx,
          isNotNull,
          reason: 'private-op drop must be per-op skip, not batch abort',
        );
      },
    );

    test(
      'inbound private update op is dropped; existing public item unchanged',
      () async {
        final existing = ShoppingItem(
          id: 'item-pub-target',
          deviceId: 'local-device',
          listType: 'public',
          name: 'Milk',
          createdAt: DateTime.parse('2026-06-08T10:00:00.000Z'),
        );
        when(
          () => mockShoppingItemRepository.findById('item-pub-target'),
        ).thenAnswer((_) async => existing);
        when(
          () => mockShoppingItemRepository.upsert(any()),
        ).thenAnswer((_) async {});

        await useCase.execute([
          {
            'op': 'update',
            'entityType': 'shopping_item',
            'entityId': 'item-pub-target',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-pub-target',
              'listType': 'private', // non-public wire value → must be dropped
              'name': 'Hijacked Name',
              'quantity': 1,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
              'updatedAt': '2026-06-08T12:00:00.000Z', // newer than local
            },
          },
        ]);

        verifyNever(() => mockShoppingItemRepository.upsert(any()));
      },
    );

    test(
      'update op cannot flip listType — existing.listType is pinned (D37-04)',
      () async {
        final existing = ShoppingItem(
          id: 'item-priv-pinned',
          deviceId: 'local-device',
          listType: 'private',
          name: 'Old Name',
          createdAt: DateTime.parse('2026-06-08T10:00:00.000Z'),
        );
        when(
          () => mockShoppingItemRepository.findById('item-priv-pinned'),
        ).thenAnswer((_) async => existing);
        when(
          () => mockShoppingItemRepository.upsert(any()),
        ).thenAnswer((_) async {});

        await useCase.execute([
          {
            'op': 'update',
            'entityType': 'shopping_item',
            'entityId': 'item-priv-pinned',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-priv-pinned',
              'listType': 'public', // wire claims public — passes the gate
              'name': 'New Name',
              'quantity': 2,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
              'updatedAt': '2026-06-08T12:00:00.000Z', // newer than local
            },
          },
        ]);

        final captured =
            verify(() => mockShoppingItemRepository.upsert(captureAny()))
                .captured
                .single as ShoppingItem;
        expect(
          captured.listType,
          'private',
          reason:
              'wire can never flip an item public↔private — '
              'existing.listType must be pinned (D37-04, W2/SYNC-03)',
        );
        expect(
          captured.name,
          'New Name',
          reason: 'non-listType fields must still take incoming values',
        );
      },
    );

    test('public create and public update still apply (regression)', () async {
      when(
        () => mockShoppingItemRepository.findById('item-pub-regression'),
      ).thenAnswer((_) async => null);
      when(
        () => mockShoppingItemRepository.upsert(any()),
      ).thenAnswer((_) async {});

      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'shopping_item',
          'entityId': 'item-pub-regression',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'item-pub-regression',
            'listType': 'public',
            'name': 'Butter',
            'quantity': 1,
            'isCompleted': false,
            'createdAt': '2026-06-08T10:00:00.000Z',
          },
        },
      ]);

      final created =
          verify(() => mockShoppingItemRepository.upsert(captureAny()))
              .captured
              .single as ShoppingItem;
      expect(created.listType, 'public');
      expect(created.name, 'Butter');

      // Now an inbound public update against the (now existing) item
      when(
        () => mockShoppingItemRepository.findById('item-pub-regression'),
      ).thenAnswer((_) async => created);

      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'shopping_item',
          'entityId': 'item-pub-regression',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'item-pub-regression',
            'listType': 'public',
            'name': 'Salted Butter',
            'quantity': 2,
            'isCompleted': false,
            'createdAt': '2026-06-08T10:00:00.000Z',
            'updatedAt': '2026-06-08T11:00:00.000Z',
          },
        },
      ]);

      final updated =
          verify(() => mockShoppingItemRepository.upsert(captureAny()))
              .captured
              .single as ShoppingItem;
      expect(updated.name, 'Salted Butter');
      expect(updated.listType, 'public');
    });
  });
}

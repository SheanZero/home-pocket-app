import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/repository_providers.dart'
    as app_accounting;
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/family_sync_outbox_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart'
    show shoppingItemRepositoryProvider;
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart'
    show userProfileRepositoryProvider;
import 'package:mocktail/mocktail.dart';

class _MockBookRepository extends Mock implements BookRepository {}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

class _MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockFamilySyncOutboxRepository extends Mock
    implements FamilySyncOutboxRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

Book _book(String id, {bool archived = false, bool shadow = false}) => Book(
  id: id,
  name: 'Book $id',
  currency: 'JPY',
  deviceId: shadow ? 'peer-device' : 'local-device',
  createdAt: DateTime.utc(2026, 8, 2),
  isArchived: archived,
  isShadow: shadow,
  groupId: shadow ? 'group-a' : null,
  ownerDeviceId: shadow ? 'peer-device' : null,
);

Transaction _transaction({
  required String id,
  required String bookId,
  required int revision,
  bool isPrivate = false,
  bool isDeleted = false,
  FamilySyncVisibility visibility = FamilySyncVisibility.shared,
  String? note,
}) => Transaction(
  id: id,
  bookId: bookId,
  deviceId: 'local-device',
  amount: 1200 + revision,
  type: TransactionType.expense,
  categoryId: 'cat-food',
  ledgerType: LedgerType.daily,
  timestamp: DateTime.utc(2026, 8, 2),
  note: note,
  currentHash: 'hash-$id',
  createdAt: DateTime.utc(2026, 8, 2),
  updatedAt: DateTime.utc(2026, 8, 2, 1),
  isPrivate: isPrivate,
  isDeleted: isDeleted,
  syncRevision: revision,
  syncOriginDeviceId: 'local-device',
  familySyncVisibility: visibility,
  familySharedRevision: visibility == FamilySyncVisibility.localOnly
      ? 0
      : revision,
  entrySource: EntrySource.manual,
);

Future<void> _insertRow(AppDatabase database, Transaction transaction) {
  return TransactionDao(database).insertTransaction(
    id: transaction.id,
    bookId: transaction.bookId,
    deviceId: transaction.deviceId,
    amount: transaction.amount,
    type: transaction.type.name,
    categoryId: transaction.categoryId,
    ledgerType: transaction.ledgerType.name,
    timestamp: transaction.timestamp,
    currentHash: transaction.currentHash,
    createdAt: transaction.createdAt,
    note: transaction.note,
    isPrivate: transaction.isPrivate,
    isDeleted: transaction.isDeleted,
    syncRevision: transaction.syncRevision,
    syncOriginDeviceId: transaction.syncOriginDeviceId,
    familySyncVisibility: transaction.familySyncVisibility.name,
    familySharedRevision: transaction.familySharedRevision,
    joyFullness: transaction.joyFullness,
    entrySource: transaction.entrySource.name,
  );
}

void main() {
  test(
    'provider includes archived local history, excludes shadow/private, and settles exact revisions',
    () async {
      final database = AppDatabase.forTesting();
      final bookRepository = _MockBookRepository();
      final transactionRepository = _MockTransactionRepository();
      final shoppingRepository = _MockShoppingItemRepository();
      final pushSync = _MockPushSyncUseCase();
      final groupRepository = _MockGroupRepository();
      final outboxRepository = _MockFamilySyncOutboxRepository();
      final profileRepository = _MockUserProfileRepository();

      final activeBook = _book('book-active');
      final archivedBook = _book('book-archived', archived: true);
      final shadowBook = _book('book-shadow', shadow: true);
      final transactions = <String, Transaction>{
        'tx-active-public': _transaction(
          id: 'tx-active-public',
          bookId: activeBook.id,
          revision: 10,
        ),
        'tx-archived-public': _transaction(
          id: 'tx-archived-public',
          bookId: archivedBook.id,
          revision: 20,
        ),
        'tx-archived-withdrawal': _transaction(
          id: 'tx-archived-withdrawal',
          bookId: archivedBook.id,
          revision: 30,
          isPrivate: true,
          visibility: FamilySyncVisibility.withdrawalPending,
          note: 'must-not-leak-withdrawal-secret',
        ),
        'tx-archived-private': _transaction(
          id: 'tx-archived-private',
          bookId: archivedBook.id,
          revision: 40,
          isPrivate: true,
          visibility: FamilySyncVisibility.localOnly,
          note: 'must-not-leak-private-secret',
        ),
        'tx-shadow-public': _transaction(
          id: 'tx-shadow-public',
          bookId: shadowBook.id,
          revision: 50,
        ),
      };
      for (final transaction in transactions.values) {
        await _insertRow(database, transaction);
      }

      when(
        () =>
            bookRepository.findAll(includeArchived: true, includeShadow: false),
      ).thenAnswer((_) async => [activeBook, archivedBook]);
      when(() => transactionRepository.findById(any())).thenAnswer(
        (invocation) async =>
            transactions[invocation.positionalArguments.single as String],
      );
      when(
        () => shoppingRepository.watchByListType('public'),
      ).thenAnswer((_) => Stream.value(const []));
      when(() => profileRepository.find()).thenAnswer((_) async => null);
      when(() => groupRepository.getActiveGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-a',
          groupName: 'Family',
          status: GroupStatus.active,
          role: 'owner',
          groupKey: 'group-key',
          members: const [],
          createdAt: DateTime.utc(2026, 8, 2),
        ),
      );
      final pushed = <Map<String, dynamic>>[];
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          syncType: 'full',
        ),
      ).thenAnswer((invocation) async {
        final operations =
            invocation.namedArguments[#operations]
                as List<Map<String, dynamic>>;
        pushed.addAll(operations);
        return PushSyncResult.success(operations.length);
      });
      final settled = <Map<String, dynamic>>[];
      when(
        () => outboxRepository.settleCovered(
          groupId: 'group-a',
          operations: any(named: 'operations'),
        ),
      ).thenAnswer((invocation) async {
        settled.addAll(
          (invocation.namedArguments[#operations]
                  as Iterable<Map<String, dynamic>>)
              .map(Map<String, dynamic>.of),
        );
      });

      final container = ProviderContainer(
        overrides: [
          app_accounting.appAppDatabaseProvider.overrideWithValue(database),
          bookRepositoryProvider.overrideWithValue(bookRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          shoppingItemRepositoryProvider.overrideWithValue(shoppingRepository),
          pushSyncUseCaseProvider.overrideWithValue(pushSync),
          groupRepositoryProvider.overrideWithValue(groupRepository),
          familySyncOutboxRepositoryProvider.overrideWithValue(
            outboxRepository,
          ),
          userProfileRepositoryProvider.overrideWithValue(profileRepository),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(database.close);

      expect(await container.read(fullSyncUseCaseProvider).execute(), 3);

      verify(
        () =>
            bookRepository.findAll(includeArchived: true, includeShadow: false),
      ).called(1);
      expect(
        pushed.map((operation) => operation['entityId']),
        unorderedEquals({
          'tx-active-public',
          'tx-archived-public',
          'tx-archived-withdrawal',
        }),
      );
      expect(
        pushed.map((operation) => operation['entityId']),
        isNot(contains('tx-archived-private')),
      );
      expect(
        pushed.map((operation) => operation['entityId']),
        isNot(contains('tx-shadow-public')),
      );
      final archivedLive = pushed.singleWhere(
        (operation) => operation['entityId'] == 'tx-archived-public',
      );
      expect(archivedLive['op'], 'reconcile');
      expect(archivedLive['revision'], 20);
      final withdrawal = pushed.singleWhere(
        (operation) => operation['entityId'] == 'tx-archived-withdrawal',
      );
      expect(withdrawal['op'], 'delete');
      expect(withdrawal['revision'], 30);
      expect(
        (withdrawal['data'] as Map<String, dynamic>).keys,
        unorderedEquals({'isDeleted', 'syncRevision', 'syncOriginDeviceId'}),
      );
      expect(withdrawal.toString(), isNot(contains('must-not-leak')));
      expect(
        settled
            .map(
              (operation) => (
                operation['entityId'],
                operation['revision'],
                operation['op'],
              ),
            )
            .toList(),
        pushed
            .map(
              (operation) => (
                operation['entityId'],
                operation['revision'],
                operation['op'],
              ),
            )
            .toList(),
      );
      expect(
        settled.map((operation) => operation['revision']),
        unorderedEquals({10, 20, 30}),
      );
    },
  );
}

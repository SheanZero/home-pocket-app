/// Presentation-layer smoke test for filteredShoppingItemsProvider.
///
/// Verifies two contracts at the Riverpod presentation layer (D39-06):
///
/// SC4 (assertion 1): A public item written via ApplySyncOperationsUseCase causes
/// filteredShoppingItemsProvider to emit a new state reactively — no ref.invalidate
/// anywhere in the production code path. Reactivity comes from the Drift stream
/// emitting on DB writes, flowing through shoppingItemRepositoryProvider.
///
/// D39-06 privacy (assertion 2): A private item written via the same path does NOT
/// appear in filteredShoppingItemsProvider when listTypeProvider is set to 'public'.
///
/// This covers a DIFFERENT layer from Phase 37's shopping_sync_round_trip_test.dart,
/// which tests raw watchByListType at the repository layer. This test covers the
/// Riverpod StreamProvider used by ShoppingListScreen.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/shopping_item_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/shopping_item_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_filter.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart'
    show fieldEncryptionServiceProvider;
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/security/providers.dart'
    show appDatabaseProvider;
import 'package:mocktail/mocktail.dart';

import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';

import '../../helpers/test_provider_scope.dart';

/// Waits for filteredShoppingItemsProvider to emit a state that contains [itemId].
///
/// Establishes a subscription BEFORE the caller performs the write so that
/// the Drift reactive stream propagates through the Riverpod graph. Resolves
/// with `true` when the item appears, `false` on timeout (handled by caller).
Future<bool> _waitForItemInStream(
  ProviderContainer container,
  ProviderListenable<AsyncValue<List<ShoppingItem>>> provider, {
  required String itemId,
}) {
  final completer = Completer<bool>();
  final sub = container.listen<AsyncValue<List<ShoppingItem>>>(
    provider,
    (_, next) {
      if (!completer.isCompleted &&
          next.hasValue &&
          next.value!.any((i) => i.id == itemId)) {
        completer.complete(true);
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

class _MockGroupRepository extends Mock implements GroupRepository {}

/// Notifier subclass that fixes listType to 'public' for stable test state.
class _FixedPublicListType extends ListType {
  @override
  String build() => 'public';
}

void main() {
  late AppDatabase db;
  late ShoppingItemRepositoryImpl shoppingItemRepo;
  late ApplySyncOperationsUseCase applyOps;
  late _MockFieldEncryptionService mockEncryption;
  late _MockGroupRepository mockGroupRepository;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting();
    mockEncryption = _MockFieldEncryptionService();
    mockGroupRepository = _MockGroupRepository();

    when(() => mockEncryption.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => mockEncryption.decryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => mockGroupRepository.getPendingGroup())
        .thenAnswer((_) async => null);

    final shoppingItemDao = ShoppingItemDao(db);
    shoppingItemRepo = ShoppingItemRepositoryImpl(
      dao: shoppingItemDao,
      encryptionService: mockEncryption,
    );

    final bookDao = BookDao(db);
    final txDao = TransactionDao(db);
    final bookRepo = BookRepositoryImpl(dao: bookDao);
    final txRepo = TransactionRepositoryImpl(
      dao: txDao,
      encryptionService: mockEncryption,
    );
    final shadowBookService = ShadowBookService(
      bookRepository: bookRepo,
      transactionRepository: txRepo,
    );

    applyOps = ApplySyncOperationsUseCase(
      transactionRepository: txRepo,
      shoppingItemRepository: shoppingItemRepo,
      shadowBookService: shadowBookService,
      groupRepository: mockGroupRepository,
    );

    // Presentation-layer container: override root DB + encryption providers so
    // shoppingItemRepositoryProvider resolves through the mock stack without
    // touching the real encrypted DB or secure storage.
    // listTypeProvider is fixed to 'public' via _FixedPublicListType for both tests.
    container = ProviderContainer.test(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        fieldEncryptionServiceProvider.overrideWithValue(mockEncryption),
        listTypeProvider.overrideWith(() => _FixedPublicListType()),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('filteredShoppingItemsProvider — presentation layer smoke', () {
    test(
      'SC4: public item via ApplySync → filteredShoppingItemsProvider emits reactively',
      () async {
        // Subscribe BEFORE the write — Riverpod 3 disposes orphan reads, so
        // holding an active subscription via container.listen is mandatory.
        // The subscribe-before-write pattern ensures the Drift reactive stream
        // is live when the DB write arrives, guaranteeing the emission propagates.
        //
        // waitForItemInStream starts the waiter BEFORE the write so that any
        // post-write emission is captured. The waiter resolves when the provider
        // emits a state where the expected item ID is present.
        final resultFuture = _waitForItemInStream(
          container,
          filteredShoppingItemsProvider,
          itemId: 'item-smoke',
        );

        await applyOps.execute([
          {
            'op': 'create',
            'entityType': kShoppingItemEntityType,
            'entityId': 'item-smoke',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-smoke',
              'listType': 'public',
              'name': 'Milk',
              'quantity': 1,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
        ]);

        final found = await resultFuture
            .timeout(const Duration(seconds: 5));
        expect(
          found,
          isTrue,
          reason:
              'filteredShoppingItemsProvider MUST emit reactively — no ref.invalidate (SC4)',
        );
      },
    );

    test(
      'D39-06: private item never appears in public filteredShoppingItemsProvider',
      () async {
        // For D39-06 privacy: apply an inbound private-item op and verify it
        // never reaches the public stream.
        //
        // Since quick task 260612-daz (W2/SYNC-02 receiver gate), an inbound
        // shopping_item op with a non-public listType is dropped at
        // ApplySyncOperationsUseCase before any DB write — receiver-side
        // enforcement, stronger than the original DAO-level exclusion. So no
        // post-write emission occurs at all: we assert the op left no trace
        // in EITHER list and the public provider state stayed empty.

        // Step 1: establish subscription (keeps provider alive).
        final sub = container.listen(
          filteredShoppingItemsProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        // Step 2: await initial emission so the stream is settled (empty list).
        final initial =
            await waitForFirstValue(container, filteredShoppingItemsProvider);
        expect(initial.hasValue, isTrue);
        expect(initial.value, isEmpty,
            reason: 'Initial state must be empty before any write');

        // Step 3: apply inbound private op — dropped by the W2 receiver gate.
        await applyOps.execute([
          {
            'op': 'create',
            'entityType': kShoppingItemEntityType,
            'entityId': 'private-smoke',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'private-smoke',
              'listType': 'private',
              'name': 'Secret Gift',
              'quantity': 1,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
        ]);

        // Step 4: the gate drops the op before any DB write, so no new stream
        // emission is expected. Assert no trace in either list, then confirm
        // the public provider state is still the settled empty list.
        final privateItems =
            await shoppingItemRepo.watchByListType('private').first;
        expect(
          privateItems.any((i) => i.id == 'private-smoke'),
          isFalse,
          reason:
              'Inbound private op must be dropped entirely by the W2 receiver '
              'gate — not written to the private list (SYNC-02)',
        );

        final publicItems =
            await shoppingItemRepo.watchByListType('public').first;
        expect(publicItems, isEmpty,
            reason: 'Dropped op must not be coerced into the public list');

        final current = container.read(filteredShoppingItemsProvider);
        expect(current.hasValue, isTrue);
        expect(
          current.value!.any((i) => i.id == 'private-smoke'),
          isFalse,
          reason:
              'Private item must never appear in public stream (D39-06, presentation layer)',
        );
      },
    );
  });
}

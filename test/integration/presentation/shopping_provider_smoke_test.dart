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
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
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

/// Waits for filteredShoppingItemsProvider to emit the next settled value after
/// a write. Uses a Completer that fires on the second (or later) hasValue
/// emission, skipping the initial cached state.
Future<AsyncValue<List<ShoppingItem>>> _waitForSettledEmission(
  ProviderContainer container,
  ProviderListenable<AsyncValue<List<ShoppingItem>>> provider,
) {
  final completer = Completer<AsyncValue<List<ShoppingItem>>>();
  var emissionCount = 0;
  final sub = container.listen<AsyncValue<List<ShoppingItem>>>(
    provider,
    (_, next) {
      emissionCount++;
      // Skip the first (cached/initial) emission; resolve on the second one.
      if (!completer.isCompleted && next.hasValue && emissionCount > 1) {
        completer.complete(next);
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
        // For D39-06 privacy: write a private item and then verify the public
        // stream does NOT contain it.
        //
        // Subscribe BEFORE the write (subscribe-before-write pattern). Then
        // await the post-write emission using waitForFirstValue. Since the
        // private item is excluded by the DAO-level WHERE clause, the stream
        // will emit an empty list after the write. We verify the private item
        // ID is absent.
        //
        // waitForFirstValue resolves on the FIRST hasValue emission. We need
        // to call it after the write so it catches the post-write emission.
        // To handle both cases (pre-write and post-write emission), we use
        // _waitForSettledEmissionAfterWrite which waits for the stream to
        // settle after the write and checks that the item is absent.

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

        // Step 3: write private item — stream re-emits after DB write.
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

        // Step 4: wait for post-write emission by waiting for a state change.
        // Since 'private-smoke' is excluded, the stream emits an empty list
        // again. We use _waitForSettledEmission to catch the post-write value.
        final postWrite = await _waitForSettledEmission(
          container,
          filteredShoppingItemsProvider,
        ).timeout(const Duration(seconds: 5));

        expect(postWrite.hasValue, isTrue);
        expect(
          postWrite.value!.any((i) => i.id == 'private-smoke'),
          isFalse,
          reason:
              'Private item must never appear in public stream (D39-06, presentation layer)',
        );
      },
    );
  });
}

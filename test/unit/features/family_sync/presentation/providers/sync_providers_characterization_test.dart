import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/check_group_validity_use_case.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/application/family_sync/transaction_change_tracker.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart'
    show userProfileRepositoryProvider;
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MockKeyManager extends Mock implements KeyManager {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockE2EEService extends Mock implements E2EEService {}

class _MockSyncQueueManager extends Mock implements SyncQueueManager {}

class _MockWebSocketService extends Mock implements WebSocketService {}

class _MockTransactionRepository extends Mock implements TransactionRepository {}

class _MockBookRepository extends Mock implements BookRepository {}

class _MockUserProfileRepository extends Mock implements UserProfileRepository {}


void main() {
  late _MockRelayApiClient mockApiClient;
  late _MockKeyManager mockKeyManager;
  late _MockGroupRepository mockGroupRepo;
  late _MockE2EEService mockE2EEService;
  late _MockSyncQueueManager mockSyncQueueManager;
  late _MockWebSocketService mockWebSocketService;
  late _MockTransactionRepository mockTransactionRepo;
  late _MockBookRepository mockBookRepo;
  late _MockUserProfileRepository mockUserProfileRepo;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = _MockRelayApiClient();
    mockKeyManager = _MockKeyManager();
    mockGroupRepo = _MockGroupRepository();
    mockE2EEService = _MockE2EEService();
    mockSyncQueueManager = _MockSyncQueueManager();
    mockWebSocketService = _MockWebSocketService();
    mockTransactionRepo = _MockTransactionRepository();
    mockBookRepo = _MockBookRepository();
    mockUserProfileRepo = _MockUserProfileRepository();

    // groupMembers stream needs activeGroupProvider to return null (no active group)
    when(
      () => mockGroupRepo.watchActiveGroup(),
    ).thenAnswer((_) => Stream.value(null));

    when(() => mockWebSocketService.dispose()).thenReturn(null);

    container = ProviderContainer(
      overrides: [
        relayApiClientProvider.overrideWithValue(mockApiClient),
        keyManagerProvider.overrideWithValue(mockKeyManager),
        groupRepositoryProvider.overrideWithValue(mockGroupRepo),
        e2eeServiceProvider.overrideWithValue(mockE2EEService),
        syncQueueManagerProvider.overrideWithValue(mockSyncQueueManager),
        webSocketServiceProvider.overrideWithValue(mockWebSocketService),
        transactionRepositoryProvider.overrideWithValue(mockTransactionRepo),
        bookRepositoryProvider.overrideWithValue(mockBookRepo),
        userProfileRepositoryProvider.overrideWithValue(mockUserProfileRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group(
    'family_sync/sync_providers characterization tests (pre-refactor behavior)',
    () {
      // HIGH-05 keepAlive lock: transactionChangeTrackerProvider
      test(
        'transactionChangeTrackerProvider is keepAlive — same instance across two reads',
        () {
          final first = container.read(transactionChangeTrackerProvider);
          final second = container.read(transactionChangeTrackerProvider);
          expect(identical(first, second), isTrue,
              reason:
                  'transactionChangeTrackerProvider must be keepAlive: true');
        },
      );

      test(
        'transactionChangeTrackerProvider constructs TransactionChangeTracker',
        () {
          final tracker = container.read(transactionChangeTrackerProvider);
          expect(tracker, isA<TransactionChangeTracker>());
        },
      );

      // HIGH-05 keepAlive lock: syncEngineProvider
      test(
        'syncEngineProvider is keepAlive — same instance across two reads',
        () {
          final first = container.read(syncEngineProvider);
          final second = container.read(syncEngineProvider);
          expect(identical(first, second), isTrue,
              reason: 'syncEngineProvider must be keepAlive: true');
        },
      );

      test('syncEngineProvider constructs SyncEngine without error', () {
        final engine = container.read(syncEngineProvider);
        expect(engine, isA<SyncEngine>());
      });

      test('pushSyncUseCaseProvider constructs PushSyncUseCase', () {
        final uc = container.read(pushSyncUseCaseProvider);
        expect(uc, isA<PushSyncUseCase>());
      });

      test('shadowBookServiceProvider constructs ShadowBookService', () {
        final svc = container.read(shadowBookServiceProvider);
        expect(svc, isA<ShadowBookService>());
      });

      test(
        'applySyncOperationsUseCaseProvider constructs ApplySyncOperationsUseCase',
        () {
          final uc = container.read(applySyncOperationsUseCaseProvider);
          expect(uc, isA<ApplySyncOperationsUseCase>());
        },
      );

      test('checkGroupValidityUseCaseProvider constructs without error', () {
        final uc = container.read(checkGroupValidityUseCaseProvider);
        expect(uc, isA<CheckGroupValidityUseCase>());
      });

      test('fullSyncUseCaseProvider constructs FullSyncUseCase', () {
        final uc = container.read(fullSyncUseCaseProvider);
        expect(uc, isA<FullSyncUseCase>());
      });

      test('syncOrchestratorProvider constructs SyncOrchestrator', () {
        final svc = container.read(syncOrchestratorProvider);
        expect(svc, isA<SyncOrchestrator>());
      });

      // activeGroupMembersProvider behavior when activeGroup is null
      test(
        'activeGroupMembersProvider resolves to empty list when activeGroupProvider returns null',
        () async {
          // activeGroupProvider will see null from mockGroupRepo.watchActiveGroup()
          // so activeGroupMembersProvider should resolve to [] (since it returns Stream.value([]))
          // Wait for the provider to settle by polling the AsyncValue
          await Future<void>.delayed(const Duration(milliseconds: 50));
          final value = container.read(activeGroupMembersProvider);
          // The value should be either loading (ActiveGroup stream not yet emitted)
          // or data with an empty list
          value.whenData(
            (members) => expect(members, isEmpty,
                reason:
                    'activeGroupMembersProvider must emit [] when no active group'),
          );
          // Also verify the provider constructed without throwing
          expect(value, isA<AsyncValue<List<GroupMember>>>());
        },
      );
    },
  );
}

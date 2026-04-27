import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/check_group_use_case.dart';
import 'package:home_pocket/application/family_sync/confirm_join_use_case.dart';
import 'package:home_pocket/application/family_sync/confirm_member_use_case.dart';
import 'package:home_pocket/application/family_sync/create_group_use_case.dart';
import 'package:home_pocket/application/family_sync/deactivate_group_use_case.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/join_group_use_case.dart';
import 'package:home_pocket/application/family_sync/leave_group_use_case.dart';
import 'package:home_pocket/application/family_sync/remove_member_use_case.dart';
import 'package:home_pocket/application/family_sync/rename_group_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MockKeyManager extends Mock implements KeyManager {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockE2EEService extends Mock implements E2EEService {}

class _MockSyncQueueManager extends Mock implements SyncQueueManager {}

class _MockSyncAvatarUseCase extends Mock implements SyncAvatarUseCase {}

class _MockFullSyncUseCase extends Mock implements FullSyncUseCase {}

class _MockShadowBookService extends Mock implements ShadowBookService {}

void main() {
  late _MockRelayApiClient mockApiClient;
  late _MockKeyManager mockKeyManager;
  late _MockGroupRepository mockGroupRepo;
  late _MockE2EEService mockE2EEService;
  late _MockSyncQueueManager mockSyncQueueManager;
  late _MockSyncAvatarUseCase mockSyncAvatarUseCase;
  late _MockFullSyncUseCase mockFullSyncUseCase;
  late _MockShadowBookService mockShadowBookService;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = _MockRelayApiClient();
    mockKeyManager = _MockKeyManager();
    mockGroupRepo = _MockGroupRepository();
    mockE2EEService = _MockE2EEService();
    mockSyncQueueManager = _MockSyncQueueManager();
    mockSyncAvatarUseCase = _MockSyncAvatarUseCase();
    mockFullSyncUseCase = _MockFullSyncUseCase();
    mockShadowBookService = _MockShadowBookService();

    container = ProviderContainer(
      overrides: [
        relayApiClientProvider.overrideWithValue(mockApiClient),
        keyManagerProvider.overrideWithValue(mockKeyManager),
        groupRepositoryProvider.overrideWithValue(mockGroupRepo),
        e2eeServiceProvider.overrideWithValue(mockE2EEService),
        syncQueueManagerProvider.overrideWithValue(mockSyncQueueManager),
        syncAvatarUseCaseProvider.overrideWithValue(mockSyncAvatarUseCase),
        fullSyncUseCaseProvider.overrideWithValue(mockFullSyncUseCase),
        shadowBookServiceProvider.overrideWithValue(mockShadowBookService),
      ],
    );
  });

  tearDown(() => container.dispose());

  group(
    'family_sync/group_providers characterization tests (pre-refactor: DI-only providers)',
    () {
      test('createGroupUseCaseProvider constructs without error', () {
        final uc = container.read(createGroupUseCaseProvider);
        expect(uc, isA<CreateGroupUseCase>());
      });

      test('joinGroupUseCaseProvider constructs without error', () {
        final uc = container.read(joinGroupUseCaseProvider);
        expect(uc, isA<JoinGroupUseCase>());
      });

      test('confirmJoinUseCaseProvider constructs without error', () {
        final uc = container.read(confirmJoinUseCaseProvider);
        expect(uc, isA<ConfirmJoinUseCase>());
      });

      test('renameGroupUseCaseProvider constructs without error', () {
        final uc = container.read(renameGroupUseCaseProvider);
        expect(uc, isA<RenameGroupUseCase>());
      });

      test('checkGroupUseCaseProvider constructs without error', () {
        final uc = container.read(checkGroupUseCaseProvider);
        expect(uc, isA<CheckGroupUseCase>());
      });

      test('confirmMemberUseCaseProvider constructs without error', () {
        final uc = container.read(confirmMemberUseCaseProvider);
        expect(uc, isA<ConfirmMemberUseCase>());
      });

      test('leaveGroupUseCaseProvider constructs without error', () {
        final uc = container.read(leaveGroupUseCaseProvider);
        expect(uc, isA<LeaveGroupUseCase>());
      });

      test('deactivateGroupUseCaseProvider constructs without error', () {
        final uc = container.read(deactivateGroupUseCaseProvider);
        expect(uc, isA<DeactivateGroupUseCase>());
      });

      test('removeMemberUseCaseProvider constructs without error', () {
        final uc = container.read(removeMemberUseCaseProvider);
        expect(uc, isA<RemoveMemberUseCase>());
      });

      test('all 9 group use case providers return non-null instances', () {
        expect(container.read(createGroupUseCaseProvider), isNotNull);
        expect(container.read(joinGroupUseCaseProvider), isNotNull);
        expect(container.read(confirmJoinUseCaseProvider), isNotNull);
        expect(container.read(renameGroupUseCaseProvider), isNotNull);
        expect(container.read(checkGroupUseCaseProvider), isNotNull);
        expect(container.read(confirmMemberUseCaseProvider), isNotNull);
        expect(container.read(leaveGroupUseCaseProvider), isNotNull);
        expect(container.read(deactivateGroupUseCaseProvider), isNotNull);
        expect(container.read(removeMemberUseCaseProvider), isNotNull);
      });
    },
  );
}

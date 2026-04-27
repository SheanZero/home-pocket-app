import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart'
    show userProfileRepositoryProvider;
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockE2EEService extends Mock implements E2EEService {}

void main() {
  late _MockRelayApiClient mockApiClient;
  late _MockGroupRepository mockGroupRepo;
  late _MockUserProfileRepository mockUserProfileRepo;
  late _MockE2EEService mockE2EEService;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = _MockRelayApiClient();
    mockGroupRepo = _MockGroupRepository();
    mockUserProfileRepo = _MockUserProfileRepository();
    mockE2EEService = _MockE2EEService();

    container = ProviderContainer(
      overrides: [
        relayApiClientProvider.overrideWithValue(mockApiClient),
        groupRepositoryProvider.overrideWithValue(mockGroupRepo),
        userProfileRepositoryProvider.overrideWithValue(mockUserProfileRepo),
        e2eeServiceProvider.overrideWithValue(mockE2EEService),
      ],
    );
  });

  tearDown(() => container.dispose());

  group(
    'family_sync/avatar_sync_providers characterization tests (pre-refactor behavior)',
    () {
      test(
        'syncAvatarUseCaseProvider constructs SyncAvatarUseCase without error',
        () {
          final useCase = container.read(syncAvatarUseCaseProvider);
          expect(useCase, isA<SyncAvatarUseCase>());
        },
      );

      test('syncAvatarUseCaseProvider returns non-null instance', () {
        expect(container.read(syncAvatarUseCaseProvider), isNotNull);
      });
    },
  );
}

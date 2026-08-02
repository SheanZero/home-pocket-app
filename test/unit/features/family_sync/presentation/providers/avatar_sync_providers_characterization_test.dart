import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart'
    show userProfileRepositoryProvider;
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockKeyManager extends Mock implements KeyManager {}

void main() {
  late _MockPushSyncUseCase mockPushSync;
  late _MockGroupRepository mockGroupRepo;
  late _MockUserProfileRepository mockUserProfileRepo;
  late _MockKeyManager mockKeyManager;
  late ProviderContainer container;

  setUp(() {
    mockPushSync = _MockPushSyncUseCase();
    mockGroupRepo = _MockGroupRepository();
    mockUserProfileRepo = _MockUserProfileRepository();
    mockKeyManager = _MockKeyManager();

    container = ProviderContainer(
      overrides: [
        pushSyncUseCaseProvider.overrideWithValue(mockPushSync),
        groupRepositoryProvider.overrideWithValue(mockGroupRepo),
        userProfileRepositoryProvider.overrideWithValue(mockUserProfileRepo),
        keyManagerProvider.overrideWithValue(mockKeyManager),
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

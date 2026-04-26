import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/profile/get_user_profile_use_case.dart';
import 'package:home_pocket/application/profile/repository_providers.dart'
    as app_profile;
import 'package:home_pocket/application/profile/save_user_profile_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/profile/presentation/providers/state_user_profile.dart';

// No external mocks needed — AppDatabase.forTesting() provides in-memory DB.
// UserProfileRepositoryImpl has no crypto deps.

void main() {
  late AppDatabase testDatabase;
  late ProviderContainer container;

  setUp(() {
    testDatabase = AppDatabase.forTesting();
    container = ProviderContainer(
      overrides: [
        app_profile.appAppDatabaseProvider.overrideWithValue(testDatabase),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await testDatabase.close();
  });

  group(
    'profile/user_profile_providers characterization tests (pre-refactor behavior)',
    () {
      test('userProfileDaoProvider constructs without error', () {
        final dao = container.read(userProfileDaoProvider);
        expect(dao, isNotNull);
      });

      test(
        'userProfileRepositoryProvider constructs UserProfileRepository',
        () {
          final repo = container.read(userProfileRepositoryProvider);
          expect(repo, isA<UserProfileRepository>());
        },
      );

      test('getUserProfileUseCaseProvider constructs without error', () {
        final uc = container.read(getUserProfileUseCaseProvider);
        expect(uc, isA<GetUserProfileUseCase>());
      });

      test('saveUserProfileUseCaseProvider constructs without error', () {
        final uc = container.read(saveUserProfileUseCaseProvider);
        expect(uc, isA<SaveUserProfileUseCase>());
      });

      test(
        'userProfileProvider future resolves to null when no profile stored',
        () async {
          final profile = await container.read(userProfileProvider.future);
          // No profile has been saved — should resolve to null
          expect(profile, isNull);
        },
      );

      test('all DI providers return non-null instances', () {
        expect(container.read(userProfileRepositoryProvider), isNotNull);
        expect(container.read(getUserProfileUseCaseProvider), isNotNull);
        expect(container.read(saveUserProfileUseCaseProvider), isNotNull);
      });
    },
  );
}

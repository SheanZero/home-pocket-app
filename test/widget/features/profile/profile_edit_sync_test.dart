import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/profile/save_user_profile_use_case.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_localizations.dart';

class _MemoryProfileRepository implements UserProfileRepository {
  _MemoryProfileRepository(this.profile);

  UserProfile? profile;

  @override
  Future<UserProfile?> find() async => profile;

  @override
  Future<void> save(UserProfile profile) async {
    this.profile = profile;
  }

  @override
  Future<void> delete(String id) async {
    if (profile?.id == id) profile = null;
  }
}

class _MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  testWidgets('successful profile edit explicitly schedules family sync', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 1);
    final profile = UserProfile(
      id: 'profile-1',
      displayName: 'Before',
      avatarEmoji: '🐱',
      createdAt: now,
      updatedAt: now,
    );
    final repository = _MemoryProfileRepository(profile);
    final syncEngine = _MockSyncEngine();
    when(syncEngine.onProfileChanged).thenReturn(null);

    await tester.pumpWidget(
      createLocalizedWidget(
        ProfileEditScreen(profile: profile),
        locale: const Locale('en'),
        overrides: [
          saveUserProfileUseCaseProvider.overrideWith(
            (ref) => SaveUserProfileUseCase(repository),
          ),
          syncEngineProvider.overrideWithValue(syncEngine),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final nameField = find.byType(TextField);
    await tester.enterText(nameField, 'After');
    final l10n = S.of(tester.element(find.byType(ProfileEditScreen)));
    await tester.tap(find.text(l10n.profileSave));
    await tester.pump();

    expect(repository.profile?.displayName, 'After');
    verify(syncEngine.onProfileChanged).called(1);
  });
}

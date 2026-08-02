import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/profile/save_user_profile_use_case.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/infrastructure/sync/avatar_semantic_staging_store.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockAvatarSemanticStagingStore extends Mock
    implements AvatarSemanticStagingStore {}

class FakeUserProfile extends Fake implements UserProfile {}

void main() {
  late MockUserProfileRepository repository;
  late SaveUserProfileUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakeUserProfile());
  });

  setUp(() {
    repository = MockUserProfileRepository();
    useCase = SaveUserProfileUseCase(repository);
  });

  group('SaveUserProfileUseCase', () {
    test('saves a valid profile', () async {
      when(() => repository.save(any())).thenAnswer((_) async {});
      when(() => repository.find()).thenAnswer((_) async => null);

      final result = await useCase.execute(
        displayName: '  たけし  ',
        avatarEmoji: '🐱',
      );

      expect(result.isSuccess, isTrue);
      expect(result.profile, isNotNull);
      expect(result.profile!.displayName, 'たけし');
      verify(() => repository.save(any())).called(1);
    });

    test('triggers profile sync only after the local save succeeds', () async {
      final events = <String>[];
      when(() => repository.save(any())).thenAnswer((_) async {
        events.add('saved');
      });
      when(() => repository.find()).thenAnswer((_) async => null);

      final result = await useCase.execute(
        displayName: 'たけし',
        avatarEmoji: '🐱',
        onSaved: () => events.add('sync'),
      );

      expect(result.isSuccess, isTrue);
      expect(events, ['saved', 'sync']);
    });

    test(
      'sync trigger failure never rolls back the saved local profile',
      () async {
        when(() => repository.save(any())).thenAnswer((_) async {});
        when(() => repository.find()).thenAnswer((_) async => null);

        final result = await useCase.execute(
          displayName: 'たけし',
          avatarEmoji: '🐱',
          onSaved: () => throw StateError('scheduler unavailable'),
        );

        expect(result.isSuccess, isTrue);
        verify(() => repository.save(any())).called(1);
      },
    );

    test('saves a valid icon-library avatar', () async {
      when(() => repository.save(any())).thenAnswer((_) async {});
      when(() => repository.find()).thenAnswer((_) async => null);

      final result = await useCase.execute(
        displayName: 'たけし',
        avatarEmoji: 'icon:cat',
      );

      expect(result.isSuccess, isTrue);
      expect(result.profile?.avatarEmoji, 'icon:cat');
      verify(() => repository.save(any())).called(1);
    });

    test(
      'new profile without an image skips avatar staging maintenance',
      () async {
        final stagingStore = MockAvatarSemanticStagingStore();
        useCase = SaveUserProfileUseCase(
          repository,
          avatarStagingStore: stagingStore,
        );
        when(() => repository.save(any())).thenAnswer((_) async {});

        final result = await useCase.execute(
          displayName: 'たけし',
          avatarEmoji: 'icon:cat',
        );

        expect(result.isSuccess, isTrue);
        verify(() => repository.save(any())).called(1);
        verifyNoMoreInteractions(stagingStore);
      },
    );

    test('rejects empty display name', () async {
      final result = await useCase.execute(
        displayName: '   ',
        avatarEmoji: '🐱',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, SaveProfileError.nameRequired);
      verifyNever(() => repository.save(any()));
    });

    test('rejects display name over 50 chars', () async {
      final result = await useCase.execute(
        displayName: 'あ' * 51,
        avatarEmoji: '🐱',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, SaveProfileError.nameTooLong);
      verifyNever(() => repository.save(any()));
    });

    test('rejects emoji not in warmEmojis list', () async {
      final result = await useCase.execute(
        displayName: 'たけし',
        avatarEmoji: '💀',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, SaveProfileError.invalidEmoji);
      verifyNever(() => repository.save(any()));
    });

    test('updates existing profile when id is provided', () async {
      final original = UserProfile(
        id: 'existing-id',
        displayName: 'たけし',
        avatarEmoji: '🐱',
        createdAt: DateTime(2026, 4, 3, 9, 0),
        updatedAt: DateTime(2026, 4, 3, 9, 0),
      );

      when(() => repository.find()).thenAnswer((_) async => original);
      when(() => repository.save(any())).thenAnswer((_) async {});

      final result = await useCase.execute(
        id: 'existing-id',
        displayName: 'はなこ',
        avatarEmoji: '🌸',
        avatarImagePath: '/path/to/photo.jpg',
      );

      expect(result.isSuccess, isTrue);
      final saved =
          verify(() => repository.save(captureAny())).captured.single
              as UserProfile;
      expect(saved.id, 'existing-id');
      expect(saved.displayName, 'はなこ');
      expect(saved.avatarEmoji, '🌸');
      expect(saved.avatarImagePath, '/path/to/photo.jpg');
      expect(saved.createdAt, original.createdAt);
    });
  });
}

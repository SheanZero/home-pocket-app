// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userProfileDao)
final userProfileDaoProvider = UserProfileDaoProvider._();

final class UserProfileDaoProvider
    extends $FunctionalProvider<UserProfileDao, UserProfileDao, UserProfileDao>
    with $Provider<UserProfileDao> {
  UserProfileDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileDaoHash();

  @$internal
  @override
  $ProviderElement<UserProfileDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserProfileDao create(Ref ref) {
    return userProfileDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfileDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfileDao>(value),
    );
  }
}

String _$userProfileDaoHash() => r'd9a359d6beb634a42f14ac5130a1e3d335077faf';

@ProviderFor(userProfileRepository)
final userProfileRepositoryProvider = UserProfileRepositoryProvider._();

final class UserProfileRepositoryProvider
    extends
        $FunctionalProvider<
          UserProfileRepository,
          UserProfileRepository,
          UserProfileRepository
        >
    with $Provider<UserProfileRepository> {
  UserProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserProfileRepository create(Ref ref) {
    return userProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfileRepository>(value),
    );
  }
}

String _$userProfileRepositoryHash() =>
    r'a69dc80e58d07581786075b7fc7cb6bb7ba252c8';

@ProviderFor(getUserProfileUseCase)
final getUserProfileUseCaseProvider = GetUserProfileUseCaseProvider._();

final class GetUserProfileUseCaseProvider
    extends
        $FunctionalProvider<
          GetUserProfileUseCase,
          GetUserProfileUseCase,
          GetUserProfileUseCase
        >
    with $Provider<GetUserProfileUseCase> {
  GetUserProfileUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getUserProfileUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getUserProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetUserProfileUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetUserProfileUseCase create(Ref ref) {
    return getUserProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetUserProfileUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetUserProfileUseCase>(value),
    );
  }
}

String _$getUserProfileUseCaseHash() =>
    r'cf982f6518f6afaacf6572efac8668b99ce2137b';

@ProviderFor(saveUserProfileUseCase)
final saveUserProfileUseCaseProvider = SaveUserProfileUseCaseProvider._();

final class SaveUserProfileUseCaseProvider
    extends
        $FunctionalProvider<
          SaveUserProfileUseCase,
          SaveUserProfileUseCase,
          SaveUserProfileUseCase
        >
    with $Provider<SaveUserProfileUseCase> {
  SaveUserProfileUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveUserProfileUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveUserProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveUserProfileUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveUserProfileUseCase create(Ref ref) {
    return saveUserProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveUserProfileUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveUserProfileUseCase>(value),
    );
  }
}

String _$saveUserProfileUseCaseHash() =>
    r'13e0a735aa3c0b7a9d908f5df9fbb22695713df2';

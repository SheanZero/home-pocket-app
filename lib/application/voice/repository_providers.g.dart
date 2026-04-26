// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appSpeechRecognitionServiceHash() =>
    r'059e8bca12f8a2a685d5667da5c8beed0e9b470d';

/// Application-layer SpeechRecognitionService provider.
///
/// Uses `app` prefix to avoid collision with any future feature-side definition
/// during Wave 2/3 coexistence (per Warning 7 fix).
///
/// Copied from [appSpeechRecognitionService].
@ProviderFor(appSpeechRecognitionService)
final appSpeechRecognitionServiceProvider =
    AutoDisposeProvider<SpeechRecognitionService>.internal(
      appSpeechRecognitionService,
      name: r'appSpeechRecognitionServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appSpeechRecognitionServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppSpeechRecognitionServiceRef =
    AutoDisposeProviderRef<SpeechRecognitionService>;
String _$startSpeechRecognitionUseCaseHash() =>
    r'2449977d8e6c57f2b0370fdaf039c21d703b25c7';

/// Application-layer StartSpeechRecognitionUseCase provider.
///
/// Copied from [startSpeechRecognitionUseCase].
@ProviderFor(startSpeechRecognitionUseCase)
final startSpeechRecognitionUseCaseProvider =
    AutoDisposeProvider<StartSpeechRecognitionUseCase>.internal(
      startSpeechRecognitionUseCase,
      name: r'startSpeechRecognitionUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$startSpeechRecognitionUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StartSpeechRecognitionUseCaseRef =
    AutoDisposeProviderRef<StartSpeechRecognitionUseCase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

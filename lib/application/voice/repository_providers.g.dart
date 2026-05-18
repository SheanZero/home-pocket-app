// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application-layer SpeechRecognitionService provider.
///
/// Uses `app` prefix to avoid collision with any future feature-side definition
/// during Wave 2/3 coexistence (per Warning 7 fix).

@ProviderFor(appSpeechRecognitionService)
final appSpeechRecognitionServiceProvider =
    AppSpeechRecognitionServiceProvider._();

/// Application-layer SpeechRecognitionService provider.
///
/// Uses `app` prefix to avoid collision with any future feature-side definition
/// during Wave 2/3 coexistence (per Warning 7 fix).

final class AppSpeechRecognitionServiceProvider
    extends
        $FunctionalProvider<
          SpeechRecognitionService,
          SpeechRecognitionService,
          SpeechRecognitionService
        >
    with $Provider<SpeechRecognitionService> {
  /// Application-layer SpeechRecognitionService provider.
  ///
  /// Uses `app` prefix to avoid collision with any future feature-side definition
  /// during Wave 2/3 coexistence (per Warning 7 fix).
  AppSpeechRecognitionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSpeechRecognitionServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSpeechRecognitionServiceHash();

  @$internal
  @override
  $ProviderElement<SpeechRecognitionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SpeechRecognitionService create(Ref ref) {
    return appSpeechRecognitionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpeechRecognitionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpeechRecognitionService>(value),
    );
  }
}

String _$appSpeechRecognitionServiceHash() =>
    r'059e8bca12f8a2a685d5667da5c8beed0e9b470d';

/// Application-layer StartSpeechRecognitionUseCase provider.

@ProviderFor(startSpeechRecognitionUseCase)
final startSpeechRecognitionUseCaseProvider =
    StartSpeechRecognitionUseCaseProvider._();

/// Application-layer StartSpeechRecognitionUseCase provider.

final class StartSpeechRecognitionUseCaseProvider
    extends
        $FunctionalProvider<
          StartSpeechRecognitionUseCase,
          StartSpeechRecognitionUseCase,
          StartSpeechRecognitionUseCase
        >
    with $Provider<StartSpeechRecognitionUseCase> {
  /// Application-layer StartSpeechRecognitionUseCase provider.
  StartSpeechRecognitionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startSpeechRecognitionUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startSpeechRecognitionUseCaseHash();

  @$internal
  @override
  $ProviderElement<StartSpeechRecognitionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StartSpeechRecognitionUseCase create(Ref ref) {
    return startSpeechRecognitionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartSpeechRecognitionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartSpeechRecognitionUseCase>(
        value,
      ),
    );
  }
}

String _$startSpeechRecognitionUseCaseHash() =>
    r'2449977d8e6c57f2b0370fdaf039c21d703b25c7';

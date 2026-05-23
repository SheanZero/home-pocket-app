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

/// Chinese numeral state machine — stateless, const constructor.
///
/// Provides ChineseNumeralStateMachine for injection into VoiceChunkMerger.
/// The merger itself is per-recording-session and constructed inline in
/// VoiceInputScreen (Plan 20-09) — only the stateless machines are provided here.

@ProviderFor(chineseNumeralStateMachine)
final chineseNumeralStateMachineProvider =
    ChineseNumeralStateMachineProvider._();

/// Chinese numeral state machine — stateless, const constructor.
///
/// Provides ChineseNumeralStateMachine for injection into VoiceChunkMerger.
/// The merger itself is per-recording-session and constructed inline in
/// VoiceInputScreen (Plan 20-09) — only the stateless machines are provided here.

final class ChineseNumeralStateMachineProvider
    extends
        $FunctionalProvider<
          ChineseNumeralStateMachine,
          ChineseNumeralStateMachine,
          ChineseNumeralStateMachine
        >
    with $Provider<ChineseNumeralStateMachine> {
  /// Chinese numeral state machine — stateless, const constructor.
  ///
  /// Provides ChineseNumeralStateMachine for injection into VoiceChunkMerger.
  /// The merger itself is per-recording-session and constructed inline in
  /// VoiceInputScreen (Plan 20-09) — only the stateless machines are provided here.
  ChineseNumeralStateMachineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chineseNumeralStateMachineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chineseNumeralStateMachineHash();

  @$internal
  @override
  $ProviderElement<ChineseNumeralStateMachine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChineseNumeralStateMachine create(Ref ref) {
    return chineseNumeralStateMachine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChineseNumeralStateMachine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChineseNumeralStateMachine>(value),
    );
  }
}

String _$chineseNumeralStateMachineHash() =>
    r'49c9b80fcdbb189ba51caefb58b0affdbf725fed';

/// Japanese numeral state machine — stateless but non-const due to static
/// sorted-keys initialization at first use.

@ProviderFor(japaneseNumeralStateMachine)
final japaneseNumeralStateMachineProvider =
    JapaneseNumeralStateMachineProvider._();

/// Japanese numeral state machine — stateless but non-const due to static
/// sorted-keys initialization at first use.

final class JapaneseNumeralStateMachineProvider
    extends
        $FunctionalProvider<
          JapaneseNumeralStateMachine,
          JapaneseNumeralStateMachine,
          JapaneseNumeralStateMachine
        >
    with $Provider<JapaneseNumeralStateMachine> {
  /// Japanese numeral state machine — stateless but non-const due to static
  /// sorted-keys initialization at first use.
  JapaneseNumeralStateMachineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'japaneseNumeralStateMachineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$japaneseNumeralStateMachineHash();

  @$internal
  @override
  $ProviderElement<JapaneseNumeralStateMachine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JapaneseNumeralStateMachine create(Ref ref) {
    return japaneseNumeralStateMachine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JapaneseNumeralStateMachine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JapaneseNumeralStateMachine>(value),
    );
  }
}

String _$japaneseNumeralStateMachineHash() =>
    r'6fc88d9818b85335affa91697207ad8f3bc56c61';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ruleEngine)
final ruleEngineProvider = RuleEngineProvider._();

final class RuleEngineProvider
    extends $FunctionalProvider<RuleEngine, RuleEngine, RuleEngine>
    with $Provider<RuleEngine> {
  RuleEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ruleEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleEngineHash();

  @$internal
  @override
  $ProviderElement<RuleEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RuleEngine create(Ref ref) {
    return ruleEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RuleEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RuleEngine>(value),
    );
  }
}

String _$ruleEngineHash() => r'99a9cb2e188a388a61aeda76ae909fcd910708ae';

@ProviderFor(classificationService)
final classificationServiceProvider = ClassificationServiceProvider._();

final class ClassificationServiceProvider
    extends
        $FunctionalProvider<
          ClassificationService,
          ClassificationService,
          ClassificationService
        >
    with $Provider<ClassificationService> {
  ClassificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classificationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classificationServiceHash();

  @$internal
  @override
  $ProviderElement<ClassificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClassificationService create(Ref ref) {
    return classificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassificationService>(value),
    );
  }
}

String _$classificationServiceHash() =>
    r'4096115d38aac706f4bb6caa14d825876a87269b';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$merchantDatabaseHash() => r'80e5be892dd258e0985ed76d137e924433721943';

/// MerchantDatabase — keepAlive because it holds an in-memory seed dataset.
/// Instantiated once and reused across the app session.
///
/// Copied from [merchantDatabase].
@ProviderFor(merchantDatabase)
final merchantDatabaseProvider = Provider<MerchantDatabase>.internal(
  merchantDatabase,
  name: r'merchantDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$merchantDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MerchantDatabaseRef = ProviderRef<MerchantDatabase>;
String _$voiceTextParserHash() => r'3493d74d0200f77486db448b8fc371a0fb3030fd';

/// VoiceTextParser — stateless NLP parser, auto-disposed when not in use.
///
/// Copied from [voiceTextParser].
@ProviderFor(voiceTextParser)
final voiceTextParserProvider = AutoDisposeProvider<VoiceTextParser>.internal(
  voiceTextParser,
  name: r'voiceTextParserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$voiceTextParserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VoiceTextParserRef = AutoDisposeProviderRef<VoiceTextParser>;
String _$categoryMatcherHash() => r'9c3f48b4d90fbf37c4a17e8a8a5c0d9b16a9acc8';

/// CategoryMatcher — wired to existing categoryRepository and categoryService.
///
/// Uses existing providers from repository_providers.dart and
/// use_case_providers.dart. Does NOT redefine categoryServiceProvider.
///
/// Copied from [categoryMatcher].
@ProviderFor(categoryMatcher)
final categoryMatcherProvider = AutoDisposeProvider<CategoryMatcher>.internal(
  categoryMatcher,
  name: r'categoryMatcherProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$categoryMatcherHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoryMatcherRef = AutoDisposeProviderRef<CategoryMatcher>;
String _$parseVoiceInputUseCaseHash() =>
    r'535bbe5ad584ac13ec2cc72ae17ce36026cb46bb';

/// ParseVoiceInputUseCase — wired to all voice application services.
///
/// Copied from [parseVoiceInputUseCase].
@ProviderFor(parseVoiceInputUseCase)
final parseVoiceInputUseCaseProvider =
    AutoDisposeProvider<ParseVoiceInputUseCase>.internal(
      parseVoiceInputUseCase,
      name: r'parseVoiceInputUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$parseVoiceInputUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ParseVoiceInputUseCaseRef =
    AutoDisposeProviderRef<ParseVoiceInputUseCase>;
String _$voiceSatisfactionEstimatorHash() =>
    r'633b00ee3ba24d00f0bf477ac217841dbcb2db4c';

/// VoiceSatisfactionEstimator — pure stateless class.
///
/// Copied from [voiceSatisfactionEstimator].
@ProviderFor(voiceSatisfactionEstimator)
final voiceSatisfactionEstimatorProvider =
    AutoDisposeProvider<VoiceSatisfactionEstimator>.internal(
      voiceSatisfactionEstimator,
      name: r'voiceSatisfactionEstimatorProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$voiceSatisfactionEstimatorHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VoiceSatisfactionEstimatorRef =
    AutoDisposeProviderRef<VoiceSatisfactionEstimator>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

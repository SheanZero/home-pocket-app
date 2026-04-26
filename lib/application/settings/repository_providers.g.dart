// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appAppDatabaseHash() => r'a93923f0b7e30eae84d8cfca4e7b57a0bd619890';

/// Application-layer re-export of [AppDatabase].
///
/// Settings feature presentation imports this instead of
/// infrastructure/security/providers.dart (HIGH-02 compliance).
///
/// NOTE: Settings feature currently does not import appDatabase directly,
/// but this file provides the canonical application-layer DI surface for
/// the settings feature (HIGH-02 prep, consumed by Plan 04-02).
///
/// Copied from [appAppDatabase].
@ProviderFor(appAppDatabase)
final appAppDatabaseProvider = AutoDisposeProvider<AppDatabase>.internal(
  appAppDatabase,
  name: r'appAppDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appAppDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppAppDatabaseRef = AutoDisposeProviderRef<AppDatabase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeGroupHash() => r'2658de6c11b33ebe061ae2029efa8b8039387a64';

/// Watches the local database for an active group.
///
/// Emits [GroupInfo] when device is in an active group, null otherwise.
/// Pure local DB stream — zero network calls.
///
/// Copied from [activeGroup].
@ProviderFor(activeGroup)
final activeGroupProvider = StreamProvider<GroupInfo?>.internal(
  activeGroup,
  name: r'activeGroupProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeGroupHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveGroupRef = StreamProviderRef<GroupInfo?>;
String _$isGroupModeHash() => r'adf89497a639cf0320d42c20b435be16f24b97f2';

/// Whether device is currently in an active group.
///
/// Derived from [activeGroupProvider]. Used for conditional UI
/// (banner visibility, mode badge text).
///
/// Copied from [isGroupMode].
@ProviderFor(isGroupMode)
final isGroupModeProvider = Provider<bool>.internal(
  isGroupMode,
  name: r'isGroupModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isGroupModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsGroupModeRef = ProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

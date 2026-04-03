// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedTabIndexHash() => r'f53863ea10a26a883f6e835fa78f66eb7997249d';

/// Global bottom navigation tab index state.
///
/// Defaults to 0 (Home tab). Kept alive so the tab selection
/// persists across navigation events within the shell.
///
/// Copied from [SelectedTabIndex].
@ProviderFor(SelectedTabIndex)
final selectedTabIndexProvider =
    NotifierProvider<SelectedTabIndex, int>.internal(
      SelectedTabIndex.new,
      name: r'selectedTabIndexProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedTabIndexHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedTabIndex = Notifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

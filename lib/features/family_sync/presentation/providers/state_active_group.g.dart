// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_active_group.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches the local database for an active group.
///
/// Emits [GroupInfo] when device is in an active group, null otherwise.
/// Pure local DB stream — zero network calls.

@ProviderFor(activeGroup)
final activeGroupProvider = ActiveGroupProvider._();

/// Watches the local database for an active group.
///
/// Emits [GroupInfo] when device is in an active group, null otherwise.
/// Pure local DB stream — zero network calls.

final class ActiveGroupProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupInfo?>,
          GroupInfo?,
          Stream<GroupInfo?>
        >
    with $FutureModifier<GroupInfo?>, $StreamProvider<GroupInfo?> {
  /// Watches the local database for an active group.
  ///
  /// Emits [GroupInfo] when device is in an active group, null otherwise.
  /// Pure local DB stream — zero network calls.
  ActiveGroupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeGroupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeGroupHash();

  @$internal
  @override
  $StreamProviderElement<GroupInfo?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<GroupInfo?> create(Ref ref) {
    return activeGroup(ref);
  }
}

String _$activeGroupHash() => r'2658de6c11b33ebe061ae2029efa8b8039387a64';

/// Whether device is currently in an active group.
///
/// Derived from [activeGroupProvider]. Used for conditional UI
/// (banner visibility, mode badge text).

@ProviderFor(isGroupMode)
final isGroupModeProvider = IsGroupModeProvider._();

/// Whether device is currently in an active group.
///
/// Derived from [activeGroupProvider]. Used for conditional UI
/// (banner visibility, mode badge text).

final class IsGroupModeProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether device is currently in an active group.
  ///
  /// Derived from [activeGroupProvider]. Used for conditional UI
  /// (banner visibility, mode badge text).
  IsGroupModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isGroupModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isGroupModeHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isGroupMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isGroupModeHash() => r'7aa524c4340066894fb0b30ca08817a49bcee2d8';

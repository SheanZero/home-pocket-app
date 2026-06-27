// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_reset_signal.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global, feature-agnostic signal fired after a destructive whole-app data
/// operation (delete-all-data / import-backup) succeeds.
///
/// The state is a monotonic counter; [fire] increments it, notifying every
/// listener exactly once per call. The app root (`_HomePocketAppState`)
/// `ref.listen`s this provider and runs a single shared re-bootstrap routine
/// (re-seed → ensure default book → invalidate all data providers → setState the
/// fresh bookId), so clear-all and import both refresh the UI without an app
/// restart and without duplicating the refresh logic.
///
/// Lives in `lib/core/state/` because it is cross-cutting (not owned by any one
/// feature), alongside the other cross-cutting `core/` concerns.

@ProviderFor(DataResetSignal)
final dataResetSignalProvider = DataResetSignalProvider._();

/// Global, feature-agnostic signal fired after a destructive whole-app data
/// operation (delete-all-data / import-backup) succeeds.
///
/// The state is a monotonic counter; [fire] increments it, notifying every
/// listener exactly once per call. The app root (`_HomePocketAppState`)
/// `ref.listen`s this provider and runs a single shared re-bootstrap routine
/// (re-seed → ensure default book → invalidate all data providers → setState the
/// fresh bookId), so clear-all and import both refresh the UI without an app
/// restart and without duplicating the refresh logic.
///
/// Lives in `lib/core/state/` because it is cross-cutting (not owned by any one
/// feature), alongside the other cross-cutting `core/` concerns.
final class DataResetSignalProvider
    extends $NotifierProvider<DataResetSignal, int> {
  /// Global, feature-agnostic signal fired after a destructive whole-app data
  /// operation (delete-all-data / import-backup) succeeds.
  ///
  /// The state is a monotonic counter; [fire] increments it, notifying every
  /// listener exactly once per call. The app root (`_HomePocketAppState`)
  /// `ref.listen`s this provider and runs a single shared re-bootstrap routine
  /// (re-seed → ensure default book → invalidate all data providers → setState the
  /// fresh bookId), so clear-all and import both refresh the UI without an app
  /// restart and without duplicating the refresh logic.
  ///
  /// Lives in `lib/core/state/` because it is cross-cutting (not owned by any one
  /// feature), alongside the other cross-cutting `core/` concerns.
  DataResetSignalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataResetSignalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataResetSignalHash();

  @$internal
  @override
  DataResetSignal create() => DataResetSignal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$dataResetSignalHash() => r'321b205257d6cbe8155983d61d6c343e751855b2';

/// Global, feature-agnostic signal fired after a destructive whole-app data
/// operation (delete-all-data / import-backup) succeeds.
///
/// The state is a monotonic counter; [fire] increments it, notifying every
/// listener exactly once per call. The app root (`_HomePocketAppState`)
/// `ref.listen`s this provider and runs a single shared re-bootstrap routine
/// (re-seed → ensure default book → invalidate all data providers → setState the
/// fresh bookId), so clear-all and import both refresh the UI without an app
/// restart and without duplicating the refresh logic.
///
/// Lives in `lib/core/state/` because it is cross-cutting (not owned by any one
/// feature), alongside the other cross-cutting `core/` concerns.

abstract class _$DataResetSignal extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

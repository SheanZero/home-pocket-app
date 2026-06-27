import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_reset_signal.g.dart';

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
@riverpod
class DataResetSignal extends _$DataResetSignal {
  @override
  int build() => 0;

  /// Notify listeners that a whole-app data reset has completed.
  void fire() => state = state + 1;
}

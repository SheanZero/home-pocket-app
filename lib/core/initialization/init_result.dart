import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'init_result.freezed.dart';

enum InitFailureType {
  masterKey,

  /// The master key is absent but an encrypted database already exists on disk.
  ///
  /// Generating a fresh random master key in this state would permanently
  /// orphan the existing data (the old database is encrypted with the old,
  /// now-unreadable key). Initialization fails loud instead of destroying data.
  masterKeyMissingWithData,

  database,
  seed,
  unknown,
}

/// Raised when the master key cannot be found but an encrypted database is
/// still present on disk.
///
/// This is the guard against silent data loss: a missing key usually means
/// "first launch", but if a database file exists it instead means the key read
/// failed (locked device, changed keychain access group, transient keychain
/// error). Minting a new key would orphan the existing data, so we surface this
/// error and let the user retry (e.g. after unlocking) or run recovery.
class MasterKeyMissingWithExistingDataError implements Exception {
  const MasterKeyMissingWithExistingDataError();

  @override
  String toString() =>
      'MasterKeyMissingWithExistingDataError: an encrypted database exists but '
      'the master key is missing; refusing to generate a new key to avoid '
      'permanent data loss.';
}

@freezed
sealed class InitResult with _$InitResult {
  const factory InitResult.success({required ProviderContainer container}) =
      InitSuccess;

  const factory InitResult.failure({
    required InitFailureType type,
    required Object error,
    StackTrace? stackTrace,
  }) = InitFailure;
}

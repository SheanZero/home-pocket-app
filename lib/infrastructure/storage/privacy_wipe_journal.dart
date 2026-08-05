/// Durable recovery boundary identifying the next privacy-wipe step.
///
/// A pending stage is intentionally replayed after a crash. For example, if
/// the database transaction committed but the process died before the journal
/// advanced, [databasePending] causes the idempotent database wipe to run
/// again.
enum PrivacyWipeJournalStage {
  databasePending('dbPending'),
  filesPending('filesPending'),
  secureUserDataPending('securePending'),
  settingsPending('settingsPending'),
  memoryPending('memoryPending');

  const PrivacyWipeJournalStage(this.wireName);

  final String wireName;

  static PrivacyWipeJournalStage fromWireName(String value) {
    for (final stage in values) {
      if (stage.wireName == value) return stage;
    }
    throw PrivacyWipeJournalCorruptException('Unknown journal stage.');
  }
}

/// Non-sensitive, versioned privacy-wipe recovery record.
class PrivacyWipeJournalEntry {
  const PrivacyWipeJournalEntry({
    required this.version,
    required this.stage,
    required this.updatedAtEpochMs,
    required this.checksum,
  });

  final int version;
  final PrivacyWipeJournalStage stage;
  final int updatedAtEpochMs;
  final String checksum;
}

/// Persistence boundary for the cross-resource privacy wipe.
abstract interface class PrivacyWipeJournalStore {
  /// Stable process-wide key used to coalesce manual and startup recovery.
  String get coordinationKey;

  Future<PrivacyWipeJournalEntry?> read();

  Future<void> write(PrivacyWipeJournalEntry entry);

  Future<void> delete();

  PrivacyWipeJournalEntry newEntry(PrivacyWipeJournalStage stage);
}

/// Fail-closed signal for malformed, tampered, or future-version journals.
class PrivacyWipeJournalCorruptException implements Exception {
  const PrivacyWipeJournalCorruptException(this.message);

  final String message;

  @override
  String toString() => 'PrivacyWipeJournalCorruptException: $message';
}

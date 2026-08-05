import 'package:home_pocket/infrastructure/storage/privacy_wipe_journal.dart';

/// Lightweight journal for isolated unit tests.
///
/// Production composition must use a persistent implementation. Keeping this
/// explicit in constructors prevents accidental volatile production wiring.
class InMemoryPrivacyWipeJournalStore implements PrivacyWipeJournalStore {
  InMemoryPrivacyWipeJournalStore({String? coordinationKey})
    : _coordinationKey =
          coordinationKey ?? 'memory-privacy-wipe-${_nextCoordinationId++}';

  static int _nextCoordinationId = 0;

  final String _coordinationKey;
  PrivacyWipeJournalEntry? _entry;

  @override
  String get coordinationKey => _coordinationKey;

  @override
  Future<void> delete() async => _entry = null;

  @override
  PrivacyWipeJournalEntry newEntry(PrivacyWipeJournalStage stage) =>
      PrivacyWipeJournalEntry(
        version: 1,
        stage: stage,
        updatedAtEpochMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        checksum: 'in-memory',
      );

  @override
  Future<PrivacyWipeJournalEntry?> read() async => _entry;

  @override
  Future<void> write(PrivacyWipeJournalEntry entry) async => _entry = entry;
}


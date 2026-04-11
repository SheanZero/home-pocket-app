import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';

void main() {
  group('SyncState', () {
    test('has all required values', () {
      expect(
        SyncState.values,
        containsAll([
          SyncState.noGroup,
          SyncState.idle,
          SyncState.initialSyncing,
          SyncState.syncing,
          SyncState.synced,
          SyncState.error,
          SyncState.queuedOffline,
        ]),
      );
    });
  });

  group('SyncMode', () {
    test('has correct priority ordering', () {
      expect(
        SyncMode.initialSync.priority,
        lessThan(SyncMode.fullPull.priority),
      );
      expect(
        SyncMode.fullPull.priority,
        lessThan(SyncMode.incrementalPush.priority),
      );
      expect(
        SyncMode.incrementalPush.priority,
        equals(SyncMode.incrementalPull.priority),
      );
      expect(
        SyncMode.incrementalPull.priority,
        lessThan(SyncMode.profileSync.priority),
      );
    });
  });

  group('SyncStatus', () {
    test('creates with required state', () {
      const status = SyncStatus(state: SyncState.idle);
      expect(status.state, SyncState.idle);
      expect(status.lastSyncAt, isNull);
      expect(status.pendingQueueCount, isNull);
      expect(status.errorMessage, isNull);
    });

    test('copyWith preserves immutability', () {
      const original = SyncStatus(state: SyncState.idle);
      final updated = original.copyWith(state: SyncState.syncing);
      expect(original.state, SyncState.idle);
      expect(updated.state, SyncState.syncing);
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final status = SyncStatus(
        state: SyncState.queuedOffline,
        lastSyncAt: now,
        pendingQueueCount: 3,
        errorMessage: null,
      );
      expect(status.pendingQueueCount, 3);
      expect(status.lastSyncAt, now);
    });
  });
}

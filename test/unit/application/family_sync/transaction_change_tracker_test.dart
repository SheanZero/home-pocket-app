import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/transaction_change_tracker.dart';

void main() {
  group('TransactionChangeTracker', () {
    late TransactionChangeTracker tracker;

    setUp(() {
      tracker = TransactionChangeTracker();
    });

    group('trackUpdate', () {
      test('appends an update operation to pending ops', () {
        final op = {
          'op': 'update',
          'entityType': 'bill',
          'entityId': 'tx-001',
          'data': {'amount': 1000},
          'timestamp': '2026-01-01T00:00:00.000Z',
        };

        tracker.trackUpdate(op);

        expect(tracker.pendingCount, 1);
        final flushed = tracker.flush();
        expect(flushed.length, 1);
        expect(flushed.first, op);
      });

      test('trackUpdate shares the same pending queue as trackCreate', () {
        final createOp = {'op': 'create', 'entityId': 'tx-001'};
        final updateOp = {'op': 'update', 'entityId': 'tx-001'};

        tracker.trackCreate(createOp);
        tracker.trackUpdate(updateOp);

        expect(tracker.pendingCount, 2);
        final flushed = tracker.flush();
        expect(flushed.length, 2);
        expect(flushed[0], createOp);
        expect(flushed[1], updateOp);
      });

      test('flush returns update ops and clears the queue', () {
        final updateOp = {'op': 'update', 'entityId': 'tx-002'};
        tracker.trackUpdate(updateOp);

        final flushed = tracker.flush();
        expect(flushed.length, 1);
        expect(tracker.pendingCount, 0);
      });

      test('multiple trackUpdate calls accumulate in order', () {
        for (var i = 0; i < 3; i++) {
          tracker.trackUpdate({'op': 'update', 'entityId': 'tx-$i'});
        }

        expect(tracker.pendingCount, 3);
        final flushed = tracker.flush();
        expect(flushed[0]['entityId'], 'tx-0');
        expect(flushed[1]['entityId'], 'tx-1');
        expect(flushed[2]['entityId'], 'tx-2');
      });

      test('existing trackCreate and trackDelete methods still work', () {
        tracker.trackCreate({'op': 'create', 'entityId': 'tx-c'});
        tracker.trackDelete(transactionId: 'tx-d', bookId: 'book-001');

        expect(tracker.pendingCount, 2);
      });
    });
  });
}

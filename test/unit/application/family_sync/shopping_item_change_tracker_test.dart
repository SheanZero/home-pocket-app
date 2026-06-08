import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';

void main() {
  group('ShoppingItemChangeTracker', () {
    late ShoppingItemChangeTracker tracker;

    setUp(() {
      tracker = ShoppingItemChangeTracker();
    });

    group('trackUpdate', () {
      test('appends an update operation to pending ops', () {
        final op = {
          'op': 'update',
          'entityType': 'shopping_item',
          'entityId': 'item-001',
          'data': {'listType': 'public', 'name': 'Milk'},
          'timestamp': '2026-06-08T10:00:00.000Z',
        };

        tracker.trackUpdate(op);

        expect(tracker.pendingCount, 1);
        final flushed = tracker.flush();
        expect(flushed.length, 1);
        expect(flushed.first, op);
      });

      test('trackUpdate shares the same pending queue as trackCreate', () {
        final createOp = {
          'op': 'create',
          'entityId': 'item-001',
          'data': {'listType': 'public'},
        };
        final updateOp = {
          'op': 'update',
          'entityId': 'item-001',
          'data': {'listType': 'public'},
        };

        tracker.trackCreate(createOp);
        tracker.trackUpdate(updateOp);

        expect(tracker.pendingCount, 2);
        final flushed = tracker.flush();
        expect(flushed.length, 2);
        expect(flushed[0], createOp);
        expect(flushed[1], updateOp);
      });

      test('flush returns update ops and clears the queue', () {
        final updateOp = {
          'op': 'update',
          'entityId': 'item-002',
          'data': {'listType': 'public'},
        };
        tracker.trackUpdate(updateOp);

        final flushed = tracker.flush();
        expect(flushed.length, 1);
        expect(tracker.pendingCount, 0);
      });

      test('multiple trackUpdate calls accumulate in order', () {
        for (var i = 0; i < 3; i++) {
          tracker.trackUpdate({
            'op': 'update',
            'entityId': 'item-$i',
            'data': {'listType': 'public'},
          });
        }

        expect(tracker.pendingCount, 3);
        final flushed = tracker.flush();
        expect(flushed[0]['entityId'], 'item-0');
        expect(flushed[1]['entityId'], 'item-1');
        expect(flushed[2]['entityId'], 'item-2');
      });

      test('existing trackCreate and trackDelete methods still work', () {
        tracker.trackCreate({
          'op': 'create',
          'entityId': 'item-c',
          'data': {'listType': 'public'},
        });
        tracker.trackDelete(itemId: 'item-d');

        expect(tracker.pendingCount, 2);
      });
    });

    group('privacy gate (D37-06 second safety net)', () {
      test(
        'trackCreate ignores non-public listType (SC-3, SYNC-02)',
        () {
          tracker.trackCreate({
            'op': 'create',
            'entityType': 'shopping_item',
            'entityId': 'item-1',
            'data': {'listType': 'private', 'name': 'Secret'},
          });
          // private → NOT enqueued (second safety net, D37-06)
          expect(tracker.pendingCount, 0);
        },
      );

      test(
        'trackCreate accepts public listType (SC-3, SYNC-01)',
        () {
          tracker.trackCreate({
            'op': 'create',
            'entityType': 'shopping_item',
            'entityId': 'item-2',
            'data': {'listType': 'public', 'name': 'Milk'},
          });
          // public → enqueued
          expect(tracker.pendingCount, 1);
        },
      );

      test('trackUpdate ignores non-public listType', () {
        tracker.trackUpdate({'data': {'listType': 'private'}});
        expect(tracker.pendingCount, 0);
      });

      test(
        'trackDelete always enqueues (caller is responsible for gate)',
        () {
          // Delete ops have no listType in data; use-case gate is primary (D37-06)
          tracker.trackDelete(itemId: 'item-3');
          expect(tracker.pendingCount, 1);
        },
      );
    });
  });
}

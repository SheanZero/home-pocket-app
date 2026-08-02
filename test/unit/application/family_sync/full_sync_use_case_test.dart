import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

Map<String, dynamic> _txnOp(String id) => {
  'op': 'reconcile',
  'entityType': 'bill',
  'entityId': id,
  'revision': 100,
  'originDeviceId': 'device-a',
  'data': {'id': id, 'syncRevision': 100},
  'timestamp': 123,
};

Map<String, dynamic> _shoppingOp(String id, {required String listType}) => {
  'op': 'create',
  'entityType': 'shopping_item',
  'entityId': id,
  'data': {'id': id, 'listType': listType, 'name': 'Item $id'},
  'timestamp': '2026-06-08T10:00:00.000Z',
};

void main() {
  late MockPushSyncUseCase pushSync;

  setUp(() {
    pushSync = MockPushSyncUseCase();
    when(
      () => pushSync.execute(
        operations: any(named: 'operations'),
        vectorClock: any(named: 'vectorClock'),
        syncType: any(named: 'syncType'),
      ),
    ).thenAnswer((invocation) async {
      final ops =
          invocation.namedArguments[#operations] as List<Map<String, dynamic>>;
      return PushSyncResult.success(ops.length);
    });
  });

  FullSyncUseCase buildUseCase({
    List<Map<String, dynamic>> transactions = const [],
    List<Map<String, dynamic>> shoppingOps = const [],
  }) {
    return FullSyncUseCase(
      pushSync: pushSync,
      fetchAllTransactions: () async => transactions,
      fetchAllShoppingOps: () async => shoppingOps,
    );
  }

  List<Map<String, dynamic>> capturedPushedOps() {
    return verify(
      () => pushSync.execute(
        operations: captureAny(named: 'operations'),
        vectorClock: any(named: 'vectorClock'),
        syncType: any(named: 'syncType'),
      ),
    ).captured.expand((c) => c as List<Map<String, dynamic>>).toList();
  }

  test('passes syncType full when pushing full sync chunks', () async {
    final useCase = buildUseCase(transactions: [_txnOp('tx-1')]);

    final total = await useCase.execute();

    expect(total, 1);
    verify(
      () => pushSync.execute(
        operations: any(named: 'operations'),
        vectorClock: {'device-a': 100},
        syncType: 'full',
      ),
    ).called(1);
  });

  test('full sync keeps live state and only minimal tombstones', () async {
    final tombstone = {
      'op': 'delete',
      'entityType': 'bill',
      'entityId': 'tx-deleted',
      'data': {
        'isDeleted': true,
        'syncRevision': 200,
        'syncOriginDeviceId': 'device-a',
      },
      'revision': 200,
      'originDeviceId': 'device-a',
      'timestamp': 123,
    };
    final useCase = buildUseCase(transactions: [_txnOp('tx-live'), tombstone]);

    expect(await useCase.execute(), 2);

    final pushed = capturedPushedOps();
    expect(pushed.map((op) => op['op']), containsAll({'reconcile', 'delete'}));
    final deletedData =
        pushed.singleWhere((op) => op['entityId'] == 'tx-deleted')['data']
            as Map<String, dynamic>;
    expect(
      deletedData.keys,
      unorderedEquals({'isDeleted', 'syncRevision', 'syncOriginDeviceId'}),
    );
  });

  test(
    'full sync carries explicit local-only photo availability without a hash',
    () async {
      final photo = {
        ..._txnOp('tx-photo'),
        'data': {
          'id': 'tx-photo',
          'syncRevision': 100,
          'photoAvailability': 'local_only',
        },
      };
      final useCase = buildUseCase(transactions: [photo]);

      expect(await useCase.execute(), 1);
      final data = capturedPushedOps().single['data'] as Map<String, dynamic>;
      expect(data['photoAvailability'], 'local_only');
      expect(data, isNot(contains('photoHash')));
    },
  );

  test(
    'pushes transactions and public shopping ops in the same stream (W1)',
    () async {
      final useCase = buildUseCase(
        transactions: [_txnOp('tx-1'), _txnOp('tx-2'), _txnOp('tx-3')],
        shoppingOps: [
          _shoppingOp('item-1', listType: 'public'),
          _shoppingOp('item-2', listType: 'public'),
        ],
      );

      final total = await useCase.execute();

      expect(total, 5, reason: '3 txn ops + 2 public shopping ops');
      final pushed = capturedPushedOps();
      expect(pushed, hasLength(5));
      expect(
        pushed.where((op) => op['entityType'] == 'shopping_item'),
        hasLength(2),
      );
    },
  );

  test(
    'defense-in-depth: private shopping ops are filtered before push',
    () async {
      final useCase = buildUseCase(
        shoppingOps: [
          _shoppingOp('item-public', listType: 'public'),
          _shoppingOp('item-private', listType: 'private'),
        ],
      );

      final total = await useCase.execute();

      expect(total, 1, reason: 'private op excluded from pushed count');
      final pushed = capturedPushedOps();
      expect(pushed, hasLength(1));
      expect(pushed.single['entityId'], 'item-public');
    },
  );

  test(
    'zero transactions but public shopping ops present still pushes (W1)',
    () async {
      final useCase = buildUseCase(
        shoppingOps: [_shoppingOp('item-solo', listType: 'public')],
      );

      final total = await useCase.execute();

      expect(
        total,
        1,
        reason: 'empty-transactions early-exit must not swallow shopping ops',
      );
      final pushed = capturedPushedOps();
      expect(pushed.single['entityId'], 'item-solo');
    },
  );

  test('transactions-only path: chunks at 50, counts queued results', () async {
    when(
      () => pushSync.execute(
        operations: any(named: 'operations'),
        vectorClock: any(named: 'vectorClock'),
        syncType: any(named: 'syncType'),
      ),
    ).thenAnswer((invocation) async {
      final ops =
          invocation.namedArguments[#operations] as List<Map<String, dynamic>>;
      return PushSyncResult.queued(ops.length);
    });

    final useCase = buildUseCase(
      transactions: List.generate(120, (i) => _txnOp('tx-$i')),
    );

    final total = await useCase.execute();

    expect(total, 120, reason: 'PushSyncQueued counts toward total');
    verify(
      () => pushSync.execute(
        operations: any(named: 'operations'),
        vectorClock: any(named: 'vectorClock'),
        syncType: 'full',
      ),
    ).called(3); // 120 ops → chunks of 50, 50, 20
  });

  test(
    'each queued chunk carries the vector clock for its own operations',
    () async {
      final firstChunk = List.generate(50, (i) => _txnOp('tx-a-$i'));
      final secondChunk = {
        ..._txnOp('tx-z'),
        'revision': 900,
        'originDeviceId': 'device-z',
        'data': {'id': 'tx-z', 'syncRevision': 900},
      };
      final useCase = buildUseCase(transactions: [...firstChunk, secondChunk]);

      await useCase.execute();

      final clocks = verify(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: captureAny(named: 'vectorClock'),
          syncType: 'full',
        ),
      ).captured.cast<Map<String, int>>();
      expect(clocks, [
        {'device-a': 100},
        {'device-z': 900},
      ]);
    },
  );

  test('returns 0 and never pushes when both sources are empty', () async {
    final useCase = buildUseCase();

    final total = await useCase.execute();

    expect(total, 0);
    verifyNever(
      () => pushSync.execute(
        operations: any(named: 'operations'),
        vectorClock: any(named: 'vectorClock'),
        syncType: any(named: 'syncType'),
      ),
    );
  });

  test('settles only chunks explicitly accepted by relay', () async {
    final accepted = <Map<String, dynamic>>[];
    final useCase = FullSyncUseCase(
      pushSync: pushSync,
      fetchAllTransactions: () async => [_txnOp('tx-covered')],
      fetchAllShoppingOps: () async => const [],
      onOperationsAccepted: (operations) async => accepted.addAll(operations),
    );

    expect(await useCase.execute(), 1);
    expect(accepted.single['entityId'], 'tx-covered');

    accepted.clear();
    when(
      () => pushSync.execute(
        operations: any(named: 'operations'),
        vectorClock: any(named: 'vectorClock'),
        syncType: any(named: 'syncType'),
      ),
    ).thenAnswer((_) async => const PushSyncResult.error('offline'));
    expect(await useCase.execute(), 0);
    expect(accepted, isEmpty);
  });

  test(
    'durably queued withdrawal retains the tombstone until relay ACK',
    () async {
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          syncType: any(named: 'syncType'),
        ),
      ).thenAnswer((_) async => const PushSyncResult.queued(1));
      final accepted = <Map<String, dynamic>>[];
      final tombstone = {
        'op': 'delete',
        'entityType': 'bill',
        'entityId': 'tx-archived-withdrawal',
        'revision': 300,
        'originDeviceId': 'device-a',
        'data': {
          'isDeleted': true,
          'syncRevision': 300,
          'syncOriginDeviceId': 'device-a',
        },
        'timestamp': 123,
      };
      final useCase = FullSyncUseCase(
        pushSync: pushSync,
        fetchAllTransactions: () async => [tombstone],
        fetchAllShoppingOps: () async => const [],
        onOperationsAccepted: (operations) async => accepted.addAll(operations),
      );

      expect(await useCase.execute(), 1);
      expect(accepted, isEmpty);
    },
  );
}

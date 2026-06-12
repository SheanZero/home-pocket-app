import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

Map<String, dynamic> _txnOp(String id) => {
  'op': 'create',
  'entityType': 'bill',
  'entityId': id,
  'data': {'id': id},
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
          invocation.namedArguments[#operations]
              as List<Map<String, dynamic>>;
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
        vectorClock: {'full_sync': 0},
        syncType: 'full',
      ),
    ).called(1);
  });

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
        reason:
            'empty-transactions early-exit must not swallow shopping ops',
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
          invocation.namedArguments[#operations]
              as List<Map<String, dynamic>>;
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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

void main() {
  late MockPushSyncUseCase pushSync;
  late FullSyncUseCase useCase;

  setUp(() {
    pushSync = MockPushSyncUseCase();
    useCase = FullSyncUseCase(
      pushSync: pushSync,
      fetchAllTransactions: () async => [
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-1',
          'data': {'id': 'tx-1'},
          'timestamp': 123,
        },
      ],
    );
    when(
      () => pushSync.execute(
        operations: any(named: 'operations'),
        vectorClock: any(named: 'vectorClock'),
        syncType: any(named: 'syncType'),
      ),
    ).thenAnswer((_) async => const PushSyncResult.success(1));
  });

  test('passes syncType full when pushing full sync chunks', () async {
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
}

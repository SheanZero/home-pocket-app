import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/drain_family_sync_outbox_use_case.dart';
import 'package:home_pocket/application/family_sync/epoch_sync_recovery_use_case.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncQueueManager extends Mock implements SyncQueueManager {}

class _MockOutboxDrainer extends Mock implements DrainFamilySyncOutboxUseCase {}

class _MockFullSync extends Mock implements FullSyncUseCase {}

void main() {
  late _MockSyncQueueManager queueManager;
  late _MockOutboxDrainer outboxDrainer;
  late _MockFullSync fullSync;

  setUp(() {
    queueManager = _MockSyncQueueManager();
    outboxDrainer = _MockOutboxDrainer();
    fullSync = _MockFullSync();
  });

  test(
    'epoch commit cleans retired ciphertext before resend and full reconcile',
    () async {
      final events = <String>[];
      final stages = <EpochSyncRecoveryStage>[];
      when(
        () => queueManager.discardRetiredEpochCiphertext(
          groupId: 'group-1',
          currentKeyEpoch: 5,
        ),
      ).thenAnswer((_) async {
        events.add('discard-retired');
        return 1;
      });
      when(() => outboxDrainer.execute()).thenAnswer((_) async {
        events.add('drain-outbox');
        return 3;
      });
      when(() => fullSync.execute()).thenAnswer((_) async {
        events.add('full-reconcile');
        return 7;
      });
      final useCase = EpochSyncRecoveryUseCase(
        queueManager: queueManager,
        outboxDrainer: outboxDrainer,
        fullSync: fullSync,
        onStageChanged: stages.add,
      );

      final result = await useCase.execute(
        groupId: 'group-1',
        currentKeyEpoch: 5,
      );

      expect(events, ['discard-retired', 'drain-outbox', 'full-reconcile']);
      expect(stages, [
        EpochSyncRecoveryStage.discardingRetiredCiphertext,
        EpochSyncRecoveryStage.drainingDurableOutbox,
        EpochSyncRecoveryStage.reconcilingFullState,
        EpochSyncRecoveryStage.completed,
      ]);
      expect(result.discardedCiphertextCount, 1);
      expect(result.acknowledgedOutboxCount, 3);
      expect(result.reconciledOperationCount, 7);
    },
  );

  test(
    'duplicate concurrent epoch recovery shares one serialized run',
    () async {
      final gate = Completer<void>();
      when(
        () => queueManager.discardRetiredEpochCiphertext(
          groupId: 'group-1',
          currentKeyEpoch: 5,
        ),
      ).thenAnswer((_) async {
        await gate.future;
        return 1;
      });
      when(() => outboxDrainer.execute()).thenAnswer((_) async => 1);
      when(() => fullSync.execute()).thenAnswer((_) async => 1);
      final useCase = EpochSyncRecoveryUseCase(
        queueManager: queueManager,
        outboxDrainer: outboxDrainer,
        fullSync: fullSync,
      );

      final first = useCase.execute(groupId: 'group-1', currentKeyEpoch: 5);
      final duplicate = useCase.execute(groupId: 'group-1', currentKeyEpoch: 5);
      gate.complete();

      final results = await Future.wait([first, duplicate]);
      expect(identical(results[0], results[1]), isTrue);
      verify(
        () => queueManager.discardRetiredEpochCiphertext(
          groupId: 'group-1',
          currentKeyEpoch: 5,
        ),
      ).called(1);
      verify(() => outboxDrainer.execute()).called(1);
      verify(() => fullSync.execute()).called(1);
    },
  );

  test(
    'offline durable resend is retained and reconciliation remains retryable',
    () async {
      when(
        () => queueManager.discardRetiredEpochCiphertext(
          groupId: 'group-1',
          currentKeyEpoch: 5,
        ),
      ).thenAnswer((_) async => 1);
      when(() => outboxDrainer.execute()).thenAnswer((_) async => 0);
      when(() => fullSync.execute()).thenAnswer((_) async => 0);
      final useCase = EpochSyncRecoveryUseCase(
        queueManager: queueManager,
        outboxDrainer: outboxDrainer,
        fullSync: fullSync,
      );

      final result = await useCase.execute(
        groupId: 'group-1',
        currentKeyEpoch: 5,
      );

      expect(result.acknowledgedOutboxCount, 0);
      expect(result.reconciledOperationCount, 0);
      verify(() => outboxDrainer.execute()).called(1);
      verify(() => fullSync.execute()).called(1);
    },
  );
}

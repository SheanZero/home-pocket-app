import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/inbound_sync_recovery_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/inbound_sync_operation_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockApplySyncOperationsUseCase extends Mock
    implements ApplySyncOperationsUseCase {}

void main() {
  late MemoryInboundSyncOperationRepository repository;
  late _MockApplySyncOperationsUseCase applyOperations;
  late InboundSyncRecoveryUseCase useCase;

  setUp(() {
    repository = MemoryInboundSyncOperationRepository();
    applyOperations = _MockApplySyncOperationsUseCase();
    useCase = InboundSyncRecoveryUseCase(
      repository: repository,
      applyOperations: applyOperations,
    );
  });

  test(
    'automatic resolution discards deterministic unsafe operations',
    () async {
      await repository.quarantine(
        operationId: 'invalid-profile',
        groupId: 'group-1',
        messageId: 'message-1',
        operationJson: '{"operationId":"invalid-profile"}',
        errorCode: 'invalid_profile_sender',
      );
      await repository.quarantine(
        operationId: 'invalid-avatar',
        groupId: 'group-1',
        messageId: 'message-2',
        operationJson: '{"operationId":"invalid-avatar"}',
        errorCode: 'avatar_validation_failed',
      );
      await repository.quarantine(
        operationId: 'oversized',
        groupId: 'group-1',
        messageId: 'message-3',
        operationJson: '{"kind":"safe-summary"}',
        errorCode: 'operation_payload_too_large',
        retryable: false,
      );

      final result = await useCase.resolveAutomatically(groupId: 'group-1');

      expect(result.retriedCount, 0);
      expect(result.discardedCount, 3);
      expect(result.remainingCount, 0);
      expect(await repository.getQuarantined(groupId: 'group-1'), isEmpty);
      verifyNever(
        () => applyOperations.execute(any(), groupId: any(named: 'groupId')),
      );
    },
  );

  test('automatic resolution retries forward-compatible operations', () async {
    const operationId = 'future-operation';
    await repository.quarantine(
      operationId: operationId,
      groupId: 'group-1',
      messageId: 'message-1',
      operationJson: '{"operationId":"$operationId","entityType":"future"}',
      errorCode: 'unsupported_entity_type',
    );
    when(() => applyOperations.execute(any(), groupId: 'group-1')).thenAnswer((
      _,
    ) async {
      await repository.markApplied(
        operationId: operationId,
        groupId: 'group-1',
        messageId: 'message-1',
      );
      return const ApplySyncOperationsResult([
        SyncOperationApplyResult(
          operationId: operationId,
          status: SyncOperationApplyStatus.applied,
        ),
      ]);
    });

    final result = await useCase.resolveAutomatically(groupId: 'group-1');

    expect(result.retriedCount, 1);
    expect(result.discardedCount, 0);
    expect(result.remainingCount, 0);
    verify(() => applyOperations.execute(any(), groupId: 'group-1')).called(1);
  });
}

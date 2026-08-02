import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_queue_recovery_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncQueueManager extends Mock implements SyncQueueManager {}

void main() {
  test(
    'retry all preserves reconciliation recommendation after send',
    () async {
      final manager = _MockSyncQueueManager();
      var summaryRead = 0;
      when(() => manager.getSummary()).thenAnswer((_) async {
        summaryRead++;
        return summaryRead == 1
            ? const SyncQueueSummary(deadLetterCount: 2)
            : const SyncQueueSummary();
      });
      when(() => manager.retryAll()).thenAnswer((_) async => 2);
      final useCase = SyncQueueRecoveryUseCase(queueManager: manager);

      final result = await useCase.retryAll();

      expect(result.sentCount, 2);
      expect(result.summary, const SyncQueueSummary());
      expect(result.reconcileSuggested, isTrue);
    },
  );

  test('discard delegates only after an explicit use case call', () async {
    final manager = _MockSyncQueueManager();
    when(() => manager.discard('sync-1')).thenAnswer((_) async {});
    final useCase = SyncQueueRecoveryUseCase(queueManager: manager);

    await useCase.discard('sync-1');

    verify(() => manager.discard('sync-1')).called(1);
  });
}

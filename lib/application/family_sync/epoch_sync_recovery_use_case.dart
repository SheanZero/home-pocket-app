import '../../infrastructure/sync/sync_queue_manager.dart';
import 'drain_family_sync_outbox_use_case.dart';
import 'full_sync_use_case.dart';

/// Observable stages of the post-epoch-commit data-plane recovery state
/// machine. Stages are strictly ordered and one group/epoch run is idempotent
/// while in flight.
enum EpochSyncRecoveryStage {
  discardingRetiredCiphertext,
  drainingDurableOutbox,
  reconcilingFullState,
  completed,
}

typedef EpochSyncRecoveryStageCallback =
    void Function(EpochSyncRecoveryStage stage);

class EpochSyncRecoveryResult {
  const EpochSyncRecoveryResult({
    required this.discardedCiphertextCount,
    required this.acknowledgedOutboxCount,
    required this.reconciledOperationCount,
  });

  final int discardedCiphertextCount;
  final int acknowledgedOutboxCount;
  final int reconciledOperationCount;
}

/// Serializes key-epoch cleanup, durable semantic resend, and full reconcile.
///
/// Retired queue rows are ciphertext caches, not mutation ownership. The
/// SQLCipher family outbox remains authoritative until its resend receives a
/// relay ACK. A network failure therefore produces zero acknowledged rows and
/// the next startup/resume safely repeats this state machine.
class EpochSyncRecoveryUseCase {
  EpochSyncRecoveryUseCase({
    required SyncQueueManager queueManager,
    required DrainFamilySyncOutboxUseCase outboxDrainer,
    required FullSyncUseCase fullSync,
    EpochSyncRecoveryStageCallback? onStageChanged,
  }) : _queueManager = queueManager,
       _outboxDrainer = outboxDrainer,
       _fullSync = fullSync,
       _onStageChanged = onStageChanged;

  final SyncQueueManager _queueManager;
  final DrainFamilySyncOutboxUseCase _outboxDrainer;
  final FullSyncUseCase _fullSync;
  final EpochSyncRecoveryStageCallback? _onStageChanged;

  final _inFlight = <String, Future<EpochSyncRecoveryResult>>{};
  Future<void> _serialTail = Future<void>.value();

  Future<EpochSyncRecoveryResult> execute({
    required String groupId,
    required int currentKeyEpoch,
  }) {
    final recoveryId = '$groupId:$currentKeyEpoch';
    final existing = _inFlight[recoveryId];
    if (existing != null) return existing;

    final previous = _serialTail;
    final operation = previous.then(
      (_) => _recover(groupId: groupId, currentKeyEpoch: currentKeyEpoch),
      onError: (_) =>
          _recover(groupId: groupId, currentKeyEpoch: currentKeyEpoch),
    );
    _serialTail = operation.then<void>((_) {}, onError: (_) {});

    late final Future<EpochSyncRecoveryResult> tracked;
    tracked = operation.whenComplete(() {
      if (identical(_inFlight[recoveryId], tracked)) {
        _inFlight.remove(recoveryId);
      }
    });
    _inFlight[recoveryId] = tracked;
    return tracked;
  }

  Future<EpochSyncRecoveryResult> _recover({
    required String groupId,
    required int currentKeyEpoch,
  }) async {
    _onStageChanged?.call(EpochSyncRecoveryStage.discardingRetiredCiphertext);
    final discarded = await _queueManager.discardRetiredEpochCiphertext(
      groupId: groupId,
      currentKeyEpoch: currentKeyEpoch,
    );

    _onStageChanged?.call(EpochSyncRecoveryStage.drainingDurableOutbox);
    final acknowledged = await _outboxDrainer.execute();

    _onStageChanged?.call(EpochSyncRecoveryStage.reconcilingFullState);
    final reconciled = await _fullSync.execute();

    _onStageChanged?.call(EpochSyncRecoveryStage.completed);
    return EpochSyncRecoveryResult(
      discardedCiphertextCount: discarded,
      acknowledgedOutboxCount: acknowledged,
      reconciledOperationCount: reconciled,
    );
  }
}

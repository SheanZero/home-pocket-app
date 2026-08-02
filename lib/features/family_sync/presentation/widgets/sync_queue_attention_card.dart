import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/family_sync/inbound_sync_recovery_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../domain/repositories/inbound_sync_operation_repository.dart';
import '../providers/repository_providers.dart';
import '../providers/state_active_group.dart';
import '../providers/state_sync.dart';

class SyncQueueAttentionCard extends ConsumerStatefulWidget {
  const SyncQueueAttentionCard({super.key});

  @override
  ConsumerState<SyncQueueAttentionCard> createState() =>
      _SyncQueueAttentionCardState();
}

class _SyncQueueAttentionCardState
    extends ConsumerState<SyncQueueAttentionCard> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    // Keep the current family subscription warm before recovery actions read
    // it. Without an active family, inbound providers expose empty state.
    ref.watch(activeGroupProvider);
    final summary = ref.watch(syncQueueSummaryProvider).value;
    final inboundSummary = ref.watch(inboundSyncSummaryProvider).value;
    final inboundEntries =
        ref.watch(inboundSyncQuarantinedProvider).value ?? const [];
    if (summary == null || inboundSummary == null) {
      return const SizedBox.shrink();
    }
    if (summary.pendingCount == 0 &&
        summary.deadLetterCount == 0 &&
        inboundSummary.quarantinedCount == 0) {
      return const SizedBox.shrink();
    }

    final l10n = S.of(context);
    final palette = context.palette;
    final needsAttention =
        summary.deadLetterCount > 0 || inboundSummary.quarantinedCount > 0;
    return Container(
      key: const Key('sync-queue-attention-card'),
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (needsAttention ? palette.error : palette.warning).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (needsAttention ? palette.error : palette.warning).withValues(
            alpha: 0.24,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                needsAttention
                    ? Icons.warning_amber_rounded
                    : Icons.cloud_upload_outlined,
                color: needsAttention ? palette.error : palette.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  needsAttention
                      ? l10n.syncQueueNeedsAttentionTitle
                      : l10n.syncQueuePendingTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.syncQueueCounts(summary.pendingCount, summary.deadLetterCount),
            style: TextStyle(color: palette.textSecondary),
          ),
          if (inboundSummary.quarantinedCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              l10n.inboundSyncCount(inboundSummary.quarantinedCount),
              style: TextStyle(color: palette.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.inboundSyncSectionTitle,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            for (final entry in inboundEntries)
              _InboundQuarantineRow(
                entry: entry,
                working: _working,
                onRetry: () => _retryInbound(entry.operationId),
                onDiscard: () => _confirmDiscardInbound(entry.operationId),
              ),
          ],
          if (needsAttention) ...[
            const SizedBox(height: 6),
            Text(
              l10n.syncQueueReconcileHint,
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _working ? null : _retryAll,
                    child: Text(l10n.syncQueueRetryAll),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: _working ? null : _confirmDiscardAll,
                    child: Text(l10n.syncQueueDiscardAll),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _retryAll() async {
    setState(() => _working = true);
    try {
      final groupId = ref.read(activeGroupProvider).value?.groupId;
      final result = await ref
          .read(syncQueueRecoveryUseCaseProvider)
          .retryAll();
      final inboundResult = groupId == null
          ? const InboundSyncRetryResult(retriedCount: 0, remainingCount: 0)
          : await ref
                .read(inboundSyncRecoveryUseCaseProvider)
                .retryAll(groupId: groupId);
      if (!mounted) return;
      if (result.summary.deadLetterCount > 0 ||
          inboundResult.remainingCount > 0) {
        showErrorFeedback(context, S.of(context).syncQueueRetryFailed);
      } else {
        showSuccessFeedback(context, S.of(context).syncQueueRetrySucceeded);
      }
    } catch (_) {
      if (mounted) {
        showErrorFeedback(context, S.of(context).syncQueueRetryFailed);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _confirmDiscardAll() async {
    final l10n = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.syncAttentionDiscardConfirmTitle),
        content: Text(l10n.syncAttentionDiscardConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.syncQueueCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.syncQueueDiscardConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _working = true);
    try {
      final groupId = ref.read(activeGroupProvider).value?.groupId;
      await ref.read(syncQueueRecoveryUseCaseProvider).discardAll();
      if (groupId != null) {
        await ref
            .read(inboundSyncRecoveryUseCaseProvider)
            .discardAll(groupId: groupId);
      }
    } catch (_) {
      if (mounted) {
        showErrorFeedback(context, S.of(context).syncQueueDiscardFailed);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _retryInbound(String operationId) async {
    setState(() => _working = true);
    try {
      final groupId = ref.read(activeGroupProvider).value?.groupId;
      if (groupId == null) {
        throw StateError('No active family for inbound recovery');
      }
      final result = await ref
          .read(inboundSyncRecoveryUseCaseProvider)
          .retryOne(groupId: groupId, operationId: operationId);
      if (!mounted) return;
      if (result.retriedCount == 1) {
        showSuccessFeedback(context, S.of(context).syncQueueRetrySucceeded);
      } else {
        showErrorFeedback(context, S.of(context).syncQueueRetryFailed);
      }
    } catch (_) {
      if (mounted) {
        showErrorFeedback(context, S.of(context).syncQueueRetryFailed);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _confirmDiscardInbound(String operationId) async {
    final l10n = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.inboundSyncDiscardConfirmTitle),
        content: Text(l10n.inboundSyncDiscardConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.syncQueueCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.syncQueueDiscardConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
    try {
      final groupId = ref.read(activeGroupProvider).value?.groupId;
      if (groupId == null) {
        throw StateError('No active family for inbound recovery');
      }
      await ref
          .read(inboundSyncRecoveryUseCaseProvider)
          .discard(groupId: groupId, operationId: operationId);
    } catch (_) {
      if (mounted) {
        showErrorFeedback(context, S.of(context).syncQueueDiscardFailed);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

class _InboundQuarantineRow extends StatelessWidget {
  const _InboundQuarantineRow({
    required this.entry,
    required this.working,
    required this.onRetry,
    required this.onDiscard,
  });

  final InboundSyncQuarantineEntry entry;
  final bool working;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return Padding(
      key: Key('inbound-quarantine-${entry.operationId}'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.inboundSyncErrorCode(entry.errorCode),
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
          ),
          if (entry.retryable)
            TextButton(
              onPressed: working ? null : onRetry,
              child: Text(l10n.inboundSyncRetryOne),
            ),
          IconButton(
            tooltip: l10n.inboundSyncDiscardOne,
            onPressed: working ? null : onDiscard,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
  }
}

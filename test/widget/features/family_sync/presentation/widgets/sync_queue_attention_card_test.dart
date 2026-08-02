import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_queue_recovery_use_case.dart';
import 'package:home_pocket/application/family_sync/inbound_sync_recovery_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/inbound_sync_operation_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/sync_queue_attention_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class _MockRecoveryUseCase extends Mock implements SyncQueueRecoveryUseCase {}

class _MockInboundRecoveryUseCase extends Mock
    implements InboundSyncRecoveryUseCase {}

void main() {
  GroupInfo activeGroup() => GroupInfo(
    groupId: 'group-1',
    groupName: 'Family',
    status: GroupStatus.active,
    role: 'owner',
    members: const [],
    createdAt: DateTime.utc(2026),
  );

  testWidgets('shows counts and requires confirmation before discard', (
    tester,
  ) async {
    final recovery = _MockRecoveryUseCase();
    final inboundRecovery = _MockInboundRecoveryUseCase();
    when(() => recovery.discardAll()).thenAnswer((_) async {});
    when(
      () => inboundRecovery.discardAll(groupId: 'group-1'),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      createLocalizedWidget(
        const Scaffold(body: SyncQueueAttentionCard()),
        overrides: [
          syncQueueRecoveryUseCaseProvider.overrideWithValue(recovery),
          inboundSyncRecoveryUseCaseProvider.overrideWithValue(inboundRecovery),
          activeGroupProvider.overrideWith(
            (ref) => Stream.value(activeGroup()),
          ),
          syncQueueSummaryProvider.overrideWith(
            (ref) => Stream.value(
              const SyncQueueSummary(pendingCount: 2, deadLetterCount: 1),
            ),
          ),
          inboundSyncSummaryProvider.overrideWith(
            (ref) => Stream.value(const InboundSyncSummary()),
          ),
          inboundSyncQuarantinedProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sync-queue-attention-card')), findsOneWidget);
    expect(find.textContaining('2'), findsWidgets);
    expect(find.textContaining('1'), findsWidgets);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    verifyNever(() => recovery.discardAll());
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Discard permanently'));
    await tester.pumpAndSettle();
    verify(() => recovery.discardAll()).called(1);
    verify(() => inboundRecovery.discardAll(groupId: 'group-1')).called(1);
  });

  testWidgets(
    'distinguishes inbound quarantine and supports retry/discard one',
    (tester) async {
      final recovery = _MockRecoveryUseCase();
      final inboundRecovery = _MockInboundRecoveryUseCase();
      final entry = InboundSyncQuarantineEntry(
        operationId: 'operation-1',
        groupId: 'group-1',
        messageId: 'message-1',
        operationJson: '{}',
        errorCode: 'unsupported_entity_type',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      when(
        () => inboundRecovery.retryOne(
          groupId: 'group-1',
          operationId: 'operation-1',
        ),
      ).thenAnswer(
        (_) async =>
            const InboundSyncRetryResult(retriedCount: 1, remainingCount: 0),
      );
      when(
        () => inboundRecovery.discard(
          groupId: 'group-1',
          operationId: 'operation-1',
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createLocalizedWidget(
          const Scaffold(body: SyncQueueAttentionCard()),
          overrides: [
            syncQueueRecoveryUseCaseProvider.overrideWithValue(recovery),
            inboundSyncRecoveryUseCaseProvider.overrideWithValue(
              inboundRecovery,
            ),
            activeGroupProvider.overrideWith(
              (ref) => Stream.value(activeGroup()),
            ),
            syncQueueSummaryProvider.overrideWith(
              (ref) => Stream.value(const SyncQueueSummary()),
            ),
            inboundSyncSummaryProvider.overrideWith(
              (ref) =>
                  Stream.value(const InboundSyncSummary(quarantinedCount: 1)),
            ),
            inboundSyncQuarantinedProvider.overrideWith(
              (ref) => Stream.value([entry]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('received changes quarantined'),
        findsOneWidget,
      );
      expect(find.textContaining('unsupported_entity_type'), findsOneWidget);

      await tester.tap(find.text('Retry').first);
      await tester.pumpAndSettle();
      verify(
        () => inboundRecovery.retryOne(
          groupId: 'group-1',
          operationId: 'operation-1',
        ),
      ).called(1);

      await tester.tap(find.byTooltip('Discard received change'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Discard permanently'));
      await tester.pumpAndSettle();
      verify(
        () => inboundRecovery.discard(
          groupId: 'group-1',
          operationId: 'operation-1',
        ),
      ).called(1);
    },
  );

  testWidgets('non-retryable inbound summary offers discard but not retry', (
    tester,
  ) async {
    final recovery = _MockRecoveryUseCase();
    final inboundRecovery = _MockInboundRecoveryUseCase();
    final entry = InboundSyncQuarantineEntry(
      operationId: 'oversized-summary',
      groupId: 'group-1',
      messageId: 'message-1',
      operationJson:
          '{"kind":"inbound_operation_rejection",'
          '"sourceBytes":70000,"sha256":"digest",'
          '"reason":"operation_payload_too_large"}',
      errorCode: 'operation_payload_too_large',
      retryable: false,
      payloadBytes: 120,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    when(
      () => inboundRecovery.discard(
        groupId: 'group-1',
        operationId: 'oversized-summary',
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      createLocalizedWidget(
        const Scaffold(body: SyncQueueAttentionCard()),
        overrides: [
          syncQueueRecoveryUseCaseProvider.overrideWithValue(recovery),
          inboundSyncRecoveryUseCaseProvider.overrideWithValue(inboundRecovery),
          activeGroupProvider.overrideWith(
            (ref) => Stream.value(activeGroup()),
          ),
          syncQueueSummaryProvider.overrideWith(
            (ref) => Stream.value(const SyncQueueSummary()),
          ),
          inboundSyncSummaryProvider.overrideWith(
            (ref) =>
                Stream.value(const InboundSyncSummary(quarantinedCount: 1)),
          ),
          inboundSyncQuarantinedProvider.overrideWith(
            (ref) => Stream.value([entry]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsNothing);
    expect(find.byTooltip('Discard received change'), findsOneWidget);
    verifyNever(
      () => inboundRecovery.retryOne(
        groupId: any(named: 'groupId'),
        operationId: any(named: 'operationId'),
      ),
    );
  });
}

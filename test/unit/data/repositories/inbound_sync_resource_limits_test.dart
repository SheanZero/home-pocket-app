import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/inbound_sync_operation_dao.dart';
import 'package:home_pocket/data/repositories/inbound_sync_operation_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/models/inbound_sync_resource_policy.dart';

void main() {
  late AppDatabase database;
  late DateTime now;
  late InboundSyncOperationRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting();
    now = DateTime.utc(2026, 8, 1);
    repository = InboundSyncOperationRepositoryImpl(
      dao: InboundSyncOperationDao(database, now: () => now),
    );
  });

  tearDown(() => database.close());

  Future<void> quarantine(
    int index, {
    String groupId = 'group-a',
    int payloadSize = 2,
  }) {
    final json = payloadSize <= 2
        ? '{}'
        : jsonEncode({'value': 'x' * (payloadSize - 12)});
    return repository.quarantine(
      groupId: groupId,
      operationId: 'operation-${index.toString().padLeft(4, '0')}',
      messageId: 'message-$index',
      operationJson: json,
      errorCode: 'unsupported_entity_type',
    );
  }

  test('policy budgets are explicit and retain normal 50-op chunks', () {
    expect(InboundSyncResourcePolicy.maxOperationsPerMessage, 500);
    expect(InboundSyncResourcePolicy.maxOperationJsonBytes, 64 * 1024);
    expect(InboundSyncResourcePolicy.maxSafeSummaryJsonBytes, 1024);
    expect(InboundSyncResourcePolicy.maxQuarantineEntriesPerGroup, 200);
    expect(
      InboundSyncResourcePolicy.maxQuarantinePayloadBytesPerGroup,
      1 << 20,
    );
    expect(InboundSyncResourcePolicy.quarantineTtl, const Duration(days: 30));
    expect(InboundSyncResourcePolicy.quarantinePageSize, 50);
  });

  test(
    'count quota evicts the oldest quarantine but preserves applied rows',
    () async {
      await repository.markApplied(
        groupId: 'group-a',
        operationId: 'applied-before-quota',
        messageId: 'applied-message',
      );
      for (
        var index = 0;
        index <= InboundSyncResourcePolicy.maxQuarantineEntriesPerGroup;
        index++
      ) {
        now = now.add(const Duration(seconds: 1));
        await quarantine(index);
      }

      final summary = await repository.getSummary(groupId: 'group-a');
      expect(
        summary.quarantinedCount,
        InboundSyncResourcePolicy.maxQuarantineEntriesPerGroup,
      );
      expect(
        await repository.findQuarantined(
          groupId: 'group-a',
          operationId: 'operation-0000',
        ),
        isNull,
      );
      expect(
        await repository.isApplied(
          groupId: 'group-a',
          operationId: 'applied-before-quota',
        ),
        isTrue,
      );
    },
  );

  test(
    'byte quota is computed by SQL and bounded independently per group',
    () async {
      for (var index = 0; index < 20; index++) {
        now = now.add(const Duration(seconds: 1));
        await quarantine(index, payloadSize: 60 * 1024);
      }
      await quarantine(0, groupId: 'group-b', payloadSize: 60 * 1024);

      final groupA = await repository.getSummary(groupId: 'group-a');
      final groupB = await repository.getSummary(groupId: 'group-b');
      expect(
        groupA.quarantinedPayloadBytes,
        lessThanOrEqualTo(
          InboundSyncResourcePolicy.maxQuarantinePayloadBytesPerGroup,
        ),
      );
      expect(groupA.quarantinedCount, lessThan(20));
      expect(groupB.quarantinedCount, 1);
    },
  );

  test('TTL cleanup runs before insert and remains group scoped', () async {
    await quarantine(0);
    await quarantine(0, groupId: 'group-b');
    now = now.add(const Duration(days: 31));
    await quarantine(1);

    expect(
      await repository.findQuarantined(
        groupId: 'group-a',
        operationId: 'operation-0000',
      ),
      isNull,
    );
    expect(
      await repository.findQuarantined(
        groupId: 'group-b',
        operationId: 'operation-0000',
      ),
      isNotNull,
    );
  });

  test('concurrent inserts cannot exceed count or byte quota', () async {
    await Future.wait([
      for (var index = 0; index < 240; index++) quarantine(index),
    ]);

    final summary = await repository.getSummary(groupId: 'group-a');
    expect(
      summary.quarantinedCount,
      lessThanOrEqualTo(InboundSyncResourcePolicy.maxQuarantineEntriesPerGroup),
    );
    expect(
      summary.quarantinedPayloadBytes,
      lessThanOrEqualTo(
        InboundSyncResourcePolicy.maxQuarantinePayloadBytesPerGroup,
      ),
    );
  });

  test(
    'summary counts all rows while list uses stable bounded pages',
    () async {
      for (var index = 0; index < 75; index++) {
        await quarantine(index);
      }

      final summary = await repository.getSummary(groupId: 'group-a');
      final first = await repository.getQuarantinedPage(groupId: 'group-a');
      final second = await repository.getQuarantinedPage(
        groupId: 'group-a',
        offset: first.entries.length,
      );
      expect(summary.quarantinedCount, 75);
      expect(first.entries, hasLength(50));
      expect(first.hasMore, isTrue);
      expect(second.entries, hasLength(25));
      expect(second.hasMore, isFalse);
      expect(
        <String>{
          ...first.entries.map((entry) => entry.operationId),
        }.intersection(<String>{
          ...second.entries.map((entry) => entry.operationId),
        }),
        isEmpty,
      );
    },
  );
}

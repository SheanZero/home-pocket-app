import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/inbound_sync_operation_dao.dart';
import 'package:home_pocket/data/repositories/inbound_sync_operation_repository_impl.dart';

void main() {
  late AppDatabase database;
  late InboundSyncOperationRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting();
    repository = InboundSyncOperationRepositoryImpl(
      dao: InboundSyncOperationDao(database),
    );
  });

  tearDown(() => database.close());

  test('same operation id is independently applied in two groups', () async {
    await repository.markApplied(
      groupId: 'group-a',
      operationId: 'same-id',
      messageId: 'message-a',
    );

    expect(
      await repository.isApplied(groupId: 'group-a', operationId: 'same-id'),
      isTrue,
    );
    expect(
      await repository.isApplied(groupId: 'group-b', operationId: 'same-id'),
      isFalse,
    );

    await repository.markApplied(
      groupId: 'group-b',
      operationId: 'same-id',
      messageId: 'message-b',
    );
    final rows = await database
        .customSelect(
          'SELECT group_id FROM inbound_sync_operations '
          "WHERE operation_id = 'same-id' ORDER BY group_id",
        )
        .get();
    expect(rows.map((row) => row.read<String>('group_id')), [
      'group-a',
      'group-b',
    ]);
  });

  test('quarantine summary list and watch are isolated by group', () async {
    for (final groupId in ['group-a', 'group-b']) {
      await repository.quarantine(
        groupId: groupId,
        operationId: 'same-id',
        messageId: 'message-$groupId',
        operationJson: '{"group":"$groupId"}',
        errorCode: 'unsupported_entity_type',
      );
    }
    await repository.quarantine(
      groupId: 'group-b',
      operationId: 'second-id',
      messageId: 'message-b-2',
      operationJson: '{}',
      errorCode: 'invalid_operation_payload',
    );

    expect(
      (await repository.getSummary(groupId: 'group-a')).quarantinedCount,
      1,
    );
    expect(
      (await repository.getSummary(groupId: 'group-b')).quarantinedCount,
      2,
    );
    expect(
      await repository
          .watchSummary(groupId: 'group-a')
          .first
          .then((summary) => summary.quarantinedCount),
      1,
    );
    expect(
      (await repository.watchQuarantined(groupId: 'group-b').first)
          .map((entry) => entry.groupId)
          .toSet(),
      {'group-b'},
    );
  });

  test('discard and group cleanup never delete another group ledger', () async {
    for (final groupId in ['group-a', 'group-b']) {
      await repository.quarantine(
        groupId: groupId,
        operationId: 'same-id',
        messageId: 'message-$groupId',
        operationJson: '{}',
        errorCode: 'unsupported_entity_type',
      );
      await repository.markApplied(
        groupId: groupId,
        operationId: 'applied-id',
        messageId: 'applied-$groupId',
      );
    }

    await repository.discardQuarantine(
      groupId: 'group-a',
      operationId: 'same-id',
    );
    expect(await repository.getQuarantined(groupId: 'group-a'), isEmpty);
    expect(await repository.getQuarantined(groupId: 'group-b'), hasLength(1));

    await repository.deleteGroupLedger(groupId: 'group-a');
    expect(
      await repository.isApplied(groupId: 'group-a', operationId: 'applied-id'),
      isFalse,
    );
    expect(
      await repository.isApplied(groupId: 'group-b', operationId: 'applied-id'),
      isTrue,
    );
  });
}

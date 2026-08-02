import 'package:drift/drift.dart';

@DataClassName('ControlEventData')
class ControlEvents extends Table {
  TextColumn get eventId => text()();
  TextColumn get groupId => text()();
  IntColumn get revision => integer()();
  TextColumn get eventType => text()();
  IntColumn get occurredAt => integer()();
  IntColumn get processedAt => integer()();

  @override
  Set<Column> get primaryKey => {eventId};

  List<TableIndex> get customIndices => [
    TableIndex(
      name: 'idx_control_events_group_revision',
      columns: {#groupId, #revision},
    ),
  ];
}

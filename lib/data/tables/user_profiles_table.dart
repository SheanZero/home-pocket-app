import 'package:drift/drift.dart';

@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  // coverage:ignore-start
  // Drift column DSL is consumed by code generation and is not callable at
  // runtime. Generated table classes cover the executable behavior.
  TextColumn get id => text()();
  TextColumn get displayName => text().withLength(min: 1, max: 50)();
  TextColumn get avatarEmoji => text()();
  TextColumn get avatarImagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
  // coverage:ignore-end

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_user_profiles_updated_at', columns: {#updatedAt}),
  ];
}

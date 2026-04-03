import 'package:drift/drift.dart';

@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().withLength(min: 1, max: 50)();
  TextColumn get avatarEmoji => text()();
  TextColumn get avatarImagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

import 'package:drift/drift.dart';

import '../app_database.dart';

class UserProfileDao {
  UserProfileDao(this._db);

  final AppDatabase _db;

  Future<UserProfileRow?> find() async {
    final query = _db.select(_db.userProfiles)..limit(1);
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  Future<void> upsert({
    required String id,
    required String displayName,
    required String avatarEmoji,
    required String? avatarImagePath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    await _db
        .into(_db.userProfiles)
        .insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            id: id,
            displayName: displayName,
            avatarEmoji: avatarEmoji,
            avatarImagePath: Value(avatarImagePath),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        );
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.userProfiles)..where((t) => t.id.equals(id))).go();
  }
}

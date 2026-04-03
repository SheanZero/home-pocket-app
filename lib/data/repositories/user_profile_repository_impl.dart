import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../daos/user_profile_dao.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl({required UserProfileDao dao}) : _dao = dao;

  final UserProfileDao _dao;

  @override
  Future<UserProfile?> find() async {
    final row = await _dao.find();
    if (row == null) {
      return null;
    }

    return UserProfile(
      id: row.id,
      displayName: row.displayName,
      avatarEmoji: row.avatarEmoji,
      avatarImagePath: row.avatarImagePath,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> save(UserProfile profile) async {
    await _dao.upsert(
      id: profile.id,
      displayName: profile.displayName,
      avatarEmoji: profile.avatarEmoji,
      avatarImagePath: profile.avatarImagePath,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  @override
  Future<void> delete(String id) => _dao.delete(id);
}

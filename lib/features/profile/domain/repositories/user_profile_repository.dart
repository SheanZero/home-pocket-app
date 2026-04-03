import '../models/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile?> find();
  Future<void> save(UserProfile profile);
  Future<void> delete(String id);
}

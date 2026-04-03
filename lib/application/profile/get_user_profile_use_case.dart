import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';

class GetUserProfileUseCase {
  GetUserProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<UserProfile?> execute() => _repository.find();
}

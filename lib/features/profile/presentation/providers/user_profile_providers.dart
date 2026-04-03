import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/profile/get_user_profile_use_case.dart';
import '../../../../application/profile/save_user_profile_use_case.dart';
import '../../../../data/daos/user_profile_dao.dart';
import '../../../../data/repositories/user_profile_repository_impl.dart';
import '../../../../infrastructure/security/providers.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';

part 'user_profile_providers.g.dart';

@riverpod
UserProfileDao userProfileDao(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return UserProfileDao(database);
}

@riverpod
UserProfileRepository userProfileRepository(Ref ref) {
  final dao = ref.watch(userProfileDaoProvider);
  return UserProfileRepositoryImpl(dao: dao);
}

@riverpod
GetUserProfileUseCase getUserProfileUseCase(Ref ref) {
  return GetUserProfileUseCase(ref.watch(userProfileRepositoryProvider));
}

@riverpod
SaveUserProfileUseCase saveUserProfileUseCase(Ref ref) {
  return SaveUserProfileUseCase(ref.watch(userProfileRepositoryProvider));
}

@riverpod
Future<UserProfile?> userProfile(Ref ref) async {
  final useCase = ref.watch(getUserProfileUseCaseProvider);
  return useCase.execute();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/user_profile.dart';
import 'repository_providers.dart';

part 'state_user_profile.g.dart';

@riverpod
Future<UserProfile?> userProfile(Ref ref) async {
  final useCase = ref.watch(getUserProfileUseCaseProvider);
  return useCase.execute();
}

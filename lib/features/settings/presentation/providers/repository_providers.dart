import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

part 'repository_providers.g.dart';

/// SharedPreferences instance provider.
@riverpod
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return await SharedPreferences.getInstance();
}

/// SettingsRepository provider (single source of truth).
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return SettingsRepositoryImpl(prefs: prefs);
}

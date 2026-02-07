import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/app_settings.dart';
import 'repository_providers.dart';

part 'settings_providers.g.dart';

/// Current app settings (async because SharedPreferences is async).
@riverpod
Future<AppSettings> appSettings(Ref ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return await repo.getSettings();
}

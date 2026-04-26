import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/app_settings.dart';
import 'repository_providers.dart';
import '../utils/voice_locale_helpers.dart';

part 'state_settings.g.dart';

/// Current app settings (async because SharedPreferences is async).
@riverpod
Future<AppSettings> appSettings(Ref ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return await repo.getSettings();
}

/// The BCP-47 locale ID to use for voice recognition.
///
/// Reads from persisted [AppSettings.voiceLanguage] and converts to
/// the format expected by speech_to_text (e.g. 'zh-CN').
@riverpod
Future<String> voiceLocaleId(Ref ref) async {
  final settings = await ref.watch(appSettingsProvider.future);
  return voiceLocaleIdFromLanguageCode(settings.voiceLanguage);
}

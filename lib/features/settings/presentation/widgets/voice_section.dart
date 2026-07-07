import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/app_settings.dart';
import '../providers/repository_providers.dart';
import '../providers/state_settings.dart';

/// Settings section for voice recognition configuration.
class VoiceSection extends ConsumerWidget {
  const VoiceSection({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            S.of(context).voiceInputSettings,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.mic),
          title: Text(S.of(context).voiceLanguage),
          subtitle: Text(_getLanguageLabel(settings.voiceLanguage, context)),
          onTap: () => _showLanguageDialog(context, ref),
        ),
        // KFB C3 (T-kfb-01): on-device recognition status + auto-degradation
        // control. The status reflects the effective POLICY derived from
        // [settings.voiceAllowOnDeviceFallback] — NOT a hardware-capability
        // probe (speech_to_text 7.x exposes no synchronous "on-device
        // supported" query).
        ListTile(
          leading: Icon(
            settings.voiceAllowOnDeviceFallback
                ? Icons.cloud_queue
                : Icons.phonelink_lock,
          ),
          title: Text(S.of(context).voiceOnDeviceRecognitionTitle),
          subtitle: Text(
            key: const ValueKey('voiceOnDeviceStatusSubtitle'),
            settings.voiceAllowOnDeviceFallback
                ? S.of(context).voiceAllowCloudFallbackTitle
                : S.of(context).voiceAllowCloudFallbackSubtitle,
          ),
        ),
        SwitchListTile(
          key: const ValueKey('voiceAllowCloudFallbackSwitch'),
          secondary: const Icon(Icons.cloud_sync),
          title: Text(S.of(context).voiceAllowCloudFallbackTitle),
          subtitle: Text(S.of(context).voiceAllowCloudFallbackSubtitle),
          value: settings.voiceAllowOnDeviceFallback,
          onChanged: (value) async {
            await ref
                .read(settingsRepositoryProvider)
                .setVoiceAllowOnDeviceFallback(value);
            ref.invalidate(appSettingsProvider);
          },
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).voiceLanguage),
        content: RadioGroup<String>(
          groupValue: settings.voiceLanguage,
          onChanged: (value) async {
            if (value != null) {
              await ref
                  .read(settingsRepositoryProvider)
                  .setVoiceLanguage(value);
              ref.invalidate(appSettingsProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(S.of(context).languageChinese),
                value: 'zh',
              ),
              RadioListTile<String>(
                title: Text(S.of(context).languageJapanese),
                value: 'ja',
              ),
              RadioListTile<String>(
                title: Text(S.of(context).languageEnglish),
                value: 'en',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageLabel(String code, BuildContext context) {
    switch (code) {
      case 'zh':
        return S.of(context).languageChinese;
      case 'ja':
        return S.of(context).languageJapanese;
      case 'en':
        return S.of(context).languageEnglish;
      default:
        return code;
    }
  }
}

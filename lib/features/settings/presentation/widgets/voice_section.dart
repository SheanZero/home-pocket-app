import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/settings_section_card.dart';
import '../../domain/models/app_settings.dart';
import '../providers/repository_providers.dart';
import '../providers/state_settings.dart';

/// Settings section for voice recognition configuration.
class VoiceSection extends ConsumerWidget {
  const VoiceSection({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSectionCard(
      title: S.of(context).voiceInputSettings,
      children: [VoiceLanguageSettingTile(settings: settings)],
    );
  }
}

/// Recognition-language row reused by the main General settings card.
class VoiceLanguageSettingTile extends ConsumerWidget {
  const VoiceLanguageSettingTile({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsActionTile(
      key: const ValueKey('settings-voice-language'),
      icon: Icons.mic_none_outlined,
      title: S.of(context).voiceLanguage,
      subtitle: _getLanguageLabel(settings.voiceLanguage, context),
      onTap: () => _showLanguageDialog(context, ref),
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
                title: Text(S.of(context).languageJapanese),
                value: 'ja',
              ),
              RadioListTile<String>(
                title: Text(S.of(context).languageChinese),
                value: 'zh',
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

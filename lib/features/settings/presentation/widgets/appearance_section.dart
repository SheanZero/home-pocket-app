import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../application/i18n/locale_settings_view.dart';
import '../../domain/models/app_settings.dart';
import '../providers/state_locale.dart';
import '../providers/repository_providers.dart';
import '../providers/state_settings.dart';

/// Hardcoded language names displayed in their own language.
const _languageNames = {'ja': '日本語', 'zh': '中文', 'en': 'English'};

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            S.of(context).appearance,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: Text(S.of(context).theme),
          subtitle: Text(_getThemeModeLabel(settings.themeMode, context)),
          onTap: () => _showThemeModeDialog(context, ref),
        ),
        _LanguageTile(settings: settings),
      ],
    );
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).selectTheme),
        content: RadioGroup<AppThemeMode>(
          groupValue: settings.themeMode,
          onChanged: (value) async {
            if (value != null) {
              await ref.read(settingsRepositoryProvider).setThemeMode(value);
              ref.invalidate(appSettingsProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeMode.values.map((mode) {
              return RadioListTile<AppThemeMode>(
                title: Text(_getThemeModeLabel(mode, context)),
                value: mode,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _getThemeModeLabel(AppThemeMode mode, BuildContext context) {
    switch (mode) {
      case AppThemeMode.system:
        return S.of(context).themeSystem;
      case AppThemeMode.light:
        return S.of(context).themeLight;
      case AppThemeMode.dark:
        return S.of(context).themeDark;
    }
  }
}

/// Language picker tile that reads locale state from [localeNotifierProvider].
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeNotifierProvider);
    final localeSettings = localeAsync.valueOrNull;

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(S.of(context).language),
      subtitle: Text(_buildSubtitle(localeSettings, context)),
      onTap: () => _showLanguageDialog(context, ref, localeSettings),
    );
  }

  String _buildSubtitle(LocaleSettings? localeSettings, BuildContext context) {
    if (localeSettings == null) {
      return '';
    }
    final nativeName = _languageNames[localeSettings.locale.languageCode] ?? '';
    if (localeSettings.isSystemDefault) {
      return '${S.of(context).languageSystem} ($nativeName)';
    }
    return nativeName;
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    LocaleSettings? localeSettings,
  ) {
    final currentCode = localeSettings?.locale.languageCode ?? 'ja';
    final isSystem = localeSettings?.isSystemDefault ?? true;
    // Use 'system' as the group value when system default is active,
    // otherwise use the language code.
    final groupValue = isSystem ? 'system' : currentCode;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).selectLanguage),
        content: RadioGroup<String>(
          groupValue: groupValue,
          onChanged: (value) async {
            if (value != null) {
              if (value == 'system') {
                await ref
                    .read(localeNotifierProvider.notifier)
                    .setSystemDefault();
              } else {
                await ref
                    .read(localeNotifierProvider.notifier)
                    .setLocale(Locale(value));
              }
              ref.invalidate(appSettingsProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(S.of(context).languageSystem),
                value: 'system',
              ),
              ..._languageNames.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

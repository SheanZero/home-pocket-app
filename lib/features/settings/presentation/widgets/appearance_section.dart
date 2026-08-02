import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../application/i18n/locale_settings_view.dart';
import '../../../../shared/widgets/settings_section_card.dart';
import '../../domain/models/app_settings.dart';
import '../providers/state_locale.dart';
import '../providers/repository_providers.dart';
import '../providers/state_settings.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSectionCard(
      title: S.of(context).settingsGeneral,
      children: [
        ThemeSettingTile(settings: settings),
        const LanguageSettingTile(),
        WeekStartSettingTile(settings: settings),
      ],
    );
  }
}

/// Theme row reused by the compact General section on [SettingsScreen].
class ThemeSettingTile extends ConsumerWidget {
  const ThemeSettingTile({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsActionTile(
      icon: Icons.contrast,
      title: S.of(context).appearance,
      subtitle: _getThemeModeLabel(settings.themeMode, context),
      onTap: () => _showThemeModeDialog(context, ref),
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
}

/// Week-start row shown in the main General settings card.
class WeekStartSettingTile extends ConsumerWidget {
  const WeekStartSettingTile({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsActionTile(
      icon: Icons.calendar_month_outlined,
      title: S.of(context).settingsWeekStart,
      subtitle: _weekStartLabel(settings.weekStartDay, context),
      onTap: () => _showWeekStartDialog(context, ref, settings.weekStartDay),
    );
  }

  void _showWeekStartDialog(
    BuildContext context,
    WidgetRef ref,
    WeekStartDay current,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).settingsWeekStart),
        content: RadioGroup<WeekStartDay>(
          groupValue: current,
          onChanged: (value) async {
            if (value != null) {
              await ref.read(settingsRepositoryProvider).setWeekStartDay(value);
              ref.invalidate(appSettingsProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WeekStartDay.values.map((day) {
              return RadioListTile<WeekStartDay>(
                title: Text(_weekStartLabel(day, context)),
                value: day,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Language picker tile that reads locale state from [localeProvider].
class LanguageSettingTile extends ConsumerWidget {
  const LanguageSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);
    final localeSettings = localeAsync.value;

    return SettingsActionTile(
      icon: Icons.language,
      title: S.of(context).language,
      subtitle: _buildSubtitle(localeSettings, context),
      onTap: () => _showLanguageDialog(context, ref, localeSettings),
    );
  }

  String _buildSubtitle(LocaleSettings? localeSettings, BuildContext context) {
    if (localeSettings == null) {
      return '';
    }
    final nativeName =
        _languageNames(context)[localeSettings.locale.languageCode] ?? '';
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
                await ref.read(localeProvider.notifier).setSystemDefault();
              } else {
                await ref
                    .read(localeProvider.notifier)
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
              ..._languageNames(context).entries.map((entry) {
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

String _weekStartLabel(WeekStartDay day, BuildContext context) {
  switch (day) {
    case WeekStartDay.monday:
      return S.of(context).settingsWeekStartMonday;
    case WeekStartDay.sunday:
      return S.of(context).settingsWeekStartSunday;
  }
}

Map<String, String> _languageNames(BuildContext context) {
  final l10n = S.of(context);
  return {
    'ja': l10n.languageJapanese,
    'zh': l10n.languageChinese,
    'en': l10n.languageEnglish,
  };
}

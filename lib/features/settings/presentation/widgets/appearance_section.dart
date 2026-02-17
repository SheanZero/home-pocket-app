import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/app_settings.dart';
import '../providers/repository_providers.dart';
import '../providers/settings_providers.dart';

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

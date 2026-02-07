import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Theme'),
          subtitle: Text(_getThemeModeLabel(settings.themeMode)),
          onTap: () => _showThemeModeDialog(context, ref),
        ),
      ],
    );
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: RadioGroup<AppThemeMode>(
          groupValue: settings.themeMode,
          onChanged: (value) async {
            if (value != null) {
              await ref
                  .read(settingsRepositoryProvider)
                  .setThemeMode(value);
              ref.invalidate(appSettingsProvider);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeMode.values.map((mode) {
              return RadioListTile<AppThemeMode>(
                title: Text(_getThemeModeLabel(mode)),
                value: mode,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _getThemeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }
}

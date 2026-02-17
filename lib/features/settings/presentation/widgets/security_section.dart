import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/app_settings.dart';
import '../providers/repository_providers.dart';
import '../providers/settings_providers.dart';

class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            S.of(context).security,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint),
          title: Text(S.of(context).biometricLock),
          subtitle: Text(S.of(context).biometricLockDescription),
          value: settings.biometricLockEnabled,
          onChanged: (value) async {
            await ref.read(settingsRepositoryProvider).setBiometricLock(value);
            ref.invalidate(appSettingsProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.notifications),
          title: Text(S.of(context).notifications),
          subtitle: Text(S.of(context).notificationsDescription),
          value: settings.notificationsEnabled,
          onChanged: (value) async {
            await ref
                .read(settingsRepositoryProvider)
                .setNotificationsEnabled(value);
            ref.invalidate(appSettingsProvider);
          },
        ),
      ],
    );
  }
}

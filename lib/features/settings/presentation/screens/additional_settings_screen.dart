import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/settings_section_card.dart';
import '../providers/state_settings.dart';
import '../widgets/appearance_section.dart';
import '../widgets/delete_all_data_section.dart';
import '../widgets/security_section.dart';
import '../widgets/voice_section.dart';

/// Secondary preferences that do not belong to the mockup's primary hierarchy.
class AdditionalSettingsScreen extends ConsumerWidget {
  const AdditionalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(centerTitle: true, title: Text(l10n.settingsAdditional)),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            SettingsSectionCard(
              title: l10n.settingsGeneral,
              children: [WeekStartSettingTile(settings: settings)],
            ),
            VoiceSection(settings: settings),
            SettingsSectionCard(
              title: l10n.notifications,
              children: [NotificationsSettingTile(settings: settings)],
            ),
            const DeleteAllDataSection(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

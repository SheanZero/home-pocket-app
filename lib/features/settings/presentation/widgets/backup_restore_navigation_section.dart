import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/settings_section_card.dart';
import '../screens/backup_restore_screen.dart';

class BackupRestoreNavigationSection extends StatelessWidget {
  const BackupRestoreNavigationSection({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return SettingsSectionCard(
      title: l10n.settingsData,
      children: [
        SettingsNavigationTile(
          key: const ValueKey('settings-backup-restore'),
          icon: Icons.storage_outlined,
          title: l10n.backupAndRestore,
          subtitle: l10n.backupAndRestoreDescription,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BackupRestoreScreen(bookId: bookId),
            ),
          ),
        ),
      ],
    );
  }
}

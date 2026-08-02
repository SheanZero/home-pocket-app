import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/state/data_reset_signal.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/settings_section_card.dart';
import '../providers/repository_providers.dart';
import '../widgets/password_dialog.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(centerTitle: true, title: Text(l10n.backupAndRestore)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _BackupHeroCard(busy: _busy),
          ),
          SettingsSectionCard(
            title: l10n.backupSectionTitle,
            children: [
              SettingsNavigationTile(
                key: const ValueKey('backup-export'),
                icon: Icons.backup_outlined,
                title: l10n.exportBackup,
                subtitle: l10n.exportBackupDescription,
                onTap: _busy ? () {} : _exportBackup,
              ),
            ],
          ),
          SettingsSectionCard(
            title: l10n.restoreSectionTitle,
            children: [
              SettingsNavigationTile(
                key: const ValueKey('backup-import'),
                icon: Icons.restore_outlined,
                title: l10n.importBackup,
                subtitle: l10n.restoreReplacesData,
                onTap: _busy ? () {} : _importBackup,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: palette.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.backupPasswordNotStored,
                    style: AppTextStyles.supporting.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    final l10n = S.of(context);
    final password = await showPasswordDialog(
      context,
      title: l10n.setBackupPassword,
      description: l10n.backupPasswordNotStored,
      isExport: true,
    );
    if (password == null || !mounted) return;

    setState(() => _busy = true);
    final result = await ref
        .read(exportBackupUseCaseProvider)
        .execute(bookId: widget.bookId, password: password);
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.isSuccess && result.data != null) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(result.data!.path)]),
      );
      if (mounted) {
        showSuccessFeedback(context, S.of(context).backupExportedSuccessfully);
      }
      return;
    }
    showErrorFeedback(context, result.error ?? S.of(context).exportFailed);
  }

  Future<void> _importBackup() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['hpb'],
    );
    if (picked == null || picked.files.single.path == null || !mounted) return;

    final l10n = S.of(context);
    final password = await showPasswordDialog(
      context,
      title: l10n.enterBackupPassword,
      description: '${l10n.restoreWarningTitle}\n${l10n.restoreWarningBody}',
      isDestructive: true,
    );
    if (password == null || !mounted) return;

    setState(() => _busy = true);
    final result = await ref
        .read(importBackupUseCaseProvider)
        .execute(
          backupFile: File(picked.files.single.path!),
          password: password,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.isSuccess) {
      ref.read(dataResetSignalProvider.notifier).fire();
      showSuccessFeedback(context, S.of(context).backupImportedSuccessfully);
      return;
    }
    showErrorFeedback(context, result.error ?? S.of(context).importFailed);
  }

}

class _BackupHeroCard extends StatelessWidget {
  const _BackupHeroCard({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.accentPrimaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: busy
                ? Padding(
                    padding: const EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: palette.accentPrimary,
                    ),
                  )
                : Icon(
                    Icons.enhanced_encryption_outlined,
                    color: palette.accentPrimary,
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.backupHeroTitle,
            style: AppTextStyles.sectionTitle.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.backupHeroDescription,
            style: AppTextStyles.body.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TrustChip(
                icon: Icons.lock_outline,
                label: l10n.backupEncryptionChip,
              ),
              _TrustChip(
                icon: Icons.folder_zip_outlined,
                label: l10n.backupCompressedChip,
              ),
              _TrustChip(
                icon: Icons.cloud_off_outlined,
                label: l10n.backupNoUploadChip,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.backgroundMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: palette.accentPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.compact.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

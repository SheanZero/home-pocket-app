import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/state/data_reset_signal.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../providers/repository_providers.dart';
import 'password_dialog.dart';

class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            S.of(context).dataManagement,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: Text(S.of(context).exportBackup),
          subtitle: Text(S.of(context).exportBackupDescription),
          onTap: () => _exportBackup(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: Text(S.of(context).importBackup),
          subtitle: Text(S.of(context).importBackupDescription),
          onTap: () => _importBackup(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever),
          title: Text(S.of(context).deleteAllData),
          subtitle: Text(S.of(context).deleteAllDataDescription),
          onTap: () => _showDeleteAllDataDialog(context, ref),
        ),
      ],
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final password = await showPasswordDialog(
      context,
      title: S.of(context).setBackupPassword,
      isExport: true,
    );
    if (password == null) return;

    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ref
        .read(exportBackupUseCaseProvider)
        .execute(bookId: bookId, password: password);

    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading

    if (result.isSuccess && result.data != null) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(result.data!.path)]),
      );
      if (context.mounted) {
        showSuccessFeedback(context, S.of(context).backupExportedSuccessfully);
      }
    } else {
      if (context.mounted) {
        showErrorFeedback(context, result.error ?? S.of(context).exportFailed);
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['hpb'],
    );

    if (result == null || result.files.single.path == null) return;

    if (!context.mounted) return;

    final password = await showPasswordDialog(
      context,
      title: S.of(context).enterBackupPassword,
    );
    if (password == null) return;

    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final importResult = await ref
        .read(importBackupUseCaseProvider)
        .execute(
          backupFile: File(result.files.single.path!),
          password: password,
        );

    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading

    if (importResult.isSuccess) {
      // Refresh Home / List / Analytics without an app restart (260627-v0w).
      ref.read(dataResetSignalProvider.notifier).fire();
      if (context.mounted) {
        showSuccessFeedback(context, S.of(context).backupImportedSuccessfully);
      }
    } else {
      if (context.mounted) {
        showErrorFeedback(
          context,
          importResult.error ?? S.of(context).importFailed,
        );
      }
    }
  }

  Future<void> _showDeleteAllDataDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showSoftConfirmDialog(
      context,
      title: S.of(context).deleteAllData,
      body: S.of(context).deleteAllDataConfirmation,
      confirmLabel: S.of(context).delete,
      cancelLabel: S.of(context).cancel,
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref.read(clearAllDataUseCaseProvider).execute();
    if (!context.mounted) return;

    if (result.isSuccess) {
      // Refresh Home / List / Analytics without an app restart (260627-v0w).
      ref.read(dataResetSignalProvider.notifier).fire();
      showSuccessFeedback(context, S.of(context).allDataDeleted);
    } else {
      showErrorFeedback(context, result.error ?? S.of(context).deleteFailed);
    }
  }
}

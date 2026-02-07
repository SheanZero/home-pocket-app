import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/backup_providers.dart';
import 'password_dialog.dart';

class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Data Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Export Backup'),
          subtitle: const Text('Create encrypted backup file'),
          onTap: () => _exportBackup(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Import Backup'),
          subtitle: const Text('Restore from backup file'),
          onTap: () => _importBackup(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever),
          title: const Text('Delete All Data'),
          subtitle: const Text('Permanently delete all records'),
          onTap: () => _showDeleteAllDataDialog(context, ref),
        ),
      ],
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final password = await showPasswordDialog(
      context,
      title: 'Set Backup Password',
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

    final result = await ref.read(exportBackupUseCaseProvider).execute(
          bookId: bookId,
          password: password,
        );

    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading

    if (result.isSuccess && result.data != null) {
      await Share.shareXFiles([XFile(result.data!.path)]);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported successfully')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Export failed')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['hpb'],
    );

    if (result == null || result.files.single.path == null) return;

    if (!context.mounted) return;

    final password = await showPasswordDialog(
      context,
      title: 'Enter Backup Password',
    );
    if (password == null) return;

    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final importResult =
        await ref.read(importBackupUseCaseProvider).execute(
              backupFile: File(result.files.single.path!),
              password: password,
            );

    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading

    if (importResult.isSuccess) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup imported successfully')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(importResult.error ?? 'Import failed')),
        );
      }
    }
  }

  void _showDeleteAllDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content:
            const Text('This action cannot be undone. Are you sure you want '
                'to delete all data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result =
                  await ref.read(clearAllDataUseCaseProvider).execute();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.isSuccess
                          ? 'All data deleted'
                          : (result.error ?? 'Delete failed'),
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

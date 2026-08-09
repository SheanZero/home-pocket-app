import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/presentation/screens/backup_restore_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../helpers/test_localizations.dart';

void main() {
  testWidgets('renders the encrypted HPB backup and restore flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const BackupRestoreScreen(bookId: 'book-backup-test'),
        locale: const Locale('ja'),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = S.of(tester.element(find.byType(BackupRestoreScreen)));

    expect(find.text(l10n.backupAndRestore), findsOneWidget);
    expect(find.text(l10n.backupHeroTitle), findsOneWidget);
    expect(find.text(l10n.exportBackup), findsOneWidget);
    expect(find.text(l10n.importBackup), findsOneWidget);
    expect(find.text(l10n.backupPasswordNotStored), findsOneWidget);
    expect(find.text(l10n.deleteAllData), findsNothing);
    expect(find.textContaining('AES-256-GCM'), findsOneWidget);
    expect(find.textContaining('.hpb'), findsOneWidget);
    expect(find.textContaining('CSV'), findsNothing);
  });

  test('keeps the file picker, encrypted restore, and share entry points', () {
    final backupRestoreSource = File(
      'lib/features/settings/presentation/screens/backup_restore_screen.dart',
    ).readAsStringSync();
    final createGroupSource = File(
      'lib/features/family_sync/presentation/screens/create_group_screen.dart',
    ).readAsStringSync();
    final groupManagementSource = File(
      'lib/features/family_sync/presentation/screens/group_management_screen.dart',
    ).readAsStringSync();

    expect(backupRestoreSource, contains('FilePicker.pickFiles('));
    expect(backupRestoreSource, contains('type: FileType.custom'));
    expect(backupRestoreSource, contains("allowedExtensions: const ['hpb']"));
    expect(
      backupRestoreSource,
      contains(
        'picked == null || picked.files.single.path == null || !mounted',
      ),
    );
    expect(backupRestoreSource, contains('restoreBackupUseCaseProvider'));
    expect(
      backupRestoreSource,
      contains(
        'SharePlus.instance.share(\n        ShareParams(files: [XFile(result.data!.path)]),',
      ),
    );
    expect(
      createGroupSource,
      contains('SharePlus.instance.share(ShareParams(text: text))'),
    );
    expect(
      groupManagementSource,
      contains('SharePlus.instance.share(ShareParams(text: text))'),
    );
  });
}

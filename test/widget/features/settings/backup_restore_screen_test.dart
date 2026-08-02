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
}

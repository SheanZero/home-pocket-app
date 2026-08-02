import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/presentation/screens/backup_restore_screen.dart';
import 'package:home_pocket/features/settings/presentation/screens/legal_sponsor_screen.dart';
import 'package:home_pocket/features/settings/presentation/widgets/backup_restore_navigation_section.dart';
import 'package:home_pocket/features/settings/presentation/widgets/legal_sponsor_navigation_section.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../helpers/test_localizations.dart';

void main() {
  testWidgets('backup settings row opens the dedicated screen', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const Scaffold(
          body: BackupRestoreNavigationSection(bookId: 'book-backup-test'),
        ),
        locale: const Locale('ja'),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = S.of(
      tester.element(find.byType(BackupRestoreNavigationSection)),
    );
    await tester.tap(find.text(l10n.backupAndRestore));
    await tester.pumpAndSettle();

    expect(find.byType(BackupRestoreScreen), findsOneWidget);
  });

  testWidgets('legal settings row opens the dedicated screen', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const Scaffold(body: LegalSponsorNavigationSection()),
        locale: const Locale('ja'),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = S.of(
      tester.element(find.byType(LegalSponsorNavigationSection)),
    );
    await tester.tap(find.text(l10n.legalSponsorSectionTitle));
    await tester.pumpAndSettle();

    expect(find.byType(LegalSponsorScreen), findsOneWidget);
  });
}

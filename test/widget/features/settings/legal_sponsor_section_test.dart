import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/licenses/app_license_registry.dart';
import 'package:home_pocket/features/settings/presentation/screens/legal_doc_screen.dart';
import 'package:home_pocket/features/settings/presentation/widgets/legal_sponsor_section.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../helpers/test_localizations.dart';

void main() {
  setUpAll(registerBundledThirdPartyLicenses);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const Scaffold(
          body: SingleChildScrollView(child: LegalSponsorSection()),
        ),
        locale: const Locale('ja'),
      ),
    );
    await tester.pumpAndSettle();
  }

  S l10nOf(WidgetTester tester) =>
      S.of(tester.element(find.byType(LegalSponsorSection)));

  testWidgets('renders legal links and hides first-release sponsorship', (
    tester,
  ) async {
    await pump(tester);
    final l10n = l10nOf(tester);

    expect(find.text(l10n.legalSponsorSectionTitle), findsOneWidget);
    expect(find.text(l10n.privacyPolicy), findsOneWidget);
    expect(find.text(l10n.termsOfUse), findsOneWidget);
    expect(find.text(l10n.tokushoNotice), findsOneWidget);
    expect(find.text(l10n.openSourceLicenses), findsOneWidget);
    expect(find.text(l10n.sponsorCardTitle), findsNothing);
    expect(find.text(l10n.sponsorButton), findsNothing);
  });

  testWidgets('privacy row opens the bundled document internally', (
    tester,
  ) async {
    await pump(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.privacyPolicy));
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocScreen), findsOneWidget);
    expect(
      tester.widget<LegalDocScreen>(find.byType(LegalDocScreen)).doc,
      LegalDoc.privacy,
    );
  });

  testWidgets('terms row opens its bundled document internally', (
    tester,
  ) async {
    await pump(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.termsOfUse));
    await tester.pumpAndSettle();
    expect(
      tester.widget<LegalDocScreen>(find.byType(LegalDocScreen)).doc,
      LegalDoc.terms,
    );
  });

  testWidgets('tokusho row opens its bundled document internally', (
    tester,
  ) async {
    await pump(tester);
    final l10n = l10nOf(tester);

    await tester.ensureVisible(find.text(l10n.tokushoNotice));
    await tester.tap(find.text(l10n.tokushoNotice));
    await tester.pumpAndSettle();
    expect(find.byType(LegalDocScreen), findsOneWidget);
    expect(
      tester.widget<LegalDocScreen>(find.byType(LegalDocScreen)).doc,
      LegalDoc.tokusho,
    );
  });

  testWidgets('OSS license row invokes showLicensePage', (tester) async {
    await pump(tester);
    final l10n = l10nOf(tester);

    await tester.ensureVisible(find.text(l10n.openSourceLicenses));
    await tester.tap(find.text(l10n.openSourceLicenses));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('Roboto Mono'), findsOneWidget);
  });

  testWidgets('legal rows use internal-navigation affordances', (tester) async {
    await pump(tester);

    expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
    expect(find.byIcon(Icons.open_in_new), findsNothing);
  });
}

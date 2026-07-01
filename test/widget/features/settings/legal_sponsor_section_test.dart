import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/config/legal_urls.dart';
import 'package:home_pocket/features/settings/presentation/screens/legal_doc_screen.dart';
import 'package:home_pocket/features/settings/presentation/widgets/legal_sponsor_section.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../helpers/test_localizations.dart';

/// Mocks the url_launcher platform channel so no real browser is needed.
/// Captures the launched URL + options for DONATE-02 assertions.
class _MockLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastUrl;
  LaunchOptions? lastOptions;
  bool result = true;
  bool shouldThrow = false;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastUrl = url;
    lastOptions = options;
    if (shouldThrow) {
      throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
    }
    return result;
  }

  @override
  Future<bool> canLaunch(String url) async => true;
}

void main() {
  late _MockLauncher launcher;

  setUp(() {
    launcher = _MockLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

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

  testWidgets('renders the section title and all 5 tone-C rows', (tester) async {
    await pump(tester);
    final l = l10nOf(tester);

    expect(find.text(l.legalSponsorSectionTitle), findsOneWidget);
    expect(find.text(l.privacyPolicy), findsOneWidget);
    expect(find.text(l.termsOfUse), findsOneWidget);
    expect(find.text(l.tokushoNotice), findsOneWidget);
    expect(find.text(l.openSourceLicenses), findsOneWidget);
    expect(find.text(l.sponsorRow), findsOneWidget);
  });

  testWidgets('privacy/terms/tokusho rows push LegalDocScreen with matching doc',
      (tester) async {
    await pump(tester);
    final l = l10nOf(tester);

    await tester.tap(find.text(l.privacyPolicy));
    await tester.pumpAndSettle();
    expect(find.byType(LegalDocScreen), findsOneWidget);
    expect(
      tester.widget<LegalDocScreen>(find.byType(LegalDocScreen)).doc,
      LegalDoc.privacy,
    );
    Navigator.of(tester.element(find.byType(LegalDocScreen))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text(l.termsOfUse));
    await tester.pumpAndSettle();
    expect(
      tester.widget<LegalDocScreen>(find.byType(LegalDocScreen)).doc,
      LegalDoc.terms,
    );
    Navigator.of(tester.element(find.byType(LegalDocScreen))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text(l.tokushoNotice));
    await tester.pumpAndSettle();
    expect(
      tester.widget<LegalDocScreen>(find.byType(LegalDocScreen)).doc,
      LegalDoc.tokusho,
    );
  });

  testWidgets('OSS license row invokes showLicensePage (LEGAL-03)',
      (tester) async {
    await pump(tester);
    final l = l10nOf(tester);

    await tester.tap(find.text(l.openSourceLicenses));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets(
      'sponsor row launches the external browser at LegalUrls.donation (DONATE-02/04)',
      (tester) async {
    await pump(tester);
    final l = l10nOf(tester);

    await tester.tap(find.text(l.sponsorRow));
    await tester.pumpAndSettle();

    expect(launcher.lastUrl, LegalUrls.donation);
    expect(launcher.lastOptions?.mode, PreferredLaunchMode.externalApplication);
  });

  testWidgets('tapping the sponsor row shows NO dialog/popup (DONATE-03)',
      (tester) async {
    await pump(tester);
    final l = l10nOf(tester);

    await tester.tap(find.text(l.sponsorRow));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('sponsor launch failure shows a single neutral SnackBar (T-56-06)',
      (tester) async {
    launcher.result = false;
    await pump(tester);
    final l = l10nOf(tester);

    await tester.tap(find.text(l.sponsorRow));
    await tester.pumpAndSettle();

    expect(find.text(l.sponsorLaunchError), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
      'sponsor launch that THROWS still shows the neutral SnackBar and does not crash (CR-01)',
      (tester) async {
    launcher.shouldThrow = true;
    await pump(tester);
    final l = l10nOf(tester);

    await tester.tap(find.text(l.sponsorRow));
    await tester.pumpAndSettle();

    // The thrown PlatformException must be swallowed: neutral SnackBar shows,
    // no exception escapes to tester.takeException().
    expect(find.text(l.sponsorLaunchError), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the sponsor external-link affordance is colored via palette.shared (tone-C)',
      (tester) async {
    await pump(tester);

    final ext = tester.widget<Icon>(find.byIcon(Icons.open_in_new));
    // ADR-019 v1.6 light `shared` steel-blue.
    expect(ext.color, const Color(0xFF5B8AC4));
  });
}

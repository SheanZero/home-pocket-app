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

  test('production legal and support URLs are HTTPS and not placeholders', () {
    final urls = [
      LegalUrls.privacyPolicyFor('ja'),
      LegalUrls.termsOfUseFor('ja'),
      LegalUrls.tokushoFor('ja'),
      LegalUrls.support,
    ];

    for (final url in urls) {
      expect(Uri.parse(url).scheme, 'https');
      expect(url, isNot(contains('example.com')));
    }
  });

  testWidgets('renders legal links and the support card', (tester) async {
    await pump(tester);
    final l10n = l10nOf(tester);

    expect(find.text(l10n.legalSponsorSectionTitle), findsOneWidget);
    expect(find.text(l10n.privacyPolicy), findsOneWidget);
    expect(find.text(l10n.termsOfUse), findsOneWidget);
    expect(find.text(l10n.tokushoNotice), findsOneWidget);
    expect(find.text(l10n.openSourceLicenses), findsOneWidget);
    expect(find.text(l10n.sponsorCardTitle), findsOneWidget);
    expect(find.text(l10n.sponsorButton), findsOneWidget);
  });

  testWidgets('privacy row opens the real localized URL externally', (
    tester,
  ) async {
    await pump(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.privacyPolicy));
    await tester.pumpAndSettle();

    expect(launcher.lastUrl, LegalUrls.privacyPolicyFor('ja'));
    expect(launcher.lastOptions?.mode, PreferredLaunchMode.externalApplication);
    expect(find.byType(LegalDocScreen), findsNothing);
  });

  testWidgets('terms and tokusho rows use their real localized URLs', (
    tester,
  ) async {
    await pump(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.termsOfUse));
    await tester.pumpAndSettle();
    expect(launcher.lastUrl, LegalUrls.termsOfUseFor('ja'));

    await tester.ensureVisible(find.text(l10n.tokushoNotice));
    await tester.tap(find.text(l10n.tokushoNotice));
    await tester.pumpAndSettle();
    expect(launcher.lastUrl, LegalUrls.tokushoFor('ja'));
  });

  testWidgets('failed legal launch falls back to the bundled offline reader', (
    tester,
  ) async {
    launcher.result = false;
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

  testWidgets('OSS license row invokes showLicensePage', (tester) async {
    await pump(tester);
    final l10n = l10nOf(tester);

    await tester.ensureVisible(find.text(l10n.openSourceLicenses));
    await tester.tap(find.text(l10n.openSourceLicenses));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('support button opens the operator contact page externally', (
    tester,
  ) async {
    await pump(tester);
    final l10n = l10nOf(tester);
    await tester.ensureVisible(find.text(l10n.sponsorButton));

    await tester.tap(find.text(l10n.sponsorButton));
    await tester.pumpAndSettle();

    expect(launcher.lastUrl, LegalUrls.support);
    expect(launcher.lastOptions?.mode, PreferredLaunchMode.externalApplication);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('support launch failure shows one neutral SnackBar', (
    tester,
  ) async {
    launcher.result = false;
    await pump(tester);
    final l10n = l10nOf(tester);
    await tester.ensureVisible(find.text(l10n.sponsorButton));

    await tester.tap(find.text(l10n.sponsorButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.sponsorLaunchError), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a throwing support launch is handled without crashing', (
    tester,
  ) async {
    launcher.shouldThrow = true;
    await pump(tester);
    final l10n = l10nOf(tester);
    await tester.ensureVisible(find.text(l10n.sponsorButton));

    await tester.tap(find.text(l10n.sponsorButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.sponsorLaunchError), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external legal affordances use the shared-link palette', (
    tester,
  ) async {
    await pump(tester);

    final icons = tester.widgetList<Icon>(find.byIcon(Icons.open_in_new));
    expect(icons, isNotEmpty);
    expect(icons.first.color, const Color(0xFF4F7186));
  });
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/legal_urls.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../screens/legal_doc_screen.dart';

/// The `法的情報・応援` settings group (tone-C, sketch 003).
///
/// Renders 5 rows: privacy policy / 利用規約 / 特商法 / OSS ライセンス /
/// 開発を応援する. The privacy/terms/tokusho rows push the offline
/// [LegalDocScreen] (LEGAL-01/02/04); the OSS row reuses the framework
/// [showLicensePage] (LEGAL-03); the sponsor row hands [LegalUrls.donation] to
/// the OS browser via `url_launcher` (DONATE-02/04) — non-transactional, no
/// dialog, no in-app WebView/IAP (DONATE-01/03).
///
/// Inserted into `settings_screen.dart` by plan 56-06.
class LegalSponsorSection extends StatelessWidget {
  const LegalSponsorSection({super.key});

  void _pushDoc(BuildContext context, LegalDoc doc) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalDocScreen(doc: doc)),
    );
  }

  /// Launches the sponsor URL in the external browser (DONATE-02).
  ///
  /// Launches directly rather than pre-checking launchability, since that check
  /// returns a false-negative on Android 11+ for https without a `<queries>`
  /// entry. On failure shows one neutral SnackBar — never crashes, never
  /// retries (T-56-06).
  Future<void> _openSponsor(BuildContext context) async {
    final l10n = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(
      Uri.parse(LegalUrls.donation),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.sponsorLaunchError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.legalSponsorSectionTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: Text(l10n.privacyPolicy),
          onTap: () => _pushDoc(context, LegalDoc.privacy),
        ),
        ListTile(
          leading: const Icon(Icons.gavel),
          title: Text(l10n.termsOfUse),
          onTap: () => _pushDoc(context, LegalDoc.terms),
        ),
        ListTile(
          leading: const Icon(Icons.receipt_long),
          title: Text(l10n.tokushoNotice),
          subtitle: Text(l10n.tokushoNoticeSubtitle),
          onTap: () => _pushDoc(context, LegalDoc.tokusho),
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: Text(l10n.openSourceLicenses),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: S.of(context).appName,
              applicationVersion: '0.1.0',
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.favorite),
          title: Text(l10n.sponsorRow),
          subtitle: Text(l10n.sponsorRowSubtitle),
          // tone-C external-link affordance — ADR-019 `shared` steel-blue
          // resolved via context.palette (never a hardcoded literal).
          trailing: Icon(Icons.open_in_new, size: 18, color: palette.shared),
          onTap: () => _openSponsor(context),
        ),
      ],
    );
  }
}

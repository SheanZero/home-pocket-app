import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/legal_urls.dart';
import '../../../../core/constants/app_info.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/settings_section_card.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../screens/legal_doc_screen.dart';

class LegalSponsorSection extends StatelessWidget {
  const LegalSponsorSection({super.key, this.showTitle = true});

  final bool showTitle;

  Future<void> _openLegalDocument(
    BuildContext context,
    LegalDoc doc,
    String url,
  ) async {
    final opened = await _launchExternal(url);
    if (!context.mounted || opened) return;

    // Legal text remains available offline if the browser cannot be opened.
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => LegalDocScreen(doc: doc)));
  }

  Future<void> _openSupport(BuildContext context) async {
    final opened = await _launchExternal(LegalUrls.support);
    if (!opened && context.mounted) {
      showErrorFeedback(context, S.of(context).sponsorLaunchError);
    }
  }

  Future<bool> _launchExternal(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('external link launch failed: $error');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final languageCode = Localizations.localeOf(context).languageCode;

    final legalRows = SettingsSectionCard(
      title: showTitle ? l10n.legalSponsorSectionTitle : null,
      children: [
        _LegalLinkTile(
          icon: Icons.privacy_tip_outlined,
          title: l10n.privacyPolicy,
          subtitle: l10n.privacyPolicyDescription,
          onTap: () => _openLegalDocument(
            context,
            LegalDoc.privacy,
            LegalUrls.privacyPolicyFor(languageCode),
          ),
        ),
        _LegalLinkTile(
          icon: Icons.description_outlined,
          title: l10n.termsOfUse,
          subtitle: l10n.termsOfUseDescription,
          onTap: () => _openLegalDocument(
            context,
            LegalDoc.terms,
            LegalUrls.termsOfUseFor(languageCode),
          ),
        ),
        _LegalLinkTile(
          icon: Icons.storefront_outlined,
          title: l10n.tokushoNotice,
          subtitle: l10n.tokushoNoticeSubtitle,
          onTap: () => _openLegalDocument(
            context,
            LegalDoc.tokusho,
            LegalUrls.tokushoFor(languageCode),
          ),
        ),
        _LegalLinkTile(
          icon: Icons.code_outlined,
          title: l10n.openSourceLicenses,
          subtitle: l10n.openSourceLicensesDescription,
          trailingExternal: false,
          onTap: () => showLicensePage(
            context: context,
            applicationName: l10n.appName,
            applicationVersion: appVersion,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        legalRows,
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Text(
            l10n.sponsorSectionTitle,
            style: AppTextStyles.sectionTitle.copyWith(
              color: palette.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Container(
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.joyLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.favorite_outline, color: palette.joyText),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.sponsorCardTitle,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.sponsorCardBody,
                  style: AppTextStyles.body.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const ValueKey('legal-support-link'),
                  onPressed: () => _openSupport(context),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(l10n.sponsorButton),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalLinkTile extends StatelessWidget {
  const _LegalLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingExternal = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool trailingExternal;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: palette.accentPrimaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: palette.accentPrimary, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.itemTitle.copyWith(color: palette.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.supporting.copyWith(color: palette.textSecondary),
      ),
      trailing: Icon(
        trailingExternal ? Icons.open_in_new : Icons.chevron_right,
        color: trailingExternal ? palette.shared : palette.textTertiary,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

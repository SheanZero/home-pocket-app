import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/settings_section_card.dart';
import '../screens/legal_sponsor_screen.dart';

class LegalSponsorNavigationSection extends StatelessWidget {
  const LegalSponsorNavigationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return SettingsSectionCard(
      title: l10n.settingsThisApp,
      children: [
        SettingsNavigationTile(
          key: const ValueKey('settings-legal-sponsor'),
          icon: Icons.policy_outlined,
          title: l10n.legalSponsorSectionTitle,
          subtitle: l10n.legalNavigationSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const LegalSponsorScreen()),
          ),
        ),
      ],
    );
  }
}

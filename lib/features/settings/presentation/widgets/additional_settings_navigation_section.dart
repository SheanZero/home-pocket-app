import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/settings_section_card.dart';
import '../screens/additional_settings_screen.dart';

class AdditionalSettingsNavigationSection extends StatelessWidget {
  const AdditionalSettingsNavigationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return SettingsSectionCard(
      title: null,
      children: [
        SettingsNavigationTile(
          icon: Icons.tune,
          title: l10n.settingsAdditional,
          subtitle: l10n.settingsAdditionalDescription,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdditionalSettingsScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

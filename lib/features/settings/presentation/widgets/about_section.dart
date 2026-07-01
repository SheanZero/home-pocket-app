import 'package:flutter/material.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../generated/app_localizations.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            S.of(context).about,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: Text(S.of(context).version),
          subtitle: const Text(appVersion),
        ),
        // Privacy + OSS-license tiles migrated to LegalSponsorSection (tone-C):
        // this section is version-only to avoid duplicate legal entries.
      ],
    );
  }
}

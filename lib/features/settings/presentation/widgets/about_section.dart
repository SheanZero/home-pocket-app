import 'package:flutter/material.dart';

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
          subtitle: const Text('0.1.0'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: Text(S.of(context).privacyPolicy),
          onTap: () {
            // TODO: Navigate to privacy policy
          },
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: Text(S.of(context).openSourceLicenses),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: S.of(context).appName,
              applicationVersion: '0.1.0',
            );
          },
        ),
      ],
    );
  }
}

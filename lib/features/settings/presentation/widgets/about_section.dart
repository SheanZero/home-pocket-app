import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('Version'),
          subtitle: Text('0.1.0'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Privacy Policy'),
          onTap: () {
            // TODO: Navigate to privacy policy
          },
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Open Source Licenses'),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'Home Pocket',
              applicationVersion: '0.1.0',
            );
          },
        ),
      ],
    );
  }
}

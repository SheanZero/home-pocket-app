import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../providers/settings_providers.dart';
import '../widgets/about_section.dart';
import '../widgets/appearance_section.dart';
import '../widgets/data_management_section.dart';
import '../widgets/security_section.dart';

/// Main settings screen with all configuration sections.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settings)),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            AppearanceSection(settings: settings),
            const Divider(),
            DataManagementSection(bookId: bookId),
            const Divider(),
            SecuritySection(settings: settings),
            const Divider(),
            const AboutSection(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/analytics/get_monthly_joy_target_recommendation_use_case.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart';
import '../../../../features/analytics/domain/models/metric_result.dart';
import '../../../../features/analytics/presentation/providers/state_happiness.dart';
import '../../../../generated/app_localizations.dart';
import '../../../family_sync/presentation/widgets/family_sync_settings_section.dart';
import '../../../profile/presentation/widgets/profile_section_card.dart';
import '../providers/repository_providers.dart';
import '../providers/state_settings.dart';
import '../widgets/about_section.dart';
import '../widgets/appearance_section.dart';
import '../widgets/data_management_section.dart';
import '../widgets/joy_target_section.dart';
import '../widgets/security_section.dart';
import '../widgets/voice_section.dart';

/// Main settings screen with all configuration sections.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final bookAsync = ref.watch(bookByIdProvider(bookId: bookId));
    final currencyCode = bookAsync.value?.currency ?? 'JPY';
    final recommendationAsync = ref.watch(
      monthlyJoyTargetRecommendationProvider(
        bookId: bookId,
        currencyCode: currencyCode,
      ),
    );
    final recommendedTarget = switch (recommendationAsync.value) {
      Value<int>(:final data) => data,
      _ => null,
    };
    final fallbackTarget =
        GetMonthlyJoyTargetRecommendationUseCase.fallbackBaseline;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settings)),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            const ProfileSectionCard(),
            const Divider(),
            AppearanceSection(settings: settings),
            const Divider(),
            VoiceSection(settings: settings),
            const Divider(),
            JoyTargetSection(
              configuredTarget: settings.monthlyJoyTarget,
              recommendedTarget: recommendedTarget,
              fallbackTarget: fallbackTarget,
              onSave: (value) async {
                await ref
                    .read(settingsRepositoryProvider)
                    .setMonthlyJoyTarget(value);
                ref.invalidate(appSettingsProvider);
              },
            ),
            const Divider(),
            DataManagementSection(bookId: bookId),
            const Divider(),
            const FamilySyncSettingsSection(),
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

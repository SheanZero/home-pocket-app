import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../widgets/family_flow_components.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';

class GroupChoiceScreen extends ConsumerWidget {
  const GroupChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: familyFlowHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 7),
              FamilyFlowHeader(
                title: l10n.familySync,
                onBack: () => Navigator.maybePop(context),
              ),
              const SizedBox(height: 31),
              Text(
                l10n.groupChoiceTitle,
                style: AppTextStyles.pageTitle.copyWith(
                  fontSize: 24,
                  height: 32 / 24,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                l10n.groupChoiceSubtitle,
                style: AppTextStyles.body.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              _FamilyChoiceCard(
                controlKey: const Key('family-choice-create'),
                lightAsset:
                    'docs/mockup/v16/assets/family-entry-create-warm-v1.png',
                darkAsset:
                    'docs/mockup/v16/assets/family-entry-create-warm-v1-dark.png',
                title: l10n.groupCreate,
                description: l10n.groupCreateDesc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateGroupScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _FamilyChoiceCard(
                controlKey: const Key('family-choice-join'),
                lightAsset:
                    'docs/mockup/v16/assets/family-entry-join-warm-v1.png',
                darkAsset:
                    'docs/mockup/v16/assets/family-entry-join-warm-v1-dark.png',
                title: l10n.familySyncEnterPartnerCode,
                description: l10n.groupJoinDesc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const JoinGroupScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 27),
              FamilyHelperNote(
                icon: LucideIcons.shieldCheck,
                text: l10n.groupE2eeHint,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyChoiceCard extends StatelessWidget {
  const _FamilyChoiceCard({
    required this.controlKey,
    required this.lightAsset,
    required this.darkAsset,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String lightAsset;
  final Key controlKey;
  final String darkAsset;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: controlKey,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 108),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: palette.accentPrimaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    isDark ? darkAsset : lightAsset,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTextStyles.supporting.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  size: 22,
                  color: palette.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

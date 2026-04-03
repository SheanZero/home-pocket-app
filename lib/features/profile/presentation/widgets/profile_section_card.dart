import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/user_profile_providers.dart';
import '../screens/profile_edit_screen.dart';
import 'avatar_display.dart';

class ProfileSectionCard extends ConsumerWidget {
  const ProfileSectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ProfileEditScreen(profile: profile),
                ),
              );
              if (changed == true) {
                ref.invalidate(userProfileProvider);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColorsDark.card : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColorsDark.borderDefault
                      : AppColors.borderDefault,
                ),
              ),
              child: Row(
                children: [
                  AvatarDisplay(
                    emoji: profile.avatarEmoji,
                    imagePath: profile.avatarImagePath,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          S.of(context).profileEdit,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: isDark
                                ? AppColorsDark.textSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isDark
                        ? AppColorsDark.textTertiary
                        : AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

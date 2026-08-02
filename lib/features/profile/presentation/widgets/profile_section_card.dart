import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/state_user_profile.dart';
import '../screens/profile_edit_screen.dart';
import 'avatar_display.dart';

class ProfileSectionCard extends ConsumerWidget {
  const ProfileSectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final palette = context.palette;

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('settings-profile-card'),
              borderRadius: BorderRadius.circular(18),
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
              child: Ink(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: palette.borderDefault),
                ),
                child: Row(
                  children: [
                    AvatarDisplay(
                      emoji: profile.avatarEmoji,
                      imagePath: profile.avatarImagePath,
                      size: 58,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            S.of(context).profileEditPersonalInfo,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: palette.textTertiary,
                    ),
                  ],
                ),
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

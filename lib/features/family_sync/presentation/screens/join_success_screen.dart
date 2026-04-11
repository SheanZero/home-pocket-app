import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import 'group_management_screen.dart';

const _purpleGradient = [
  Color(0xFFE8D5F5),
  Color(0xFFF3EAF9),
  Color(0xFFFAF5FD),
];

class JoinSuccessScreen extends ConsumerWidget {
  const JoinSuccessScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.ownerDisplayName,
    required this.ownerAvatarEmoji,
    required this.myDisplayName,
    required this.myAvatarEmoji,
  });

  final String groupId;
  final String groupName;
  final String ownerDisplayName;
  final String ownerAvatarEmoji;
  final String myDisplayName;
  final String myAvatarEmoji;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration emoji
                const Text('\u{1F389}', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 20),

                // Welcome title
                Text(
                  l10n.groupJoinSuccess,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Group name
                Text(
                  groupName,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Two overlapping avatars
                SizedBox(
                  width: 128,
                  height: 78,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: AvatarDisplay(
                            emoji: ownerAvatarEmoji,
                            size: 72,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: AvatarDisplay(
                            emoji: myAvatarEmoji,
                            size: 72,
                            gradientColors: _purpleGradient,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Names row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ownerDisplayName,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '&',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      myDisplayName,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Enter button (CTA)
                GestureDetector(
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => GroupManagementScreen(groupId: groupId),
                    ),
                    (_) => false,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE85A4F), Color(0xFFF08070)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x28E85A4F),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.arrowRight,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.groupEnterGroup,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

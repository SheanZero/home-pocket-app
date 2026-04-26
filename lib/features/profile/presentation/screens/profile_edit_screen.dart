import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/profile/save_user_profile_use_case.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/user_profile.dart';
import '../providers/repository_providers.dart';
import '../providers/state_user_profile.dart';
import '../widgets/avatar_display.dart';
import '../widgets/scattered_emoji_background.dart';
import 'avatar_picker_screen.dart';

const _editDarkBackground = Color(0xFF141418);
const _editDarkSurface = Color(0xFF2A2A32);
const _editDarkTextPrimary = Color(0xFFF0F0F5);
const _editDarkTextSecondary = Color(0xFF6B6B78);

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _nicknameController;
  late String _selectedEmoji;
  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _selectedEmoji = widget.profile.avatarEmoji;
    _selectedImagePath = widget.profile.avatarImagePath;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _canSave => _nicknameController.text.trim().isNotEmpty && !_isSaving;

  Future<void> _openAvatarPicker() async {
    final result = await Navigator.of(context).push<AvatarPickerResult>(
      MaterialPageRoute(
        builder: (_) => AvatarPickerScreen(
          currentEmoji: _selectedEmoji,
          currentImagePath: _selectedImagePath,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedEmoji = result.emoji;
      _selectedImagePath = result.imagePath;
    });
  }

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }

    final l10n = S.of(context);
    setState(() => _isSaving = true);

    final result = await ref
        .read(saveUserProfileUseCaseProvider)
        .execute(
          id: widget.profile.id,
          displayName: _nicknameController.text,
          avatarEmoji: _selectedEmoji,
          avatarImagePath: _selectedImagePath,
          oldAvatarImagePath: widget.profile.avatarImagePath,
        );

    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      ref.invalidate(userProfileProvider);
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSaving = false);

    final message = _profileEditMessageForError(l10n, result.error);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? _editDarkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark
        ? _editDarkTextSecondary
        : AppColors.textSecondary;
    final inputFill = isDark ? _editDarkSurface : AppColors.backgroundMuted;
    final inputBorder = isDark ? _editDarkSurface : AppColors.borderDefault;

    return Scaffold(
      backgroundColor: isDark ? _editDarkBackground : AppColors.background,
      body: ScatteredEmojiBackground(
        pattern: ScatteredEmojiPattern.profileEdit,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.chevron_left,
                        size: 22,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.profileEdit,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _openAvatarPicker,
                        child: Column(
                          children: [
                            AvatarDisplay(
                              emoji: _selectedEmoji,
                              imagePath: _selectedImagePath,
                              size: 110,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '✏️ ${l10n.profileChangeAvatar}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.profileNickname,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nicknameController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.profileNicknamePlaceholder,
                          hintStyle: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            color: textSecondary,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 16,
                              end: 10,
                            ),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                '📝',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          filled: true,
                          fillColor: inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.accentPrimary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ProfileEditButton(
                        label: l10n.profileSave,
                        enabled: _canSave,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _profileEditMessageForError(S l10n, SaveProfileError? error) {
  switch (error) {
    case SaveProfileError.nameRequired:
      return l10n.profileNameRequired;
    case SaveProfileError.nameTooLong:
      return l10n.profileNameTooLong;
    case SaveProfileError.invalidEmoji:
    case null:
      return l10n.profileSaveFailed;
  }
}

class _ProfileEditButton extends StatelessWidget {
  const _ProfileEditButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: enabled
              ? const [AppColors.accentPrimary, AppColors.fabGradientStart]
              : [
                  AppColors.accentPrimary.withValues(alpha: 0.45),
                  AppColors.fabGradientStart.withValues(alpha: 0.45),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPrimary.withValues(
              alpha: enabled ? 0.16 : 0.08,
            ),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundColor: Colors.white,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: enabled ? 1 : 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

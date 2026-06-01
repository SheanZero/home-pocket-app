import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/profile/save_user_profile_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../features/home/presentation/screens/main_shell_screen.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/constants/warm_emojis.dart';
import '../providers/repository_providers.dart';
import '../providers/state_user_profile.dart';
import '../widgets/avatar_display.dart';
import '../widgets/scattered_emoji_background.dart';
import 'avatar_picker_screen.dart';

class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState
    extends ConsumerState<ProfileOnboardingScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  late String _selectedEmoji;
  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = randomWarmEmoji();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nicknameController.text.trim().isNotEmpty && !_isSaving;

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

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    final l10n = S.of(context);
    setState(() => _isSaving = true);

    final result = await ref
        .read(saveUserProfileUseCaseProvider)
        .execute(
          displayName: _nicknameController.text,
          avatarEmoji: _selectedEmoji,
          avatarImagePath: _selectedImagePath,
        );

    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      ref.invalidate(userProfileProvider);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShellScreen(bookId: widget.bookId),
        ),
      );
      return;
    }

    setState(() => _isSaving = false);

    final message = _messageForError(l10n, result.error);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: ScatteredEmojiBackground(
        pattern: ScatteredEmojiPattern.onboarding,
        child: SafeArea(
          child: Center(
            child: SizedBox(
              width: 318,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 24),
                    child: Column(
                      children: [
                        Text(
                          l10n.profileSetup,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.profileSetupSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 28),
                    child: Column(
                      children: [
                        AvatarDisplay(
                          emoji: _selectedEmoji,
                          imagePath: _selectedImagePath,
                          size: 110,
                          onTap: _openAvatarPicker,
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _openAvatarPicker,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '✏️',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: palette.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.profileChangeAvatar,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileNickname,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nicknameController,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: palette.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.profileNicknamePlaceholder,
                            hintStyle: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              color: palette.textTertiary,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 14,
                                end: 10,
                              ),
                              child: Center(
                                widthFactor: 1,
                                child: Text(
                                  '📝',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                            filled: true,
                            fillColor: palette.card,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: palette.borderDefault),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: palette.borderDefault),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: palette.accentPrimary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ProfileGradientButton(
                          label: l10n.profileStart,
                          enabled: _canSubmit,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _messageForError(S l10n, SaveProfileError? error) {
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

class _ProfileGradientButton extends StatelessWidget {
  const _ProfileGradientButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: enabled
              ? [palette.accentPrimary, palette.fabGradientStart]
              : [
                  palette.accentPrimary.withValues(alpha: 0.45),
                  palette.fabGradientStart.withValues(alpha: 0.45),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.accentPrimary.withValues(
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/profile/save_user_profile_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../family_sync/presentation/providers/state_sync.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../domain/models/user_profile.dart';
import '../providers/repository_providers.dart';
import '../providers/state_user_profile.dart';
import '../widgets/avatar_display.dart';
import 'avatar_picker_screen.dart';

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
          onSaved: () => ref.read(syncEngineProvider).onProfileChanged(),
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
    showErrorFeedback(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(centerTitle: true, title: Text(l10n.profileEdit)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(
            children: [
              GestureDetector(
                onTap: _openAvatarPicker,
                child: Column(
                  children: [
                    AvatarDisplay(
                      emoji: _selectedEmoji,
                      imagePath: _selectedImagePath,
                      size: 88,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _openAvatarPicker,
                      child: Text(l10n.profileChangeAvatar),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.profileDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: palette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nicknameController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: palette.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: l10n.profileNicknamePlaceholder,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: palette.textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                    color: palette.textSecondary,
                  ),
                  filled: true,
                  fillColor: palette.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
              _ProfileEditButton(
                label: l10n.profileSave,
                enabled: _canSave,
                onPressed: _save,
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
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: palette.accentPrimary.withValues(alpha: enabled ? 1 : 0.45),
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

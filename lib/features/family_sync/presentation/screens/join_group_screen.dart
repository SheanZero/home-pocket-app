import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../application/family_sync/join_group_use_case.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/providers/user_profile_providers.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../providers/group_providers.dart';
import 'confirm_join_screen.dart';

const _purpleGradient = [
  Color(0xFFE8D5F5),
  Color(0xFFF3EAF9),
  Color(0xFFFAF5FD),
];

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();

  UserProfile? _profile;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
    unawaited(_loadProfile());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(userProfileProvider.future);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  String get _code => _codeController.text;

  bool get _isCodeComplete => _code.length == 6;

  Future<void> _handleVerify() async {
    if (!_isCodeComplete) return;

    final profile = _profile;
    if (profile == null) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final result = await ref.read(joinGroupUseCaseProvider).execute(
      inviteCode: _code,
      displayName: profile.displayName,
      avatarEmoji: profile.avatarEmoji,
    );

    if (!mounted) return;

    switch (result) {
      case JoinGroupVerified():
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ConfirmJoinScreen(result: result),
          ),
        );
      case JoinGroupError(:final message):
        setState(() {
          _isVerifying = false;
          _errorMessage = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final profile = _profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _Header(title: l10n.familySyncEnterPartnerCode),
              const SizedBox(height: 36),

              // Avatar section
              if (profile != null) ...[
                AvatarDisplay(
                  emoji: profile.avatarEmoji,
                  imagePath: profile.avatarImagePath,
                  size: 90,
                  gradientColors: _purpleGradient,
                ),
                const SizedBox(height: 12),
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.groupMyName,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Code input — single hidden TextField + visual digit boxes
              GestureDetector(
                onTap: () => _codeFocusNode.requestFocus(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Hidden TextField that captures all input
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        width: 1,
                        height: 1,
                        child: TextField(
                          controller: _codeController,
                          focusNode: _codeFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          autofocus: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                          ),
                        ),
                      ),
                    ),
                    // Visual digit boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          _DigitDisplay(
                            digit: i < _code.length ? _code[i] : '',
                            isFocused: _codeFocusNode.hasFocus &&
                                i == _code.length.clamp(0, 5),
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '\u{2022}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                        for (int i = 3; i < 6; i++) ...[
                          if (i > 3) const SizedBox(width: 8),
                          _DigitDisplay(
                            digit: i < _code.length ? _code[i] : '',
                            isFocused: _codeFocusNode.hasFocus &&
                                i == _code.length.clamp(0, 5),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Hint text
              Text(
                l10n.groupCodeHint,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Verify button (CTA)
              _GradientButton(
                onTap: _isCodeComplete && !_isVerifying ? _handleVerify : null,
                icon: LucideIcons.search,
                label: l10n.groupVerify,
                isLoading: _isVerifying,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.groupBack,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 60),
      ],
    );
  }
}

class _DigitDisplay extends StatelessWidget {
  const _DigitDisplay({
    required this.digit,
    required this.isFocused,
  });

  final String digit;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final hasText = digit.isNotEmpty;

    return Container(
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasText || isFocused
              ? AppColors.accentPrimary
              : AppColors.borderDefault,
          width: isFocused ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onTap,
    required this.icon,
    required this.label,
    this.isLoading = false,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
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
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

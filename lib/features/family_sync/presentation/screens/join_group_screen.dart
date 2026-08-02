import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../application/family_sync/group_operation_error.dart';
import '../../../../application/family_sync/join_group_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/providers/state_user_profile.dart';
import '../providers/repository_providers.dart';
import '../widgets/family_flow_components.dart';
import 'confirm_join_screen.dart';

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
    _codeController.addListener(_rebuild);
    _codeFocusNode.addListener(_rebuild);
    unawaited(_loadProfile());
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _codeController.removeListener(_rebuild);
    _codeFocusNode.removeListener(_rebuild);
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

    final result = await ref
        .read(joinGroupUseCaseProvider)
        .execute(
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
      case JoinGroupError(:final message, :final kind):
        setState(() {
          _isVerifying = false;
          _errorMessage = kind == GroupOperationErrorKind.membershipConflict
              ? S.of(context).familySyncSingleGroupConflict
              : message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                title: l10n.familyFlowJoinHeader,
                onBack: () => Navigator.maybePop(context),
              ),
              const SizedBox(height: 16),
              FamilyFlowProgress(
                labels: [
                  l10n.familyFlowJoinStepCode,
                  l10n.familyFlowJoinStepConfirm,
                  l10n.familyFlowJoinStepWait,
                ],
                currentStep: 0,
              ),
              const SizedBox(height: 27),
              FamilyFlowIntro(
                title: l10n.familyFlowJoinCodeTitle,
                subtitle: l10n.familyFlowJoinCodeSubtitle,
              ),
              const SizedBox(height: 22),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _codeFocusNode.requestFocus(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
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
                          decoration: const InputDecoration(counterText: ''),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var index = 0; index < 6; index++) ...[
                          if (index > 0) SizedBox(width: index == 3 ? 19 : 7),
                          Expanded(
                            child: _DigitDisplay(
                              digit: index < _code.length ? _code[index] : '',
                              isFocused:
                                  _codeFocusNode.hasFocus &&
                                  index == _code.length.clamp(0, 5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: AppTextStyles.label.copyWith(color: palette.error),
                ),
              ],
              const SizedBox(height: 18),
              FamilyPrimaryButton(
                onPressed: _isCodeComplete && !_isVerifying
                    ? _handleVerify
                    : null,
                label: l10n.familyFlowReviewFamily,
                isLoading: _isVerifying,
              ),
              const SizedBox(height: 20),
              FamilyHelperNote(
                icon: LucideIcons.shieldCheck,
                text: l10n.familyFlowJoinBeforeApprovalHelper,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _DigitDisplay extends StatelessWidget {
  const _DigitDisplay({required this.digit, required this.isFocused});

  final String digit;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final highlighted = digit.isNotEmpty || isFocused;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 62,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: highlighted ? palette.accentPrimary : palette.borderDefault,
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: palette.accentPrimary.withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: AppTextStyles.numerals(
          TextStyle(
            fontSize: 27,
            height: 34 / 27,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
      ),
    );
  }
}

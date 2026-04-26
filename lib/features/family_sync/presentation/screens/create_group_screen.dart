import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../application/family_sync/create_group_use_case.dart';
import '../../../../application/family_sync/notify_member_approval_use_case.dart';
import '../../../../application/family_sync/rename_group_use_case.dart';
import '../../../../application/family_sync/repository_providers.dart'
    show WebSocketEventType, notifyMemberApprovalUseCaseProvider;
import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/providers/user_profile_providers.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../providers/repository_providers.dart';
import '../widgets/group_rename_dialog.dart';
import '../../../../application/family_sync/check_group_use_case.dart';
import 'member_approval_screen.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  UserProfile? _profile;
  String _groupName = '';
  String? _groupId;
  String? _inviteCode;
  int? _expiresAt;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasNavigated = false;
  StreamSubscription<dynamic>? _wsEventSubscription;
  NotifyMemberApprovalUseCase? _notifyUseCase;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final profile = await ref.read(userProfileProvider.future);
    if (!mounted) return;

    if (profile == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Profile not found';
      });
      return;
    }

    final l10n = S.of(context);
    final defaultGroupName = l10n.groupDefaultName(profile.displayName);

    setState(() {
      _profile = profile;
      _groupName = defaultGroupName;
    });

    await _createGroup(profile, defaultGroupName);
  }

  Future<void> _createGroup(UserProfile profile, String groupName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(createGroupUseCaseProvider)
        .execute(
          displayName: profile.displayName,
          avatarEmoji: profile.avatarEmoji,
          groupName: groupName,
        );

    if (!mounted) return;

    switch (result) {
      case CreateGroupSuccess(
        :final groupId,
        :final inviteCode,
        :final expiresAt,
      ):
        setState(() {
          _groupId = groupId;
          _inviteCode = inviteCode;
          _expiresAt = expiresAt;
          _isLoading = false;
        });
        unawaited(_connectWebSocket(groupId));
      case CreateGroupError(:final message):
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
    }
  }

  @override
  void dispose() {
    unawaited(_wsEventSubscription?.cancel());
    _notifyUseCase?.disconnectWebSocket();
    super.dispose();
  }

  Future<void> _connectWebSocket(String groupId) async {
    final useCase = ref.read(notifyMemberApprovalUseCaseProvider);
    _notifyUseCase = useCase;

    _wsEventSubscription = useCase.listenForJoinRequests().listen((event) {
      if (!mounted) return;
      if (event.type == WebSocketEventType.joinRequest) {
        unawaited(_handleJoinRequest());
      }
    });

    await useCase.connectWebSocket(groupId: groupId);
  }

  Future<void> _handleJoinRequest() async {
    if (_hasNavigated) return;

    final groupId = _groupId;
    if (groupId == null) return;

    final result = await ref.read(checkGroupUseCaseProvider).execute();
    if (!mounted || _hasNavigated) return;

    switch (result) {
      case CheckGroupInGroup():
        _hasNavigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => MemberApprovalScreen(groupId: groupId),
          ),
        );
      case CheckGroupNotInGroup():
      case CheckGroupError():
        break;
    }
  }

  Future<void> _handleRename() async {
    final newName = await GroupRenameDialog.show(context, _groupName);
    if (newName == null || !mounted) return;

    final groupId = _groupId;
    if (groupId == null) return;

    final result = await ref
        .read(renameGroupUseCaseProvider)
        .execute(groupId: groupId, groupName: newName);

    if (!mounted) return;

    switch (result) {
      case RenameGroupSuccess(:final groupName):
        setState(() => _groupName = groupName);
      case RenameGroupError(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handleShare() async {
    final code = _inviteCode;
    if (code == null) return;
    await Share.share(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildError(l10n)
            : _buildContent(l10n),
      ),
    );
  }

  Widget _buildError(S l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 42),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: AppColors.accentPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(S l10n) {
    final profile = _profile;
    if (profile == null) return const SizedBox.shrink();

    final code = _inviteCode ?? '';
    final firstHalf = code.length >= 3 ? code.substring(0, 3) : code;
    final secondHalf = code.length >= 6 ? code.substring(3, 6) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 42),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _Header(title: l10n.groupCreate),
          const SizedBox(height: 36),

          // Avatar section
          AvatarDisplay(
            emoji: profile.avatarEmoji,
            imagePath: profile.avatarImagePath,
            size: 90,
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
            l10n.groupOwner,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.accentPrimary,
            ),
          ),
          const SizedBox(height: 28),

          // Group name row
          GestureDetector(
            onTap: _handleRename,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('\u{1F3E0}', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  _groupName,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.pencil,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Invite code card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDefault),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  l10n.groupInviteCode,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      firstHalf,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPrimary,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      secondHalf,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPrimary,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
                if (_expiresAt != null) ...[
                  const SizedBox(height: 12),
                  _TimerRow(expiresAt: _expiresAt!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Share button (CTA)
          _GradientButton(
            onTap: _handleShare,
            icon: LucideIcons.share2,
            label: l10n.groupShareCode,
          ),
          const SizedBox(height: 32),
        ],
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

class _TimerRow extends StatelessWidget {
  const _TimerRow({required this.expiresAt});

  final int expiresAt;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final expiresDateTime = DateTime.fromMillisecondsSinceEpoch(
      expiresAt * 1000,
    );
    final remaining = expiresDateTime.difference(DateTime.now());
    final minutes = remaining.inMinutes.clamp(0, 999);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.clock, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          l10n.groupInviteExpiry(minutes),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        ),
      ),
    );
  }
}

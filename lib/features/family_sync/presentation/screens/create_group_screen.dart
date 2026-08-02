import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../application/family_sync/create_group_use_case.dart';
import '../../../../application/family_sync/group_operation_error.dart';
import '../../../../application/family_sync/manage_group_invite_use_case.dart';
import '../../../../application/family_sync/notify_member_approval_use_case.dart';
import '../../../../application/family_sync/rename_group_use_case.dart';
import '../../../../application/family_sync/repository_providers.dart'
    show WebSocketEventType, notifyMemberApprovalUseCaseProvider;
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/providers/state_user_profile.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../providers/repository_providers.dart';
import '../widgets/family_flow_components.dart';
import '../widgets/family_network_unavailable_dialog.dart';
import '../widgets/group_rename_dialog.dart';
import '../widgets/invite_expiry_countdown.dart';
import '../../../../application/family_sync/check_group_use_case.dart';
import 'member_approval_screen.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key, this.shareInvite});

  final Future<void> Function(String text)? shareInvite;

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  UserProfile? _profile;
  String _groupName = '';
  String? _groupId;
  String? _inviteCode;
  int? _expiresAt;
  bool _isLoadingProfile = true;
  bool _isCreating = false;
  bool _isRefreshingInvite = false;
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
        _isLoadingProfile = false;
        _errorMessage = 'Profile not found';
      });
      return;
    }

    final l10n = S.of(context);
    final defaultGroupName = l10n.groupDefaultName(profile.displayName);

    setState(() {
      _profile = profile;
      _groupName = defaultGroupName;
      _groupNameController.text = defaultGroupName;
      _isLoadingProfile = false;
    });
  }

  Future<void> _submitCreate() async {
    if (_isCreating || _groupId != null) return;

    final profile = _profile;
    final groupName = _groupNameController.text.trim();
    if (profile == null || groupName.isEmpty) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
      _groupName = groupName;
    });

    final result = await ref
        .read(createGroupUseCaseProvider)
        .execute(
          displayName: profile.displayName,
          avatarEmoji: profile.avatarEmoji,
          groupName: groupName,
          avatarImageHash: null,
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
          _groupName = result.groupName ?? groupName;
          _groupNameController.text = _groupName;
          _isCreating = false;
        });
        unawaited(_connectWebSocket(groupId));
      case CreateGroupError(:final message, :final kind):
        if (kind == GroupOperationErrorKind.networkUnavailable) {
          setState(() {
            _isCreating = false;
            _errorMessage = null;
          });
          final retry = await showFamilyNetworkUnavailableDialog(context);
          if (retry && mounted) {
            await _submitCreate();
          }
          return;
        }
        setState(() {
          _isCreating = false;
          _errorMessage = kind == GroupOperationErrorKind.membershipConflict
              ? S.of(context).familySyncSingleGroupConflict
              : message;
        });
    }
  }

  @override
  void dispose() {
    unawaited(_wsEventSubscription?.cancel());
    _notifyUseCase?.disconnectWebSocket();
    _groupNameController.dispose();
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
      case CheckGroupPendingApproval():
      case CheckGroupAwaitingKey():
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
        showErrorFeedback(context, message);
    }
  }

  Future<void> _handleShare() async {
    final code = _inviteCode;
    if (code == null) return;
    final text = S.of(context).familySyncInviteShareMessage(_groupName, code);
    final share = widget.shareInvite;
    if (share != null) {
      await share(text);
    } else {
      await SharePlus.instance.share(ShareParams(text: text));
    }
  }

  Future<void> _handleCopy() async {
    final code = _inviteCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      showSuccessFeedback(context, S.of(context).familySyncInviteCopied);
    }
  }

  Future<void> _handleRegenerate() async {
    final groupId = _groupId;
    if (groupId == null || _isRefreshingInvite) return;

    setState(() => _isRefreshingInvite = true);
    final result = await ref
        .read(manageGroupInviteUseCaseProvider)
        .execute(groupId: groupId, forceRefresh: true);
    if (!mounted) return;

    switch (result) {
      case ManageGroupInviteSuccess(:final inviteCode, :final expiresAt):
        setState(() {
          _inviteCode = inviteCode;
          _expiresAt = expiresAt.millisecondsSinceEpoch ~/ 1000;
          _isRefreshingInvite = false;
        });
        showSuccessFeedback(context, S.of(context).familySyncInviteRegenerated);
      case ManageGroupInviteForbidden():
        setState(() => _isRefreshingInvite = false);
        showErrorFeedback(context, S.of(context).familySyncInviteOwnerOnly);
      case ManageGroupInviteError():
        setState(() => _isRefreshingInvite = false);
        showErrorFeedback(
          context,
          S.of(context).familySyncRegenerateInviteFailed,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;

    return PopScope(
      canPop: !_isCreating,
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: _isLoadingProfile
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildError(l10n)
              : _buildContent(l10n),
        ),
      ),
    );
  }

  Widget _buildError(S l10n) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: familyFlowHorizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: palette.accentPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.groupCreateFailed(_errorMessage ?? ''),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: palette.textSecondary),
            ),
            if (_profile != null) ...[
              const SizedBox(height: 20),
              FamilyPrimaryButton(
                controlKey: const Key('create-group-retry'),
                onPressed: _submitCreate,
                label: l10n.retry,
                isLoading: _isCreating,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(S l10n) {
    final profile = _profile;
    if (profile == null) return const SizedBox.shrink();
    if (_groupId == null) return _buildDraft(l10n, profile);

    final code = _inviteCode ?? '';
    final firstHalf = code.length >= 3 ? code.substring(0, 3) : code;
    final secondHalf = code.length >= 6 ? code.substring(3, 6) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: familyFlowHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 7),
          FamilyFlowHeader(
            title: l10n.familyFlowCreateHeader,
            backKey: const Key('create-group-back'),
            onBack: _isCreating ? null : () => Navigator.maybePop(context),
          ),
          const SizedBox(height: 16),
          FamilyFlowProgress(
            labels: [
              l10n.familyFlowCreateStepCreate,
              l10n.familyFlowCreateStepInvite,
              l10n.familyFlowCreateStepApprove,
            ],
            currentStep: 1,
          ),
          const SizedBox(height: 27),
          FamilyHouseIdentity(
            name: _groupName,
            subtitle: l10n.familyFlowOwnerSummary(profile.displayName),
            onEdit: _handleRename,
            editLabel: l10n.edit,
          ),
          const SizedBox(height: 22),
          _InviteCodeCard(
            code: '$firstHalf $secondHalf'.trim(),
            expiresAt: _expiresAt,
            onCopy: _handleCopy,
            onRegenerate: _isRefreshingInvite ? null : _handleRegenerate,
            isRefreshing: _isRefreshingInvite,
          ),
          const SizedBox(height: 18),
          FamilyPrimaryButton(
            onPressed: _handleShare,
            label: l10n.groupShareCode,
            controlKey: const Key('create-group-share-invite'),
          ),
          const SizedBox(height: 20),
          FamilyHelperNote(text: l10n.familyFlowCreateInviteHelper),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDraft(S l10n, UserProfile profile) {
    final palette = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: familyFlowHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 7),
          FamilyFlowHeader(
            title: l10n.familyFlowCreateHeader,
            backKey: const Key('create-group-back'),
            onBack: _isCreating ? null : () => Navigator.maybePop(context),
          ),
          const SizedBox(height: 16),
          FamilyFlowProgress(
            labels: [
              l10n.familyFlowCreateStepCreate,
              l10n.familyFlowCreateStepInvite,
              l10n.familyFlowCreateStepApprove,
            ],
            currentStep: 0,
          ),
          const SizedBox(height: 27),
          FamilyFlowIntro(
            title: l10n.familyFlowCreateTitle,
            subtitle: l10n.familyFlowCreateSubtitle,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.familyFlowOwnerSummary(profile.displayName),
                  style: AppTextStyles.supporting.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('create-group-name-field'),
                  controller: _groupNameController,
                  enabled: !_isCreating,
                  maxLength: 50,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitCreate(),
                  decoration: InputDecoration(
                    labelText: l10n.groupName,
                    filled: true,
                    fillColor: palette.backgroundSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.groupCreateConfirmationHint,
            style: AppTextStyles.supporting.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FamilyPrimaryButton(
            controlKey: const Key('create-group-submit'),
            onPressed: _isCreating ? null : _submitCreate,
            label: _isCreating
                ? l10n.familySyncCreatingGroup
                : l10n.groupCreate,
            isLoading: _isCreating,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({
    required this.code,
    required this.expiresAt,
    required this.onCopy,
    required this.onRegenerate,
    required this.isRefreshing,
  });

  final String code;
  final int? expiresAt;
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.numerals(
                      TextStyle(
                        fontSize: 27,
                        height: 34 / 27,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (expiresAt != null) ...[
                  const SizedBox(width: 8),
                  FamilyInviteExpiryCountdown(
                    expiresAt: DateTime.fromMillisecondsSinceEpoch(
                      expiresAt! * Duration.millisecondsPerSecond,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            key: const Key('create-group-copy-code'),
            onPressed: onCopy,
            tooltip: l10n.familySyncInviteCopy,
            icon: Icon(
              LucideIcons.copy,
              size: 20,
              color: palette.textSecondary,
            ),
          ),
          TextButton(
            key: const Key('create-group-regenerate-code'),
            onPressed: onRegenerate,
            style: TextButton.styleFrom(
              foregroundColor: palette.accentPrimary,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              textStyle: AppTextStyles.label,
            ),
            child: isRefreshing
                ? SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.accentPrimary,
                    ),
                  )
                : Text(l10n.familyFlowRegenerateInvite),
          ),
        ],
      ),
    );
  }
}

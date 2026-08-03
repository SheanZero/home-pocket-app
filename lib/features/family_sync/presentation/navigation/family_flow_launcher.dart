import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/family_sync/check_group_use_case.dart';
import '../../../../application/family_sync/group_operation_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../providers/repository_providers.dart';
import '../screens/group_choice_screen.dart';
import '../screens/group_management_screen.dart';
import '../screens/waiting_approval_screen.dart';
import '../widgets/family_network_unavailable_dialog.dart';

/// Resolves every user-initiated family entry against the relay server before
/// choosing a screen. Local state is a cache; [CheckGroupUseCase] reconciles it
/// from the authoritative membership response.
Future<void> openAuthoritativeFamilyFlow(
  BuildContext context,
  WidgetRef ref, {
  bool replaceCurrent = false,
}) async {
  if (!context.mounted) return;

  final l10n = S.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.familySyncCheckingGroup)),
          ],
        ),
      ),
    ),
  );

  final result = await ref.read(checkGroupUseCaseProvider).execute();
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  switch (result) {
    case CheckGroupInGroup(:final groupId):
      await _openResolvedRoute(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GroupManagementScreen(groupId: groupId),
        ),
        replaceCurrent: replaceCurrent,
      );
    case CheckGroupNotInGroup():
      await _openResolvedRoute(
        context,
        MaterialPageRoute<void>(builder: (_) => const GroupChoiceScreen()),
        replaceCurrent: replaceCurrent,
      );
    case CheckGroupPendingApproval(:final groupId):
      await _openMembershipTransition(
        context,
        ref,
        groupId: groupId,
        initialMode: WaitingApprovalInitialMode.pendingApproval,
        replaceCurrent: replaceCurrent,
      );
    case CheckGroupAwaitingKey(:final groupId):
      await _openMembershipTransition(
        context,
        ref,
        groupId: groupId,
        initialMode: WaitingApprovalInitialMode.recoveringKey,
        replaceCurrent: replaceCurrent,
      );
    case CheckGroupError(:final message, :final kind):
      if (kind == GroupOperationErrorKind.networkUnavailable) {
        await handleFamilyNetworkFailure(
          context,
          result,
          onRetry: () => openAuthoritativeFamilyFlow(
            context,
            ref,
            replaceCurrent: replaceCurrent,
          ),
        );
        return;
      }
      showErrorFeedback(context, l10n.familySyncCheckFailed(message));
  }
}

Future<void> _openMembershipTransition(
  BuildContext context,
  WidgetRef ref, {
  required String groupId,
  required WaitingApprovalInitialMode initialMode,
  required bool replaceCurrent,
}) async {
  final group = await ref.read(groupRepositoryProvider).getGroupById(groupId);
  if (!context.mounted) return;
  if (group == null) {
    showErrorFeedback(context, S.of(context).familySyncRestoreFailed);
    return;
  }
  final ownerDisplayName = group.members
      .where((member) => member.role == 'owner')
      .map((member) => member.displayName)
      .firstOrNull;
  await _openResolvedRoute(
    context,
    MaterialPageRoute<void>(
      builder: (_) => WaitingApprovalScreen(
        groupId: group.groupId,
        groupName: group.groupName,
        ownerDisplayName: ownerDisplayName ?? '',
        initialMode: initialMode,
      ),
    ),
    replaceCurrent: replaceCurrent,
  );
}

Future<void> _openResolvedRoute(
  BuildContext context,
  Route<void> route, {
  required bool replaceCurrent,
}) {
  if (replaceCurrent) {
    return Navigator.of(context).pushReplacement(route);
  }
  return Navigator.of(context).push(route);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../application/family_sync/group_operation_error.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/settings_section_card.dart';
import '../../domain/models/sync_status_model.dart';
import '../../../../application/family_sync/check_group_use_case.dart';
import '../providers/repository_providers.dart';
import '../providers/state_active_group.dart';
import '../providers/state_sync.dart';
import '../screens/group_management_screen.dart';
import '../screens/group_choice_screen.dart';
import 'family_network_unavailable_dialog.dart';
import 'sync_status_badge.dart';

/// Settings section for Family Sync.
///
/// Shows current sync status and navigates to pairing or management screens.
class FamilySyncSettingsSection extends ConsumerWidget {
  const FamilySyncSettingsSection({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusStreamProvider);
    final syncState = syncStatusAsync.value?.state ?? SyncState.noGroup;
    final l10n = S.of(context);
    final activeGroup = ref.watch(activeGroupProvider).value;
    final subtitle = activeGroup != null
        ? l10n.familySyncMemberCount(activeGroup.members.length)
        : compact && syncState == SyncState.noGroup
        ? l10n.settingsNotSet
        : _stateDescription(l10n, syncState);

    return SettingsSectionCard(
      title: l10n.settingsFamily,
      children: [
        SettingsActionTile(
          icon: Icons.group_outlined,
          title: l10n.familySync,
          subtitle: subtitle,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact) ...[
                SyncStatusBadge(state: syncState, compact: true),
                const SizedBox(width: 8),
              ],
              const SettingsChevron(),
            ],
          ),
          onTap: () => _navigate(context, ref, syncState),
        ),
      ],
    );
  }

  Future<void> _navigate(
    BuildContext context,
    WidgetRef ref,
    SyncState state,
  ) async {
    final localGroup = ref.read(activeGroupProvider).value;
    if (!context.mounted) return;

    if (localGroup != null || state != SyncState.noGroup) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GroupManagementScreen(groupId: localGroup?.groupId),
        ),
      );
      return;
    }

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

    Navigator.of(context).pop();

    switch (result) {
      case CheckGroupInGroup(:final groupId):
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GroupManagementScreen(groupId: groupId),
          ),
        );
      case CheckGroupNotInGroup():
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const GroupChoiceScreen()),
        );
      case CheckGroupPendingApproval():
      case CheckGroupAwaitingKey():
        break;
      case CheckGroupError(:final message, :final kind):
        if (kind == GroupOperationErrorKind.networkUnavailable) {
          final retry = await showFamilyNetworkUnavailableDialog(context);
          if (retry && context.mounted) {
            await _navigate(context, ref, state);
          }
          return;
        }
        showErrorFeedback(context, l10n.familySyncCheckFailed(message));
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const GroupChoiceScreen()),
        );
    }
  }

  String _stateDescription(S l10n, SyncState state) {
    return switch (state) {
      SyncState.synced => l10n.familySyncStatusSynced,
      SyncState.syncing => l10n.familySyncStatusSyncing,
      SyncState.initialSyncing => l10n.syncInitialProgress,
      SyncState.awaitingKey => l10n.syncInitialProgress,
      SyncState.queuedOffline => l10n.familySyncStatusOffline,
      SyncState.needsAttention => l10n.syncQueueNeedsAttentionDescription,
      SyncState.error => l10n.familySyncStatusError,
      SyncState.idle => l10n.familySyncStatusSynced,
      SyncState.noGroup => l10n.familySyncStatusUnpaired,
    };
  }
}

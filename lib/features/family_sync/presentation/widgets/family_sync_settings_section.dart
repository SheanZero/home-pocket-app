import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/sync_status_model.dart';
import '../../use_cases/check_group_use_case.dart';
import '../providers/active_group_provider.dart';
import '../providers/group_providers.dart';
import '../providers/sync_providers.dart';
import '../screens/group_management_screen.dart';
import '../screens/group_choice_screen.dart';
import 'sync_status_badge.dart';

/// Settings section for Family Sync.
///
/// Shows current sync status and navigates to pairing or management screens.
class FamilySyncSettingsSection extends ConsumerWidget {
  const FamilySyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusStreamProvider);
    final syncState =
        syncStatusAsync.valueOrNull?.state ?? SyncState.noGroup;
    final l10n = S.of(context);
    final activeGroup = ref.watch(activeGroupProvider).valueOrNull;
    final subtitle = activeGroup != null
        ? l10n.familySyncMemberCount(activeGroup.members.length)
        : _stateDescription(l10n, syncState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.familySync,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: Text(l10n.familySync),
          subtitle: Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SyncStatusBadge(state: syncState, compact: true),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
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
    final localGroup = ref.read(activeGroupProvider).valueOrNull;
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
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const GroupChoiceScreen()));
      case CheckGroupError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.familySyncCheckFailed(message))),
        );
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const GroupChoiceScreen()));
    }
  }

  String _stateDescription(S l10n, SyncState state) {
    return switch (state) {
      SyncState.synced => l10n.familySyncStatusSynced,
      SyncState.syncing => l10n.familySyncStatusSyncing,
      SyncState.initialSyncing => l10n.syncInitialProgress,
      SyncState.queuedOffline => l10n.familySyncStatusOffline,
      SyncState.error => l10n.familySyncStatusError,
      SyncState.idle => l10n.familySyncStatusSynced,
      SyncState.noGroup => l10n.familySyncStatusUnpaired,
    };
  }
}

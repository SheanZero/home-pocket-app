import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/sync_status.dart';
import '../../use_cases/check_group_use_case.dart';
import '../providers/active_group_provider.dart';
import '../providers/group_providers.dart';
import '../providers/sync_providers.dart';
import '../screens/group_management_screen.dart';
import '../screens/pairing_screen.dart';
import 'sync_status_badge.dart';

/// Settings section for Family Sync.
///
/// Shows current sync status and navigates to pairing or management screens.
class FamilySyncSettingsSection extends ConsumerWidget {
  const FamilySyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusNotifierProvider);
    final l10n = S.of(context);
    final activeGroup = ref.watch(activeGroupProvider).valueOrNull;
    final subtitle = activeGroup != null
        ? l10n.familySyncMemberCount(activeGroup.members.length)
        : _statusDescription(l10n, syncStatus);

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
              SyncStatusBadge(status: syncStatus, compact: true),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => _navigate(context, ref, syncStatus),
        ),
      ],
    );
  }

  Future<void> _navigate(
    BuildContext context,
    WidgetRef ref,
    SyncStatus status,
  ) async {
    final localGroup = ref.read(activeGroupProvider).valueOrNull;
    if (!context.mounted) return;

    if (localGroup != null || status != SyncStatus.unpaired) {
      if (localGroup != null) {
        ref
            .read(syncStatusNotifierProvider.notifier)
            .updateStatus(SyncStatus.synced);
      }
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
        ref
            .read(syncStatusNotifierProvider.notifier)
            .updateStatus(SyncStatus.synced);
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GroupManagementScreen(groupId: groupId),
          ),
        );
      case CheckGroupNotInGroup():
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const PairingScreen()));
      case CheckGroupError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.familySyncCheckFailed(message))),
        );
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const PairingScreen()));
    }
  }

  String _statusDescription(S l10n, SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return l10n.familySyncStatusSynced;
      case SyncStatus.syncing:
        return l10n.familySyncStatusSyncing;
      case SyncStatus.offline:
        return l10n.familySyncStatusOffline;
      case SyncStatus.syncError:
        return l10n.familySyncStatusError;
      case SyncStatus.pairing:
        return l10n.familySyncStatusPairing;
      case SyncStatus.unpaired:
        return l10n.familySyncStatusUnpaired;
    }
  }
}

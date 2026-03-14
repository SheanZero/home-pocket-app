import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../providers/repository_providers.dart';
import '../../domain/models/sync_status.dart';
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
    final groupFuture = ref.read(groupRepositoryProvider).getActiveGroup();

    return FutureBuilder(
      future: groupFuture,
      builder: (context, snapshot) {
        final group = snapshot.data;
        final subtitle = group != null
            ? l10n.familySyncMemberCount(group.members.length)
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
      },
    );
  }

  void _navigate(BuildContext context, WidgetRef ref, SyncStatus status) {
    final Widget screen;
    if (status == SyncStatus.unpaired) {
      screen = const PairingScreen();
    } else {
      screen = const GroupManagementScreen();
    }

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
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

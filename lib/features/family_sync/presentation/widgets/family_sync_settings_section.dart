import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/settings_section_card.dart';
import '../../domain/models/sync_status_model.dart';
import '../navigation/family_flow_launcher.dart';
import '../providers/state_active_group.dart';
import '../providers/state_sync.dart';
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
          onTap: () => openAuthoritativeFamilyFlow(context, ref),
        ),
      ],
    );
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

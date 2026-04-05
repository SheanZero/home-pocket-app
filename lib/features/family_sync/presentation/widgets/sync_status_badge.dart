import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/sync_status_model.dart';

/// Displays a colored badge with icon and label for sync status.
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({
    super.key,
    required this.state,
    this.compact = false,
  });

  final SyncState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final config = _stateConfig(state, context);

    if (compact) {
      return Icon(config.icon, size: 16, color: config.color);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: config.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _stateConfig(SyncState state, BuildContext context) {
    final l10n = S.of(context);
    return switch (state) {
      SyncState.noGroup => _StatusConfig(
        icon: Icons.link_off,
        color: Colors.grey,
        label: l10n.familySyncBadgeUnpaired,
      ),
      SyncState.idle => _StatusConfig(
        icon: Icons.check_circle_outline,
        color: Colors.grey,
        label: l10n.familySyncBadgeSynced,
      ),
      SyncState.initialSyncing => _StatusConfig(
        icon: Icons.sync,
        color: Colors.blue,
        label: l10n.syncInitialProgress,
      ),
      SyncState.syncing => _StatusConfig(
        icon: Icons.sync,
        color: Colors.blue,
        label: l10n.familySyncBadgeSyncing,
      ),
      SyncState.synced => _StatusConfig(
        icon: Icons.check_circle,
        color: Colors.green,
        label: l10n.familySyncBadgeSynced,
      ),
      SyncState.error => _StatusConfig(
        icon: Icons.error,
        color: Colors.red,
        label: l10n.familySyncBadgeError,
      ),
      SyncState.queuedOffline => _StatusConfig(
        icon: Icons.cloud_off,
        color: Colors.orange,
        label: l10n.familySyncBadgeOffline,
      ),
    };
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}

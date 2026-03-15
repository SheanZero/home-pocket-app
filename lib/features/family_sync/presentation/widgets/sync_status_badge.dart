import 'package:flutter/material.dart';

import '../../domain/models/sync_status.dart';

/// Displays a colored badge with icon and label for sync status.
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final SyncStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

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

  _StatusConfig _statusConfig(SyncStatus status) {
    return switch (status) {
      SyncStatus.unpaired => const _StatusConfig(
        icon: Icons.link_off,
        color: Colors.grey,
        label: 'Unpaired',
      ),
      SyncStatus.pairing => const _StatusConfig(
        icon: Icons.link,
        color: Colors.orange,
        label: 'Pairing',
      ),
      SyncStatus.synced => const _StatusConfig(
        icon: Icons.check_circle,
        color: Colors.green,
        label: 'Synced',
      ),
      SyncStatus.syncing => const _StatusConfig(
        icon: Icons.sync,
        color: Colors.blue,
        label: 'Syncing',
      ),
      SyncStatus.syncError => const _StatusConfig(
        icon: Icons.error,
        color: Colors.red,
        label: 'Error',
      ),
      SyncStatus.offline => const _StatusConfig(
        icon: Icons.cloud_off,
        color: Colors.orange,
        label: 'Offline',
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

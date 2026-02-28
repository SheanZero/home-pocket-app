import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/paired_device.dart';
import '../../domain/models/sync_status.dart';
import 'sync_status_badge.dart';

/// Displays partner device information with sync status.
class PartnerDeviceTile extends ConsumerWidget {
  const PartnerDeviceTile({
    super.key,
    required this.device,
    required this.syncStatus,
    this.onTap,
  });

  final PairedDevice device;
  final SyncStatus syncStatus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(currentLocaleProvider);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.devices,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        device.partnerDeviceName ?? 'Unknown Device',
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: device.lastSyncAt != null
          ? Text(
              DateFormatter.formatRelative(device.lastSyncAt!, locale),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Text(
              '-',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: SyncStatusBadge(status: syncStatus),
    );
  }
}

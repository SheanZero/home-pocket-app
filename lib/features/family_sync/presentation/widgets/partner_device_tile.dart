import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/group_member.dart';

/// Displays partner device information with sync status.
class PartnerDeviceTile extends StatelessWidget {
  const PartnerDeviceTile({
    super.key,
    required this.device,
    this.onTap,
    this.trailing,
  });

  final GroupMember device;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = S.of(context);
    final roleLabel = device.role == 'owner'
        ? l10n.familySyncRoleOwner
        : l10n.familySyncRoleMember;
    final statusLabel = device.status == 'active'
        ? l10n.familySyncMemberStatusActive
        : l10n.familySyncMemberStatusPending;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(Icons.devices, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(device.deviceName, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        '$roleLabel · $statusLabel',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing,
    );
  }
}

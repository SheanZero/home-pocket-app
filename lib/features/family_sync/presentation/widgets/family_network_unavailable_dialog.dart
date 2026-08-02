import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';

/// Shows retry guidance for family operations that require the relay.
///
/// Returns `true` only when the user explicitly asks to retry.
Future<bool> showFamilyNetworkUnavailableDialog(BuildContext context) async {
  final l10n = S.of(context);
  final retry = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('family-network-unavailable-dialog'),
      icon: const Icon(Icons.wifi_off_rounded),
      title: Text(l10n.familySyncNetworkUnavailableTitle),
      content: Text(l10n.familySyncNetworkUnavailableMessage),
      actions: [
        TextButton(
          key: const Key('family-network-unavailable-cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('family-network-unavailable-retry'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.retry),
        ),
      ],
    ),
  );
  return retry ?? false;
}

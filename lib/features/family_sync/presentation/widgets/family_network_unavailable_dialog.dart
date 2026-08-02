import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Shows retry guidance for family operations that require the relay.
///
/// Returns `true` only when the user explicitly asks to retry.
Future<bool> showFamilyNetworkUnavailableDialog(BuildContext context) async {
  final l10n = S.of(context);
  final retry = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final palette = dialogContext.palette;
      return AlertDialog(
        key: const Key('family-network-unavailable-dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        iconPadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        icon: Center(
          child: Container(
            key: const Key('family-network-unavailable-icon-badge'),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: palette.accentPrimaryLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: palette.accentPrimary.withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.accentPrimary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              key: const Key('family-network-unavailable-icon'),
              size: 40,
              color: palette.accentPrimary,
            ),
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Text(
          l10n.familySyncNetworkUnavailableTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleSmall.copyWith(color: palette.textPrimary),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        content: Text(
          l10n.familySyncNetworkUnavailableMessage,
          style: AppTextStyles.bodyMedium.copyWith(
            color: palette.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        actions: [
          TextButton(
            key: const Key('family-network-unavailable-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: palette.accentPrimary),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('family-network-unavailable-retry'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.retry),
          ),
        ],
      );
    },
  );
  return retry ?? false;
}

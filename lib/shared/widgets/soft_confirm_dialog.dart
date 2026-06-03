import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// Shared warm rounded confirmation dialog (260603-nr1 #1).
///
/// Replaces the default Material [AlertDialog] for destructive confirmations so
/// the visual language matches the soft-toast feedback system: rounded corners,
/// warm card surface, palette-driven colours. The confirm action is tinted with
/// `palette.error` (destructive); cancel uses `palette.textSecondary`.
///
/// Reused by the list swipe-delete confirmation and the edit-screen delete
/// action. Returns `true` when confirmed, `false`/`null` when cancelled or
/// dismissed.
Future<bool> showSoftConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final palette = ctx.palette;
      return Dialog(
        backgroundColor: palette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.borderDefault),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: palette.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.textSecondary,
                    ),
                    child: Text(
                      cancelLabel,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.error,
                    ),
                    child: Text(
                      confirmLabel,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: palette.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

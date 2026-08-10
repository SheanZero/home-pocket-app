import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Compact, shared entry point for personal/family management.
///
/// The visible badge keeps the home-header treatment while the outer tap
/// target fills 40dp of the primary-header row.
class FamilyModeBadge extends StatelessWidget {
  const FamilyModeBadge({
    super.key,
    required this.isGroupMode,
    required this.onTap,
  });

  final bool isGroupMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final backgroundColor = isGroupMode
        ? context.palette.familyBadgeBg
        : context.palette.dailyLight;
    final foregroundColor = isGroupMode
        ? context.palette.accentPrimary
        : context.palette.daily;
    final label = isGroupMode ? l10n.homeFamilyMode : l10n.homePersonalMode;
    final icon = isGroupMode ? Icons.people : Icons.person;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.5),
              child: Container(
                constraints: const BoxConstraints(minHeight: 27),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: foregroundColor),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: AppTextStyles.compact.copyWith(
                        fontWeight: FontWeight.w700,
                        color: foregroundColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

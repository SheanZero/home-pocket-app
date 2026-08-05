import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

const familyFlowHorizontalPadding = 20.0;

class FamilyFlowHeader extends StatelessWidget {
  const FamilyFlowHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.backKey,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Key? backKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: MaterialLocalizations.of(context).backButtonTooltip,
              child: Semantics(
                button: true,
                enabled: onBack != null,
                child: GestureDetector(
                  key: backKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      LucideIcons.chevronLeft,
                      size: 22,
                      color: onBack == null
                          ? palette.textTertiary
                          : palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 58),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.pageTitle.copyWith(
                color: palette.textPrimary,
              ),
            ),
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing!),
        ],
      ),
    );
  }
}

class FamilyFlowProgress extends StatelessWidget {
  const FamilyFlowProgress({
    super.key,
    required this.labels,
    required this.currentStep,
  }) : assert(labels.length == 3),
       assert(currentStep >= 0 && currentStep < 3);

  final List<String> labels;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final maxLabelWidth = MediaQuery.sizeOf(context).width < 360 ? 50.0 : 76.0;

    return Semantics(
      label: '${currentStep + 1} / ${labels.length}',
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            _ProgressStep(
              label: labels[index],
              index: index,
              currentStep: currentStep,
              maxLabelWidth: maxLabelWidth,
            ),
            if (index < labels.length - 1)
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: index < currentStep
                      ? palette.accentPrimary
                      : palette.borderList,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.label,
    required this.index,
    required this.currentStep,
    required this.maxLabelWidth,
  });

  final String label;
  final int index;
  final int currentStep;
  final double maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isComplete = index < currentStep;
    final isActive = index == currentStep;
    final isHighlighted = isComplete || isActive;

    return Flexible(
      flex: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHighlighted ? palette.accentPrimary : palette.card,
              border: Border.all(
                color: isHighlighted
                    ? palette.accentPrimary
                    : palette.borderList,
              ),
            ),
            alignment: Alignment.center,
            child: isComplete
                ? Icon(LucideIcons.check, size: 15, color: palette.card)
                : Text(
                    '${index + 1}',
                    style: AppTextStyles.compact.copyWith(
                      color: isActive ? palette.card : palette.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxLabelWidth),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.compact.copyWith(
                color: isHighlighted
                    ? palette.accentPrimary
                    : palette.textSecondary,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyFlowIntro extends StatelessWidget {
  const FamilyFlowIntro({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.pageTitle.copyWith(
            fontSize: 23,
            height: 30 / 23,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}

class FamilyHouseIdentity extends StatelessWidget {
  const FamilyHouseIdentity({
    super.key,
    required this.name,
    required this.subtitle,
    this.onEdit,
    this.editLabel,
    this.compact = false,
  });

  final String name;
  final String subtitle;
  final VoidCallback? onEdit;
  final String? editLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final markSize = compact ? 48.0 : 54.0;

    return Row(
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            color: palette.accentPrimaryLight,
            borderRadius: BorderRadius.circular(compact ? 13 : 15),
          ),
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.house,
            size: compact ? 26 : 30,
            color: palette.accentPrimary,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.pageTitle.copyWith(
                  fontSize: compact ? 18 : 21,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.supporting.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(LucideIcons.pencil, size: 17),
            label: Text(editLabel ?? ''),
            style: TextButton.styleFrom(
              foregroundColor: palette.accentPrimary,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              textStyle: AppTextStyles.label,
            ),
          ),
      ],
    );
  }
}

class FamilyVerifiedBadge extends StatelessWidget {
  const FamilyVerifiedBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.accentPrimaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.badgeCheck,
              size: 15,
              color: palette.accentPrimary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.compact.copyWith(
                  color: palette.accentPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FamilyHelperNote extends StatelessWidget {
  const FamilyHelperNote({
    super.key,
    required this.text,
    this.icon = LucideIcons.info,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: palette.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.supporting.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class FamilyPrimaryButton extends StatelessWidget {
  const FamilyPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.controlKey,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Key? controlKey;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled || isLoading ? 1 : 0.48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [palette.fabGradientEnd, palette.fabGradientStart],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: palette.actionShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              key: controlKey,
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.primaryActionForeground,
                        ),
                      )
                    else ...[
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 18,
                          color: palette.primaryActionForeground,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: palette.primaryActionForeground,
                          ),
                        ),
                      ),
                    ],
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

class FamilySecondaryButton extends StatelessWidget {
  const FamilySecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.controlKey,
    this.icon,
    this.isLoading = false,
    this.prominent = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Key? controlKey;
  final IconData? icon;
  final bool isLoading;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final button = OutlinedButton.icon(
      key: controlKey,
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: prominent ? palette.joyText : palette.textSecondary,
              ),
            )
          : Icon(icon ?? LucideIcons.circle, size: icon == null ? 0 : 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(prominent ? 58 : 52),
        foregroundColor: prominent ? palette.joyText : palette.textPrimary,
        backgroundColor: prominent ? palette.joyLight : null,
        disabledForegroundColor: prominent
            ? palette.joyText.withValues(alpha: 0.68)
            : palette.textSecondary,
        disabledBackgroundColor: prominent ? palette.joyLight : null,
        side: BorderSide(
          color: prominent
              ? palette.joy.withValues(alpha: 0.72)
              : palette.borderDefault,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: AppTextStyles.button.copyWith(
          fontWeight: prominent ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );

    if (!prominent) return button;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: palette.actionShadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: button,
    );
  }
}

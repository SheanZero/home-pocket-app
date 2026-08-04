import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The two top-level Statistics views defined by the V16 mockup.
enum AnalyticsPrimaryTab { spending, joy }

/// V16 Statistics primary tabs.
///
/// The shared warm surface is deliberately borderless. The selected tab reads
/// as a softly raised sheet of paper with a small bookmark at its top edge;
/// the inactive tab stays visually attached to the shared base. Text keeps
/// priority over the supporting chart icon at narrow widths.
class AnalyticsPrimaryTabs extends StatelessWidget {
  const AnalyticsPrimaryTabs({
    super.key,
    required this.selected,
    required this.spendingLabel,
    required this.joyLabel,
    required this.spendingSummary,
    required this.joySummary,
    required this.onChanged,
  });

  final AnalyticsPrimaryTab selected;
  final String spendingLabel;
  final String joyLabel;
  final String spendingSummary;
  final String joySummary;
  final ValueChanged<AnalyticsPrimaryTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      key: const Key('analytics-primary-tabs'),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Color.lerp(palette.backgroundMuted, palette.background, 0.34),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 94,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _AnalyticsPrimaryTabButton(
                key: const Key('analytics-primary-tab-spending'),
                tab: AnalyticsPrimaryTab.spending,
                selected: selected == AnalyticsPrimaryTab.spending,
                label: spendingLabel,
                summary: spendingSummary,
                icon: Icons.donut_small,
                onTap: () => onChanged(AnalyticsPrimaryTab.spending),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _AnalyticsPrimaryTabButton(
                key: const Key('analytics-primary-tab-joy'),
                tab: AnalyticsPrimaryTab.joy,
                selected: selected == AnalyticsPrimaryTab.joy,
                label: joyLabel,
                summary: joySummary,
                icon: Icons.bar_chart_rounded,
                onTap: () => onChanged(AnalyticsPrimaryTab.joy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsPrimaryTabButton extends StatelessWidget {
  const _AnalyticsPrimaryTabButton({
    super.key,
    required this.tab,
    required this.selected,
    required this.label,
    required this.summary,
    required this.icon,
    required this.onTap,
  });

  final AnalyticsPrimaryTab tab;
  final bool selected;
  final String label;
  final String summary;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isJoy = tab == AnalyticsPrimaryTab.joy;
    final isNarrow = MediaQuery.sizeOf(context).width < 380;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 160);
    final accent = isJoy ? palette.joy : palette.accentPrimary;
    final selectedText = isJoy ? palette.joyText : palette.dailyText;
    final soft = isJoy ? palette.joyLight : palette.accentPrimaryLight;
    final visualSize = isNarrow ? 34.0 : 38.0;
    final iconSize = isNarrow ? 32.0 : 34.0;
    final gap = isNarrow ? 3.0 : 4.0;
    final horizontalPadding = isNarrow ? 6.0 : 12.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleStyle = AppTextStyles.itemTitle.copyWith(
      color: selected ? selectedText : palette.textPrimary,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
    );

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      value: summary,
      onTap: onTap,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, selected ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: selected ? Color.lerp(palette.card, soft, 0.18) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : palette.navShadow.withValues(alpha: 0.11),
                      blurRadius: isDark ? 20 : 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTap,
                  child: SizedBox(
                    height: 94,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 14,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final titlePainter = TextPainter(
                            text: TextSpan(text: label, style: titleStyle),
                            maxLines: 1,
                            textDirection: Directionality.of(context),
                          )..layout();
                          final showVisual =
                              titlePainter.width <=
                              constraints.maxWidth - visualSize - gap;

                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      key: Key(
                                        'analytics-primary-tab-${tab.name}-title',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: titleStyle,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      summary,
                                      key: Key(
                                        'analytics-primary-tab-${tab.name}-summary',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body.copyWith(
                                        color: selected
                                            ? selectedText
                                            : palette.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (showVisual) ...[
                                SizedBox(width: gap),
                                SizedBox.square(
                                  dimension: visualSize,
                                  child: Icon(
                                    icon,
                                    key: Key(
                                      'analytics-primary-tab-${tab.name}-icon',
                                    ),
                                    size: iconSize,
                                    color: selected
                                        ? selectedText
                                        : accent.withValues(alpha: 0.52),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: -5,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      key: Key('analytics-primary-tab-${tab.name}-bookmark'),
                      width: 36,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The tone of an [AnalyticsSectionHeader] — drives the left bar color and the
/// tag chip's text/background colors (round-5 r5 mock `.sect-h.prac` /
/// `.sect-h.joy`).
enum SectionTone {
  /// 实用 (practical / spend) sections — green leaf bar, daily-tinted tag chip.
  practical,

  /// 悦己 (joy) sections — sakura bar, joy-tinted tag chip.
  joy,
}

/// A section header above an analytics card (round-5 r5 mock `.sect-h`).
///
/// Renders a 3px-wide rounded vertical bar + a 12px/w600 letter-spaced [title]
/// + a trailing tag chip ([tag], 10.5px/w600). Per the mock:
///   - [SectionTone.practical] → bar = `palette.accentPrimary` (leaf green),
///     tag chip text = `palette.dailyText` on `palette.dailyLight`.
///   - [SectionTone.joy] → bar = `palette.joy` (sakura), tag chip text =
///     `palette.joyText` on `palette.joyLight`.
///
/// [title] and [tag] are passed ALREADY LOCALIZED by the caller (the shell
/// resolves them via `S.of(context)`), so this widget contains zero literal CJK
/// (`hardcoded_cjk_ui_scan`). All colors resolve via `context.palette`
/// (`color_literal_scan`).
class AnalyticsSectionHeader extends StatelessWidget {
  const AnalyticsSectionHeader({
    super.key,
    required this.title,
    required this.tag,
    required this.tone,
  });

  /// Pre-localized section title (e.g. "支出趋势").
  final String title;

  /// Pre-localized tag-chip label (e.g. "实用" / "悦己").
  final String tag;

  /// Practical (green) vs joy (sakura) tinting.
  final SectionTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final Color barColor;
    final Color tagTextColor;
    final Color tagBgColor;
    switch (tone) {
      case SectionTone.practical:
        barColor = palette.accentPrimary;
        tagTextColor = palette.dailyText;
        tagBgColor = palette.dailyLight;
      case SectionTone.joy:
        barColor = palette.joy;
        tagTextColor = palette.joyText;
        tagBgColor = palette.joyLight;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // 3px × 13px rounded vertical bar.
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.96, // .08em on 12px
                color: palette.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tagBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.42, // .04em on 10.5px
                color: tagTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

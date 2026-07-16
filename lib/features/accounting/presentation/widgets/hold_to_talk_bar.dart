import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Quick task 260622-nhs / 260623-0cj: the 「语音记录」 voice-record key that sits
/// ABOVE the SmartKeyboard on the single-page entry screen.
///
/// 260623-0cj R2: the strip background is white ([AppPalette.card]) and carries
/// the keypad assembly's top border, so the voice key + keypad read as ONE
/// unified surface (一体) — the keypad below drops its own top border
/// (`SmartKeyboard(showTopBorder: false)`). The key itself is a centered,
/// edge-inset 200×44 **capsule** styled exactly like the 「记录」 (Record/Save)
/// button: the FAB sakura-pink gradient, white icon + white [titleMedium] label,
/// and the same action shadow. The capsule is the only tap target; a single
/// [onTap] raises the inline voice panel (no press-and-hold).
///
/// Stateless about recording — the host owns the session state. The mic is a
/// line-style [Icons.mic_none] (not filled). All colors via [AppPalette]; the
/// label via [S].
class VoiceRecordBar extends StatelessWidget {
  const VoiceRecordBar({
    super.key,
    required this.onTap,
    this.useV16Layout = false,
  });

  final VoidCallback onTap;
  final bool useV16Layout;

  /// 260623-0cj: approved A/B midpoint width; R2 height = 44 dp (HIG touch
  /// target, equal to the keypad's bottom row).
  static const double _pillWidth = 200.0;
  static const double _pillHeight = 44.0;
  static const double _pillRadius = _pillHeight / 2; // full capsule (stadium)

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    final pillWidth = useV16Layout ? 304.0 : _pillWidth;
    final pillHeight = useV16Layout ? 46.0 : _pillHeight;
    final pillRadius = useV16Layout ? 12.0 : _pillRadius;

    return Container(
      key: const ValueKey('voice-record-bar'),
      // White, unified with the keypad below (一体); carries the assembly's top
      // border (the keypad omits its own via showTopBorder: false).
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.borderDefault)),
      ),
      // 260623-0cj R3: 12 dp above the pill (matches the 12 dp digit inter-row
      // gap); 0 below because the keypad's own 12 dp top padding supplies the
      // 12 dp gap to row 1 — so the pill sits 12 dp from the top edge AND 12 dp
      // from the digits, evenly, like another keypad row.
      padding: EdgeInsets.only(top: useV16Layout ? 10 : 12),
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(pillRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(pillRadius),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: useV16Layout ? palette.backgroundMuted : null,
              gradient: useV16Layout
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.fabGradientStart,
                        palette.fabGradientEnd,
                      ],
                    ),
              borderRadius: BorderRadius.circular(pillRadius),
              border: useV16Layout
                  ? Border.all(color: palette.borderDefault)
                  : null,
              boxShadow: useV16Layout
                  ? null
                  : [
                      BoxShadow(
                        color: palette.actionShadow,
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: SizedBox(
              key: const ValueKey('voice-record-pill'),
              width: pillWidth,
              height: pillHeight,
              child: useV16Layout
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mic_none,
                            size: 20,
                            color: palette.accentPrimary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.voiceRecordBar,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.label.copyWith(
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  l10n.entryVoiceLaunchHelp,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.micro.copyWith(
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: palette.textTertiary,
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mic_none,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.voiceRecordBar,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

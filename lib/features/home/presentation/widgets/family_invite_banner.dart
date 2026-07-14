import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// v15 `faithfulInvite()` — horizontal 3-column invite banner.
///
/// `[avatar pair | copy | actions]`. The copy column carries the title,
/// subtitle, and a "設定 › 家庭" path button ([onSettingsTap]). The actions
/// column stacks a dismiss button ([onDismiss]) over the sakura "家族を追加"
/// CTA ([onTap] → GroupChoiceScreen).
///
/// Pure UI component — no providers. Dismiss state is owned by the host screen
/// via ephemeral [onDismiss] (setState), not a persisted provider.
class FamilyInviteBanner extends StatelessWidget {
  const FamilyInviteBanner({
    super.key,
    required this.onTap,
    required this.onSettingsTap,
    required this.onDismiss,
  });

  final VoidCallback onTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _avatarPair(palette),
          const SizedBox(width: 10),
          Expanded(child: _copyColumn(l10n, palette)),
          const SizedBox(width: 10),
          _actionsColumn(l10n, palette),
        ],
      ),
    );
  }

  // ── Column 1: overlapping avatar pair ──
  Widget _avatarPair(AppPalette palette) {
    return SizedBox(
      width: 52,
      height: 36,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: _avatar(palette, palette.accentPrimary, Icons.face),
          ),
          Positioned(
            left: 18,
            child: _avatar(palette, palette.daily, Icons.face_2),
          ),
        ],
      ),
    );
  }

  Widget _avatar(AppPalette palette, Color bg, IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: palette.card, width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  // ── Column 2: copy + settings-path button ──
  Widget _copyColumn(S l10n, AppPalette palette) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeFamilyBannerTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.homeFamilyBannerSubtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        // "設定 › 家庭" path button → settings screen.
        InkWell(
          onTap: onSettingsTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Text(
              l10n.homeFamilyInviteSettingsPath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.accentPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Column 3: dismiss (top) + CTA (bottom) ──
  Widget _actionsColumn(S l10n, AppPalette palette) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Semantics(
          button: true,
          label: l10n.homeFamilyInviteDismissLabel,
          child: InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close,
                size: 18,
                color: palette.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 92,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              // v15 `.faithful-invite-cta`: sakura-pink add-family action.
              color: palette.joy,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_add, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.homeFamilyInviteTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

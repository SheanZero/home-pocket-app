import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import 'invite_expiry_countdown.dart';

const _ticketHeight = 252.0;
const _ticketCornerRadius = 14.0;
const _ticketNotchRadius = 20.0;

/// Warm-paper invite ticket used after a family has been created.
///
/// The edge perforations are part of the actual clipped surface, so the
/// outline, ink reactions, and physical shadow all follow the same silhouette.
class FamilyInviteTicket extends StatelessWidget {
  const FamilyInviteTicket({
    super.key,
    required this.code,
    required this.expiresAt,
    required this.onCopy,
    required this.onRegenerate,
    required this.isRefreshing,
    this.now,
  });

  final String code;
  final DateTime? expiresAt;
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;
  final bool isRefreshing;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;

    return SizedBox(
      key: const Key('family-invite-ticket-surface'),
      width: double.infinity,
      height: _ticketHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, 4),
              child: PhysicalShape(
                key: const Key('family-invite-ticket-physical-shape'),
                clipper: const FamilyInviteTicketClipper(),
                color: Colors.transparent,
                shadowColor: palette.textPrimary.withValues(alpha: 0.12),
                elevation: 2,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipPath(
              clipper: const FamilyInviteTicketClipper(),
              child: Material(
                color: palette.card,
                child: CustomPaint(
                  key: const Key('family-invite-ticket-border-painter'),
                  foregroundPainter: _FamilyInviteTicketBorderPainter(
                    color: palette.borderDefault,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 27),
                          child: _TicketLabel(label: l10n.groupInviteCode),
                        ),
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 27),
                          child: FittedBox(
                            key: const Key('family-invite-ticket-code-fit'),
                            fit: BoxFit.scaleDown,
                            child: Text(
                              code,
                              key: const Key('family-invite-ticket-code'),
                              maxLines: 1,
                              softWrap: false,
                              style: AppTextStyles.numerals(
                                TextStyle(
                                  fontSize: 45,
                                  height: 52 / 45,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3.2,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (expiresAt != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 27),
                            child: FamilyInviteExpiryCountdown(
                              expiresAt: expiresAt!,
                              now: now,
                              showProgress: true,
                              validityDuration: const Duration(minutes: 10),
                              textStyle: AppTextStyles.label,
                            ),
                          )
                        else
                          const SizedBox(height: 34),
                        const SizedBox(height: 12),
                        Padding(
                          key: const Key('family-invite-ticket-action-divider'),
                          padding: const EdgeInsets.symmetric(horizontal: 27),
                          child: _DashedDivider(color: palette.borderDefault),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  key: const Key('family-invite-ticket-copy'),
                                  height: 48,
                                  child: _TicketActionButton(
                                    key: const Key('create-group-copy-code'),
                                    onPressed: onCopy,
                                    icon: const Icon(
                                      LucideIcons.copy,
                                      size: 20,
                                    ),
                                    label: Text(l10n.familyFlowCopyInvite),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 27,
                                color: palette.borderDivider,
                              ),
                              Expanded(
                                child: SizedBox(
                                  key: const Key(
                                    'family-invite-ticket-regenerate',
                                  ),
                                  height: 48,
                                  child: _TicketActionButton(
                                    key: const Key(
                                      'create-group-regenerate-code',
                                    ),
                                    onPressed: onRegenerate,
                                    icon: isRefreshing
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: palette.accentPrimary,
                                            ),
                                          )
                                        : const Icon(
                                            LucideIcons.refreshCw,
                                            size: 20,
                                          ),
                                    label: Text(
                                      l10n.familyFlowRegenerateInvite,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketActionButton extends StatelessWidget {
  const _TicketActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: palette.accentPrimary,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        textStyle: AppTextStyles.label,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 7),
          Flexible(
            child: DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: label,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketLabel extends StatelessWidget {
  const _TicketLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Expanded(child: _DashedLine(color: palette.borderDefault)),
        const SizedBox(width: 8),
        _TicketDot(color: palette.borderDefault),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              color: palette.accentPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _TicketDot(color: palette.borderDefault),
        const SizedBox(width: 8),
        Expanded(child: _DashedLine(color: palette.borderDefault)),
      ],
    );
  }
}

class _TicketDot extends StatelessWidget {
  const _TicketDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 1,
    child: CustomPaint(painter: _DashedLinePainter(color: color)),
  );
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    child: CustomPaint(painter: _DashedLinePainter(color: color)),
  );
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    const dashWidth = 5.0;
    const dashGap = 5.0;
    for (var start = 0.0; start < size.width; start += dashWidth + dashGap) {
      canvas.drawLine(
        Offset(start, size.height / 2),
        Offset((start + dashWidth).clamp(0, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Clips the ticket to rounded corners, fine side perforations, and two large
/// semicircular side notches.
class FamilyInviteTicketClipper extends CustomClipper<Path> {
  const FamilyInviteTicketClipper();

  @override
  Path getClip(Size size) => buildPath(size);

  static Path buildPath(Size size) {
    final base = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(_ticketCornerRadius),
        ),
      );
    final cutouts = Path();
    final notchCenterY = size.height * 0.46;

    for (final x in [0.0, size.width]) {
      cutouts.addOval(
        Rect.fromCircle(
          center: Offset(x, notchCenterY),
          radius: _ticketNotchRadius,
        ),
      );
      _addFinePerforations(
        cutouts,
        x: x,
        startY: 25,
        endY: notchCenterY - _ticketNotchRadius - 8,
      );
      _addFinePerforations(
        cutouts,
        x: x,
        startY: notchCenterY + _ticketNotchRadius + 8,
        endY: size.height - 25,
      );
    }

    return Path.combine(PathOperation.difference, base, cutouts);
  }

  static void _addFinePerforations(
    Path path, {
    required double x,
    required double startY,
    required double endY,
  }) {
    const spacing = 10.5;
    const radius = 2.2;
    for (var y = startY; y <= endY; y += spacing) {
      path.addOval(Rect.fromCircle(center: Offset(x, y), radius: radius));
    }
  }

  @override
  bool shouldReclip(FamilyInviteTicketClipper oldClipper) => false;
}

class _FamilyInviteTicketBorderPainter extends CustomPainter {
  const _FamilyInviteTicketBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      FamilyInviteTicketClipper.buildPath(size),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_FamilyInviteTicketBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

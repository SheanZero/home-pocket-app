import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// A shared second-by-second countdown for family invite codes.
///
/// The display transitions from `MM:SS` validity copy to a red localized
/// expired state without requiring its parent screen to rebuild.
class FamilyInviteExpiryCountdown extends StatefulWidget {
  const FamilyInviteExpiryCountdown({
    super.key,
    required this.expiresAt,
    this.now,
    this.textStyle,
  });

  final DateTime expiresAt;

  /// Optional clock override used by deterministic widget tests.
  final DateTime Function()? now;

  final TextStyle? textStyle;

  @override
  State<FamilyInviteExpiryCountdown> createState() =>
      _FamilyInviteExpiryCountdownState();
}

class _FamilyInviteExpiryCountdownState
    extends State<FamilyInviteExpiryCountdown> {
  Timer? _ticker;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didUpdateWidget(FamilyInviteExpiryCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt ||
        oldWidget.now != widget.now) {
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    if (!widget.expiresAt.isAfter(_now)) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {});
      if (!widget.expiresAt.isAfter(_now)) timer.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final remaining = widget.expiresAt.difference(_now);
    final expired = remaining <= Duration.zero;
    final totalSeconds = expired
        ? 0
        : (remaining.inMilliseconds / Duration.millisecondsPerSecond).ceil();
    final minutes = totalSeconds ~/ Duration.secondsPerMinute;
    final seconds = totalSeconds.remainder(Duration.secondsPerMinute);
    final time =
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
    final label = expired
        ? l10n.groupInviteExpired
        : l10n.groupInviteCountdown(time);
    final color = expired ? palette.error : palette.textSecondary;

    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expired ? LucideIcons.circleAlert : LucideIcons.clock,
            key: const Key('family-invite-expiry-countdown-icon'),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            key: const Key('family-invite-expiry-countdown-label'),
            maxLines: 1,
            style: (widget.textStyle ?? AppTextStyles.supporting).copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

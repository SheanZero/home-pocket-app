import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import 'digit_code_display.dart';
import 'info_hint_box.dart';
import 'outline_action_button.dart';

/// Displays the QR code and 6-digit pair code for device pairing.
///
/// Shows:
/// - QR code (250x250) encoding the pair data
/// - 6-digit code formatted as "XXX XXX"
/// - Expiry countdown timer
/// - Regenerate button
class PairCodeDisplay extends StatefulWidget {
  const PairCodeDisplay({
    super.key,
    required this.inviteCode,
    required this.qrData,
    required this.expiresAt,
    required this.onRegenerate,
    required this.onShare,
  });

  final String inviteCode;
  final String qrData;
  final DateTime expiresAt;
  final VoidCallback onRegenerate;
  final VoidCallback onShare;

  @override
  State<PairCodeDisplay> createState() => _PairCodeDisplayState();
}

class _PairCodeDisplayState extends State<PairCodeDisplay> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    setState(() {
      _remaining = widget.expiresAt.difference(now);
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
      }
    });
  }

  String get _formattedTime {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get _isExpired => _remaining == Duration.zero;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x145A9CC8),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                gapless: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.familySyncPairCode,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        DigitCodeDisplay(code: widget.inviteCode),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isExpired ? Icons.timer_off : Icons.timer_outlined,
              size: 16,
              color: _isExpired ? Colors.redAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _isExpired
                  ? l10n.familySyncCodeExpired
                  : l10n.familySyncExpiryLabel(_formattedTime),
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlineActionButton(
                icon: Icons.share_outlined,
                label: l10n.familySyncShare,
                onPressed: widget.onShare,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlineActionButton(
                icon: Icons.refresh,
                label: l10n.refresh,
                onPressed: widget.onRegenerate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InfoHintBox(message: l10n.familySyncScanOrEnter),
        if (_isExpired) ...[
          const SizedBox(height: 12),
          Text(
            l10n.familySyncCodeExpired,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 12,
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    );
  }
}

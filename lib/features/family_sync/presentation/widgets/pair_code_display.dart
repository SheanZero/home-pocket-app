import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    required this.pairCode,
    required this.qrData,
    required this.expiresAt,
    required this.onRegenerate,
  });

  final String pairCode;
  final String qrData;
  final DateTime expiresAt;
  final VoidCallback onRegenerate;

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

  String get _formattedCode {
    final code = widget.pairCode;
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    }
    return code;
  }

  String get _formattedTime {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get _isExpired => _remaining == Duration.zero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: widget.qrData,
            version: QrVersions.auto,
            size: 250,
            gapless: true,
          ),
        ),
        const SizedBox(height: 24),

        // 6-digit code
        Text(
          _formattedCode,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 8),

        // Expiry timer
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isExpired ? Icons.timer_off : Icons.timer_outlined,
              size: 16,
              color: _isExpired
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _isExpired ? 'Expired' : _formattedTime,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _isExpired
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Regenerate button
        if (_isExpired)
          FilledButton.icon(
            onPressed: widget.onRegenerate,
            icon: const Icon(Icons.refresh),
            label: const Text('Regenerate'),
          ),
      ],
    );
  }
}

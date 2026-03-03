import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import 'gradient_action_button.dart';
import 'otp_digit_input.dart';
import 'outline_action_button.dart';

/// Input widget for entering a 6-digit pair code.
class PairCodeInput extends StatefulWidget {
  const PairCodeInput({
    super.key,
    required this.onSubmit,
    required this.onScanQr,
    this.isLoading = false,
    this.errorMessage,
  });

  final void Function(String code) onSubmit;
  final VoidCallback onScanQr;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<PairCodeInput> createState() => _PairCodeInputState();
}

class _PairCodeInputState extends State<PairCodeInput> {
  String _code = '';

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x145A9CC8),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.group_add_outlined,
            color: AppColors.survival,
            size: 32,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.familySyncJoinTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.familySyncJoinDescription,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
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
        OtpDigitInput(
          onChanged: (value) => setState(() => _code = value),
          onCompleted: (value) => _code = value,
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        GradientActionButton(
          label: l10n.familySyncJoinGroup,
          onPressed: _code.length == 6 && !widget.isLoading
              ? () => widget.onSubmit(_code)
              : null,
          isLoading: widget.isLoading,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.familySyncOrDivider,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        const SizedBox(height: 20),
        OutlineActionButton(
          icon: Icons.qr_code_scanner,
          label: l10n.familySyncScanQr,
          onPressed: widget.onScanQr,
        ),
      ],
    );
  }
}

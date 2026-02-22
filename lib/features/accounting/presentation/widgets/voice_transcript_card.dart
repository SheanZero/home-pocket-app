import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Card that displays real-time voice transcript text.
///
/// Shows [partialText] in grey while recording is in progress.
/// Shows [finalText] in dark once recognition is complete.
class VoiceTranscriptCard extends StatelessWidget {
  /// Whether recording is currently in progress.
  final bool isRecording;

  /// Partial (in-progress) recognized text — shown in grey.
  final String partialText;

  /// Final recognized text — shown in dark.
  final String finalText;

  const VoiceTranscriptCard({
    super.key,
    required this.isRecording,
    required this.partialText,
    required this.finalText,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = finalText.isNotEmpty ? finalText : partialText;
    final isFinal = finalText.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRecording ? Icons.mic : Icons.mic_none,
                size: 16,
                color: isRecording ? Colors.red : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                isRecording ? '...' : '',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayText,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isFinal ? AppColors.textPrimary : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Animated voice waveform visualization.
///
/// Displays 16 bars whose heights are driven by [soundLevel].
/// When [isActive] is false, all bars are rendered at a minimal height.
class VoiceWaveform extends StatelessWidget {
  /// Normalized sound level: 0.0 (silent) to 1.0 (maximum).
  final double soundLevel;

  /// Whether the waveform is currently active (recording in progress).
  final bool isActive;

  /// Color of the waveform bars.
  final Color color;

  const VoiceWaveform({
    super.key,
    required this.soundLevel,
    this.isActive = false,
    this.color = AppColors.survival,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(16, (i) {
          // Each bar's height: based on soundLevel + positional phase offset
          // Centre bars are taller; side bars are shorter (waveform shape)
          final phase = (i - 8).abs() / 8.0;
          final height = isActive
              ? 8.0 + 40.0 * soundLevel * (1.0 - phase * 0.5)
              : 4.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 3,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: isActive ? 0.4 + 0.6 * soundLevel : 0.2,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

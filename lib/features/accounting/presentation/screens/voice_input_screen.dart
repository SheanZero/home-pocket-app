import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../widgets/entry_mode_switcher.dart';
import '../widgets/input_mode_tabs.dart';

/// Stub voice input screen with recording UI.
///
/// Shows a transcript card, animated waveform bars, microphone button,
/// and a "Next" action. Currently only static UI.
class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key, required this.bookId});

  final String bookId;

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    if (_isRecording) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.addTransaction, style: AppTextStyles.headlineMedium),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Input mode tabs (Voice active)
          EntryModeSwitcher(
            selectedMode: InputMode.voice,
            bookId: widget.bookId,
          ),

          const SizedBox(height: 32),

          // Transcript card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
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
                        Icons.mic,
                        size: 16,
                        color: _isRecording
                            ? Colors.red
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isRecording ? '...' : l10n.tapToRecord,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecording ? '...' : '',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Waveform bars
          if (_isRecording)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(12, (i) {
                    final scale =
                        0.3 + 0.7 * ((_pulseController.value + i * 0.08) % 1.0);
                    return Container(
                      width: 3,
                      height: 24 * scale,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppColors.survival.withValues(
                          alpha: 0.4 + 0.6 * scale,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              },
            ),

          const SizedBox(height: 24),

          // Mic button
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isRecording
                      ? [Colors.red.shade300, Colors.red.shade500]
                      : [AppColors.fabGradientStart, AppColors.fabGradientEnd],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : AppColors.survival)
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            l10n.tapToRecord,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Next button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.fabGradientStart,
                      AppColors.fabGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Stub: just pop back for now
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: Text(
                        l10n.next,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
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

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

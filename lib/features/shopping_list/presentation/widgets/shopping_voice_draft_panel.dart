import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Presentation states for the optional voice-draft layer on the shopping form.
enum ShoppingVoiceDraftState {
  manual,
  listening,
  processing,
  review,
  unavailable,
}

/// Localized copy consumed by [ShoppingVoiceDraftPanel].
///
/// Keeping every visible and semantic string in this immutable value lets the
/// widget stay independent from generated localizations and makes it reusable
/// from screens with different localization-loading strategies.
@immutable
class ShoppingVoiceDraftCopy {
  const ShoppingVoiceDraftCopy({
    required this.manualTitle,
    required this.manualHelp,
    required this.manualSemanticLabel,
    required this.privacyLabel,
    required this.listeningStatus,
    required this.processingStatus,
    required this.reviewStatus,
    required this.unavailableStatus,
    required this.keyboardSemanticLabel,
    required this.listeningTranscriptPlaceholder,
    required this.processingTranscriptPlaceholder,
    required this.reviewTranscriptPlaceholder,
    required this.unavailableTranscript,
    required this.stopSemanticLabel,
    required this.processingSemanticLabel,
    required this.rerecordSemanticLabel,
    required this.unavailableCoreSemanticLabel,
    required this.listeningHelp,
    required this.processingHelp,
    required this.reviewHelp,
    required this.unavailableHelp,
    required this.settingsLabel,
    required this.settingsSemanticLabel,
  });

  final String manualTitle;
  final String manualHelp;
  final String manualSemanticLabel;
  final String privacyLabel;
  final String listeningStatus;
  final String processingStatus;
  final String reviewStatus;
  final String unavailableStatus;
  final String keyboardSemanticLabel;
  final String listeningTranscriptPlaceholder;
  final String processingTranscriptPlaceholder;
  final String reviewTranscriptPlaceholder;
  final String unavailableTranscript;
  final String stopSemanticLabel;
  final String processingSemanticLabel;
  final String rerecordSemanticLabel;
  final String unavailableCoreSemanticLabel;
  final String listeningHelp;
  final String processingHelp;
  final String reviewHelp;
  final String unavailableHelp;
  final String settingsLabel;
  final String settingsSemanticLabel;
}

/// V16 voice-draft surface for shopping-item creation.
///
/// This widget is intentionally presentation-only. Recognition, parsing,
/// draft snapshots, and session cancellation remain responsibilities of the
/// owning screen/controller.
class ShoppingVoiceDraftPanel extends StatelessWidget {
  const ShoppingVoiceDraftPanel({
    super.key,
    required this.state,
    required this.copy,
    required this.transcript,
    required this.soundLevel,
    required this.onOpen,
    required this.onStop,
    required this.onKeyboard,
    required this.onRerecord,
    required this.onSettings,
  });

  final ShoppingVoiceDraftState state;
  final ShoppingVoiceDraftCopy copy;
  final String transcript;

  /// Current recognizer level. Values outside 0...1 are safely clamped.
  final double soundLevel;

  final VoidCallback onOpen;
  final VoidCallback onStop;
  final VoidCallback onKeyboard;
  final VoidCallback onRerecord;
  final VoidCallback onSettings;

  static const manualStateKey = ValueKey<String>('shopping_voice_state_manual');
  static const listeningStateKey = ValueKey<String>(
    'shopping_voice_state_listening',
  );
  static const processingStateKey = ValueKey<String>(
    'shopping_voice_state_processing',
  );
  static const reviewStateKey = ValueKey<String>('shopping_voice_state_review');
  static const unavailableStateKey = ValueKey<String>(
    'shopping_voice_state_unavailable',
  );
  static const manualMicBoxKey = ValueKey<String>(
    'shopping_voice_manual_mic_box',
  );
  static const headerKey = ValueKey<String>('shopping_voice_header');
  static const keyboardActionKey = ValueKey<String>(
    'shopping_voice_keyboard_action',
  );
  static const coreActionKey = ValueKey<String>('shopping_voice_core_action');
  static const waveformKey = ValueKey<String>('shopping_voice_waveform');
  static const settingsActionKey = ValueKey<String>(
    'shopping_voice_settings_action',
  );

  static Key stateKey(ShoppingVoiceDraftState state) => switch (state) {
    ShoppingVoiceDraftState.manual => manualStateKey,
    ShoppingVoiceDraftState.listening => listeningStateKey,
    ShoppingVoiceDraftState.processing => processingStateKey,
    ShoppingVoiceDraftState.review => reviewStateKey,
    ShoppingVoiceDraftState.unavailable => unavailableStateKey,
  };

  @override
  Widget build(BuildContext context) {
    if (state == ShoppingVoiceDraftState.manual) {
      return _buildManualCard(context);
    }
    return _buildActivePanel(context);
  }

  Widget _buildManualCard(BuildContext context) {
    final palette = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: palette.borderDefault),
    );

    return Semantics(
      key: manualStateKey,
      button: true,
      label: copy.manualSemanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: palette.card,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: shape,
            onTap: onOpen,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Container(
                      key: manualMicBoxKey,
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: palette.accentPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.mic_none_rounded,
                        size: 21,
                        color: palette.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            copy.manualTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            copy.manualHelp,
                            maxLines: 2,
                            style: AppTextStyles.compact.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: palette.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivePanel(BuildContext context) {
    final palette = context.palette;
    final isUnavailable = state == ShoppingVoiceDraftState.unavailable;

    return Semantics(
      key: stateKey(state),
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 190),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.borderDefault),
          boxShadow: [
            BoxShadow(
              color: palette.navShadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(palette),
            const SizedBox(height: 3),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 21),
              child: Center(
                child: Text(
                  _effectiveTranscript,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            _ShoppingVoiceWaveform(
              key: waveformKey,
              soundLevel: soundLevel,
              isListening: state == ShoppingVoiceDraftState.listening,
              color: palette.joy,
            ),
            const SizedBox(height: 3),
            _buildCore(palette),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 17),
              child: Text(
                _help,
                textAlign: TextAlign.center,
                style: AppTextStyles.supporting.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
            if (isUnavailable) ...[
              const SizedBox(height: 4),
              _buildSettingsAction(palette),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette palette) {
    return SizedBox(
      key: headerKey,
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: palette.textTertiary,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      copy.privacyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.compact.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: state == ShoppingVoiceDraftState.unavailable
                      ? palette.textTertiary
                      : palette.joy,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _status,
                maxLines: 1,
                style: AppTextStyles.supporting.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                key: keyboardActionKey,
                button: true,
                label: copy.keyboardSemanticLabel,
                child: ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: 44,
                    child: Material(
                      color: palette.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: BorderSide(color: palette.borderDefault),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onKeyboard,
                        child: Icon(
                          Icons.keyboard_rounded,
                          size: 22,
                          color: palette.textSecondary,
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

  Widget _buildCore(AppPalette palette) {
    final VoidCallback? callback = switch (state) {
      ShoppingVoiceDraftState.listening => onStop,
      ShoppingVoiceDraftState.review => onRerecord,
      ShoppingVoiceDraftState.processing ||
      ShoppingVoiceDraftState.unavailable => null,
      ShoppingVoiceDraftState.manual => null,
    };
    final semanticLabel = switch (state) {
      ShoppingVoiceDraftState.listening => copy.stopSemanticLabel,
      ShoppingVoiceDraftState.processing => copy.processingSemanticLabel,
      ShoppingVoiceDraftState.review => copy.rerecordSemanticLabel,
      ShoppingVoiceDraftState.unavailable => copy.unavailableCoreSemanticLabel,
      ShoppingVoiceDraftState.manual => copy.manualSemanticLabel,
    };
    final (background, foreground) = switch (state) {
      ShoppingVoiceDraftState.listening => (palette.joy, palette.card),
      ShoppingVoiceDraftState.review => (palette.joyLight, palette.joyText),
      ShoppingVoiceDraftState.processing => (
        palette.backgroundMuted,
        palette.joyText,
      ),
      ShoppingVoiceDraftState.unavailable || ShoppingVoiceDraftState.manual => (
        palette.backgroundMuted,
        palette.textTertiary,
      ),
    };

    return Semantics(
      key: coreActionKey,
      button: true,
      enabled: callback != null,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 58,
          child: Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
            ),
            clipBehavior: Clip.antiAlias,
            shadowColor: palette.actionShadow,
            elevation: state == ShoppingVoiceDraftState.listening ? 3 : 1,
            child: InkWell(
              onTap: callback,
              child: Center(child: _buildCoreIcon(foreground)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoreIcon(Color color) => switch (state) {
    ShoppingVoiceDraftState.listening => Icon(
      Icons.stop_rounded,
      size: 29,
      color: color,
    ),
    ShoppingVoiceDraftState.processing => SizedBox.square(
      dimension: 25,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
    ),
    ShoppingVoiceDraftState.review => Icon(
      Icons.mic_rounded,
      size: 29,
      color: color,
    ),
    ShoppingVoiceDraftState.unavailable => Icon(
      Icons.mic_off_rounded,
      size: 29,
      color: color,
    ),
    ShoppingVoiceDraftState.manual => Icon(
      Icons.mic_none_rounded,
      size: 29,
      color: color,
    ),
  };

  Widget _buildSettingsAction(AppPalette palette) {
    return Semantics(
      key: settingsActionKey,
      button: true,
      label: copy.settingsSemanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 40,
          child: OutlinedButton(
            onPressed: onSettings,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.accentPrimary,
              side: BorderSide(color: palette.borderList),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(copy.settingsLabel),
          ),
        ),
      ),
    );
  }

  String get _status => switch (state) {
    ShoppingVoiceDraftState.listening => copy.listeningStatus,
    ShoppingVoiceDraftState.processing => copy.processingStatus,
    ShoppingVoiceDraftState.review => copy.reviewStatus,
    ShoppingVoiceDraftState.unavailable => copy.unavailableStatus,
    ShoppingVoiceDraftState.manual => copy.manualTitle,
  };

  String get _effectiveTranscript {
    if (transcript.isNotEmpty) return transcript;
    return switch (state) {
      ShoppingVoiceDraftState.listening => copy.listeningTranscriptPlaceholder,
      ShoppingVoiceDraftState.processing =>
        copy.processingTranscriptPlaceholder,
      ShoppingVoiceDraftState.review => copy.reviewTranscriptPlaceholder,
      ShoppingVoiceDraftState.unavailable => copy.unavailableTranscript,
      ShoppingVoiceDraftState.manual => copy.manualHelp,
    };
  }

  String get _help => switch (state) {
    ShoppingVoiceDraftState.listening => copy.listeningHelp,
    ShoppingVoiceDraftState.processing => copy.processingHelp,
    ShoppingVoiceDraftState.review => copy.reviewHelp,
    ShoppingVoiceDraftState.unavailable => copy.unavailableHelp,
    ShoppingVoiceDraftState.manual => copy.manualHelp,
  };
}

class _ShoppingVoiceWaveform extends StatelessWidget {
  const _ShoppingVoiceWaveform({
    super.key,
    required this.soundLevel,
    required this.isListening,
    required this.color,
  });

  static const _barHeights = <double>[
    9,
    18,
    13,
    25,
    17,
    29,
    12,
    22,
    27,
    16,
    24,
    11,
    20,
    15,
  ];

  final double soundLevel;
  final bool isListening;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final level = soundLevel.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final nominalHeight in _barHeights)
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 3,
              height: isListening
                  ? 4 + (nominalHeight - 4) * (0.35 + 0.65 * level)
                  : nominalHeight,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
        ],
      ),
    );
  }
}

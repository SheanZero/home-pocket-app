import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The five presentation states owned by the V16 unified-accounting voice dock.
enum UnifiedVoiceEntryState { idle, listening, processing, review, unavailable }

/// All visible and semantic copy rendered by [UnifiedVoiceEntryDock].
///
/// Keeping copy outside the widget lets each host resolve localized strings
/// without coupling this reusable presentation component to generated l10n.
@immutable
final class UnifiedVoiceEntryCopy {
  const UnifiedVoiceEntryCopy({
    required this.privacy,
    required this.status,
    required this.transcript,
    required this.help,
    required this.keyboardSemanticLabel,
    required this.coreSemanticLabel,
    required this.primaryAction,
    required this.settingsAction,
    required this.continuousSummary,
    required this.continuousAction,
  });

  final String privacy;
  final String status;
  final String transcript;
  final String help;
  final String keyboardSemanticLabel;
  final String coreSemanticLabel;
  final String primaryAction;
  final String settingsAction;
  final String continuousSummary;
  final String continuousAction;
}

/// Fixed V16 bottom dock for voice-assisted unified transaction entry.
///
/// The host owns recognition and save state. This widget only renders that
/// state and routes the five user intents through explicit callbacks.
class UnifiedVoiceEntryDock extends StatelessWidget {
  const UnifiedVoiceEntryDock({
    super.key,
    required this.state,
    required this.copy,
    required this.soundLevel,
    required this.continuousMode,
    required this.isSubmitting,
    required this.onKeyboard,
    required this.onCore,
    required this.onPrimary,
    required this.onSettings,
    required this.onToggleContinuous,
  });

  static const double height = 336;

  final UnifiedVoiceEntryState state;
  final UnifiedVoiceEntryCopy copy;
  final double soundLevel;
  final bool continuousMode;
  final bool isSubmitting;
  final VoidCallback onKeyboard;
  final VoidCallback onCore;
  final VoidCallback onPrimary;
  final VoidCallback onSettings;
  final VoidCallback onToggleContinuous;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      key: const Key('unified-voice-entry-dock'),
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          border: Border(top: BorderSide(color: palette.borderDefault)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: palette.navShadow,
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 17),
          child: Column(
            children: [
              _VoiceDockHeader(
                copy: copy,
                unavailable: state == UnifiedVoiceEntryState.unavailable,
                onKeyboard: onKeyboard,
              ),
              Expanded(
                child: _VoiceDockMain(
                  state: state,
                  copy: copy,
                  soundLevel: soundLevel,
                  onCore: onCore,
                ),
              ),
              _VoiceActionSlot(
                state: state,
                copy: copy,
                isSubmitting: isSubmitting,
                onPrimary: onPrimary,
                onSettings: onSettings,
              ),
              const SizedBox(height: 5),
              _ContinuousControl(
                copy: copy,
                continuousMode: continuousMode,
                onTap: onToggleContinuous,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceDockHeader extends StatelessWidget {
  const _VoiceDockHeader({
    required this.copy,
    required this.unavailable,
    required this.onKeyboard,
  });

  final UnifiedVoiceEntryCopy copy;
  final bool unavailable;
  final VoidCallback onKeyboard;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      key: const Key('unified-voice-header'),
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: palette.textTertiary,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    copy.privacy,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: AppTextStyles.compact.copyWith(
                      color: palette.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 128),
            child: Semantics(
              liveRegion: true,
              label: copy.status,
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    key: const Key('unified-voice-status-dot'),
                    decoration: BoxDecoration(
                      color: unavailable ? palette.textTertiary : palette.joy,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 8),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      copy.status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.supporting.copyWith(
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: copy.keyboardSemanticLabel,
                excludeFromSemantics: true,
                child: Semantics(
                  button: true,
                  label: copy.keyboardSemanticLabel,
                  excludeSemantics: true,
                  child: SizedBox.square(
                    key: const Key('unified-voice-keyboard'),
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
                          Icons.keyboard_alt_outlined,
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
}

class _VoiceDockMain extends StatelessWidget {
  const _VoiceDockMain({
    required this.state,
    required this.copy,
    required this.soundLevel,
    required this.onCore,
  });

  final UnifiedVoiceEntryState state;
  final UnifiedVoiceEntryCopy copy;
  final double soundLevel;
  final VoidCallback onCore;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 7, 0, 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 34,
            child: Center(
              child: Text(
                copy.transcript,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _JoyWaveform(
            soundLevel: soundLevel,
            isListening: state == UnifiedVoiceEntryState.listening,
          ),
          const SizedBox(height: 8),
          _VoiceCoreButton(state: state, copy: copy, onTap: onCore),
          const SizedBox(height: 5),
          SizedBox(
            height: 17,
            child: Text(
              copy.help,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.supporting.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoyWaveform extends StatelessWidget {
  const _JoyWaveform({required this.soundLevel, required this.isListening});

  static const _barHeights = <double>[
    9,
    18,
    13,
    25,
    17,
    29,
    12,
    22,
    30,
    16,
    25,
    11,
    21,
    15,
    27,
    10,
  ];

  final double soundLevel;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final level = soundLevel.clamp(0.0, 1.0);
    final scale = isListening ? 0.35 + (0.65 * level) : 1.0;

    return ExcludeSemantics(
      child: SizedBox(
        key: const Key('unified-voice-waveform'),
        height: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final baseHeight in _barHeights)
              AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 3,
                height: baseHeight * scale,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: palette.joy.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VoiceCoreButton extends StatelessWidget {
  const _VoiceCoreButton({
    required this.state,
    required this.copy,
    required this.onTap,
  });

  final UnifiedVoiceEntryState state;
  final UnifiedVoiceEntryCopy copy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled =
        state != UnifiedVoiceEntryState.processing &&
        state != UnifiedVoiceEntryState.unavailable;

    final (background, foreground, icon) = switch (state) {
      UnifiedVoiceEntryState.idle => (palette.joy, palette.card, Icons.mic),
      UnifiedVoiceEntryState.listening => (
        palette.joy,
        palette.card,
        Icons.stop_rounded,
      ),
      UnifiedVoiceEntryState.processing => (
        palette.backgroundMuted,
        palette.textSecondary,
        Icons.autorenew_rounded,
      ),
      UnifiedVoiceEntryState.review => (
        palette.joyLight,
        palette.joyText,
        Icons.mic,
      ),
      UnifiedVoiceEntryState.unavailable => (
        palette.backgroundMuted,
        palette.textTertiary,
        Icons.mic_off_rounded,
      ),
    };

    return Semantics(
      button: true,
      enabled: enabled,
      label: copy.coreSemanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        key: const Key('unified-voice-core'),
        dimension: 60,
        child: Material(
          color: background,
          shadowColor: state == UnifiedVoiceEntryState.listening
              ? palette.actionShadow
              : palette.navShadow,
          elevation: 2,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Icon(icon, size: 30, color: foreground),
          ),
        ),
      ),
    );
  }
}

class _VoiceActionSlot extends StatelessWidget {
  const _VoiceActionSlot({
    required this.state,
    required this.copy,
    required this.isSubmitting,
    required this.onPrimary,
    required this.onSettings,
  });

  final UnifiedVoiceEntryState state;
  final UnifiedVoiceEntryCopy copy;
  final bool isSubmitting;
  final VoidCallback onPrimary;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('unified-voice-action-slot'),
      height: 46,
      width: double.infinity,
      child: switch (state) {
        UnifiedVoiceEntryState.review => _FilledVoiceAction(
          materialKey: const Key('unified-voice-primary-action'),
          label: copy.primaryAction,
          icon: isSubmitting
              ? Icons.autorenew_rounded
              : Icons.receipt_long_rounded,
          enabled: !isSubmitting,
          onTap: onPrimary,
        ),
        UnifiedVoiceEntryState.unavailable => _FilledVoiceAction(
          materialKey: const Key('unified-voice-settings-action'),
          label: copy.settingsAction,
          icon: Icons.help_outline_rounded,
          enabled: true,
          onTap: onSettings,
        ),
        _ => const SizedBox.expand(),
      },
    );
  }
}

class _FilledVoiceAction extends StatelessWidget {
  const _FilledVoiceAction({
    required this.materialKey,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final Key materialKey;
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        key: materialKey,
        color: palette.accentPrimary,
        shadowColor: enabled ? palette.actionShadow : palette.navShadow,
        elevation: enabled ? 2 : 0,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: palette.card),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.button.copyWith(color: palette.card),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinuousControl extends StatelessWidget {
  const _ContinuousControl({
    required this.copy,
    required this.continuousMode,
    required this.onTap,
  });

  final UnifiedVoiceEntryCopy copy;
  final bool continuousMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      height: 27,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              copy.continuousSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.compact.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Semantics(
              button: true,
              toggled: continuousMode,
              label: copy.continuousAction,
              excludeSemantics: true,
              child: GestureDetector(
                key: const Key('unified-voice-continuous-action'),
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Center(
                  child: Text(
                    copy.continuousAction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.compact.copyWith(
                      color: palette.accentPrimary,
                      fontWeight: FontWeight.w700,
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

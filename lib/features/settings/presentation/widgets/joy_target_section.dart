import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/settings_section_card.dart';

/// Monthly Joy-target row reused by the compact General section.
class JoyTargetTile extends StatelessWidget {
  const JoyTargetTile({
    required this.configuredTarget,
    required this.recommendedTarget,
    required this.fallbackTarget,
    required this.onSave,
    this.compact = false,
    super.key,
  });

  final int? configuredTarget;
  final int? recommendedTarget;
  final int fallbackTarget;
  final Future<void> Function(int? value) onSave;
  final bool compact;

  int get _activeTarget =>
      configuredTarget ?? recommendedTarget ?? fallbackTarget;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final currentLine = configuredTarget == null
        ? l10n.settingsJoyTargetCurrentRecommended(_activeTarget)
        : l10n.settingsJoyTargetCurrentConfigured(configuredTarget!);
    final recommendationLine = recommendedTarget == null
        ? l10n.settingsJoyTargetFallback
        : l10n.settingsJoyTargetRecommendation(recommendedTarget!);

    return SettingsActionTile(
      icon: Icons.spa_outlined,
      title: compact ? l10n.settingsJoyTargetTitle : currentLine,
      subtitle: compact
          ? l10n.settingsJoyTargetValue(_activeTarget)
          : recommendationLine,
      onTap: () => _showDialog(context),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _JoyTargetDialog(configuredTarget: configuredTarget, onSave: onSave),
    );
  }
}

class _JoyTargetDialog extends StatefulWidget {
  const _JoyTargetDialog({
    required this.configuredTarget,
    required this.onSave,
  });

  final int? configuredTarget;
  final Future<void> Function(int? value) onSave;

  @override
  State<_JoyTargetDialog> createState() => _JoyTargetDialogState();
}

class _JoyTargetDialogState extends State<_JoyTargetDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.configuredTarget?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.settingsJoyTargetTitle),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.settingsJoyTargetInputLabel,
          hintText: l10n.settingsJoyTargetInputHint,
          errorText: _errorText,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => _saveValue(null),
          child: Text(l10n.settingsJoyTargetUseRecommendation),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.settingsJoyTargetCancel),
        ),
        FilledButton(
          onPressed: _validateAndSave,
          child: Text(l10n.settingsJoyTargetSave),
        ),
      ],
    );
  }

  Future<void> _saveValue(int? value) async {
    await widget.onSave(value);
    if (mounted) Navigator.of(context).pop();
  }

  void _validateAndSave() {
    final l10n = S.of(context);
    final raw = _controller.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0 || parsed.toString() != raw) {
      setState(() => _errorText = l10n.settingsJoyTargetInvalid);
      return;
    }
    _saveValue(parsed);
  }
}

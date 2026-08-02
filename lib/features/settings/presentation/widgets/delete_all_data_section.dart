import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/data_reset_signal.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/settings_section_card.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../providers/repository_providers.dart';

/// Keeps destructive local-data controls outside the backup/restore flow.
class DeleteAllDataSection extends ConsumerStatefulWidget {
  const DeleteAllDataSection({super.key});

  @override
  ConsumerState<DeleteAllDataSection> createState() =>
      _DeleteAllDataSectionState();
}

class _DeleteAllDataSectionState extends ConsumerState<DeleteAllDataSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return SettingsSectionCard(
      title: l10n.dataManagement,
      children: [
        SettingsNavigationTile(
          key: const ValueKey('settings-delete-all'),
          icon: Icons.delete_forever_outlined,
          iconColor: palette.error,
          title: l10n.deleteAllData,
          subtitle: l10n.deleteAllDataDescription,
          onTap: _busy ? () {} : _deleteAllData,
        ),
      ],
    );
  }

  Future<void> _deleteAllData() async {
    final l10n = S.of(context);
    final confirmed = await showSoftConfirmDialog(
      context,
      title: l10n.deleteAllData,
      body: l10n.deleteAllDataConfirmation,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final result = await ref.read(clearAllDataUseCaseProvider).execute();
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.isSuccess) {
      ref.read(dataResetSignalProvider.notifier).fire();
      showSuccessFeedback(context, S.of(context).allDataDeleted);
      return;
    }
    showErrorFeedback(context, result.error ?? S.of(context).deleteFailed);
  }
}

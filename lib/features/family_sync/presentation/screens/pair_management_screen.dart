import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/family_sync/unpair_use_case.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/paired_device.dart';
import '../../domain/models/sync_status.dart';
import '../providers/pair_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/sync_providers.dart';
import '../widgets/partner_device_tile.dart';
import '../widgets/sync_status_badge.dart';

/// Screen for managing the current device pairing.
///
/// Shows current pair info, sync status, and unpair action.
class PairManagementScreen extends ConsumerStatefulWidget {
  const PairManagementScreen({super.key});

  @override
  ConsumerState<PairManagementScreen> createState() =>
      _PairManagementScreenState();
}

class _PairManagementScreenState extends ConsumerState<PairManagementScreen> {
  PairedDevice? _activePair;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPair();
  }

  Future<void> _loadPair() async {
    setState(() => _isLoading = true);
    final pairRepo = ref.read(pairRepositoryProvider);
    final pair = await pairRepo.getActivePair();
    if (mounted) {
      setState(() {
        _activePair = pair;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUnpair() async {
    final pair = _activePair;
    if (pair == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).familySyncUnpairDevice),
        content: Text(
          S.of(context).familySyncUnpairConfirm(
                pair.partnerDeviceName ?? 'this device',
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(S.of(context).familySyncUnpair),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final useCase = ref.read(unpairUseCaseProvider);
    final result = await useCase.execute(pair.pairId);

    if (!mounted) return;

    if (result is UnpairSuccess) {
      ref.read(syncStatusNotifierProvider.notifier).updateStatus(
            SyncStatus.unpaired,
          );
      Navigator.of(context).pop();
    } else if (result is UnpairError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).familySyncUnpairFailed(result.message)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncStatusNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).familySync),
        actions: [
          SyncStatusBadge(status: syncStatus),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activePair != null
              ? _buildPairedContent(syncStatus)
              : _buildUnpairedContent(),
    );
  }

  Widget _buildPairedContent(SyncStatus syncStatus) {
    final pair = _activePair!;
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.familySyncPairedDevice,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                PartnerDeviceTile(
                  device: pair,
                  syncStatus: syncStatus,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pair info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.familySyncPairInfo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(l10n.familySyncPairId, pair.pairId.substring(0, 8)),
                _buildInfoRow(
                  l10n.familySyncPairedSince,
                  pair.confirmedAt != null
                      ? DateFormatter.formatDate(pair.confirmedAt!, locale)
                      : '-',
                ),
                _buildInfoRow(l10n.familySyncBookId, pair.bookId),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Unpair button
        OutlinedButton.icon(
          onPressed: _handleUnpair,
          icon: const Icon(Icons.link_off),
          label: Text(l10n.familySyncUnpair),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnpairedContent() {
    final l10n = S.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.devices,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.familySyncNoDevicePaired,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.familySyncPairPrompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

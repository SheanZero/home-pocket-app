import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/sync_status_model.dart';
import '../../use_cases/check_group_use_case.dart';
import '../providers/group_providers.dart';
import '../providers/sync_providers.dart';
import 'group_management_screen.dart';

/// Centered waiting screen displayed after the joiner has confirmed their
/// join request and is waiting for the group owner to approve.
///
/// Preserves the existing polling + event-listener pattern from the previous
/// implementation but with a redesigned UI matching the Pencil design.
class WaitingApprovalScreen extends ConsumerStatefulWidget {
  const WaitingApprovalScreen({
    super.key,
    required this.groupName,
    required this.ownerDisplayName,
  });

  final String groupName;
  final String ownerDisplayName;

  @override
  ConsumerState<WaitingApprovalScreen> createState() =>
      _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen> {
  bool _hasNavigated = false;
  StreamSubscription<SyncStatus>? _syncSubscription;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _listenForSyncStatus();
    _startPollingTimer();
  }

  void _listenForSyncStatus() {
    final engine = ref.read(syncEngineProvider);
    _syncSubscription = engine.statusStream.listen((status) {
      if (!mounted || _hasNavigated) return;
      // When SyncEngine detects memberConfirmed, it transitions to
      // initialSyncing or synced — either means approval happened.
      if (status.state == SyncState.initialSyncing ||
          status.state == SyncState.synced) {
        unawaited(_verifyGroupAndNavigate());
      }
    });
  }

  void _startPollingTimer() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!mounted || _hasNavigated) return;
        unawaited(_verifyGroupAndNavigate());
      },
    );
  }

  Future<void> _verifyGroupAndNavigate() async {
    if (_hasNavigated) return;

    final result = await ref.read(checkGroupUseCaseProvider).execute();
    if (!mounted || _hasNavigated) return;

    switch (result) {
      case CheckGroupInGroup(:final groupId):
        _hasNavigated = true;
        _pollingTimer?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => GroupManagementScreen(groupId: groupId),
          ),
        );
      case CheckGroupNotInGroup():
        // Still waiting for approval — nothing to do.
        break;
      case CheckGroupError():
        // Silently ignore transient errors; polling will retry.
        break;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    unawaited(_syncSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Group name row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '\u{1F3E0}',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.groupName,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Circular progress indicator
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: AppColors.accentPrimary,
                    backgroundColor: AppColors.borderDefault,
                  ),
                ),
                const SizedBox(height: 28),

                // Waiting title
                Text(
                  l10n.groupWaitingApproval,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Description with owner name
                Text(
                  l10n.groupWaitingDesc(widget.ownerDisplayName),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Hint lines
                Text(
                  l10n.groupWaitingHint1,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.groupWaitingHint2,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

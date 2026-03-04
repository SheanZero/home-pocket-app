import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/sync_status.dart';
import '../../use_cases/create_group_use_case.dart';
import '../../use_cases/join_group_use_case.dart';
import '../providers/group_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/sync_providers.dart';
import 'waiting_approval_screen.dart';
import '../widgets/pair_code_display.dart';
import '../widgets/pair_code_input.dart';

/// Pairing screen with two tabs:
/// 1. "Show My Code" - displays QR + 6-digit code for partner to scan/enter
/// 2. "Enter Partner Code" - input field for 6-digit code
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  CreateGroupResult? _createResult;
  JoinGroupResult? _joinResult;
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    unawaited(_ensureSyncNotificationsReady());
    _createGroup();
  }

  Future<void> _ensureSyncNotificationsReady() async {
    try {
      await ref.read(syncTriggerServiceProvider).initialize();
    } catch (error) {
      if (!mounted) return;
      debugPrint(
        'PairingScreen: failed to initialize sync notifications: $error',
      );
    }
  }

  Future<void> _createGroup() async {
    setState(() => _isCreating = true);
    final useCase = ref.read(createGroupUseCaseProvider);
    final result = await useCase.execute(widget.bookId);
    if (mounted) {
      setState(() {
        _createResult = result;
        _isCreating = false;
      });
    }
  }

  Future<void> _joinGroup(String code) async {
    setState(() {
      _isJoining = true;
      _joinResult = null;
    });
    final useCase = ref.read(joinGroupUseCaseProvider);
    final result = await useCase.execute(code);
    if (mounted) {
      setState(() {
        _joinResult = result;
        _isJoining = false;
      });

      if (result is JoinGroupSuccess) {
        ref
            .read(syncStatusNotifierProvider.notifier)
            .updateStatus(SyncStatus.pairing);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).familySyncJoinSuccess)),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => WaitingApprovalScreen(groupId: result.groupId),
          ),
        );
      }
    }
  }

  Future<void> _shareInviteCode(String inviteCode) async {
    final l10n = S.of(context);
    await Share.share(
      '${l10n.familySyncPairCode}\n$inviteCode\n\n${l10n.familySyncScanOrEnter}',
    );
  }

  void _handleScanQr() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).familySyncJoinDescription)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep sync and push services alive while the pairing flow is visible.
    ref.watch(syncTriggerServiceProvider);
    ref.watch(pushNotificationServiceProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).familySync),
          bottom: TabBar(
            tabs: [
              Tab(text: S.of(context).familySyncShowMyCode),
              Tab(text: S.of(context).familySyncEnterPartnerCode),
            ],
          ),
        ),
        body: TabBarView(children: [_buildShowCodeTab(), _buildEnterCodeTab()]),
      ),
    );
  }

  Widget _buildShowCodeTab() {
    if (_isCreating) {
      return const Center(child: CircularProgressIndicator());
    }

    final result = _createResult;
    if (result == null) {
      return Center(child: Text(S.of(context).familySyncCreatingGroup));
    }

    return switch (result) {
      CreateGroupSuccess(:final inviteCode, :final expiresAt) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PairCodeDisplay(
            inviteCode: inviteCode,
            qrData: 'hp://join/$inviteCode',
            expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
            onRegenerate: _createGroup,
            onShare: () => _shareInviteCode(inviteCode),
          ),
        ),
      ),
      CreateGroupError(:final message) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _createGroup,
              child: Text(S.of(context).retry),
            ),
          ],
        ),
      ),
    };
  }

  Widget _buildEnterCodeTab() {
    final errorMessage = _joinResult is JoinGroupError
        ? (_joinResult as JoinGroupError).message
        : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: PairCodeInput(
          onSubmit: _joinGroup,
          onScanQr: _handleScanQr,
          isLoading: _isJoining,
          errorMessage: errorMessage,
        ),
      ),
    );
  }
}

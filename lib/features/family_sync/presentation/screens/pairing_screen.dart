import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/family_sync/create_pair_use_case.dart';
import '../../../../application/family_sync/join_pair_use_case.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/pair_providers.dart';
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
  CreatePairResult? _createResult;
  JoinPairResult? _joinResult;
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _createPair();
  }

  Future<void> _createPair() async {
    setState(() => _isCreating = true);
    final useCase = ref.read(createPairUseCaseProvider);
    final result = await useCase.execute(widget.bookId);
    if (mounted) {
      setState(() {
        _createResult = result;
        _isCreating = false;
      });
    }
  }

  Future<void> _joinPair(String code) async {
    setState(() {
      _isJoining = true;
      _joinResult = null;
    });
    final useCase = ref.read(joinPairUseCaseProvider);
    final result = await useCase.execute(code);
    if (mounted) {
      setState(() {
        _joinResult = result;
        _isJoining = false;
      });

      if (result is JoinPairSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Paired with ${result.partnerDeviceName}. '
                'Waiting for confirmation...',
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        body: TabBarView(
          children: [
            _buildShowCodeTab(),
            _buildEnterCodeTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildShowCodeTab() {
    if (_isCreating) {
      return const Center(child: CircularProgressIndicator());
    }

    final result = _createResult;
    if (result == null) {
      return const Center(child: Text('Creating pair code...'));
    }

    return switch (result) {
      CreatePairSuccess(:final pairCode, :final qrData, :final expiresAt) =>
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: PairCodeDisplay(
              pairCode: pairCode,
              qrData: qrData,
              expiresAt:
                  DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
              onRegenerate: _createPair,
            ),
          ),
        ),
      CreatePairError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _createPair,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
    };
  }

  Widget _buildEnterCodeTab() {
    final errorMessage = _joinResult is JoinPairError
        ? (_joinResult as JoinPairError).message
        : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: PairCodeInput(
          onSubmit: _joinPair,
          isLoading: _isJoining,
          errorMessage: errorMessage,
        ),
      ),
    );
  }
}

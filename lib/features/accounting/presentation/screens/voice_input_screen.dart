import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/speech/speech_recognition_service.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/models/voice_parse_result.dart';
import '../providers/repository_providers.dart';
import '../providers/voice_providers.dart';
import '../widgets/entry_mode_switcher.dart';
import '../widgets/input_mode_tabs.dart';
import '../widgets/soft_toast.dart';
import '../widgets/voice_parse_preview.dart';
import '../widgets/voice_transcript_card.dart';
import '../widgets/voice_waveform.dart';
import 'transaction_confirm_screen.dart';

/// Voice input screen for creating transactions through natural language speech.
///
/// Replaces the previous static stub with a full [ConsumerStatefulWidget]
/// implementation. Manages [SpeechRecognitionService] lifecycle directly
/// (not from provider) for correct stateful lifecycle binding.
class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> {
  // Speech recognition service — managed directly (stateful lifecycle)
  final SpeechRecognitionService _speechService = SpeechRecognitionService();

  // Recording state
  bool _isRecording = false;
  bool _isInitialized = false;

  // Transcript state
  String _partialText = '';
  String _finalText = '';

  // Sound level state (normalized 0.0–1.0)
  double _soundLevel = 0.0;

  // Parse result
  VoiceParseResult? _parseResult;

  // Audio features collection
  final List<double> _soundLevels = [];
  final List<DateTime> _timestamps = [];
  DateTime? _startTime;
  int _partialResultCount = 0;
  int _lastWordCount = 0;

  // Debounce timer for partial result parsing
  Timer? _parseDebounce;

  // Sound level sampling throttle
  DateTime? _lastSampleTime;

  @override
  void initState() {
    super.initState();
    _initSpeechService();
  }

  Future<void> _initSpeechService() async {
    final available = await _speechService.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );

    if (mounted) {
      setState(() => _isInitialized = available);

      if (!available) {
        _showPermissionError();
      }
    }
  }

  void _onStatus(String status) {
    if (!mounted) return;
    // When speech service reports "done" or "notListening" after recording
    if ((status == 'done' || status == 'notListening') && _isRecording) {
      setState(() {
        _isRecording = false;
        _soundLevel = 0.0;
      });
    }
  }

  void _onError(String errorMsg, bool permanent) {
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _soundLevel = 0.0;
    });
  }

  void _showPermissionError() {
    // Insert a SoftToast overlay for permission error feedback
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: SoftToast(
          message: 'マイクへのアクセスを許可してください',
          icon: Icons.mic_off,
          onDismissed: () => entry.remove(),
        ),
      ),
    );
    overlay.insert(entry);
  }

  Future<void> _toggleRecording() async {
    if (!_isInitialized) return;

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // Read the user's persisted voice language setting (async provider, use valueOrNull fallback)
    final localeId = ref.read(voiceLocaleIdProvider).valueOrNull ?? 'zh-CN';

    // Reset state
    setState(() {
      _isRecording = true;
      _partialText = '';
      _finalText = '';
      _soundLevel = 0.0;
      _parseResult = null;
    });
    _soundLevels.clear();
    _timestamps.clear();
    _startTime = DateTime.now();
    _partialResultCount = 0;
    _lastWordCount = 0;

    await _speechService.startListening(
      onResult: _onResult,
      onSoundLevel: _onSoundLevel,
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopRecording() async {
    await _speechService.stopListening();
    setState(() {
      _isRecording = false;
      _soundLevel = 0.0;
    });
  }

  void _onSoundLevel(double level) {
    if (!mounted) return;

    // Throttle sound level sampling to 100ms
    final now = DateTime.now();
    if (_lastSampleTime != null &&
        now.difference(_lastSampleTime!).inMilliseconds < 100) {
      // Update UI only
      setState(() => _soundLevel = level);
      return;
    }
    _lastSampleTime = now;
    _soundLevels.add(level);
    _timestamps.add(now);

    setState(() => _soundLevel = level);
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    if (!result.finalResult) {
      _partialResultCount++;
      _lastWordCount = _countWords(result.recognizedWords);

      setState(() => _partialText = result.recognizedWords);

      // Debounce parsing for partial results (300ms)
      _parseDebounce?.cancel();
      _parseDebounce = Timer(const Duration(milliseconds: 300), () {
        if (result.recognizedWords.isNotEmpty) {
          _parseVoiceInput(result.recognizedWords);
        }
      });
    } else {
      // Final result
      final text = result.recognizedWords;
      setState(() {
        _finalText = text;
        _partialText = '';
        _isRecording = false;
        _soundLevel = 0.0;
      });

      _parseDebounce?.cancel();
      if (text.isNotEmpty) {
        _parseFinalResult(text);
      }
    }
  }

  Future<void> _parseVoiceInput(String text) async {
    if (!mounted) return;
    final useCase = ref.read(parseVoiceInputUseCaseProvider);
    final result = await useCase.execute(text);
    if (mounted && result.isSuccess) {
      setState(() => _parseResult = result.data);
    }
  }

  Future<void> _parseFinalResult(String text) async {
    if (!mounted) return;
    final useCase = ref.read(parseVoiceInputUseCaseProvider);
    final result = await useCase.execute(text);

    if (!mounted || !result.isSuccess) return;

    var parseResult = result.data!;

    // For soul ledger transactions, estimate satisfaction from audio features
    if (parseResult.ledgerType == LedgerType.soul) {
      final features = _buildAudioFeatures();
      final estimator = ref.read(voiceSatisfactionEstimatorProvider);
      final satisfaction = estimator.estimate(
        audioFeatures: features,
        recognizedText: text,
      );
      parseResult = parseResult.copyWith(estimatedSatisfaction: satisfaction);
    }

    setState(() => _parseResult = parseResult);
  }

  VoiceAudioFeatures _buildAudioFeatures() {
    final now = DateTime.now();
    return VoiceAudioFeatures(
      soundLevels: List.unmodifiable(_soundLevels),
      timestamps: List.unmodifiable(_timestamps),
      startTime: _startTime ?? now,
      endTime: now,
      partialResultCount: _partialResultCount,
      wordCount: _lastWordCount,
    );
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    // Japanese/Chinese: estimate by character count (2 chars ≈ 1 word)
    // English: split by whitespace
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(text);
    if (hasLatin) {
      return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    }
    return (text.replaceAll(RegExp(r'\s'), '').length / 2).ceil();
  }

  Future<void> _navigateToConfirm() async {
    final result = _parseResult;
    if (result == null) return;

    final categoryId =
        result.categoryMatch?.categoryId ?? result.merchantCategoryId;

    if (categoryId == null) {
      // No category matched — show error
      if (!mounted) return;
      final overlay = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: SoftToast(
            message: 'カテゴリが認識できませんでした',
            icon: Icons.folder_off_outlined,
            onDismissed: () => entry.remove(),
          ),
        ),
      );
      overlay.insert(entry);
      return;
    }

    // Look up the Category object
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final category = await categoryRepo.findById(categoryId);

    if (!mounted) return;

    if (category == null) {
      final overlay = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: SoftToast(
            message: 'カテゴリが見つかりません',
            icon: Icons.folder_off_outlined,
            onDismissed: () => entry.remove(),
          ),
        ),
      );
      overlay.insert(entry);
      return;
    }

    // Look up parent category if the matched category has a parentId
    final parentCategory = category.parentId != null
        ? await categoryRepo.findById(category.parentId!)
        : null;

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionConfirmScreen(
          bookId: widget.bookId,
          amount: result.amount ?? 0,
          category: category,
          parentCategory: parentCategory,
          date: DateTime.now(),
          initialMerchant: result.merchantName,
          initialSatisfaction: result.ledgerType == LedgerType.soul
              ? result.estimatedSatisfaction
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final hasResult = _parseResult != null;
    final hasText = _finalText.isNotEmpty || _partialText.isNotEmpty;

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

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Transcript card
                  VoiceTranscriptCard(
                    isRecording: _isRecording,
                    partialText: _partialText,
                    finalText: _finalText,
                  ),

                  if (hasResult || hasText) const SizedBox(height: 16),

                  // Parse result preview
                  if (hasResult)
                    VoiceParsePreview(parseResult: _parseResult),
                ],
              ),
            ),
          ),

          // Waveform
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: VoiceWaveform(
              soundLevel: _soundLevel,
              isActive: _isRecording,
              color: AppColors.survival,
            ),
          ),

          // Mic button
          GestureDetector(
            onTap: _isInitialized ? _toggleRecording : null,
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

          // Next button — enabled only when parse result is ready
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: hasResult
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.fabGradientStart,
                            AppColors.fabGradientEnd,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.fabGradientStart.withValues(alpha: 0.4),
                            AppColors.fabGradientEnd.withValues(alpha: 0.4),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: hasResult ? _navigateToConfirm : null,
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
    _parseDebounce?.cancel();
    _speechService.cancelListening();
    super.dispose();
  }
}

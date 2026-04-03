import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../infrastructure/speech/speech_recognition_service.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/models/category.dart';
import '../../domain/models/voice_parse_result.dart';
import '../providers/repository_providers.dart';
import '../providers/voice_providers.dart';
import '../utils/category_display_utils.dart';
import '../widgets/entry_mode_switcher.dart';
import '../widgets/input_mode_tabs.dart';
import '../widgets/soft_toast.dart';
import '../widgets/voice_waveform.dart';
import 'transaction_confirm_screen.dart';

/// Voice input screen for creating transactions through natural language speech.
///
/// Replaces the previous static stub with a full [ConsumerStatefulWidget]
/// implementation. Manages [SpeechRecognitionService] lifecycle directly
/// (not from provider) for correct stateful lifecycle binding.
class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key, required this.bookId, this.speechService});

  final String bookId;
  final SpeechRecognitionService? speechService;

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> {
  // Speech recognition service — managed directly (stateful lifecycle)
  late final SpeechRecognitionService _speechService =
      widget.speechService ?? SpeechRecognitionService();

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

  // Resolved category objects for display
  Category? _resolvedCategory;
  Category? _resolvedParentCategory;

  // Effective voice locale (updated reactively from voiceLocaleIdProvider)
  String _voiceLocaleId = 'zh-CN';

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
    // Use the locale pre-warmed and kept current by ref.watch in build().
    final localeId = _voiceLocaleId;

    // Reset state
    setState(() {
      _isRecording = true;
      _partialText = '';
      _finalText = '';
      _soundLevel = 0.0;
      _parseResult = null;
      _resolvedCategory = null;
      _resolvedParentCategory = null;
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
      await _resolveCategory(
        result.data?.categoryMatch?.categoryId ??
            result.data?.merchantCategoryId,
      );
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
    await _resolveCategory(
      parseResult.categoryMatch?.categoryId ?? parseResult.merchantCategoryId,
    );
  }

  Future<void> _resolveCategory(String? categoryId) async {
    if (categoryId == null) {
      if (mounted) {
        setState(() {
          _resolvedCategory = null;
          _resolvedParentCategory = null;
        });
      }
      return;
    }
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final category = await categoryRepo.findById(categoryId);
    final parentCategory = category?.parentId != null
        ? await categoryRepo.findById(category!.parentId!)
        : null;
    if (mounted) {
      setState(() {
        _resolvedCategory = category;
        _resolvedParentCategory = parentCategory;
      });
    }
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

    // Look up the Category object (may be null if not recognized)
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final category = categoryId != null
        ? await categoryRepo.findById(categoryId)
        : null;

    // Look up parent category if the matched category has a parentId
    final parentCategory = category?.parentId != null
        ? await categoryRepo.findById(category!.parentId!)
        : null;

    if (!mounted) return;

    // Extract keyword for voice learning
    final keyword = _extractVoiceKeyword(result);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionConfirmScreen(
          bookId: widget.bookId,
          amount: result.amount ?? 0,
          category: category,
          parentCategory: parentCategory,
          date: result.parsedDate ?? DateTime.now(),
          initialMerchant: result.merchantName,
          initialSatisfaction: result.ledgerType == LedgerType.soul
              ? result.estimatedSatisfaction
              : null,
          voiceKeyword: keyword,
        ),
      ),
    );
  }

  String _extractVoiceKeyword(VoiceParseResult result) {
    var remaining = result.rawText;

    // Remove amount patterns
    remaining = remaining.replaceAll(
      RegExp(r'[¥￥]?\s*[\d,]+\.?\d*\s*(円|元|ドル)?'),
      '',
    );

    // Remove merchant name if matched
    if (result.merchantName != null) {
      remaining = remaining.replaceFirst(result.merchantName!, '');
    }

    // Remove Japanese particles
    remaining = remaining.replaceAll(RegExp(r'[のにでをはがもへとや]'), '');

    // Remove Chinese particles
    remaining = remaining.replaceAll(RegExp(r'[的了吗呢吧啊呀哦]'), '');

    return remaining.trim();
  }

  String _transcriptText() {
    return _finalText.isNotEmpty ? _finalText : _partialText;
  }

  String _parsedAmountText(Locale locale) {
    final amount = _parseResult?.amount;
    if (amount == null) return '';
    return NumberFormatter.formatCurrency(amount, 'JPY', locale);
  }

  String _parsedCategoryText(Locale locale) {
    final category = _resolvedCategory;
    if (category == null) return '';
    return formatCategoryPath(
      category: category,
      parentCategory: _resolvedParentCategory,
      locale: locale,
    );
  }

  String _parsedDateText(Locale locale, S l10n) {
    final date = _parseResult?.parsedDate;
    if (date == null) return l10n.todayDate;
    return DateFormatter.formatDate(date, locale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final hasResult = _parseResult != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(currentLocaleProvider);

    // Watch voiceLocaleIdProvider so the screen rebuilds when the user changes
    // the voice language in Settings. The current value is stored in
    // _voiceLocaleId for synchronous use in _startRecording().
    final voiceLocaleAsync = ref.watch(voiceLocaleIdProvider);
    if (voiceLocaleAsync case AsyncData(:final value)) {
      _voiceLocaleId = value;
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.background
          : AppColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: isDark ? AppColorsDark.card : AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.addTransaction,
          style: AppTextStyles.headlineMedium.copyWith(
            color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
          ),
        ),
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
                  VoiceRecognitionResultCard(
                    transcript: _transcriptText(),
                    recognitionLabel: l10n.recognitionResult,
                    amountLabel: l10n.amount,
                    amountValue: _parsedAmountText(locale),
                    categoryLabel: l10n.category,
                    categoryValue: _parsedCategoryText(locale),
                    dateLabel: l10n.date,
                    dateValue: _parsedDateText(locale, l10n),
                    isDark: isDark,
                  ),
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
                  colors: const [
                    AppColors.actionGradientStart,
                    AppColors.actionGradientEnd,
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.actionShadow,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 32),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            l10n.tapToRecord,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColorsDark.textTertiary
                  : AppColors.textTertiary,
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
                            AppColors.actionGradientStart,
                            AppColors.actionGradientEnd,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.actionGradientStart.withValues(
                              alpha: 0.4,
                            ),
                            AppColors.actionGradientEnd.withValues(alpha: 0.4),
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

class VoiceRecognitionResultCard extends StatelessWidget {
  const VoiceRecognitionResultCard({
    super.key,
    required this.transcript,
    required this.recognitionLabel,
    required this.amountLabel,
    required this.amountValue,
    required this.categoryLabel,
    required this.categoryValue,
    required this.dateLabel,
    required this.dateValue,
    required this.isDark,
  });

  final String transcript;
  final String recognitionLabel;
  final String amountLabel;
  final String amountValue;
  final String categoryLabel;
  final String categoryValue;
  final String dateLabel;
  final String dateValue;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark
        ? AppColorsDark.textPrimary
        : AppColors.textPrimary;
    final secondaryColor = isDark
        ? AppColorsDark.textSecondary
        : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.card : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            recognitionLabel,
            style: AppTextStyles.bodySmall.copyWith(
              color: secondaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transcript,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: isDark
                ? AppColorsDark.backgroundDivider
                : AppColors.backgroundDivider,
          ),
          _ParsedInfoRow(
            icon: Icons.payments_outlined,
            label: amountLabel,
            value: amountValue,
            isDark: isDark,
          ),
          _ParsedDivider(isDark: isDark),
          _ParsedInfoRow(
            icon: Icons.shopping_bag_outlined,
            label: categoryLabel,
            value: categoryValue,
            isDark: isDark,
          ),
          _ParsedDivider(isDark: isDark),
          _ParsedInfoRow(
            icon: Icons.calendar_today_outlined,
            label: dateLabel,
            value: dateValue,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ParsedInfoRow extends StatelessWidget {
  const _ParsedInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppColorsDark.textTertiary : AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColorsDark.textSecondary
                  : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColorsDark.textPrimary
                    : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsedDivider extends StatelessWidget {
  const _ParsedDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: isDark
          ? AppColorsDark.backgroundDivider
          : AppColors.backgroundDivider,
    );
  }
}

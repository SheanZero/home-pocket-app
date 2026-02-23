import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../application/ocr/scan_receipt_use_case.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/category.dart';
import '../providers/ocr_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/voice_providers.dart';
import '../widgets/entry_mode_switcher.dart';
import '../widgets/input_mode_tabs.dart';
import 'transaction_confirm_screen.dart';

/// OCR scanner screen with dark camera-style UI.
///
/// Acquires images via camera or gallery, runs OCR pipeline
/// (preprocess → recognize → parse), resolves merchant → category,
/// then navigates to TransactionConfirmScreen with pre-filled data.
class OcrScannerScreen extends ConsumerStatefulWidget {
  const OcrScannerScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends ConsumerState<OcrScannerScreen> {
  bool _isProcessing = false;

  Future<void> _scan(ImageSource source) async {
    // 1. Pick image
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source);
    if (xFile == null || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      // 2. Read bytes
      final bytes = await xFile.readAsBytes();

      // 3. Run OCR pipeline
      final useCase = ref.read(scanReceiptUseCaseProvider);
      final result = await useCase.executeFromBytes(bytes);

      if (!mounted) return;

      if (result.isError) {
        setState(() => _isProcessing = false);
        _showError(result.error!);
        return;
      }

      final data = result.data!;

      // 4. Resolve merchant → category (same pattern as VoiceInputScreen)
      Category? category;
      Category? parentCategory;

      if (data.merchantName != null && data.merchantName!.isNotEmpty) {
        final merchantDb = ref.read(merchantDatabaseProvider);
        final match = merchantDb.findMerchant(data.merchantName!);

        if (match != null) {
          final categoryRepo = ref.read(categoryRepositoryProvider);
          category = await categoryRepo.findById(match.categoryId);
          if (category?.parentId != null) {
            parentCategory = await categoryRepo.findById(category!.parentId!);
          }
        }
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // 5. Navigate to confirm screen
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TransactionConfirmScreen(
            bookId: widget.bookId,
            amount: data.amount ?? 0,
            category: category,
            parentCategory: parentCategory,
            date: data.date ?? DateTime.now(),
            initialMerchant: data.merchantName,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError(OcrError.scanFailed);
      }
    }
  }

  void _showError(OcrError error) {
    final l10n = S.of(context);
    final message = switch (error) {
      OcrError.noImageSelected => l10n.ocrNoImageSelected,
      OcrError.preprocessingFailed => l10n.ocrPreprocessingFailed,
      OcrError.noTextRecognized => l10n.ocrNoTextRecognized,
      OcrError.scanFailed => l10n.ocrScanFailed,
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A2530),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.ocrScanTitle,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // balance the back button
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Input mode tabs (OCR active)
                EntryModeSwitcher(
                  selectedMode: InputMode.ocr,
                  bookId: widget.bookId,
                ),

                const SizedBox(height: 24),

                // Camera viewfinder area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.survival.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.document_scanner_outlined,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.ocrHint,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isProcessing ? l10n.ocrProcessing : l10n.ocrHint,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery
                      _CircleButton(
                        icon: Icons.photo_library_outlined,
                        onTap: _isProcessing
                            ? () {}
                            : () => _scan(ImageSource.gallery),
                      ),
                      // Shutter
                      GestureDetector(
                        onTap: _isProcessing
                            ? null
                            : () => _scan(ImageSource.camera),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Flash (stub — will be implemented with live camera preview)
                      _CircleButton(
                        icon: Icons.flash_off_outlined,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Processing overlay
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        l10n.ocrProcessing,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/constants/warm_emojis.dart';
import '../widgets/avatar_display.dart';
import '../widgets/scattered_emoji_background.dart';

const _profileDarkBackground = Color(0xFF141418);
const _profileDarkSurface = Color(0xFF2A2A32);
const _profileDarkTextPrimary = Color(0xFFF0F0F5);
const _profileDarkTextSecondary = Color(0xFF6B6B78);

class AvatarPickerResult {
  const AvatarPickerResult({required this.emoji, this.imagePath});

  final String emoji;
  final String? imagePath;
}

class AvatarPickerScreen extends StatefulWidget {
  const AvatarPickerScreen({
    super.key,
    required this.currentEmoji,
    this.currentImagePath,
  });

  final String currentEmoji;
  final String? currentImagePath;

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late String _selectedEmoji;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.currentEmoji;
    _selectedImagePath = widget.currentImagePath;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _selectedImagePath == null ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l10n = S.of(context);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null || !mounted) {
        return;
      }

      final documentsDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${documentsDir.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final destination = File(
        '${avatarDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(picked.path).copy(destination.path);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImagePath = destination.path;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profilePhotoFailed)));
    }
  }

  void _submit() {
    Navigator.of(context).pop(
      AvatarPickerResult(emoji: _selectedEmoji, imagePath: _selectedImagePath),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? _profileDarkTextPrimary
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? _profileDarkTextSecondary
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? _profileDarkBackground : AppColors.background,
      body: ScatteredEmojiBackground(
        pattern: ScatteredEmojiPattern.avatarPicker,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.profileCancel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      l10n.profileSelectAvatar,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _submit,
                      child: Text(
                        '${l10n.profileDone} ✓',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          AvatarDisplay(
                            emoji: _selectedEmoji,
                            imagePath: _selectedImagePath,
                            size: 110,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '✏️ ${l10n.profileChangeAvatar}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? _profileDarkSurface
                                  : AppColors.borderDefault,
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.accentPrimary,
                          indicatorWeight: 2,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: AppColors.accentPrimary,
                          unselectedLabelColor: textSecondary,
                          labelStyle: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: [
                            Tab(text: l10n.profileEmojiTab),
                            Tab(text: l10n.profilePhotoTab),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _EmojiGrid(
                              selectedEmoji: _selectedEmoji,
                              hasSelectedImage: _selectedImagePath != null,
                              isDark: isDark,
                              onSelected: (emoji) {
                                setState(() {
                                  _selectedEmoji = emoji;
                                  _selectedImagePath = null;
                                });
                              },
                            ),
                            _PhotoTab(
                              isDark: isDark,
                              label: l10n.profileUploadPhoto,
                              onPickPhoto: _pickPhoto,
                              hasSelectedImage: _selectedImagePath != null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({
    required this.selectedEmoji,
    required this.hasSelectedImage,
    required this.isDark,
    required this.onSelected,
  });

  final String selectedEmoji;
  final bool hasSelectedImage;
  final bool isDark;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tileColor = isDark ? _profileDarkSurface : AppColors.backgroundMuted;
    final tileText = isDark ? _profileDarkTextPrimary : AppColors.textPrimary;

    return GridView.builder(
      itemCount: warmEmojis.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 56,
      ),
      itemBuilder: (context, index) {
        final emoji = warmEmojis[index];
        final isSelected = !hasSelectedImage && emoji == selectedEmoji;

        return GestureDetector(
          onTap: () => onSelected(emoji),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected && !isDark ? Colors.white : tileColor,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.accentPrimary, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: TextStyle(fontSize: 28, height: 1, color: tileText),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoTab extends StatelessWidget {
  const _PhotoTab({
    required this.isDark,
    required this.label,
    required this.onPickPhoto,
    required this.hasSelectedImage,
  });

  final bool isDark;
  final String label;
  final VoidCallback onPickPhoto;
  final bool hasSelectedImage;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? _profileDarkTextSecondary
        : AppColors.textSecondary;
    final surfaceColor = isDark ? _profileDarkSurface : AppColors.card;

    return Center(
      child: GestureDetector(
        onTap: onPickPhoto,
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? _profileDarkSurface : AppColors.borderDefault,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasSelectedImage
                    ? Icons.check_circle_outline
                    : Icons.add_photo_alternate_outlined,
                color: AppColors.accentPrimary,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasSelectedImage ? 'JPG / PNG' : 'JPG / PNG · 512px',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

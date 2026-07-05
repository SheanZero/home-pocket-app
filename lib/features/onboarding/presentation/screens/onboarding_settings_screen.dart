import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/profile/save_user_profile_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/constants/warm_emojis.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../accounting/presentation/providers/repository_providers.dart';
import '../../../accounting/presentation/widgets/currency_selector_sheet.dart';
import '../../../profile/presentation/providers/repository_providers.dart';
import '../../../profile/presentation/providers/state_user_profile.dart';
import '../../../profile/presentation/screens/avatar_picker_screen.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../../../settings/presentation/providers/repository_providers.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../../settings/presentation/providers/state_settings.dart';
import '../utils/onboarding_locale_resolution.dart';

/// The onboarding basic-settings page (D-01 / D-03 / D-10), re-skinned to the
/// Welcome A design screen 04 (WELA-02).
///
/// Eyebrow + title header, tappable avatar with a camera badge, inline name
/// field, 4-segment display-language selector (日本語/中文/English/自動),
/// currency + voice picker rows and the この設定ではじめる confirm button.
/// All persistence/provider/validation logic is unchanged from the D-10
/// implementation: language writes through instantly, currency updates
/// `Book.currency`, voice persists a concrete code, and the confirm button
/// stays disabled until a nickname is set (D-14).
///
/// On successful confirm the screen saves the profile and signals completion
/// via [onConfirmed] — it does NOT navigate itself and does NOT set
/// `onboarding_complete` (that is the flow host's final step, 54-07).
class OnboardingSettingsScreen extends ConsumerStatefulWidget {
  const OnboardingSettingsScreen({
    super.key,
    required this.bookId,
    required this.onConfirmed,
  });

  final String bookId;

  /// Fired exactly once when the profile save succeeds; the flow host wires
  /// this to advance to the lock-entry screen (54-07).
  final VoidCallback onConfirmed;

  @override
  ConsumerState<OnboardingSettingsScreen> createState() =>
      _OnboardingSettingsScreenState();
}

class _OnboardingSettingsScreenState
    extends ConsumerState<OnboardingSettingsScreen> {
  // Identity (folded from ProfileOnboardingScreen).
  String _nickname = '';
  late String _selectedEmoji;
  String? _selectedImagePath;
  late final TextEditingController _nicknameController;

  // UI language: `_pickedLanguageCode == null` while untouched means "follow
  // the system default" (D-08).
  bool _languageTouched = false;
  String? _pickedLanguageCode;

  // Currency (default JPY, D-09) and voice (default = chosen UI lang, D-09).
  String _currencyCode = 'JPY';
  late String _voiceLanguageCode;
  bool _voiceExplicitlyPicked = false;

  bool _isSaving = false;

  String get _deviceLanguage => PlatformDispatcher.instance.locale.languageCode;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = randomWarmEmoji();
    _nicknameController = TextEditingController();
    // Voice tracks the (untouched) UI-language preselect, always concrete.
    _voiceLanguageCode = resolveVoiceLanguageForOnboarding(
      explicitlyPicked: false,
      pickedLanguage: '',
      deviceLanguage: _deviceLanguage,
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _canStart => _nickname.trim().isNotEmpty && !_isSaving;

  /// Whether the user explicitly pinned a concrete UI language (vs accepting
  /// the system preselect). Drives voice-default tracking + confirm semantics.
  bool get _languageExplicitlyPinned =>
      _languageTouched && _pickedLanguageCode != null;

  /// The segment that renders as selected: the pinned concrete code, or 自動
  /// while the user follows the system default.
  String get _selectedLanguageSegment =>
      _languageExplicitlyPinned ? _pickedLanguageCode! : 'system';

  // ── Editors ───────────────────────────────────────────────────────────────

  Future<void> _openAvatarPicker() async {
    final result = await Navigator.of(context).push<AvatarPickerResult>(
      MaterialPageRoute(
        builder: (_) => AvatarPickerScreen(
          currentEmoji: _selectedEmoji,
          currentImagePath: _selectedImagePath,
        ),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _selectedEmoji = result.emoji;
      _selectedImagePath = result.imagePath;
    });
  }

  Future<void> _applyLanguageSelection(String value) async {
    // Write through immediately so MaterialApp switches locale instantly
    // (D-07/D-08, ONBOARD-03). Explicit pick pins 'ja'/'zh'/'en'; the 自動
    // segment persists 'system' (keep following the device).
    if (value == 'system') {
      await ref.read(localeProvider.notifier).setSystemDefault();
    } else {
      await ref.read(localeProvider.notifier).setLocale(Locale(value));
    }
    if (!mounted) {
      return;
    }
    ref.invalidate(appSettingsProvider);
    setState(() {
      _languageTouched = true;
      _pickedLanguageCode = value == 'system' ? null : value;
      // Voice default tracks the chosen UI language until voice is overridden.
      if (!_voiceExplicitlyPicked) {
        _voiceLanguageCode = resolveVoiceLanguageForOnboarding(
          explicitlyPicked: value != 'system',
          pickedLanguage: value,
          deviceLanguage: _deviceLanguage,
        );
      }
    });
  }

  Future<void> _openCurrencyPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencySelectorSheet(
        selectedCode: _currencyCode,
        onSelect: (code) => _applyCurrencySelection(code),
      ),
    );
  }

  /// Writes the chosen currency through to `Book.currency` — a NEW book-default
  /// write path (ONBOARD-04 / D-09, RESEARCH Pattern 3).
  Future<void> _applyCurrencySelection(String code) async {
    final book = await ref.read(bookByIdProvider(bookId: widget.bookId).future);
    if (book != null) {
      await ref
          .read(bookRepositoryProvider)
          .update(book.copyWith(currency: code));
    }
    if (!mounted) {
      return;
    }
    ref.invalidate(bookByIdProvider);
    setState(() => _currencyCode = code);
  }

  Future<void> _openVoicePicker() async {
    final l10n = S.of(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.onboardingRowVoice),
        content: RadioGroup<String>(
          groupValue: _voiceLanguageCode,
          onChanged: (value) {
            if (value != null) {
              Navigator.pop(dialogContext, value);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languageOptions(l10n).entries
                .map(
                  (entry) => RadioListTile<String>(
                    title: Text(entry.value),
                    value: entry.key,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    await ref.read(settingsRepositoryProvider).setVoiceLanguage(picked);
    if (!mounted) {
      return;
    }
    setState(() {
      _voiceExplicitlyPicked = true;
      _voiceLanguageCode = picked;
    });
  }

  /// Confirm handler for `この設定ではじめる` (enabled only once a nickname is
  /// set, D-14). Persists the untouched defaults (system language + concrete
  /// voice language), saves the profile, and signals completion to the flow
  /// host. Does NOT set `onboarding_complete` (the flow host's final step,
  /// 54-07).
  Future<void> _confirm() async {
    if (!_canStart) {
      return;
    }
    final l10n = S.of(context);
    setState(() => _isSaving = true);

    // D-08: an untouched UI-language row means "keep following the device".
    if (!_languageExplicitlyPinned) {
      await ref.read(localeProvider.notifier).setSystemDefault();
      if (!mounted) {
        return;
      }
      ref.invalidate(appSettingsProvider);
    }

    // D-09 / Pitfall 4: voice language is always a concrete ja/zh/en code,
    // never the 'system' sentinel — guaranteed by the 54-01 resolver.
    final voiceLanguage = resolveVoiceLanguageForOnboarding(
      explicitlyPicked: _voiceExplicitlyPicked,
      pickedLanguage: _voiceLanguageCode,
      deviceLanguage: _deviceLanguage,
    );
    await ref.read(settingsRepositoryProvider).setVoiceLanguage(voiceLanguage);
    if (!mounted) {
      return;
    }

    final result = await ref
        .read(saveUserProfileUseCaseProvider)
        .execute(
          displayName: _nickname,
          avatarEmoji: _selectedEmoji,
          avatarImagePath: _selectedImagePath,
        );
    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      ref.invalidate(userProfileProvider);
      widget.onConfirmed();
      return;
    }

    setState(() => _isSaving = false);
    showErrorFeedback(context, _messageForError(l10n, result.error));
  }

  // ── Labels ──────────────────────────────────────────────────────────────

  Map<String, String> _languageOptions(S l10n) => {
    'ja': l10n.languageJapanese,
    'zh': l10n.languageChinese,
    'en': l10n.languageEnglish,
  };

  String _languageName(S l10n, String code) =>
      _languageOptions(l10n)[code] ?? l10n.languageJapanese;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 8),
                children: [
                  Text(
                    l10n.onboardingSetupEyebrow,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: palette.dailyText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onboardingSetupTitle,
                    style: TextStyle(
                      fontSize: 23,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: _AvatarBlock(
                      emoji: _selectedEmoji,
                      imagePath: _selectedImagePath,
                      onTap: _openAvatarPicker,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FieldLabel(text: l10n.onboardingRowName),
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: _fieldBoxDecoration(palette),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _nicknameController,
                      onChanged: (value) => setState(() => _nickname = value),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: l10n.profileNicknamePlaceholder,
                        hintStyle: TextStyle(
                          fontSize: 14.5,
                          color: palette.textTertiary,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel(text: l10n.onboardingRowLanguage),
                  Row(
                    children: [
                      _LanguageSegment(
                        key: const ValueKey('onboarding-lang-ja'),
                        flex: 10,
                        label: l10n.languageJapanese,
                        selected: _selectedLanguageSegment == 'ja',
                        onTap: () => _applyLanguageSelection('ja'),
                      ),
                      const SizedBox(width: 6),
                      _LanguageSegment(
                        key: const ValueKey('onboarding-lang-zh'),
                        flex: 10,
                        label: l10n.languageChinese,
                        selected: _selectedLanguageSegment == 'zh',
                        onTap: () => _applyLanguageSelection('zh'),
                      ),
                      const SizedBox(width: 6),
                      _LanguageSegment(
                        key: const ValueKey('onboarding-lang-en'),
                        flex: 13,
                        label: l10n.languageEnglish,
                        selected: _selectedLanguageSegment == 'en',
                        onTap: () => _applyLanguageSelection('en'),
                      ),
                      const SizedBox(width: 6),
                      _LanguageSegment(
                        key: const ValueKey('onboarding-lang-system'),
                        flex: 10,
                        label: l10n.onboardingLanguageAuto,
                        selected: _selectedLanguageSegment == 'system',
                        onTap: () => _applyLanguageSelection('system'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.info_outline,
                          size: 13,
                          color: palette.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.onboardingLanguageAutoNote,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: palette.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel(text: l10n.onboardingRowCurrency),
                  _PickerRow(
                    key: const ValueKey('onboarding-currency-row'),
                    chip: Text(
                      NumberFormatter.currencySymbol(_currencyCode),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.dailyText,
                      ),
                    ),
                    value: _currencyCode,
                    onTap: _openCurrencyPicker,
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel(text: l10n.onboardingRowVoice),
                  _PickerRow(
                    key: const ValueKey('onboarding-voice-row'),
                    chip: Icon(
                      Icons.mic_none,
                      size: 14,
                      color: palette.dailyText,
                    ),
                    value: _languageName(l10n, _voiceLanguageCode),
                    onTap: _openVoicePicker,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 6, 26, 16),
              child: _ConfirmButton(
                label: l10n.onboardingStart,
                enabled: _canStart,
                onPressed: _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps a [SaveProfileError] to the localized message (ported from
/// `ProfileOnboardingScreen._messageForError`).
String _messageForError(S l10n, SaveProfileError? error) {
  switch (error) {
    case SaveProfileError.nameRequired:
      return l10n.profileNameRequired;
    case SaveProfileError.nameTooLong:
      return l10n.profileNameTooLong;
    case SaveProfileError.invalidEmoji:
    case null:
      return l10n.profileSaveFailed;
  }
}

BoxDecoration _fieldBoxDecoration(AppPalette palette) => BoxDecoration(
  color: palette.card,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: palette.borderDefault),
);

/// Small field label above each input (design 04: 11px w600).
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}

/// The tappable 88×88 avatar with a camera badge — a real affordance:
/// `AvatarPickerScreen` already supports photos.
class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({
    required this.emoji,
    required this.imagePath,
    required this.onTap,
  });

  final String emoji;
  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      key: const ValueKey('onboarding-avatar-block'),
      onTap: onTap,
      child: SizedBox(
        width: 92,
        height: 92,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: palette.accentPrimaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: palette.accentPrimaryBorder),
              ),
              alignment: Alignment.center,
              child: AvatarDisplay(
                emoji: emoji,
                imagePath: imagePath,
                size: 84,
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: palette.accentPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.background, width: 3),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One display-language segment (design 04: 42px, radius 12; selected =
/// accent bg + white label, unselected = card bg + border).
class _LanguageSegment extends StatelessWidget {
  const _LanguageSegment({
    super.key,
    required this.flex,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int flex;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: selected ? palette.accentPrimary : palette.card,
            borderRadius: BorderRadius.circular(12),
            border: selected ? null : Border.all(color: palette.borderDefault),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.accentPrimary.withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? Colors.white : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A 46px picker row (currency/voice): leading 26×26 chip + current value +
/// trailing chevron; opens the existing sheet/dialog via [onTap].
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    super.key,
    required this.chip,
    required this.value,
    required this.onTap,
  });

  final Widget chip;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _fieldBoxDecoration(palette),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: palette.accentPrimaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: chip,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: palette.textPrimary,
                ),
              ),
            ),
            Icon(Icons.expand_more, size: 18, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Flat leaf-green confirm button (design 04); disabled state dims the accent
/// while `!_canStart` (D-14 gating unchanged).
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: enabled
            ? palette.accentPrimary
            : palette.accentPrimary.withValues(alpha: 0.45),
        boxShadow: [
          BoxShadow(
            color: palette.accentPrimary.withValues(
              alpha: enabled ? 0.30 : 0.12,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundColor: Colors.white,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: enabled ? 1 : 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

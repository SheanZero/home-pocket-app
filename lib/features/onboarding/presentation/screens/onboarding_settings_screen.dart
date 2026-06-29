import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/profile/save_user_profile_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
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

/// The merged onboarding basic-settings page (D-01 / D-03 / D-10).
///
/// A single screen of unified 「ラベル: 現在値 [変更]」 rows for nickname +
/// avatar (folded from `ProfileOnboardingScreen`) + UI-language + 記帳通貨 +
/// 音声入力言語. Each row opens a sheet/picker/dialog and the
/// `この設定で始める` button stays disabled until a nickname is set (D-14).
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

  // UI language: the device preselect (D-07) and whether the user has touched
  // the row. `_pickedLanguageCode == null` while untouched means "follow the
  // system default" (D-08).
  late String _devicePreselect;
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
    _devicePreselect = preselectOnboardingLanguage(_deviceLanguage);
    // Voice tracks the (untouched) UI-language preselect, always concrete.
    _voiceLanguageCode = resolveVoiceLanguageForOnboarding(
      explicitlyPicked: false,
      pickedLanguage: '',
      deviceLanguage: _deviceLanguage,
    );
  }

  bool get _canStart => _nickname.trim().isNotEmpty && !_isSaving;

  /// Whether the user explicitly pinned a concrete UI language (vs accepting
  /// the system preselect). Drives voice-default tracking + confirm semantics.
  bool get _languageExplicitlyPinned =>
      _languageTouched && _pickedLanguageCode != null;

  // ── Editors ───────────────────────────────────────────────────────────────

  Future<void> _openNicknameEditor() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NicknameDialog(initialValue: _nickname),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() => _nickname = result);
  }

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

  Future<void> _openLanguagePicker() async {
    final l10n = S.of(context);
    final groupValue = _languageExplicitlyPinned ? _pickedLanguageCode! : 'system';
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: RadioGroup<String>(
          groupValue: groupValue,
          onChanged: (value) {
            if (value != null) {
              Navigator.pop(dialogContext, value);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(l10n.languageSystem),
                value: 'system',
              ),
              ..._languageOptions(l10n).entries.map(
                (entry) => RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    await _applyLanguageSelection(picked);
  }

  Future<void> _applyLanguageSelection(String value) async {
    // Write through immediately so MaterialApp switches locale instantly
    // (D-07/D-08, ONBOARD-03). Explicit pick pins 'ja'/'zh'/'en'; accepting the
    // system option persists 'system' (keep following the device).
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
            children: _languageOptions(l10n)
                .entries
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

  /// Confirm handler for `この設定で始める` (enabled only once a nickname is set,
  /// D-14). Persists the untouched defaults (system language + concrete voice
  /// language), saves the profile, and signals completion to the flow host.
  /// Does NOT set `onboarding_complete` (the flow host's final step, 54-07).
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

    final result = await ref.read(saveUserProfileUseCaseProvider).execute(
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

  String _languageRowValue(S l10n) {
    if (!_languageExplicitlyPinned) {
      return '${l10n.languageSystem} (${_languageName(l10n, _devicePreselect)})';
    }
    return _languageName(l10n, _pickedLanguageCode!);
  }

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
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  Text(
                    l10n.onboardingSettingsTitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.onboardingSettingsSubtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsRow(
                    leading: Icon(Icons.badge_outlined,
                        color: palette.textSecondary),
                    label: l10n.profileNickname,
                    value: _nickname.trim().isEmpty
                        ? l10n.onboardingNicknameUnset
                        : _nickname,
                    changeLabel: l10n.onboardingChange,
                    onTap: _openNicknameEditor,
                  ),
                  _SettingsRow(
                    leading: AvatarDisplay(
                      emoji: _selectedEmoji,
                      imagePath: _selectedImagePath,
                      size: 40,
                    ),
                    label: l10n.profileChangeAvatar,
                    value: null,
                    changeLabel: l10n.onboardingChange,
                    onTap: _openAvatarPicker,
                  ),
                  _SettingsRow(
                    leading:
                        Icon(Icons.language, color: palette.textSecondary),
                    label: l10n.language,
                    value: _languageRowValue(l10n),
                    changeLabel: l10n.onboardingChange,
                    onTap: _openLanguagePicker,
                  ),
                  _SettingsRow(
                    leading: Icon(Icons.payments_outlined,
                        color: palette.textSecondary),
                    label: l10n.onboardingRowCurrency,
                    value: _currencyCode,
                    changeLabel: l10n.onboardingChange,
                    onTap: _openCurrencyPicker,
                  ),
                  _SettingsRow(
                    leading: Icon(Icons.mic_none,
                        color: palette.textSecondary),
                    label: l10n.onboardingRowVoice,
                    value: _languageName(l10n, _voiceLanguageCode),
                    changeLabel: l10n.onboardingChange,
                    onTap: _openVoicePicker,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.onboardingSettingsHint,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _OnboardingGradientButton(
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

/// Nickname text-input dialog that owns its [TextEditingController] so the
/// controller's lifecycle is tied to the dialog route (avoids use-after-dispose
/// during the exit transition).
class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return AlertDialog(
      title: Text(l10n.profileNickname),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.profileNicknamePlaceholder,
          filled: true,
          fillColor: palette.card,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.onboardingChange),
        ),
      ],
    );
  }
}

/// A single unified 「ラベル: 現在値 [変更]」 row (D-10).
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.leading,
    required this.label,
    required this.value,
    required this.changeLabel,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final String? value;
  final String changeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: leading,
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
      subtitle: value == null
          ? null
          : Text(
              value!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
      trailing: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: palette.accentPrimary,
        ),
        child: Text(changeLabel),
      ),
      onTap: onTap,
    );
  }
}

/// Gradient confirm button ported from `ProfileOnboardingScreen`
/// (`_ProfileGradientButton`) — disabled state dims the leaf-green→sakura
/// gradient.
class _OnboardingGradientButton extends StatelessWidget {
  const _OnboardingGradientButton({
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
        gradient: LinearGradient(
          colors: enabled
              ? [palette.accentPrimary, palette.fabGradientStart]
              : [
                  palette.accentPrimary.withValues(alpha: 0.45),
                  palette.fabGradientStart.withValues(alpha: 0.45),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.accentPrimary.withValues(
              alpha: enabled ? 0.16 : 0.08,
            ),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
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
              fontFamily: 'Outfit',
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

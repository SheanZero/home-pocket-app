import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/profile/save_user_profile_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/security/biometric_service.dart';
import '../../../../infrastructure/security/models/auth_result.dart';
import '../../../../infrastructure/security/providers.dart';
import '../../../../shared/constants/warm_emojis.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../accounting/presentation/providers/repository_providers.dart';
import '../../../accounting/presentation/widgets/currency_selector_sheet.dart';
import '../../../applock/presentation/providers/repository_providers.dart';
import '../../../applock/presentation/screens/set_pin_screen.dart';
import '../../../profile/presentation/providers/repository_providers.dart';
import '../../../profile/presentation/providers/state_user_profile.dart';
import '../../../profile/presentation/screens/avatar_picker_screen.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../../../settings/presentation/providers/repository_providers.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../../settings/presentation/providers/state_settings.dart';
import '../utils/onboarding_locale_resolution.dart';

enum _OnboardingSecurityMethod { biometric, pin }

/// The V16 onboarding settings page: profile, locale/currency/voice, and
/// optional security protection in one final step.
///
/// The profile editor is compact, the three preferences share one row style,
/// and security progressively discloses biometric/PIN choices under a master
/// switch. PIN setup stays in context and reports its completion state.
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
    this.initialAvatarId,
  });

  final String bookId;
  final String? initialAvatarId;

  /// Fired exactly once when profile, preferences, and optional security have
  /// all persisted; the flow host then marks onboarding complete.
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

  bool _securityEnabled = false;
  _OnboardingSecurityMethod _securityMethod =
      _OnboardingSecurityMethod.biometric;
  bool _pinConfigured = false;
  bool _biometricAuthorized = false;
  bool _biometricAuthorizationInProgress = false;

  bool _isSaving = false;

  String get _deviceLanguage => PlatformDispatcher.instance.locale.languageCode;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.initialAvatarId ?? randomWarmEmoji();
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

  bool get _canStart =>
      _nickname.trim().isNotEmpty &&
      !_isSaving &&
      (!_securityEnabled ||
          _securityMethod == _OnboardingSecurityMethod.biometric ||
          _pinConfigured);

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
    final result = await AvatarPickerScreen.show(
      context,
      currentEmoji: _selectedEmoji,
      currentImagePath: _selectedImagePath,
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
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OnboardingOptionSheet(
        title: l10n.onboardingRowLanguage,
        description: l10n.onboardingLanguageAutoNote,
        selectedValue: _selectedLanguageSegment,
        options: [
          _OnboardingOption(
            value: 'ja',
            label: l10n.languageJapanese,
            icon: Icons.language,
          ),
          _OnboardingOption(
            value: 'zh',
            label: l10n.languageChinese,
            icon: Icons.language,
          ),
          _OnboardingOption(
            value: 'en',
            label: l10n.languageEnglish,
            icon: Icons.language,
          ),
          _OnboardingOption(
            value: 'system',
            label: l10n.onboardingLanguageAuto,
            icon: Icons.auto_awesome_outlined,
          ),
        ],
        keyPrefix: 'onboarding-language',
      ),
    );
    if (picked != null && mounted) {
      await _applyLanguageSelection(picked);
    }
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
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OnboardingOptionSheet(
        title: l10n.onboardingRowVoice,
        selectedValue: _voiceLanguageCode,
        options: _languageOptions(l10n).entries
            .map(
              (entry) => _OnboardingOption(
                value: entry.key,
                label: entry.value,
                icon: Icons.mic_none,
              ),
            )
            .toList(),
        keyPrefix: 'onboarding-voice',
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

  Future<void> _toggleSecurity(
    bool enabled, {
    required bool biometricAvailable,
  }) async {
    if (_biometricAuthorizationInProgress) {
      return;
    }
    if (!enabled) {
      setState(() => _securityEnabled = false);
      return;
    }

    setState(() {
      _securityEnabled = true;
      if (_securityMethod == _OnboardingSecurityMethod.biometric &&
          !biometricAvailable) {
        _securityMethod = _OnboardingSecurityMethod.pin;
      }
    });

    if (_securityMethod != _OnboardingSecurityMethod.biometric) {
      return;
    }
    final authorized = await _authorizeBiometric();
    if (!authorized && mounted) {
      setState(() => _securityMethod = _OnboardingSecurityMethod.pin);
    }
  }

  Future<void> _selectSecurityMethod(_OnboardingSecurityMethod method) async {
    if (_biometricAuthorizationInProgress) {
      return;
    }
    if (method == _OnboardingSecurityMethod.pin) {
      setState(() => _securityMethod = method);
      return;
    }

    final authorized = await _authorizeBiometric();
    if (!mounted) {
      return;
    }
    setState(
      () => _securityMethod = authorized
          ? _OnboardingSecurityMethod.biometric
          : _OnboardingSecurityMethod.pin,
    );
  }

  Future<bool> _authorizeBiometric() async {
    if (_biometricAuthorized) {
      return true;
    }
    if (_biometricAuthorizationInProgress) {
      return false;
    }

    setState(() => _biometricAuthorizationInProgress = true);
    final result = await ref
        .read(biometricServiceProvider)
        .authenticate(reason: S.of(context).appLockReauthReason);
    if (!mounted) {
      return false;
    }

    final authorized = result is AuthResultSuccess;
    ref.invalidate(biometricAvailabilityProvider);
    setState(() {
      _biometricAuthorizationInProgress = false;
      _biometricAuthorized = authorized;
    });
    return authorized;
  }

  Future<bool> _openSetPin() async {
    // The nickname field can still own focus when the PIN action is tapped.
    // Release it before pushing the app-owned keypad so the iOS QWERTY
    // keyboard cannot linger over the transition.
    FocusManager.instance.primaryFocus?.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return false;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SetPinScreen(isUpdating: _pinConfigured),
      ),
    );
    if (result != true || !mounted) {
      return false;
    }
    setState(() => _pinConfigured = true);
    return true;
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
    FocusManager.instance.primaryFocus?.unfocus();
    // Biometrics remains the primary unlock method, while the app's existing
    // security invariant still requires a PIN fallback so a biometric lockout
    // can never strand the user.
    if (_securityEnabled &&
        _securityMethod == _OnboardingSecurityMethod.biometric &&
        !_pinConfigured) {
      final pinReady = await _openSetPin();
      if (!pinReady || !mounted) {
        return;
      }
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
      await _persistSecuritySelection();
      if (!mounted) {
        return;
      }
      ref.invalidate(userProfileProvider);
      ref.invalidate(appSettingsProvider);
      widget.onConfirmed();
      return;
    }

    setState(() => _isSaving = false);
    showErrorFeedback(context, _messageForError(l10n, result.error));
  }

  Future<void> _persistSecuritySelection() async {
    final repository = ref.read(settingsRepositoryProvider);
    if (!_securityEnabled) {
      await ref.read(appLockServiceProvider).disableLock();
      await repository.setBiometricUnlockEnabled(false);
      return;
    }

    // Both methods reach this point only after SetPinScreen persisted a valid
    // hash. Arm the master flag last so the app can never lock without a PIN.
    final useBiometrics =
        _securityMethod == _OnboardingSecurityMethod.biometric;
    await repository.setBiometricUnlockEnabled(useBiometrics);
    await repository.setAppLockEnabled(true);
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
    final biometricAvailable =
        ref
            .watch(biometricAvailabilityProvider)
            .value
            ?.canAttemptAuthentication ??
        false;
    final languageValue = _selectedLanguageSegment == 'system'
        ? l10n.onboardingLanguageAuto
        : _languageName(l10n, _selectedLanguageSegment);
    final requiredHint = _nickname.trim().isEmpty
        ? l10n.onboardingSetupNameRequiredHint
        : _securityEnabled &&
              _securityMethod == _OnboardingSecurityMethod.pin &&
              !_pinConfigured
        ? l10n.onboardingSetupPinRequiredHint
        : l10n.onboardingSetupChangeLaterHint;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _SetupAmbience(),
            Column(
              children: [
                SizedBox(
                  height: 52,
                  child: Center(
                    child: Text(
                      l10n.onboardingSetupTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AvatarBlock(
                            emoji: _selectedEmoji,
                            imagePath: _selectedImagePath,
                            onTap: _openAvatarPicker,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FieldLabel(
                                  text: l10n.onboardingRowName,
                                  requiredText: l10n.onboardingRequired,
                                ),
                                Container(
                                  height: 54,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: _fieldBoxDecoration(palette),
                                  alignment: Alignment.centerLeft,
                                  child: TextField(
                                    controller: _nicknameController,
                                    onChanged: (value) =>
                                        setState(() => _nickname = value),
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
                                      fontWeight: FontWeight.w600,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _PreferenceCard(
                        children: [
                          _PreferenceRow(
                            key: const ValueKey('onboarding-language-row'),
                            icon: Icons.language,
                            label: l10n.onboardingRowLanguage,
                            value: languageValue,
                            onTap: _openLanguagePicker,
                          ),
                          _PreferenceRow(
                            key: const ValueKey('onboarding-currency-row'),
                            icon: Icons.account_balance_wallet_outlined,
                            label: l10n.onboardingRowCurrency,
                            value: _currencyCode,
                            onTap: _openCurrencyPicker,
                          ),
                          _PreferenceRow(
                            key: const ValueKey('onboarding-voice-row'),
                            icon: Icons.mic_none,
                            label: l10n.onboardingRowVoice,
                            value: _languageName(l10n, _voiceLanguageCode),
                            onTap: _openVoicePicker,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _OnboardingSecurityCard(
                        key: const ValueKey('onboarding-security-card'),
                        enabled: _securityEnabled,
                        method: _securityMethod,
                        pinConfigured: _pinConfigured,
                        biometricAvailable: biometricAvailable,
                        onToggle: (enabled) => _toggleSecurity(
                          enabled,
                          biometricAvailable: biometricAvailable,
                        ),
                        onSelectMethod: _selectSecurityMethod,
                        onSetPin: _openSetPin,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 9, 24, 16),
                  decoration: BoxDecoration(
                    color: palette.background.withValues(alpha: 0.96),
                    border: Border(
                      top: BorderSide(
                        color: palette.borderDefault.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      _ConfirmButton(
                        label: _isSaving
                            ? l10n.onboardingPreparingHome
                            : l10n.onboardingStart,
                        enabled: _canStart,
                        isLoading: _isSaving,
                        onPressed: _confirm,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        requiredHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
  const _FieldLabel({required this.text, required this.requiredText});

  final String text;
  final String requiredText;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: palette.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: style),
          const SizedBox(width: 8),
          Text(requiredText, style: style),
        ],
      ),
    );
  }
}

/// Compact circular avatar for onboarding.
///
/// The initial emoji is randomized from the existing warm avatar library and
/// the same production renderer is used before and after customization.
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
    final l10n = S.of(context);
    return Semantics(
      button: true,
      label: l10n.onboardingAvatarChange,
      child: GestureDetector(
        key: const ValueKey('onboarding-avatar-block'),
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarDisplay(emoji: emoji, imagePath: imagePath, size: 76),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 14,
                    color: palette.dailyText,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      l10n.onboardingAvatarChange,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: palette.dailyText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupAmbience extends StatelessWidget {
  const _SetupAmbience();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = Color.alphaBlend(
      palette.accentPrimary.withValues(alpha: 0.16),
      palette.borderDefault,
    );
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: 62,
              left: 25,
              child: Transform.rotate(
                angle: -0.25,
                child: Icon(Icons.eco_outlined, size: 13, color: color),
              ),
            ),
            Positioned(
              top: 82,
              right: 28,
              child: Transform.rotate(
                angle: 0.2,
                child: Icon(Icons.spa_outlined, size: 16, color: color),
              ),
            ),
            Positioned(
              bottom: 172,
              left: 31,
              child: Transform.rotate(
                angle: -0.18,
                child: Icon(Icons.eco_outlined, size: 14, color: color),
              ),
            ),
            Positioned(
              bottom: 76,
              right: 24,
              child: Transform.rotate(
                angle: 0.3,
                child: Icon(Icons.spa_outlined, size: 11, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(height: 1, color: palette.borderDefault),
          ],
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: Icon(icon, size: 26, color: palette.dailyText),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.dailyText,
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.chevron_right, size: 20, color: palette.dailyText),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingOption {
  const _OnboardingOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class _OnboardingOptionSheet extends StatelessWidget {
  const _OnboardingOptionSheet({
    required this.title,
    required this.selectedValue,
    required this.options,
    required this.keyPrefix,
    this.description,
  });

  final String title;
  final String? description;
  final String selectedValue;
  final List<_OnboardingOption> options;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.borderList,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: palette.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.borderDefault),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0; index < options.length; index++) ...[
                    InkWell(
                      key: ValueKey('$keyPrefix-${options[index].value}'),
                      onTap: () =>
                          Navigator.of(context).pop(options[index].value),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              options[index].icon,
                              size: 22,
                              color: palette.dailyText,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                options[index].label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            if (options[index].value == selectedValue)
                              Icon(
                                Icons.check_circle,
                                size: 21,
                                color: palette.accentPrimary,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (index != options.length - 1)
                      Divider(height: 1, color: palette.borderDefault),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSecurityCard extends StatelessWidget {
  const _OnboardingSecurityCard({
    super.key,
    required this.enabled,
    required this.method,
    required this.pinConfigured,
    required this.biometricAvailable,
    required this.onToggle,
    required this.onSelectMethod,
    required this.onSetPin,
  });

  final bool enabled;
  final _OnboardingSecurityMethod method;
  final bool pinConfigured;
  final bool biometricAvailable;
  final ValueChanged<bool> onToggle;
  final ValueChanged<_OnboardingSecurityMethod> onSelectMethod;
  final Future<bool> Function() onSetPin;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);
    final asset = Theme.of(context).brightness == Brightness.dark
        ? 'docs/mockup/v16/assets/onboarding-privacy-warm-v1-dark.png'
        : 'docs/mockup/v16/assets/onboarding-privacy-warm-v1.png';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          palette.accentPrimaryLight.withValues(alpha: 0.42),
          palette.card,
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: palette.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(asset, width: 56, height: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onboardingSecurityTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.onboardingSecurityDescription,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.45,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            key: const ValueKey('onboarding-security-toggle'),
            onTap: () => onToggle(!enabled),
            borderRadius: BorderRadius.circular(13),
            child: Container(
              constraints: const BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: palette.borderDefault),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.onboardingSecurityEnable,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  Switch(value: enabled, onChanged: onToggle),
                ],
              ),
            ),
          ),
          if (!enabled) ...[
            const SizedBox(height: 15),
            Text(
              l10n.onboardingSecurityDeferTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              l10n.onboardingSecurityDeferBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: palette.textTertiary),
            ),
          ] else ...[
            const SizedBox(height: 13),
            Text(
              l10n.onboardingSecurityMethodLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.borderDefault),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _SecurityMethodRow(
                    key: const ValueKey('onboarding-security-biometric'),
                    icon: Icons.fingerprint,
                    title: l10n.onboardingSecurityBiometric,
                    description: l10n.onboardingSecurityBiometricDescription,
                    badge: l10n.onboardingSecurityRecommended,
                    selected: method == _OnboardingSecurityMethod.biometric,
                    enabled: biometricAvailable,
                    onTap: () =>
                        onSelectMethod(_OnboardingSecurityMethod.biometric),
                  ),
                  Divider(height: 1, color: palette.borderDefault),
                  _SecurityMethodRow(
                    key: const ValueKey('onboarding-security-pin'),
                    icon: Icons.password,
                    title: l10n.onboardingSecurityPin,
                    description: l10n.onboardingSecurityPinDescription,
                    selected: method == _OnboardingSecurityMethod.pin,
                    onTap: () => onSelectMethod(_OnboardingSecurityMethod.pin),
                  ),
                ],
              ),
            ),
            if (method == _OnboardingSecurityMethod.pin) ...[
              const SizedBox(height: 9),
              _PinStatusRow(
                key: const ValueKey('onboarding-pin-status-row'),
                configured: pinConfigured,
                onSetPin: onSetPin,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SecurityMethodRow extends StatelessWidget {
  const _SecurityMethodRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.badge,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? badge;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Opacity(
      opacity: enabled ? 1 : 0.46,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          color: selected
              ? Color.alphaBlend(
                  palette.accentPrimaryLight.withValues(alpha: 0.72),
                  palette.card,
                )
              : Colors.transparent,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.accentPrimaryLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 23, color: palette.dailyText),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.accentPrimaryLight,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: palette.dailyText,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 21,
                color: selected ? palette.accentPrimary : palette.borderList,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sketch 004A: one compact status/action row for both pending and configured
/// states. Keeping the same structure prevents the security card from jumping
/// into a different nested layout after a PIN is saved.
class _PinStatusRow extends StatelessWidget {
  const _PinStatusRow({
    super.key,
    required this.configured,
    required this.onSetPin,
  });

  final bool configured;
  final Future<bool> Function() onSetPin;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);
    final statusColor = configured ? palette.success : palette.warning;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          (configured ? palette.successLight : palette.accentPrimaryLight)
              .withValues(alpha: 0.48),
          palette.card,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.accentPrimaryBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.accentPrimaryLight,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.tag, size: 22, color: palette.dailyText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        configured
                            ? l10n.onboardingSecurityPinComplete
                            : l10n.onboardingSecurityPinMissing,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  configured
                      ? l10n.onboardingSecurityPinCompleteDescription
                      : l10n.onboardingSecurityPinSetupHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.25,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            key: const ValueKey('onboarding-pin-status-action'),
            onPressed: onSetPin,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              foregroundColor: palette.dailyText,
              side: BorderSide(color: palette.accentPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(
              configured
                  ? l10n.onboardingSecurityPinUpdateAction
                  : l10n.onboardingSecurityPinSetAction,
            ),
          ),
        ],
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
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: enabled || isLoading
            ? palette.accentPrimary
            : palette.accentPrimary.withValues(alpha: 0.45),
        boxShadow: [
          BoxShadow(
            color: palette.accentPrimary.withValues(
              alpha: enabled || isLoading ? 0.30 : 0.12,
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
            foregroundColor: palette.primaryActionForeground,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: isLoading
                ? Row(
                    key: const ValueKey('onboarding-confirm-loading'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          key: ValueKey('onboarding-confirm-progress'),
                          strokeWidth: 2,
                          color: palette.primaryActionForeground,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: palette.primaryActionForeground,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    label,
                    key: const ValueKey('onboarding-confirm-label'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.primaryActionForeground.withValues(
                        alpha: enabled ? 1 : 0.7,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/analytics/get_monthly_joy_target_recommendation_use_case.dart';
import '../../../../infrastructure/security/providers.dart';
import '../../../applock/presentation/screens/set_pin_screen.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart';
import '../../../../features/analytics/domain/models/metric_result.dart';
import '../../../../features/analytics/presentation/providers/state_happiness.dart';
import '../../../../generated/app_localizations.dart';
import '../../../family_sync/presentation/widgets/family_sync_settings_section.dart';
import '../../../profile/presentation/widgets/profile_section_card.dart';
import '../providers/repository_providers.dart';
import '../providers/state_settings.dart';
import '../widgets/about_section.dart';
import '../widgets/appearance_section.dart';
import '../widgets/data_management_section.dart';
import '../widgets/joy_target_section.dart';
import '../widgets/security_section.dart';
import '../widgets/voice_section.dart';

/// Main settings screen with all configuration sections.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    required this.bookId,
    this.scrollToSecurity = false,
  });

  final String bookId;

  /// Opt-in deep-link intent (D-13 / ONBOARD-06). When true, the list is
  /// scrolled so the [SecuritySection] is brought into view after the first
  /// frame. Defaults to false so every existing caller is byte-compatible.
  final bool scrollToSecurity;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Anchor on the [SecuritySection] slot — the deep-link scroll target.
  final GlobalKey _securitySectionKey = GlobalKey();

  /// Drives the deep-link scroll. Attaching it has no side-effect on the
  /// default (non-deep-link) render.
  final ScrollController _scrollController = ScrollController();

  /// One-shot guard so the scroll does not re-fire on rebuild.
  bool _didScrollToSecurity = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeScrollToSecurity({required bool lockNotSet}) {
    if (!widget.scrollToSecurity || _didScrollToSecurity) return;
    if (!_scrollController.hasClients) return;
    _didScrollToSecurity = true;
    // SecuritySection sits near the end of a lazy ListView, so its element is
    // not mounted at offset 0 and its GlobalKey context is null. Jump to the
    // bottom first to force the bottom slice (including SecuritySection) to
    // build, then center the section precisely once its context exists.
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _securitySectionKey.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // D-10: arriving via the Phase 54 "现在设置" deep-link with the lock not
      // yet configured starts the set-PIN double-entry flow immediately. The
      // `_didScrollToSecurity` guard above keeps this one-shot (no re-fire on
      // rebuild). Non-deep-link callers never reach here.
      if (lockNotSet) {
        unawaited(_autoOpenSetPin());
      }
    });
  }

  /// Push the double-entry [SetPinScreen]; on success arm the lock exactly as
  /// the [SecuritySection] master-toggle ON handler does (never lock without a
  /// PIN). Reads no provider until the user actually sets a PIN.
  Future<void> _autoOpenSetPin() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const SetPinScreen()),
    );
    if (result != true) return;
    await ref.read(appLockServiceProvider).enableLock();
    if (!mounted) return;
    ref.invalidate(appSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final bookAsync = ref.watch(bookByIdProvider(bookId: widget.bookId));
    final currencyCode = bookAsync.value?.currency ?? 'JPY';
    final recommendationAsync = ref.watch(
      monthlyJoyTargetRecommendationProvider(
        bookId: widget.bookId,
        currencyCode: currencyCode,
      ),
    );
    final recommendedTarget = switch (recommendationAsync.value) {
      Value<int>(:final data) => data,
      _ => null,
    };
    final fallbackTarget =
        GetMonthlyJoyTargetRecommendationUseCase.fallbackBaseline;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settings)),
      body: settingsAsync.when(
        data: (settings) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _maybeScrollToSecurity(
              lockNotSet: !settings.appLockEnabled,
            ),
          );
          return ListView(
            controller: _scrollController,
            children: [
              const ProfileSectionCard(),
              const Divider(),
              AppearanceSection(settings: settings),
              const Divider(),
              VoiceSection(settings: settings),
              const Divider(),
              JoyTargetSection(
                configuredTarget: settings.monthlyJoyTarget,
                recommendedTarget: recommendedTarget,
                fallbackTarget: fallbackTarget,
                onSave: (value) async {
                  await ref
                      .read(settingsRepositoryProvider)
                      .setMonthlyJoyTarget(value);
                  ref.invalidate(appSettingsProvider);
                },
              ),
              const Divider(),
              DataManagementSection(bookId: widget.bookId),
              const Divider(),
              const FamilySyncSettingsSection(),
              const Divider(),
              KeyedSubtree(
                key: _securitySectionKey,
                child: SecuritySection(settings: settings),
              ),
              const Divider(),
              const AboutSection(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

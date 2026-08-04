import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';

import '../../../../application/analytics/get_monthly_joy_target_recommendation_use_case.dart';
import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart';
import '../../../../features/accounting/presentation/utils/category_display_utils.dart';
import '../../../../features/analytics/domain/models/family_happiness.dart';
import '../../../../features/analytics/domain/models/metric_result.dart';
import '../../../../features/analytics/presentation/providers/state_analytics.dart';
import '../../../../features/analytics/presentation/providers/state_happiness.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/family_sync/presentation/navigation/family_flow_launcher.dart';
import '../../../../features/profile/domain/models/user_profile.dart';
import '../../../../features/profile/presentation/providers/state_user_profile.dart';
import '../../../list/presentation/providers/state_list_filter.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../../settings/presentation/providers/state_settings.dart';
import '../providers/state_home.dart';
import '../providers/state_shadow_books.dart';
import '../providers/state_today_transactions.dart';
import '../../../accounting/presentation/screens/transaction_edit_screen.dart';
import '../../../../shared/utils/invalidate_transaction_dependents.dart';
import '../../../../shared/utils/currency_conversion.dart'
    show subunitToUnitFor;
import '../../../../shared/widgets/family_transaction_attribution.dart';
import '../../../../shared/widgets/main_surface_header.dart';
import '../widgets/family_invite_banner.dart';
import '../widgets/family_member_spending_card.dart';
import '../widgets/hero_header.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/home_joy_prompt.dart';
import '../widgets/month_picker_dialog.dart';
import '../widgets/home_transaction_tile.dart';
import '../widgets/transaction_list_card.dart';

/// Home tab content (Tab 0 inside MainShellScreen).
///
/// Flat vertical scroll layout with section dividers.
/// Wires providers to pure UI widgets. No Scaffold, no bottom nav.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.bookId,
    this.onSettingsTap,
    this.onAddJoyTap,
    this.onJoyAnalyticsTap,
  });

  final String bookId;
  final VoidCallback? onSettingsTap;
  final ValueChanged<HomeJoyPrompt>? onAddJoyTap;
  final VoidCallback? onJoyAnalyticsTap;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _fmt = FormatterService();

  /// Ephemeral, session-only dismissal of the family-invite banner (v15).
  /// Intentionally NOT persisted — resets on rebuild/relaunch to avoid adding
  /// a codegen-backed provider for a low-stakes affordance.
  bool _inviteDismissed = false;

  @override
  Widget build(BuildContext context) {
    final bookId = widget.bookId;
    final l10n = S.of(context);
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.value ?? const Locale('ja');
    final isGroupMode = ref.watch(isGroupModeProvider);
    final selectedMonth = ref.watch(homeSelectedMonthProvider);
    final year = selectedMonth.year;
    final month = selectedMonth.month;
    final currentMonthStart = DateTime(year, month, 1);
    final currentMonthEnd = DateTime(year, month + 1, 0, 23, 59, 59);

    final shadowBooksAsync = isGroupMode
        ? ref.watch(shadowBooksProvider)
        : const AsyncData<List<ShadowBookInfo>>([]);
    final profileAsync = isGroupMode
        ? ref.watch(userProfileProvider)
        : const AsyncData<UserProfile?>(null);
    final transactionsAsync = isGroupMode
        ? ref.watch(familyTodayTransactionsProvider(bookId: bookId))
        : ref.watch(todayTransactionsProvider(bookId: bookId));
    // Used for currency code in the transaction list formatter (WR-01 fix).
    final bookAsyncOuter = ref.watch(bookByIdProvider(bookId: bookId));
    final outerCurrencyCode = bookAsyncOuter.value?.currency ?? 'JPY';

    return SingleChildScrollView(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: MainSurfaceHeader.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero header ──
              HeroHeader(
                year: year,
                month: month,
                isGroupMode: isGroupMode,
                onSettingsTap: widget.onSettingsTap ?? () {},
                onMonthTap: () async {
                  final picked = await showMonthPickerDialog(
                    context,
                    selectedYear: year,
                    selectedMonth: month,
                  );
                  if (picked == null || !context.mounted) return;
                  ref
                      .read(homeSelectedMonthProvider.notifier)
                      .selectMonth(picked.year, picked.month);
                },
              ),
              // V15 `.home-faithful .app-header`: 13px before the hero card.
              const SizedBox(height: MainSurfaceHeader.contentSpacing),

              // ── Home hero card (Phase 10 — integrates the legacy
              //    month-overview, ledger-comparison, and joy-fullness cards
              //    into a single composition). ──
              Builder(
                builder: (context) {
                  final reportAsync = ref.watch(
                    monthlyReportProvider(
                      bookId: bookId,
                      startDate: currentMonthStart,
                      endDate: currentMonthEnd,
                    ),
                  );
                  final bookAsync = ref.watch(bookByIdProvider(bookId: bookId));

                  // CLAUDE.md Pitfall #9 — fallback only when Book is missing.
                  // This is the SOLE legitimate JPY currency-code literal in
                  // the home feature; future grep audits verify no other site
                  // re-introduces it.
                  final currencyCode = bookAsync.value?.currency ?? 'JPY';

                  final happinessAsync = ref.watch(
                    happinessReportProvider(
                      bookId: bookId,
                      startDate: currentMonthStart,
                      endDate: currentMonthEnd,
                      currencyCode: currencyCode,
                    ),
                  );
                  final bestJoyAsync = ref.watch(
                    bestJoyMomentProvider(
                      bookId: bookId,
                      startDate: currentMonthStart,
                      endDate: currentMonthEnd,
                    ),
                  );
                  final bestJoyRow = switch (bestJoyAsync.value) {
                    Value(:final data) => data,
                    _ => null,
                  };
                  final defaultBestJoyCategory = bestJoyRow == null
                      ? null
                      : defaultCategoryFromId(bestJoyRow.categoryId);
                  final customBestJoyCategoryAsync =
                      bestJoyRow != null && defaultBestJoyCategory == null
                      ? ref.watch(categoryByIdProvider(bestJoyRow.categoryId))
                      : null;
                  final bestJoyCategory =
                      defaultBestJoyCategory ??
                      customBestJoyCategoryAsync?.value;
                  final bestJoyCategoryName = bestJoyRow == null
                      ? null
                      : categoryNameForDisplay(
                          categoryId: bestJoyRow.categoryId,
                          category: bestJoyCategory,
                          locale: locale,
                          isLoading:
                              customBestJoyCategoryAsync?.isLoading ?? false,
                        );
                  final settingsAsync = ref.watch(appSettingsProvider);
                  final targetRecommendationAsync = ref.watch(
                    monthlyJoyTargetRecommendationProvider(
                      bookId: bookId,
                      currencyCode: currencyCode,
                    ),
                  );
                  final configuredTarget =
                      settingsAsync.value?.monthlyJoyTarget;
                  final configuredTargetValid =
                      configuredTarget != null && configuredTarget > 0;
                  final recommendedTarget =
                      switch (targetRecommendationAsync.value) {
                        Value<int>(:final data) => data,
                        _ => null,
                      };
                  final fallbackBaseline =
                      GetMonthlyJoyTargetRecommendationUseCase.fallbackBaseline;
                  final activeMonthlyJoyTarget = configuredTargetValid
                      ? configuredTarget
                      : recommendedTarget ?? fallbackBaseline;

                  // Group-mode-only providers — short-circuit to AsyncData(null/[])
                  // when not in group mode so the .when() chain below resolves
                  // immediately without spinning on never-watched providers.
                  final familyAsync = isGroupMode
                      ? ref
                            .watch(
                              familyHappinessProvider(
                                primaryBookId: bookId,
                                startDate: currentMonthStart,
                                endDate: currentMonthEnd,
                              ),
                            )
                            .whenData<FamilyHappiness?>((value) => value)
                      : const AsyncData<FamilyHappiness?>(null);
                  final shadowAggregateAsync = isGroupMode
                      ? ref
                            .watch(
                              shadowAggregateProvider(
                                startDate: currentMonthStart,
                                endDate: currentMonthEnd,
                              ),
                            )
                            .whenData<ShadowAggregate?>((value) => value)
                      : const AsyncData<ShadowAggregate?>(null);

                  Widget loading() => const SizedBox(
                    height: 320,
                    child: Center(child: CircularProgressIndicator()),
                  );
                  Widget error(Object e) => _ErrorText(message: '$e');

                  return reportAsync.when(
                    loading: loading,
                    error: (e, _) => error(e),
                    data: (report) => happinessAsync.when(
                      loading: loading,
                      error: (e, _) => error(e),
                      data: (happiness) => bestJoyAsync.when(
                        loading: loading,
                        error: (e, _) => error(e),
                        data: (bestJoy) => familyAsync.when(
                          loading: loading,
                          error: (e, _) => error(e),
                          data: (family) => shadowBooksAsync.when(
                            loading: loading,
                            error: (e, _) => error(e),
                            data: (shadowBooks) => shadowAggregateAsync.when(
                              loading: loading,
                              error: (e, _) => error(e),
                              data: (shadowAggregate) {
                                final profile = profileAsync.value;
                                final currentBook = bookAsync.value;
                                final reports =
                                    shadowAggregate?.perBookReports ?? const {};
                                final memberItems = <FamilyMemberSpendingItem>[
                                  FamilyMemberSpendingItem(
                                    deviceId: currentBook?.deviceId ?? 'self',
                                    displayName:
                                        profile?.displayName ??
                                        l10n.analyticsDonutMemberFilterSelf,
                                    avatarEmoji: profile?.avatarEmoji ?? '',
                                    avatarImagePath: profile?.avatarImagePath,
                                    totalExpenses: report.totalExpenses,
                                    joyTotal: report.joyTotal,
                                    dailyTotal: report.dailyTotal,
                                  ),
                                  for (final shadow in shadowBooks)
                                    FamilyMemberSpendingItem(
                                      deviceId:
                                          shadow.book.ownerDeviceId ??
                                          shadow.book.id,
                                      displayName: shadow.memberDisplayName,
                                      avatarEmoji: shadow.memberAvatarEmoji,
                                      avatarImagePath:
                                          shadow.memberAvatarImagePath,
                                      totalExpenses:
                                          reports[shadow.book.id]
                                              ?.totalExpenses ??
                                          0,
                                      joyTotal:
                                          reports[shadow.book.id]?.joyTotal ??
                                          0,
                                      dailyTotal:
                                          reports[shadow.book.id]?.dailyTotal ??
                                          0,
                                    ),
                                ];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    HomeHeroCard(
                                      report: report,
                                      happiness: happiness,
                                      bestJoy: bestJoy,
                                      bestJoyCategoryName: bestJoyCategoryName,
                                      family: family,
                                      shadowBooks: shadowBooks,
                                      shadowAggregate: shadowAggregate,
                                      currencyCode: currencyCode,
                                      locale: locale,
                                      isGroupMode: isGroupMode,
                                      activeMonthlyJoyTarget:
                                          activeMonthlyJoyTarget,
                                      recommendedMonthlyJoyTarget:
                                          recommendedTarget,
                                      isMonthlyJoyTargetConfigured:
                                          configuredTargetValid,
                                      onTap: widget.onJoyAnalyticsTap ?? () {},
                                      onAddJoy: widget.onAddJoyTap,
                                    ),
                                    if (isGroupMode) ...[
                                      const SizedBox(height: 18),
                                      FamilyMemberSpendingCard(
                                        items: memberItems,
                                        currencyCode: currencyCode,
                                        locale: locale,
                                        onMemberTap: (_) =>
                                            widget.onJoyAnalyticsTap?.call(),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Group bar or Family invite banner ──
              if (!isGroupMode && !_inviteDismissed) ...[
                FamilyInviteBanner(
                  onTap: () => openAuthoritativeFamilyFlow(context, ref),
                  onSettingsTap: widget.onSettingsTap ?? () {},
                  onDismiss: () => setState(() => _inviteDismissed = true),
                ),
                const SizedBox(height: 16),
              ],

              // ── Transactions header row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 16,
                        color: context.palette.accentPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.homeRecentTransactions,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      ref
                          .read(listFilterProvider.notifier)
                          .selectMonth(now.year, now.month);
                      ref.read(selectedTabIndexProvider.notifier).select(1);
                    },
                    child: Text(
                      l10n.homeViewAllTransactions,
                      style: AppTextStyles.label.copyWith(
                        color: context.palette.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Transaction list card ──
              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          l10n.noTransactionsYet,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  return TransactionListCard(
                    children: transactions.map((tx) {
                      final isSoul = tx.ledgerType == LedgerType.joy;
                      final defaultCategory = defaultCategoryFromId(
                        tx.categoryId,
                      );
                      final customCategoryAsync = defaultCategory == null
                          ? ref.watch(categoryByIdProvider(tx.categoryId))
                          : null;
                      final displayCategory =
                          defaultCategory ?? customCategoryAsync?.value;
                      final payer = isGroupMode
                          ? _familyPayer(
                              tx,
                              primaryBookId: bookId,
                              profile: profileAsync.value,
                              shadows: shadowBooksAsync.value ?? const [],
                              selfLabel: l10n.familyTransactionPayerSelf,
                              memberFallbackLabel:
                                  l10n.analyticsDonutMemberFilterLabel,
                            )
                          : null;
                      return HomeTransactionTile(
                        foreignAnnotation: _foreignAnnotation(tx, locale),
                        l1Icon: displayCategory == null
                            ? Icons.category
                            : parentCategoryIconForCategory(displayCategory),
                        tagText: isSoul
                            ? l10n.listLedgerJoy
                            : l10n.listLedgerDaily,
                        tagBgColor: isSoul
                            ? context.palette.joyLight
                            : context.palette.dailyLight,
                        // v15 `.faithful-tag`: badge text uses the darker
                        // *Text tone for contrast (joyText / dailyText).
                        tagTextColor: isSoul
                            ? context.palette.joyText
                            : context.palette.dailyText,
                        merchant: tx.merchant,
                        payerName: payer?.name,
                        payerTone: payer?.tone ?? FamilyPayerTone.primary,
                        payerAvatarEmoji: payer?.avatarEmoji,
                        payerAvatarImagePath: payer?.avatarImagePath,
                        category: categoryNameForDisplay(
                          categoryId: tx.categoryId,
                          category: displayCategory,
                          locale: locale,
                          isLoading: customCategoryAsync?.isLoading ?? false,
                        ),
                        // v15 `.faithful-tx-icon`: leading L1 icon tinted by
                        // ledger *Text tone — joy→joyText, daily→dailyText.
                        categoryColor: isSoul
                            ? context.palette.joyText
                            : context.palette.dailyText,
                        formattedAmount: _formatAmount(
                          tx,
                          outerCurrencyCode,
                          locale,
                        ),
                        amountColor: isGroupMode
                            ? context.palette.textPrimary
                            : isSoul
                            ? context.palette.joyText
                            : context.palette.textPrimary,
                        satisfactionValue: tx.ledgerType == LedgerType.joy
                            ? tx.joyFullness
                            : null,
                        // Await the edit screen's pop-with-result and refresh
                        // the Home list on save/delete (result == true). The
                        // edit screen delegates invalidation to its caller —
                        // List does this too (list_screen.dart WR-03). Without
                        // it, edits/deletes persist to the DB but the cached
                        // todayTransactionsProvider keeps showing stale data.
                        onTap: isGroupMode && tx.bookId != bookId
                            ? null
                            : () async {
                                try {
                                  final result = await Navigator.of(context)
                                      .push<bool>(
                                        MaterialPageRoute<bool>(
                                          builder: (_) => TransactionEditScreen(
                                            transaction: tx,
                                          ),
                                        ),
                                      );
                                  if (result == true) {
                                    invalidateTransactionDependents(
                                      ref,
                                      bookId: bookId,
                                      year: year,
                                      month: month,
                                    );
                                  }
                                } catch (e, st) {
                                  FlutterError.reportError(
                                    FlutterErrorDetails(
                                      exception: e,
                                      stack: st,
                                      library: 'home_screen',
                                    ),
                                  );
                                }
                              },
                      );
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _ErrorText(message: '$error'),
              ),

              // ── Bottom padding for pill nav ──
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ── Data wiring helpers ──

  // WR-01 fix: use FormatterService instead of hardcoded JPY NumberFormat.
  String _formatAmount(Transaction tx, String currencyCode, Locale locale) =>
      _fmt.formatCurrency(tx.amount, currencyCode, locale);

  /// Original-currency annotation for FOREIGN rows only — mirrors
  /// `list_screen` so Home recent items show the foreign amount under the JPY
  /// amount. Null for JPY/domestic rows (the tile then renders the bare
  /// amount). Stored original MINOR units → major via FormatterService with
  /// trimWholeFraction (260614-dx1): whole amounts drop ".00" ($12,211), real
  /// fractions keep their decimals (kr12.50).
  String? _foreignAnnotation(Transaction tx, Locale locale) {
    final originalCurrency = tx.originalCurrency;
    final originalAmount = tx.originalAmount;
    if (originalCurrency == null ||
        originalCurrency.toUpperCase() == 'JPY' ||
        originalAmount == null) {
      return null;
    }
    return _fmt.formatCurrency(
      originalAmount / subunitToUnitFor(originalCurrency),
      originalCurrency,
      locale,
      trimWholeFraction: true,
    );
  }

  _FamilyPayer _familyPayer(
    Transaction tx, {
    required String primaryBookId,
    required UserProfile? profile,
    required List<ShadowBookInfo> shadows,
    required String selfLabel,
    required String memberFallbackLabel,
  }) {
    if (tx.bookId == primaryBookId) {
      return _FamilyPayer(
        name: selfLabel,
        tone: FamilyPayerTone.primary,
        avatarEmoji: profile?.avatarEmoji ?? '',
        avatarImagePath: profile?.avatarImagePath,
      );
    }
    for (var index = 0; index < shadows.length; index++) {
      final shadow = shadows[index];
      if (shadow.book.id == tx.bookId) {
        return _FamilyPayer(
          name: shadow.memberDisplayName.isEmpty
              ? memberFallbackLabel
              : shadow.memberDisplayName,
          tone: familyPayerToneForShadowIndex(index),
          avatarEmoji: shadow.memberAvatarEmoji,
          avatarImagePath: shadow.memberAvatarImagePath,
        );
      }
    }
    return _FamilyPayer(
      name: memberFallbackLabel,
      tone: FamilyPayerTone.shared,
      avatarEmoji: '',
      avatarImagePath: null,
    );
  }
}

class _FamilyPayer {
  const _FamilyPayer({
    required this.name,
    required this.tone,
    required this.avatarEmoji,
    required this.avatarImagePath,
  });

  final String name;
  final FamilyPayerTone tone;
  final String avatarEmoji;
  final String? avatarImagePath;
}

/// Reusable error text widget for async error states.
class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Error: $message',
        style: AppTextStyles.bodySmall.copyWith(color: context.palette.error),
      ),
    );
  }
}

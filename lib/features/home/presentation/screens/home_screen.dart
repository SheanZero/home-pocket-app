import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';

import '../../../../application/analytics/get_monthly_joy_target_recommendation_use_case.dart';
import '../../../../application/accounting/category_localization_service.dart';
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
import '../../../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/family_sync/presentation/screens/group_choice_screen.dart';
import '../../../list/presentation/providers/state_list_filter.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../../settings/presentation/providers/state_settings.dart';
import '../providers/state_home.dart';
import '../providers/state_shadow_books.dart';
import '../providers/state_today_transactions.dart';
import '../../../accounting/presentation/screens/transaction_edit_screen.dart';
import '../../../../shared/utils/invalidate_transaction_dependents.dart';
import '../../../../shared/utils/currency_conversion.dart' show subunitToUnitFor;
import '../widgets/family_invite_banner.dart';
import '../widgets/hero_header.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/month_picker_dialog.dart';
import '../widgets/home_transaction_tile.dart';
import '../widgets/transaction_list_card.dart';

/// Home tab content (Tab 0 inside MainShellScreen).
///
/// Flat vertical scroll layout with section dividers.
/// Wires providers to pure UI widgets. No Scaffold, no bottom nav.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.bookId, this.onSettingsTap});

  final String bookId;
  final VoidCallback? onSettingsTap;

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

    final todayTxAsync = ref.watch(todayTransactionsProvider(bookId: bookId));
    // Used for currency code in the transaction list formatter (WR-01 fix).
    final bookAsyncOuter = ref.watch(bookByIdProvider(bookId: bookId));
    final outerCurrencyCode = bookAsyncOuter.value?.currency ?? 'JPY';

    return SingleChildScrollView(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
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
              // 24 (not 16) to visually match AnalyticsScreen's AppBar+padding stack (user decision 260518-v4v).
              // Analytics has a 56px opaque AppBar creating structural visual weight absent on home
              // (inline body HeroHeader). Reducing analytics padding to 8px would look cramped;
              // bumping home from 16px to 24px achieves visual equivalence. Numeric asymmetry intentional.
              const SizedBox(height: 24),

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
                                startDate: currentMonthStart,
                                endDate: currentMonthEnd,
                              ),
                            )
                            .whenData<FamilyHappiness?>((value) => value)
                      : const AsyncData<FamilyHappiness?>(null);
                  final shadowBooksAsync = isGroupMode
                      ? ref
                            .watch(shadowBooksProvider)
                            .whenData<List<ShadowBookInfo>?>((value) => value)
                      : const AsyncData<List<ShadowBookInfo>?>(null);
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
                              data: (shadowAggregate) => HomeHeroCard(
                                report: report,
                                happiness: happiness,
                                bestJoy: bestJoy,
                                family: family,
                                shadowBooks: shadowBooks,
                                shadowAggregate: shadowAggregate,
                                currencyCode: currencyCode,
                                locale: locale,
                                isGroupMode: isGroupMode,
                                activeMonthlyJoyTarget: activeMonthlyJoyTarget,
                                recommendedMonthlyJoyTarget: recommendedTarget,
                                isMonthlyJoyTargetConfigured:
                                    configuredTargetValid,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        AnalyticsScreen(bookId: bookId),
                                  ),
                                ),
                              ),
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
              if (isGroupMode) ...[
                // TODO: Wire GroupBar with actual group data when available
                const SizedBox.shrink(),
                const SizedBox(height: 16),
              ],
              if (!isGroupMode && !_inviteDismissed) ...[
                FamilyInviteBanner(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GroupChoiceScreen(),
                      ),
                    );
                  },
                  onSettingsTap: widget.onSettingsTap ?? () {},
                  onDismiss: () => setState(() => _inviteDismissed = true),
                ),
                const SizedBox(height: 16),
              ],

              // ── Transactions header row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.homeRecentTransactions,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: context.palette.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      ref
                          .read(listFilterProvider.notifier)
                          .selectMonth(now.year, now.month);
                      ref
                          .read(selectedTabIndexProvider.notifier)
                          .select(1);
                    },
                    child: Text(
                      l10n.homeViewAllTransactions,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.palette.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Transaction list card ──
              todayTxAsync.when(
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
                      return HomeTransactionTile(
                        foreignAnnotation: _foreignAnnotation(tx, locale),
                        l1Icon: parentCategoryIconFromId(tx.categoryId),
                        tagText: isGroupMode
                            ? _memberInitial(tx)
                            : (isSoul
                                  ? l10n.listLedgerJoy
                                  : l10n.listLedgerDaily),
                        tagBgColor: isSoul
                            ? context.palette.joyLight
                            : context.palette.dailyLight,
                        // v15 `.faithful-tag`: badge text uses the darker
                        // *Text tone for contrast (joyText / dailyText).
                        tagTextColor: isSoul
                            ? context.palette.joyText
                            : context.palette.dailyText,
                        merchant: tx.merchant,
                        category: CategoryLocalizationService.resolveFromId(
                          tx.categoryId,
                          locale,
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
                        amountColor: isSoul
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
                        onTap: () async {
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

  /// Extracts the first character of a member identifier for group mode.
  String _memberInitial(Transaction tx) {
    // Use device ID first character as fallback; real member data TBD
    return tx.deviceId.isNotEmpty ? tx.deviceId[0].toUpperCase() : '?';
  }
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

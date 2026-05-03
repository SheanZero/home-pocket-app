import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart';
import '../../../../features/analytics/domain/models/family_happiness.dart';
import '../../../../features/analytics/presentation/providers/state_analytics.dart';
import '../../../../features/analytics/presentation/providers/state_happiness.dart';
import '../../../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/family_sync/presentation/screens/group_choice_screen.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../providers/state_shadow_books.dart';
import '../providers/state_today_transactions.dart';
import '../widgets/family_invite_banner.dart';
import '../widgets/hero_header.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/home_transaction_tile.dart';
import '../widgets/transaction_list_card.dart';

/// Home tab content (Tab 0 inside MainShellScreen).
///
/// Flat vertical scroll layout with section dividers.
/// Wires providers to pure UI widgets. No Scaffold, no bottom nav.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.bookId, this.onSettingsTap});

  final String bookId;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.valueOrNull ?? const Locale('ja');
    final isGroupMode = ref.watch(isGroupModeProvider);
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final todayTxAsync = ref.watch(todayTransactionsProvider(bookId: bookId));

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
                onSettingsTap: onSettingsTap ?? () {},
                onDateTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).datePickerComingSoon),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Home hero card (replaces MonthOverviewCard +
              //    LedgerComparisonSection + SoulFullnessCard — Phase 10). ──
              Builder(
                builder: (context) {
                  final reportAsync = ref.watch(
                    monthlyReportProvider(
                      bookId: bookId,
                      year: year,
                      month: month,
                    ),
                  );
                  final bookAsync = ref.watch(
                    bookByIdProvider(bookId: bookId),
                  );

                  // CLAUDE.md Pitfall #9 — fallback only when Book is missing.
                  // This is the SOLE legitimate JPY currency-code literal in
                  // the home feature; future grep audits verify no other site
                  // re-introduces it.
                  final currencyCode =
                      bookAsync.valueOrNull?.currency ?? 'JPY';

                  final happinessAsync = ref.watch(
                    happinessReportProvider(
                      bookId: bookId,
                      year: year,
                      month: month,
                      currencyCode: currencyCode,
                    ),
                  );
                  final bestJoyAsync = ref.watch(
                    bestJoyMomentProvider(
                      bookId: bookId,
                      year: year,
                      month: month,
                    ),
                  );

                  // Group-mode-only providers — short-circuit to AsyncData(null/[])
                  // when not in group mode so the .when() chain below resolves
                  // immediately without spinning on never-watched providers.
                  final familyAsync = isGroupMode
                      ? ref
                            .watch(
                              familyHappinessProvider(year: year, month: month),
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
                              shadowAggregateProvider(year: year, month: month),
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
              if (!isGroupMode) ...[
                FamilyInviteBanner(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GroupChoiceScreen(),
                      ),
                    );
                  },
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
                      color: context.wmTextPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to full transaction list
                    },
                    child: Text(
                      l10n.homeViewAllTransactions,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accentPrimary,
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
                            color: context.wmTextSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  return TransactionListCard(
                    children: transactions.map((tx) {
                      final isSoul = tx.ledgerType == LedgerType.soul;
                      return HomeTransactionTile(
                        tagText: isGroupMode
                            ? _memberInitial(tx)
                            : (isSoul ? '\u9b42' : '\u751f'),
                        tagBgColor: isSoul
                            ? context.wmSoulTagBg
                            : context.wmSurvivalTagBg,
                        tagTextColor: isSoul
                            ? AppColors.soul
                            : AppColors.survival,
                        merchant:
                            tx.merchant ??
                            CategoryLocalizationService.resolveFromId(
                              tx.categoryId,
                              locale,
                            ),
                        category: CategoryLocalizationService.resolveFromId(
                          tx.categoryId,
                          locale,
                        ),
                        categoryColor: isSoul
                            ? AppColors.accentPrimary
                            : context.wmTextSecondary,
                        formattedAmount: _formatAmount(tx),
                        amountColor: isSoul
                            ? AppColors.accentPrimary
                            : context.wmTextPrimary,
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

  String _formatAmount(Transaction tx) {
    final formatted = NumberFormat.currency(
      symbol: '\u00a5',
      decimalDigits: 0,
    ).format(tx.amount);
    return tx.type == TransactionType.expense ? '-$formatted' : formatted;
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
        style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/analytics/presentation/providers/analytics_providers.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/category/category_service.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../providers/home_providers.dart';
import '../providers/today_transactions_provider.dart';
import '../widgets/family_invite_banner.dart';
import '../widgets/hero_header.dart';
import '../widgets/home_transaction_tile.dart';
import '../widgets/month_overview_card.dart';
import '../widgets/ohtani_converter.dart';
import '../widgets/soul_fullness_card.dart';

/// Home tab content (Tab 0 inside MainShellScreen).
///
/// Scrollable content only -- no Scaffold, no bottom nav.
/// Wires providers to pure UI widgets.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.bookId, this.onSettingsTap});

  final String bookId;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider);
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final reportAsync = ref.watch(
      monthlyReportProvider(bookId: bookId, year: year, month: month),
    );
    final todayTxAsync = ref.watch(todayTransactionsProvider(bookId: bookId));
    final ohtaniVisible = ref.watch(ohtaniConverterVisibleProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero header + Month overview card with blue background overlap
          _buildHeroWithCard(
              context, l10n, locale, year, month, reportAsync, todayTxAsync),
          const SizedBox(height: 16),

          // Family invite banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FamilyInviteBanner(onTap: () {}),
          ),
          const SizedBox(height: 16),

          // Today's transactions header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: todayTxAsync.when(
              data: (transactions) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.homeTodayTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.homeTodayCount(transactions.length),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              loading: () => Text(
                l10n.homeTodayTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              error: (_, _) => Text(l10n.homeTodayTitle),
            ),
          ),
          const SizedBox(height: 8),

          // Today's transaction list
          todayTxAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Center(
                    child: Text(
                      l10n.noTransactionsYet,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return Column(
                children: transactions.map((tx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: HomeTransactionTile(
                      merchant: tx.merchant ??
                          CategoryService.resolveFromId(
                            tx.categoryId,
                            locale,
                          ),
                      categoryLabel: CategoryService.resolveFromId(
                        tx.categoryId,
                        locale,
                      ),
                      formattedAmount: _formatAmount(tx),
                      ledgerType: tx.ledgerType,
                      iconData: _iconForCategory(tx.categoryId),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Error: $error'),
            ),
          ),
          const SizedBox(height: 8),

          // Ohtani converter
          if (ohtaniVisible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OhtaniConverter(
                emoji: '\u{1F35A}',
                text:
                    todayTxAsync.whenOrNull(
                      data: (txs) {
                        final total = txs.fold<int>(
                          0,
                          (sum, tx) => sum + tx.amount,
                        );
                        final bowls = (total / 500).toStringAsFixed(1);
                        return '$bowls bowls of gyudon';
                      },
                    ) ??
                    '',
                onDismiss: () =>
                    ref.read(ohtaniConverterVisibleProvider.notifier).dismiss(),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Builds the blue hero header with the MonthOverviewCard overlapping into it.
  ///
  /// Uses a Stack where a blue Container sets the background height, and a
  /// Column (HeroHeader + card) determines the overall layout height. The blue
  /// extends ~60px below the header content, creating the overlap effect with
  /// the card's top portion sitting inside the blue zone.
  Widget _buildHeroWithCard(
    BuildContext context,
    S l10n,
    Locale locale,
    int year,
    int month,
    AsyncValue reportAsync,
    AsyncValue<List<Transaction>> todayTxAsync,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Blue background (square: height == screen width)
        Container(
          height: screenWidth,
          decoration: const BoxDecoration(
            color: AppColors.heroBackground,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),
        // Content: header + gap + card (the card overlaps the blue area)
        Column(
          children: [
            HeroHeader(
              year: year,
              month: month,
              onSettingsTap: onSettingsTap ?? () {},
              onDateTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Date picker coming soon'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            reportAsync.when(
              data: (report) {
                final previousTotal =
                    report.previousMonthComparison?.previousExpenses ?? 0;
                final previousMonth =
                    report.previousMonthComparison?.previousMonth ??
                    (month == 1 ? 12 : month - 1);

                final totalExpense = report.totalExpenses;
                final soulPercent = totalExpense > 0
                    ? (report.soulTotal * 100 ~/ totalExpense)
                    : 0;
                final happinessROI = totalExpense > 0
                    ? report.soulTotal / totalExpense * 10
                    : 0.0;
                final fullness = soulPercent.clamp(0, 100);

                // Find most recent soul transaction from today
                final recentSoulTx = todayTxAsync.whenOrNull(
                  data: (txs) {
                    final soulTxs = txs
                        .where((tx) =>
                            tx.ledgerType == LedgerType.soul &&
                            tx.type == TransactionType.expense)
                        .toList();
                    if (soulTxs.isEmpty) return null;
                    soulTxs.sort(
                        (a, b) => b.timestamp.compareTo(a.timestamp));
                    return soulTxs.first;
                  },
                );

                return MonthOverviewCard(
                  totalExpense: totalExpense,
                  survivalExpense: report.survivalTotal,
                  soulExpense: report.soulTotal,
                  previousMonthTotal: previousTotal,
                  currentMonthNumber: month,
                  previousMonthNumber: previousMonth,
                  modeBadgeText: l10n.homePersonalMode,
                  child: SoulFullnessCard(
                    soulPercentage: soulPercent,
                    happinessROI:
                        double.parse(happinessROI.toStringAsFixed(1)),
                    fullnessLevel: fullness,
                    recentMerchant: recentSoulTx?.merchant ??
                        (recentSoulTx != null
                            ? CategoryService.resolveFromId(
                                recentSoulTx.categoryId,
                                locale,
                              )
                            : ''),
                    recentAmount: recentSoulTx?.amount ?? 0,
                    recentQuote: recentSoulTx?.note ?? '',
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Error: $error'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatAmount(Transaction tx) {
    final formatted = NumberFormat.currency(
      symbol: '\u00a5',
      decimalDigits: 0,
    ).format(tx.amount);
    return tx.type == TransactionType.expense ? '-$formatted' : formatted;
  }

  IconData _iconForCategory(String categoryId) {
    switch (categoryId) {
      case 'cat_food':
        return Icons.restaurant;
      case 'cat_housing':
        return Icons.home_outlined;
      case 'cat_transport':
        return Icons.train;
      case 'cat_utilities':
        return Icons.bolt;
      case 'cat_entertainment':
        return Icons.movie;
      case 'cat_education':
        return Icons.school;
      case 'cat_health':
        return Icons.medical_services;
      case 'cat_shopping':
        return Icons.shopping_bag;
      default:
        return Icons.receipt_long;
    }
  }
}

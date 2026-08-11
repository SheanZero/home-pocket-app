import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/analytics/get_monthly_joy_target_recommendation_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/book.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart';
import '../../../../features/accounting/presentation/screens/transaction_edit_screen.dart';
import '../../../../features/accounting/presentation/utils/category_display_utils.dart';
import '../../../../features/analytics/domain/models/best_joy_moment_row.dart';
import '../../../../features/analytics/domain/models/family_happiness.dart';
import '../../../../features/analytics/domain/models/happiness_report.dart';
import '../../../../features/analytics/domain/models/metric_result.dart';
import '../../../../features/analytics/domain/models/monthly_report.dart';
import '../../../../features/analytics/presentation/providers/state_analytics.dart';
import '../../../../features/analytics/presentation/providers/state_happiness.dart';
import '../../../../features/family_sync/presentation/navigation/family_flow_launcher.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/profile/domain/models/user_profile.dart';
import '../../../../features/profile/presentation/providers/state_user_profile.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/utils/invalidate_transaction_dependents.dart';
import '../../../../shared/utils/transaction_display_amounts.dart';
import '../../../../shared/widgets/family_transaction_attribution.dart';
import '../../../../shared/widgets/main_surface_header.dart';
import '../../../list/presentation/providers/state_list_filter.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../../settings/presentation/providers/state_settings.dart';
import '../providers/state_home.dart';
import '../providers/state_shadow_books.dart';
import '../providers/state_today_transactions.dart';
import '../widgets/family_invite_banner.dart';
import '../widgets/family_member_spending_card.dart';
import '../widgets/hero_header.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/home_joy_prompt.dart';
import '../widgets/home_transaction_tile.dart';
import '../widgets/month_picker_dialog.dart';
import '../widgets/transaction_list_card.dart';

/// Home tab content (Tab 0 inside MainShellScreen).
///
/// Provider coordination is split into independently testable hero and recent
/// transaction sections so the page shell remains a small layout concern.
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
  bool _inviteDismissed = false;

  @override
  Widget build(BuildContext context) {
    final isGroupMode = ref.watch(isGroupModeProvider);
    final selectedMonth = ref.watch(homeSelectedMonthProvider);
    return SingleChildScrollView(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: MainSurfaceHeader.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeroHeader(
                year: selectedMonth.year,
                month: selectedMonth.month,
                isGroupMode: isGroupMode,
                onSettingsTap: widget.onSettingsTap ?? () {},
                onMonthTap: () => _pickMonth(selectedMonth),
                onModeTap: () => openAuthoritativeFamilyFlow(context, ref),
              ),
              const SizedBox(height: MainSurfaceHeader.contentSpacing),
              _HomeHeroSection(
                bookId: widget.bookId,
                selectedMonth: selectedMonth,
                isGroupMode: isGroupMode,
                onAddJoyTap: widget.onAddJoyTap,
                onJoyAnalyticsTap: widget.onJoyAnalyticsTap,
              ),
              const SizedBox(height: 16),
              if (!isGroupMode && !_inviteDismissed) ...[
                FamilyInviteBanner(
                  onTap: () => openAuthoritativeFamilyFlow(context, ref),
                  onSettingsTap: widget.onSettingsTap ?? () {},
                  onDismiss: () => setState(() => _inviteDismissed = true),
                ),
                const SizedBox(height: 16),
              ],
              _RecentTransactionsSection(
                bookId: widget.bookId,
                selectedMonth: selectedMonth,
                isGroupMode: isGroupMode,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMonth(({int year, int month}) selectedMonth) async {
    final picked = await showMonthPickerDialog(
      context,
      selectedYear: selectedMonth.year,
      selectedMonth: selectedMonth.month,
    );
    if (picked == null || !mounted) return;
    ref
        .read(homeSelectedMonthProvider.notifier)
        .selectMonth(picked.year, picked.month);
  }
}

class _HomeHeroSection extends ConsumerWidget {
  const _HomeHeroSection({
    required this.bookId,
    required this.selectedMonth,
    required this.isGroupMode,
    required this.onAddJoyTap,
    required this.onJoyAnalyticsTap,
  });

  final String bookId;
  final ({int year, int month}) selectedMonth;
  final bool isGroupMode;
  final ValueChanged<HomeJoyPrompt>? onAddJoyTap;
  final VoidCallback? onJoyAnalyticsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    final dates = _monthRange(selectedMonth);
    final bookAsync = ref.watch(bookByIdProvider(bookId: bookId));
    final currencyCode = bookAsync.value?.currency ?? 'JPY';
    final reportAsync = ref.watch(
      monthlyReportProvider(
        bookId: bookId,
        startDate: dates.start,
        endDate: dates.end,
      ),
    );
    final happinessAsync = ref.watch(
      happinessReportProvider(
        bookId: bookId,
        startDate: dates.start,
        endDate: dates.end,
        currencyCode: currencyCode,
      ),
    );
    final bestJoyAsync = ref.watch(
      bestJoyMomentProvider(
        bookId: bookId,
        startDate: dates.start,
        endDate: dates.end,
      ),
    );
    final gate = _asyncGate([reportAsync, happinessAsync, bestJoyAsync]);
    if (gate != null) return gate;

    return _ResolvedHomeHero(
      bookId: bookId,
      dates: dates,
      report: reportAsync.value!,
      happiness: happinessAsync.value!,
      bestJoy: bestJoyAsync.value!,
      bestJoyCategoryName: _bestJoyCategoryName(
        ref,
        bestJoyAsync.value!,
        locale,
      ),
      currencyCode: currencyCode,
      locale: locale,
      isGroupMode: isGroupMode,
      target: _monthlyTarget(ref, bookId, currencyCode),
      currentBook: bookAsync.value,
      onAddJoyTap: onAddJoyTap,
      onJoyAnalyticsTap: onJoyAnalyticsTap,
    );
  }

  String? _bestJoyCategoryName(
    WidgetRef ref,
    MetricResult<BestJoyMomentRow> result,
    Locale locale,
  ) {
    final row = switch (result) {
      Value(:final data) => data,
      _ => null,
    };
    if (row == null) return null;
    final defaultCategory = defaultCategoryFromId(row.categoryId);
    final custom = defaultCategory == null
        ? ref.watch(categoryByIdProvider(row.categoryId))
        : null;
    return categoryNameForDisplay(
      categoryId: row.categoryId,
      category: defaultCategory ?? custom?.value,
      locale: locale,
      isLoading: custom?.isLoading ?? false,
    );
  }

  _MonthlyTarget _monthlyTarget(
    WidgetRef ref,
    String bookId,
    String currencyCode,
  ) {
    final configured = ref.watch(appSettingsProvider).value?.monthlyJoyTarget;
    final isConfigured = configured != null && configured > 0;
    final recommendation = switch (ref
        .watch(
          monthlyJoyTargetRecommendationProvider(
            bookId: bookId,
            currencyCode: currencyCode,
          ),
        )
        .value) {
      Value<int>(:final data) => data,
      _ => null,
    };
    return _MonthlyTarget(
      active: isConfigured
          ? configured
          : recommendation ??
                GetMonthlyJoyTargetRecommendationUseCase.fallbackBaseline,
      recommended: recommendation,
      isConfigured: isConfigured,
    );
  }
}

class _ResolvedHomeHero extends ConsumerWidget {
  const _ResolvedHomeHero({
    required this.bookId,
    required this.dates,
    required this.report,
    required this.happiness,
    required this.bestJoy,
    required this.bestJoyCategoryName,
    required this.currencyCode,
    required this.locale,
    required this.isGroupMode,
    required this.target,
    required this.currentBook,
    required this.onAddJoyTap,
    required this.onJoyAnalyticsTap,
  });

  final String bookId;
  final ({DateTime start, DateTime end}) dates;
  final MonthlyReport report;
  final HappinessReport happiness;
  final MetricResult<BestJoyMomentRow> bestJoy;
  final String? bestJoyCategoryName;
  final String currencyCode;
  final Locale locale;
  final bool isGroupMode;
  final _MonthlyTarget target;
  final Book? currentBook;
  final ValueChanged<HomeJoyPrompt>? onAddJoyTap;
  final VoidCallback? onJoyAnalyticsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = _family(ref);
    final shadowsAsync = _shadows(ref);
    final aggregateAsync = _aggregate(ref);
    final gate = _asyncGate([familyAsync, shadowsAsync, aggregateAsync]);
    if (gate != null) return gate;

    final shadows = shadowsAsync.value!;
    final aggregate = aggregateAsync.value;
    final profile = isGroupMode ? ref.watch(userProfileProvider).value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeHeroCard(
          report: report,
          happiness: happiness,
          bestJoy: bestJoy,
          bestJoyCategoryName: bestJoyCategoryName,
          family: familyAsync.value,
          shadowBooks: shadows,
          shadowAggregate: aggregate,
          currencyCode: currencyCode,
          locale: locale,
          isGroupMode: isGroupMode,
          activeMonthlyJoyTarget: target.active,
          recommendedMonthlyJoyTarget: target.recommended,
          isMonthlyJoyTargetConfigured: target.isConfigured,
          onTap: onJoyAnalyticsTap ?? () {},
          onAddJoy: onAddJoyTap,
        ),
        if (isGroupMode) ...[
          const SizedBox(height: 18),
          FamilyMemberSpendingCard(
            items: _memberItems(
              context,
              profile,
              shadows,
              aggregate?.perBookReports ?? const {},
            ),
            currencyCode: currencyCode,
            locale: locale,
            onMemberTap: (_) => onJoyAnalyticsTap?.call(),
          ),
        ],
      ],
    );
  }

  AsyncValue<FamilyHappiness?> _family(WidgetRef ref) => isGroupMode
      ? ref
            .watch(
              familyHappinessProvider(
                primaryBookId: bookId,
                startDate: dates.start,
                endDate: dates.end,
              ),
            )
            .whenData<FamilyHappiness?>((value) => value)
      : const AsyncData<FamilyHappiness?>(null);

  AsyncValue<List<ShadowBookInfo>> _shadows(WidgetRef ref) => isGroupMode
      ? ref.watch(shadowBooksProvider)
      : const AsyncData<List<ShadowBookInfo>>([]);

  AsyncValue<ShadowAggregate?> _aggregate(WidgetRef ref) => isGroupMode
      ? ref
            .watch(
              shadowAggregateProvider(
                startDate: dates.start,
                endDate: dates.end,
              ),
            )
            .whenData<ShadowAggregate?>((value) => value)
      : const AsyncData<ShadowAggregate?>(null);

  List<FamilyMemberSpendingItem> _memberItems(
    BuildContext context,
    UserProfile? profile,
    List<ShadowBookInfo> shadows,
    Map<String, MonthlyReport> reports,
  ) => [
    FamilyMemberSpendingItem(
      deviceId: currentBook?.deviceId ?? 'self',
      displayName:
          profile?.displayName ?? S.of(context).analyticsDonutMemberFilterSelf,
      avatarEmoji: profile?.avatarEmoji ?? '',
      avatarImagePath: profile?.avatarImagePath,
      totalExpenses: report.totalExpenses,
      joyTotal: report.joyTotal,
      dailyTotal: report.dailyTotal,
    ),
    for (final shadow in shadows)
      FamilyMemberSpendingItem(
        deviceId: shadow.book.ownerDeviceId ?? shadow.book.id,
        displayName: shadow.memberDisplayName,
        avatarEmoji: shadow.memberAvatarEmoji,
        avatarImagePath: shadow.memberAvatarImagePath,
        totalExpenses: reports[shadow.book.id]?.totalExpenses ?? 0,
        joyTotal: reports[shadow.book.id]?.joyTotal ?? 0,
        dailyTotal: reports[shadow.book.id]?.dailyTotal ?? 0,
      ),
  ];
}

class _RecentTransactionsSection extends ConsumerWidget {
  const _RecentTransactionsSection({
    required this.bookId,
    required this.selectedMonth,
    required this.isGroupMode,
  });

  final String bookId;
  final ({int year, int month}) selectedMonth;
  final bool isGroupMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    final transactions = isGroupMode
        ? ref.watch(familyTodayTransactionsProvider(bookId: bookId))
        : ref.watch(todayTransactionsProvider(bookId: bookId));
    final profile = isGroupMode ? ref.watch(userProfileProvider).value : null;
    final shadows = isGroupMode
        ? ref.watch(shadowBooksProvider).value ?? const <ShadowBookInfo>[]
        : const <ShadowBookInfo>[];
    final currencyCode =
        ref.watch(bookByIdProvider(bookId: bookId)).value?.currency ?? 'JPY';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TransactionsHeader(),
        const SizedBox(height: 12),
        transactions.when(
          data: (items) => _TransactionResults(
            transactions: items,
            bookId: bookId,
            selectedMonth: selectedMonth,
            isGroupMode: isGroupMode,
            profile: profile,
            shadows: shadows,
            currencyCode: currencyCode,
            locale: locale,
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _ErrorText(message: '$error'),
        ),
      ],
    );
  }
}

class _TransactionsHeader extends ConsumerWidget {
  const _TransactionsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    return Row(
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
    );
  }
}

class _TransactionResults extends StatelessWidget {
  const _TransactionResults({
    required this.transactions,
    required this.bookId,
    required this.selectedMonth,
    required this.isGroupMode,
    required this.profile,
    required this.shadows,
    required this.currencyCode,
    required this.locale,
  });

  final List<Transaction> transactions;
  final String bookId;
  final ({int year, int month}) selectedMonth;
  final bool isGroupMode;
  final UserProfile? profile;
  final List<ShadowBookInfo> shadows;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            S.of(context).noTransactionsYet,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ),
      );
    }
    return TransactionListCard(
      children: [
        for (final transaction in transactions)
          _RecentTransactionTile(
            transaction: transaction,
            bookId: bookId,
            selectedMonth: selectedMonth,
            isGroupMode: isGroupMode,
            profile: profile,
            shadows: shadows,
            currencyCode: currencyCode,
            locale: locale,
          ),
      ],
    );
  }
}

class _RecentTransactionTile extends ConsumerWidget {
  const _RecentTransactionTile({
    required this.transaction,
    required this.bookId,
    required this.selectedMonth,
    required this.isGroupMode,
    required this.profile,
    required this.shadows,
    required this.currencyCode,
    required this.locale,
  });

  final Transaction transaction;
  final String bookId;
  final ({int year, int month}) selectedMonth;
  final bool isGroupMode;
  final UserProfile? profile;
  final List<ShadowBookInfo> shadows;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final category = _categoryPresentation(ref);
    final visuals = _visuals(context, l10n);
    final payer = _payer(l10n);
    final displayAmounts = formatTransactionDisplayAmounts(
      amountMinorUnits: transaction.amount,
      amountCurrencyCode: currencyCode,
      originalCurrencyCode: transaction.originalCurrency,
      originalAmountMinorUnits: transaction.originalAmount,
      locale: locale,
    );
    return HomeTransactionTile(
      foreignAnnotation: displayAmounts.foreignAnnotation,
      l1Icon: category.icon,
      tagText: visuals.tagText,
      tagBgColor: visuals.tagBackground,
      tagTextColor: visuals.tagForeground,
      merchant: transaction.merchant,
      payerName: payer?.name,
      payerTone: payer?.tone ?? FamilyPayerTone.self,
      payerAvatarEmoji: payer?.avatarEmoji,
      payerAvatarImagePath: payer?.avatarImagePath,
      category: category.name,
      categoryColor: visuals.categoryColor,
      formattedAmount: displayAmounts.primaryAmount,
      amountColor: visuals.amountColor,
      satisfactionValue: visuals.satisfactionValue,
      onTap: _editCallback(context, ref),
    );
  }

  ({IconData icon, String name}) _categoryPresentation(WidgetRef ref) {
    final defaultCategory = defaultCategoryFromId(transaction.categoryId);
    final customCategory = defaultCategory == null
        ? ref.watch(categoryByIdProvider(transaction.categoryId))
        : null;
    final category = defaultCategory ?? customCategory?.value;
    return (
      icon: category == null
          ? Icons.category
          : parentCategoryIconForCategory(category),
      name: categoryNameForDisplay(
        categoryId: transaction.categoryId,
        category: category,
        locale: locale,
        isLoading: customCategory?.isLoading ?? false,
      ),
    );
  }

  _TilePresentation _visuals(BuildContext context, S l10n) {
    final isJoy = transaction.ledgerType == LedgerType.joy;
    return _TilePresentation(
      tagText: isJoy ? l10n.listLedgerJoy : l10n.listLedgerDaily,
      tagBackground: isJoy
          ? context.palette.joyLight
          : context.palette.dailyLight,
      tagForeground: isJoy
          ? context.palette.joyText
          : context.palette.dailyText,
      categoryColor: isJoy
          ? context.palette.joyText
          : context.palette.dailyText,
      amountColor: isGroupMode || !isJoy
          ? context.palette.textPrimary
          : context.palette.joyText,
      satisfactionValue: isJoy ? transaction.joyFullness : null,
    );
  }

  _FamilyPayer? _payer(S l10n) => isGroupMode
      ? _familyPayer(
          transaction,
          primaryBookId: bookId,
          profile: profile,
          shadows: shadows,
          selfLabel: l10n.familyTransactionPayerSelf,
          memberFallbackLabel: l10n.analyticsDonutMemberFilterLabel,
        )
      : null;

  VoidCallback? _editCallback(BuildContext context, WidgetRef ref) =>
      isGroupMode && transaction.bookId != bookId
      ? null
      : () => _openEditor(context, ref);

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => TransactionEditScreen(transaction: transaction),
        ),
      );
      if (result == true) {
        invalidateTransactionDependents(
          ref,
          bookId: bookId,
          year: selectedMonth.year,
          month: selectedMonth.month,
        );
      }
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'home_screen',
        ),
      );
    }
  }
}

({DateTime start, DateTime end}) _monthRange(({int year, int month}) month) => (
  start: DateTime(month.year, month.month, 1),
  end: DateTime(month.year, month.month + 1, 0, 23, 59, 59),
);

Widget? _asyncGate(Iterable<AsyncValue<dynamic>> values) {
  for (final value in values) {
    if (value.hasError && !value.hasValue) {
      return _ErrorText(message: '${value.error}');
    }
    if (value.isLoading && !value.hasValue) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }
  }
  return null;
}

_FamilyPayer _familyPayer(
  Transaction transaction, {
  required String primaryBookId,
  required UserProfile? profile,
  required List<ShadowBookInfo> shadows,
  required String selfLabel,
  required String memberFallbackLabel,
}) {
  if (transaction.bookId == primaryBookId) {
    return _FamilyPayer(
      name: selfLabel,
      tone: FamilyPayerTone.self,
      avatarEmoji: profile?.avatarEmoji ?? '',
      avatarImagePath: profile?.avatarImagePath,
    );
  }
  for (var index = 0; index < shadows.length; index++) {
    final shadow = shadows[index];
    if (shadow.book.id == transaction.bookId) {
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
    tone: FamilyPayerTone.memberA,
    avatarEmoji: '',
    avatarImagePath: null,
  );
}

class _TilePresentation {
  const _TilePresentation({
    required this.tagText,
    required this.tagBackground,
    required this.tagForeground,
    required this.categoryColor,
    required this.amountColor,
    required this.satisfactionValue,
  });

  final String tagText;
  final Color tagBackground;
  final Color tagForeground;
  final Color categoryColor;
  final Color amountColor;
  final int? satisfactionValue;
}

class _MonthlyTarget {
  const _MonthlyTarget({
    required this.active,
    required this.recommended,
    required this.isConfigured,
  });

  final int active;
  final int? recommended;
  final bool isConfigured;
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

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      'Error: $message',
      style: AppTextStyles.bodySmall.copyWith(color: context.palette.error),
    ),
  );
}

@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/month_comparison.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_member_spending_card.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_hero_card.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_transaction_tile.dart';
import 'package:home_pocket/features/home/presentation/widgets/transaction_list_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/widgets/family_transaction_attribution.dart';
import 'package:home_pocket/shared/widgets/main_surface_header.dart';

import '../helpers/happiness_test_fixtures.dart';

String _asset(String fileName) =>
    '${Directory.current.path}/docs/mockup/v16/assets/$fileName';

Widget _preview({required bool family}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ja'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    theme: AppTheme.light,
    home: Scaffold(
      body: RepaintBoundary(
        key: Key(family ? 'family-home-preview' : 'personal-home-preview'),
        child: ColoredBox(
          color: AppPalette.light.background,
          child: SizedBox(
            width: 390,
            height: 1180,
            child: SingleChildScrollView(
              child: Padding(
                padding: MainSurfaceHeader.screenPadding,
                child: Builder(
                  builder: (context) {
                    final l10n = S.of(context);
                    final snapshot = fixtureMonthlyReportRich().copyWith(
                      totalExpenses: family ? 155120 : 186420,
                      joyTotal: family ? 34620 : 53620,
                      dailyTotal: family ? 120500 : 132800,
                      previousMonthComparison: MonthComparison(
                        previousMonth: 6,
                        previousYear: 2026,
                        previousIncome: 300000,
                        previousExpenses: family ? 178900 : 202640,
                        incomeChange: 0,
                        expenseChange: family ? -13 : -8,
                      ),
                    );
                    final happiness = fixtureHappinessReportRich().copyWith(
                      joyContribution: const Value(64, 23),
                      avgSatisfaction: const Value(8.2, 23),
                      highlightsCount: const Value(12, 23),
                    );
                    final shadows = family ? fixtureShadowBooksThree() : null;
                    final shadowAggregate = family
                        ? fixtureShadowAggregateThree()
                        : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeroHeader(
                          year: 2026,
                          month: 7,
                          isGroupMode: family,
                          onSettingsTap: () {},
                          onMonthTap: () {},
                        ),
                        const SizedBox(
                          height: MainSurfaceHeader.contentSpacing,
                        ),
                        HomeHeroCard(
                          report: snapshot,
                          happiness: happiness,
                          bestJoy: Value(
                            BestJoyMomentRow(
                              transactionId: 'favorite',
                              amount: 4800,
                              joyFullness: 10,
                              categoryId: 'cat_hobbies_oshikatsu',
                              timestamp: DateTime.utc(2026, 7, 6),
                            ),
                            23,
                          ),
                          bestJoyCategoryName: '趣味・コレクション',
                          family: family ? fixtureFamilyHappinessRich() : null,
                          shadowBooks: shadows,
                          shadowAggregate: shadowAggregate,
                          currencyCode: 'JPY',
                          locale: const Locale('ja'),
                          isGroupMode: family,
                          activeMonthlyJoyTarget: 80,
                          recommendedMonthlyJoyTarget: 80,
                          isMonthlyJoyTargetConfigured: true,
                          onTap: () {},
                        ),
                        if (family) ...[
                          const SizedBox(height: 18),
                          FamilyMemberSpendingCard(
                            items: [
                              FamilyMemberSpendingItem(
                                deviceId: 'owner',
                                displayName: 'あおい',
                                avatarEmoji: '',
                                avatarImagePath: _asset(
                                  'family-avatar-owner.png',
                                ),
                                totalExpenses: 84200,
                                joyTotal: 18400,
                                dailyTotal: 65800,
                              ),
                              FamilyMemberSpendingItem(
                                deviceId: 'hanako',
                                displayName: '花子',
                                avatarEmoji: '',
                                avatarImagePath: _asset(
                                  'family-avatar-hanako.png',
                                ),
                                totalExpenses: 62600,
                                joyTotal: 16420,
                                dailyTotal: 46180,
                              ),
                              FamilyMemberSpendingItem(
                                deviceId: 'taro',
                                displayName: '太郎',
                                avatarEmoji: '',
                                avatarImagePath: _asset(
                                  'family-avatar-taro.png',
                                ),
                                totalExpenses: 80820,
                                joyTotal: 18800,
                                dailyTotal: 62020,
                              ),
                            ],
                            currencyCode: 'JPY',
                            locale: const Locale('ja'),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
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
                            const Spacer(),
                            Text(
                              l10n.homeViewAllTransactions,
                              style: AppTextStyles.label.copyWith(
                                color: context.palette.accentPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TransactionListCard(
                          children: [
                            _transaction(
                              context,
                              family: family,
                              category: '食費',
                              amount: '¥3,280',
                              payer: '花子',
                              merchant: 'ライフ',
                              avatar: 'family-avatar-hanako.png',
                              icon: Icons.local_grocery_store,
                            ),
                            _transaction(
                              context,
                              family: family,
                              category: 'カフェ',
                              amount: '¥980',
                              payer: 'あおい',
                              merchant: '喫茶 月舟',
                              avatar: 'family-avatar-owner.png',
                              icon: Icons.local_cafe,
                              joy: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _transaction(
  BuildContext context, {
  required bool family,
  required String category,
  required String amount,
  required String payer,
  required String merchant,
  required String avatar,
  required IconData icon,
  bool joy = false,
}) {
  final palette = context.palette;
  final isSelf = payer == 'あおい';
  return HomeTransactionTile(
    l1Icon: icon,
    tagText: joy ? 'ときめき' : '日常',
    tagBgColor: joy ? palette.joyLight : palette.dailyLight,
    tagTextColor: joy ? palette.joyText : palette.dailyText,
    category: category,
    categoryColor: joy ? palette.joyText : palette.dailyText,
    formattedAmount: amount,
    amountColor: family
        ? palette.textPrimary
        : joy
        ? palette.joyText
        : palette.textPrimary,
    merchant: family ? merchant : payer,
    satisfactionValue: joy ? 8 : null,
    payerName: family ? (isSelf ? '自分' : payer) : null,
    payerTone: isSelf ? FamilyPayerTone.primary : FamilyPayerTone.joy,
    payerAvatarEmoji: family ? '' : null,
    payerAvatarImagePath: family ? _asset(avatar) : null,
  );
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('RobotoMonoNumerals')
      ..addFont(
        File('/System/Library/Fonts/Supplemental/Arial Unicode.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(Uint8List.fromList(bytes))),
      );
    await loader.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(
        File(
          '/Users/xinz/flutter/bin/cache/artifacts/material_fonts/'
          'MaterialIcons-Regular.otf',
        ).readAsBytes().then(
          (bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
        ),
      );
    await materialIcons.load();
  });

  for (final family in [false, true]) {
    testWidgets(
      '${family ? 'family' : 'personal'} home matches V16 structure',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 1180);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_preview(family: family));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(
            Key(family ? 'family-home-preview' : 'personal-home-preview'),
          ),
          matchesGoldenFile(
            'goldens/home_v16_${family ? 'family' : 'personal'}_alignment.png',
          ),
        );
      },
    );
  }
}

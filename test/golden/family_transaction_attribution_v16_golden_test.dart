@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_transaction_tile.dart';
import 'package:home_pocket/features/home/presentation/widgets/transaction_list_card.dart';
import 'package:home_pocket/features/list/domain/models/tagged_transaction.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_transaction_tile.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/widgets/family_transaction_attribution.dart';

String _asset(String fileName) =>
    '${Directory.current.path}/docs/mockup/v17/assets/$fileName';

TaggedTransaction _transaction(String id, LedgerType ledgerType) {
  final now = DateTime(2026, 8, 3, 10, 30);
  return TaggedTransaction(
    transaction: Transaction(
      id: id,
      bookId: 'family-book',
      deviceId: 'device',
      amount: 1400,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: ledgerType,
      timestamp: now,
      currentHash: 'hash-$id',
      createdAt: now,
      entrySource: EntrySource.manual,
    ),
  );
}

Widget _preview(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark ? AppPalette.dark : AppPalette.light;
  final baseTheme = isDark ? AppTheme.dark : AppTheme.light;
  return ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(fontFamily: 'NotoSansCJK'),
        primaryTextTheme: baseTheme.primaryTextTheme.apply(
          fontFamily: 'NotoSansCJK',
        ),
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: const Key('family-transaction-attribution-preview'),
          child: ColoredBox(
            color: palette.background,
            child: SizedBox(
              width: 390,
              height: 390,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('首页 · 最近支出', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    TransactionListCard(
                      children: [
                        HomeTransactionTile(
                          l1Icon: Icons.local_cafe,
                          tagText: '悦己',
                          tagBgColor: palette.joyLight,
                          tagTextColor: palette.joyText,
                          category: '休闲运动',
                          categoryColor: palette.joyText,
                          formattedAmount: '¥1,400',
                          amountColor: palette.textPrimary,
                          merchant: '喫茶 月舟',
                          satisfactionValue: 9,
                          payerName: '我',
                          payerTone: FamilyPayerTone.self,
                          payerAvatarEmoji: '',
                          payerAvatarImagePath: _asset(
                            'family-avatar-owner.png',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text('明细', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    TransactionListCard(
                      children: [
                        ListTransactionTile(
                          taggedTx: _transaction('hanako', LedgerType.daily),
                          bookId: 'family-book',
                          onTap: () {},
                          onDeleted: () {},
                          tagText: '日常',
                          tagBgColor: palette.dailyLight,
                          tagTextColor: palette.dailyText,
                          category: '外出就餐',
                          categoryColor: palette.dailyText,
                          formattedAmount: '¥1,236',
                          l1Icon: Icons.restaurant,
                          locale: const Locale('zh'),
                          merchant: 'ライフ',
                          readOnly: true,
                          familyPayerLabel: '花子',
                          familyPayerTone: FamilyPayerTone.memberA,
                          familyPayerAvatarEmoji: '',
                          familyPayerAvatarImagePath: _asset(
                            'family-avatar-hanako.png',
                          ),
                        ),
                        ListTransactionTile(
                          taggedTx: _transaction('owner', LedgerType.joy),
                          bookId: 'family-book',
                          onTap: () {},
                          onDeleted: () {},
                          tagText: '悦己',
                          tagBgColor: palette.joyLight,
                          tagTextColor: palette.joyText,
                          category: '休闲运动',
                          categoryColor: palette.joyText,
                          formattedAmount: '¥1,400',
                          l1Icon: Icons.sports_esports,
                          locale: const Locale('zh'),
                          merchant: '喫茶 月舟',
                          satisfactionValue: 9,
                          readOnly: true,
                          familyPayerLabel: '我',
                          familyPayerTone: FamilyPayerTone.self,
                          familyPayerAvatarEmoji: '',
                          familyPayerAvatarImagePath: _asset(
                            'family-avatar-owner.png',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    final textFont = FontLoader('NotoSansCJK')
      ..addFont(
        File('/System/Library/Fonts/Hiragino Sans GB.ttc').readAsBytes().then(
          (bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
        ),
      );
    await textFont.load();
    final numeralFont = FontLoader('RobotoMonoNumerals')
      ..addFont(
        File('/System/Library/Fonts/Supplemental/Arial Unicode.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(Uint8List.fromList(bytes))),
      );
    await numeralFont.load();
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

  testWidgets('family Home and List share V16 payer attribution', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 390);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_preview(Brightness.light));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('family-transaction-attribution-preview')),
      matchesGoldenFile('goldens/family_transaction_attribution_v16_zh.png'),
    );
  });

  testWidgets('family payer attribution supports dark identity colors', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 390);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_preview(Brightness.dark));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('family-transaction-attribution-preview')),
      matchesGoldenFile(
        'goldens/family_transaction_attribution_v16_dark_zh.png',
      ),
    );
  });
}

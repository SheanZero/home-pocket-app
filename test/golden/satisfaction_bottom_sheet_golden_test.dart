@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/screens/manual_one_step_screen.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpeechService extends Mock
    implements StartSpeechRecognitionUseCase {}

void main() {
  testWidgets('Joy satisfaction sheet on the manual entry screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final parent = Category(
      id: 'food',
      name: '食费',
      icon: 'restaurant',
      color: '#000000',
      level: 1,
      createdAt: DateTime.utc(2026),
    );
    final category = Category(
      id: 'dining-out',
      name: '外出就餐',
      icon: 'restaurant',
      color: '#000000',
      parentId: parent.id,
      level: 2,
      createdAt: DateTime.utc(2026),
    );
    final speechService = _MockSpeechService();
    when(
      () => speechService.initialize(
        onStatus: any(named: 'onStatus'),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((_) async => true);
    when(() => speechService.cancel()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentLocaleProvider.overrideWith((_) async => const Locale('zh')),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          theme: AppTheme.light,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: ManualOneStepScreen(
            bookId: 'book-1',
            initialAmount: 1236,
            initialCategory: category,
            initialParentCategory: parent,
            initialDate: DateTime(2026, 8, 4),
            initialLedgerType: LedgerType.daily,
            speechService: speechService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ledger_type_joy_chip')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Overlay),
      matchesGoldenFile('goldens/satisfaction_bottom_sheet_manual_zh.png'),
    );
  });
}

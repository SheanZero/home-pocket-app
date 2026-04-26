// Characterization test for TransactionConfirmScreen.
// Locks: screen renders without crash, Scaffold/AppBar present,
// DateFormatter + NumberFormatter call sites produce formatted output.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/transaction_confirm_screen.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

Widget _buildApp(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  late _MockCategoryRepository mockCategoryRepo;
  late _MockSettingsRepository mockSettingsRepo;

  setUp(() {
    mockCategoryRepo = _MockCategoryRepository();
    mockSettingsRepo = _MockSettingsRepository();

    when(() => mockCategoryRepo.findAll()).thenAnswer((_) async => []);
    when(() => mockCategoryRepo.findActive()).thenAnswer((_) async => []);
    when(
      () => mockCategoryRepo.findById(any()),
    ).thenAnswer((_) async => null);
    when(
      () => mockSettingsRepo.getSettings(),
    ).thenAnswer((_) async => const AppSettings(language: 'ja'));

    registerFallbackValue(
      Transaction(
        id: '',
        bookId: '',
        deviceId: '',
        amount: 0,
        type: TransactionType.expense,
        categoryId: '',
        ledgerType: LedgerType.survival,
        timestamp: DateTime.now(),
        currentHash: '',
        createdAt: DateTime.now(),
      ),
    );
  });

  group(
    'TransactionConfirmScreen characterization tests (pre-refactor behavior)',
    () {
      testWidgets('renders without crashing with valid parameters', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            TransactionConfirmScreen(
              bookId: 'book-001',
              amount: 1500,
              date: DateTime(2026, 3, 15, 12, 30),
            ),
            [
              categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
              settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            ],
          ),
        );
        await tester.pump();
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('contains an AppBar', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            TransactionConfirmScreen(
              bookId: 'book-001',
              amount: 1500,
              date: DateTime(2026, 3, 15, 12, 30),
            ),
            [
              categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
              settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            ],
          ),
        );
        await tester.pump();
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets(
        'NumberFormatter call site — amount display contains yen symbol',
        (tester) async {
          await tester.pumpWidget(
            _buildApp(
              TransactionConfirmScreen(
                bookId: 'book-001',
                amount: 1500,
                date: DateTime(2026, 3, 15, 12, 30),
              ),
              [
                categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
                settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
              ],
            ),
          );
          await tester.pump();
          // NumberFormatter is called for amount display — ¥ symbol must appear
          expect(find.textContaining('¥'), findsWidgets);
        },
      );

      testWidgets(
        'DateFormatter call site — date text rendered (slash or colon separator)',
        (tester) async {
          await tester.pumpWidget(
            _buildApp(
              TransactionConfirmScreen(
                bookId: 'book-001',
                amount: 1500,
                // Use an old date so DateFormatter.formatDate produces yyyy/MM/dd
                date: DateTime(2020, 1, 1),
              ),
              [
                categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
                settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
              ],
            ),
          );
          await tester.pump();
          // DateFormatter.formatDate called for old dates -> '/'
          expect(find.textContaining('/'), findsWidgets);
        },
      );

      testWidgets('createTransactionUseCaseProvider is wired (provider exists)',
          (tester) async {
        // This test verifies the use_case_providers wiring does not throw
        // at build time — pure construction check.
        await tester.pumpWidget(
          _buildApp(
            TransactionConfirmScreen(
              bookId: 'book-001',
              amount: 500,
              date: DateTime.now(),
            ),
            [
              categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
              settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            ],
          ),
        );
        await tester.pump();
        // No crash = wiring is intact
        expect(find.byType(TransactionConfirmScreen), findsOneWidget);
      });
    },
  );
}

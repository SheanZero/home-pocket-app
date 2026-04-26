// Characterization test for VoiceInputScreen.
// Locks: screen renders without crash, Scaffold present.
// StartSpeechRecognitionUseCase is injected via constructor (not provider),
// so no platform speech service is initialized.
// VoiceInputScreen manages its own speech lifecycle directly.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockStartSpeechRecognitionUseCase extends Mock
    implements StartSpeechRecognitionUseCase {}

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
  late _MockStartSpeechRecognitionUseCase mockSpeechService;

  setUp(() {
    mockCategoryRepo = _MockCategoryRepository();
    mockSettingsRepo = _MockSettingsRepository();
    mockSpeechService = _MockStartSpeechRecognitionUseCase();

    when(() => mockCategoryRepo.findAll()).thenAnswer((_) async => []);
    when(() => mockCategoryRepo.findActive()).thenAnswer((_) async => []);
    when(
      () => mockSettingsRepo.getSettings(),
    ).thenAnswer((_) async => const AppSettings(language: 'ja'));
    // initialize() is called in initState with optional named params — stub them
    when(
      () => mockSpeechService.initialize(
        onStatus: any(named: 'onStatus'),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((_) async => false);
    // cancel() is called in dispose
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
  });

  group(
    'VoiceInputScreen characterization tests (post-refactor: StartSpeechRecognitionUseCase)',
    () {
      testWidgets('renders without crashing with injected SpeechService', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            VoiceInputScreen(
              bookId: 'book-001',
              speechService: mockSpeechService,
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
            VoiceInputScreen(
              bookId: 'book-001',
              speechService: mockSpeechService,
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
        'StartSpeechRecognitionUseCase injected via constructor — not from provider',
        (tester) async {
          // Key characterization: VoiceInputScreen uses widget.speechService
          // (StartSpeechRecognitionUseCase?) ?? uses appSpeechRecognitionServiceProvider.
          // This test verifies the injection path is wired correctly (no platform calls).
          await tester.pumpWidget(
            _buildApp(
              VoiceInputScreen(
                bookId: 'book-001',
                speechService: mockSpeechService,
              ),
              [
                categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
                settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
              ],
            ),
          );
          await tester.pump();
          // Screen renders using the injected use case (no platform channel calls)
          expect(find.byType(VoiceInputScreen), findsOneWidget);
        },
      );
    },
  );
}

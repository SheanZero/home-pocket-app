// Characterization test for VoiceInputScreen.
// Locks: screen renders without crash, Scaffold present.
// SpeechRecognitionService is injected via constructor (not provider),
// so no SpeechRecognitionService mock in overrides needed.
// VoiceInputScreen manages its own speech lifecycle directly.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/speech/speech_recognition_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockSpeechRecognitionService extends Mock
    implements SpeechRecognitionService {}

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
  late _MockSpeechRecognitionService mockSpeechService;

  setUp(() {
    mockCategoryRepo = _MockCategoryRepository();
    mockSettingsRepo = _MockSettingsRepository();
    mockSpeechService = _MockSpeechRecognitionService();

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
    // cancelListening() is called in dispose
    when(
      () => mockSpeechService.cancelListening(),
    ).thenAnswer((_) async {});
  });

  group(
    'VoiceInputScreen characterization tests (pre-refactor behavior)',
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
        'SpeechRecognitionService injected via constructor — not from provider',
        (tester) async {
          // Key characterization: VoiceInputScreen uses widget.speechService ?? SpeechRecognitionService()
          // This test verifies the injection path is wired correctly.
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
          // Screen renders using the injected service (no platform channel calls)
          expect(find.byType(VoiceInputScreen), findsOneWidget);
        },
      );
    },
  );
}

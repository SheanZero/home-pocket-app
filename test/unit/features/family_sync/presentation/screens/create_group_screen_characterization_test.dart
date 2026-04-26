// Characterization test for CreateGroupScreen.
// Locks: screen renders without crash with required providers overridden.
// CreateGroupScreen uses keyManagerProvider (crypto), webSocketServiceProvider,
// userProfileProvider (async), and group_providers for group use cases.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart'
    show webSocketServiceProvider, keyManagerProvider;
import 'package:home_pocket/features/family_sync/presentation/screens/create_group_screen.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart'
    show userProfileRepositoryProvider;
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockKeyManager extends Mock implements KeyManager {}

class _MockWebSocketService extends Mock implements WebSocketService {}

class _MockUserProfileRepository extends Mock implements UserProfileRepository {}

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
  late _MockKeyManager mockKeyManager;
  late _MockWebSocketService mockWebSocketService;
  late _MockUserProfileRepository mockUserProfileRepo;
  late _MockSettingsRepository mockSettingsRepo;

  setUp(() {
    mockKeyManager = _MockKeyManager();
    mockWebSocketService = _MockWebSocketService();
    mockUserProfileRepo = _MockUserProfileRepository();
    mockSettingsRepo = _MockSettingsRepository();

    when(() => mockUserProfileRepo.find()).thenAnswer((_) async => null);
    when(() => mockWebSocketService.dispose()).thenReturn(null);
    when(
      () => mockSettingsRepo.getSettings(),
    ).thenAnswer((_) async => const AppSettings(language: 'ja'));
  });

  group(
    'CreateGroupScreen characterization tests (pre-refactor behavior)',
    () {
      testWidgets('renders without crashing', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const CreateGroupScreen(),
            [
              keyManagerProvider.overrideWithValue(mockKeyManager),
              webSocketServiceProvider.overrideWithValue(mockWebSocketService),
              userProfileRepositoryProvider.overrideWithValue(
                mockUserProfileRepo,
              ),
              settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            ],
          ),
        );
        await tester.pump();
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('contains a Scaffold body with content', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const CreateGroupScreen(),
            [
              keyManagerProvider.overrideWithValue(mockKeyManager),
              webSocketServiceProvider.overrideWithValue(mockWebSocketService),
              userProfileRepositoryProvider.overrideWithValue(
                mockUserProfileRepo,
              ),
              settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            ],
          ),
        );
        await tester.pump();
        // CreateGroupScreen wraps its content in a Scaffold
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets(
        'keyManagerProvider wired — crypto provider is overrideable',
        (tester) async {
          // This test verifies keyManagerProvider can be overridden,
          // locking the dependency injection path before Plan 04-01 refactoring.
          await tester.pumpWidget(
            _buildApp(
              const CreateGroupScreen(),
              [
                keyManagerProvider.overrideWithValue(mockKeyManager),
                webSocketServiceProvider.overrideWithValue(mockWebSocketService),
                userProfileRepositoryProvider.overrideWithValue(
                  mockUserProfileRepo,
                ),
                settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
              ],
            ),
          );
          await tester.pump();
          expect(find.byType(CreateGroupScreen), findsOneWidget);
        },
      );
    },
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'prewarming SharedPreferences keeps the synchronous settings repository ready',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final preferences = await container.read(
        sharedPreferencesProvider.future,
      );
      await Future<void>.delayed(Duration.zero);

      expect(() => container.read(settingsRepositoryProvider), returnsNormally);
      expect(
        container.read(sharedPreferencesProvider).value,
        same(preferences),
      );
      expect(
        container.read(settingsRepositoryProvider),
        isA<SettingsRepository>(),
      );
    },
  );
}

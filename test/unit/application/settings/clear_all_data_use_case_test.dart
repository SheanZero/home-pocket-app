import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/clear_all_data_use_case.dart';
import 'package:home_pocket/infrastructure/storage/privacy_wipe_journal.dart';

void main() {
  test('does not run later stages after database failure', () async {
    final calls = <String>[];
    final useCase = ClearAllDataUseCase(
      journalStore: InMemoryPrivacyWipeJournalStore(),
      suspendSync: () async => calls.add('suspend'),
      wipeDatabase: () async {
        calls.add('database');
        throw StateError('DB error');
      },
      wipeAppOwnedFiles: () async => calls.add('files'),
      clearSecureUserData: () async => calls.add('secure'),
      resetSettings: () async => calls.add('settings'),
      resetInMemoryState: () async => calls.add('memory'),
    );

    final result = await useCase.execute();

    expect(result.isError, isTrue);
    expect(result.error, contains('Failed to clear local data'));
    expect(calls, ['suspend', 'database']);
  });

  test('does not infer or issue any server deletion step', () async {
    var localSteps = 0;
    final useCase = ClearAllDataUseCase(
      journalStore: InMemoryPrivacyWipeJournalStore(),
      suspendSync: () async => localSteps++,
      wipeDatabase: () async => localSteps++,
      wipeAppOwnedFiles: () async => localSteps++,
      clearSecureUserData: () async => localSteps++,
      resetSettings: () async => localSteps++,
      resetInMemoryState: () async => localSteps++,
    );

    expect((await useCase.execute()).isSuccess, isTrue);
    expect(localSteps, 6);
  });
}

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/clear_all_data_use_case.dart';
import 'package:home_pocket/infrastructure/storage/file_privacy_wipe_journal_store.dart';
import 'package:home_pocket/infrastructure/storage/privacy_wipe_journal.dart';

void main() {
  late Directory temp;
  late Directory support;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('privacy-wipe-journal-');
    support = Directory('${temp.path}/support')..createSync();
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  FilePrivacyWipeJournalStore makeStore() => FilePrivacyWipeJournalStore(
    supportDirectoryResolver: () async => support.path,
    clock: () => DateTime.utc(2026, 8, 2, 12),
  );

  ClearAllDataUseCase makeUseCase({
    required PrivacyWipeJournalStore journalStore,
    ClearAllDataStep? suspendSync,
    ClearAllDataStep? wipeDatabase,
    ClearAllDataStep? wipeAppOwnedFiles,
    ClearAllDataStep? clearSecureUserData,
    ClearAllDataStep? resetSettings,
    ClearAllDataStep? resetInMemoryState,
  }) => ClearAllDataUseCase(
    journalStore: journalStore,
    suspendSync: suspendSync ?? () async {},
    wipeDatabase: wipeDatabase ?? () async {},
    wipeAppOwnedFiles: wipeAppOwnedFiles ?? () async {},
    clearSecureUserData: clearSecureUserData ?? () async {},
    resetSettings: resetSettings ?? () async {},
    resetInMemoryState: resetInMemoryState ?? () async {},
  );

  test(
    'database committed but response lost keeps dbPending and a new instance safely redoes it',
    () async {
      var databaseCommits = 0;
      final first = makeUseCase(
        journalStore: makeStore(),
        wipeDatabase: () async {
          databaseCommits++;
          throw StateError('process stopped after database commit');
        },
      );

      expect((await first.execute()).isError, isTrue);
      expect(
        (await makeStore().read())?.stage,
        PrivacyWipeJournalStage.databasePending,
      );

      final resumedCalls = <String>[];
      final reconstructed = makeUseCase(
        journalStore: makeStore(),
        suspendSync: () async => resumedCalls.add('suspend'),
        wipeDatabase: () async {
          databaseCommits++;
          resumedCalls.add('database');
        },
        wipeAppOwnedFiles: () async => resumedCalls.add('files'),
        clearSecureUserData: () async => resumedCalls.add('secure'),
        resetSettings: () async => resumedCalls.add('settings'),
        resetInMemoryState: () async => resumedCalls.add('memory'),
      );

      expect((await reconstructed.resumePending()).isSuccess, isTrue);
      expect(databaseCommits, 2, reason: 'dbPending is deliberately replayed');
      expect(resumedCalls, [
        'suspend',
        'database',
        'files',
        'secure',
        'settings',
        'memory',
      ]);
      expect(await makeStore().read(), isNull, reason: 'journal deletes last');
    },
  );

  for (final fault
      in <
        ({
          String name,
          PrivacyWipeJournalStage expectedStage,
          int callbackIndex,
        })
      >[
        (
          name: 'files',
          expectedStage: PrivacyWipeJournalStage.filesPending,
          callbackIndex: 1,
        ),
        (
          name: 'secure storage',
          expectedStage: PrivacyWipeJournalStage.secureUserDataPending,
          callbackIndex: 2,
        ),
        (
          name: 'settings',
          expectedStage: PrivacyWipeJournalStage.settingsPending,
          callbackIndex: 3,
        ),
        (
          name: 'memory',
          expectedStage: PrivacyWipeJournalStage.memoryPending,
          callbackIndex: 4,
        ),
      ]) {
    test(
      '${fault.name} failure resumes from its durable pending boundary',
      () async {
        final attempts = List<int>.filled(5, 0);

        Future<void> run(int index, {required bool failFirst}) async {
          attempts[index]++;
          if (failFirst &&
              index == fault.callbackIndex &&
              attempts[index] == 1) {
            throw StateError('injected ${fault.name} failure');
          }
        }

        ClearAllDataUseCase instance({required bool failFirst}) => makeUseCase(
          journalStore: makeStore(),
          wipeDatabase: () => run(0, failFirst: failFirst),
          wipeAppOwnedFiles: () => run(1, failFirst: failFirst),
          clearSecureUserData: () => run(2, failFirst: failFirst),
          resetSettings: () => run(3, failFirst: failFirst),
          resetInMemoryState: () => run(4, failFirst: failFirst),
        );

        expect((await instance(failFirst: true).execute()).isError, isTrue);
        expect((await makeStore().read())?.stage, fault.expectedStage);

        expect(
          (await instance(failFirst: false).resumePending()).isSuccess,
          isTrue,
        );
        for (var index = 0; index < fault.callbackIndex; index++) {
          expect(
            attempts[index],
            1,
            reason: 'completed stage $index is skipped',
          );
        }
        expect(attempts[fault.callbackIndex], 2);
        for (
          var index = fault.callbackIndex + 1;
          index < attempts.length;
          index++
        ) {
          expect(attempts[index], 1);
        }
        expect(await makeStore().read(), isNull);
      },
    );
  }

  for (final boundary
      in <
        ({
          String name,
          int callbackIndex,
          int? failOnWrite,
          bool failDelete,
          PrivacyWipeJournalStage retainedStage,
        })
      >[
        (
          name: 'database journal advance',
          callbackIndex: 0,
          failOnWrite: 2,
          failDelete: false,
          retainedStage: PrivacyWipeJournalStage.databasePending,
        ),
        (
          name: 'files journal advance',
          callbackIndex: 1,
          failOnWrite: 3,
          failDelete: false,
          retainedStage: PrivacyWipeJournalStage.filesPending,
        ),
        (
          name: 'secure journal advance',
          callbackIndex: 2,
          failOnWrite: 4,
          failDelete: false,
          retainedStage: PrivacyWipeJournalStage.secureUserDataPending,
        ),
        (
          name: 'settings journal advance',
          callbackIndex: 3,
          failOnWrite: 5,
          failDelete: false,
          retainedStage: PrivacyWipeJournalStage.settingsPending,
        ),
        (
          name: 'final journal delete',
          callbackIndex: 4,
          failOnWrite: null,
          failDelete: true,
          retainedStage: PrivacyWipeJournalStage.memoryPending,
        ),
      ]) {
    test(
      '${boundary.name} failure replays the last safe pending stage',
      () async {
        final attempts = List<int>.filled(5, 0);
        Future<void> run(int index) async => attempts[index]++;
        final durableStore = makeStore();
        final faultingStore = _FaultingPrivacyWipeJournalStore(
          durableStore,
          failOnWrite: boundary.failOnWrite,
          failDelete: boundary.failDelete,
        );
        ClearAllDataUseCase instance(PrivacyWipeJournalStore store) =>
            makeUseCase(
              journalStore: store,
              wipeDatabase: () => run(0),
              wipeAppOwnedFiles: () => run(1),
              clearSecureUserData: () => run(2),
              resetSettings: () => run(3),
              resetInMemoryState: () => run(4),
            );

        expect((await instance(faultingStore).execute()).isError, isTrue);
        expect((await durableStore.read())?.stage, boundary.retainedStage);

        expect(
          (await instance(durableStore).resumePending()).isSuccess,
          isTrue,
        );
        for (var index = 0; index < boundary.callbackIndex; index++) {
          expect(
            attempts[index],
            1,
            reason: 'completed stage $index stays done',
          );
        }
        expect(
          attempts[boundary.callbackIndex],
          2,
          reason: 'last non-durably-advanced stage is replayed',
        );
        for (
          var index = boundary.callbackIndex + 1;
          index < attempts.length;
          index++
        ) {
          expect(attempts[index], 1);
        }
        expect(await durableStore.read(), isNull);
      },
    );
  }

  test(
    'manual and startup instances share one process-wide single flight',
    () async {
      final suspended = Completer<void>();
      var databaseWipes = 0;
      final manual = makeUseCase(
        journalStore: makeStore(),
        suspendSync: () => suspended.future,
        wipeDatabase: () async => databaseWipes++,
      );
      final startup = makeUseCase(
        journalStore: makeStore(),
        wipeDatabase: () async => databaseWipes++,
      );

      final first = manual.execute();
      await Future<void>.delayed(Duration.zero);
      final second = startup.resumePending();
      suspended.complete();

      expect((await first).isSuccess, isTrue);
      expect((await second).isSuccess, isTrue);
      expect(databaseWipes, 1);
    },
  );

  test(
    'startup no-op without a journal does not suspend or mutate stores',
    () async {
      var callbacks = 0;
      final result = await makeUseCase(
        journalStore: makeStore(),
        suspendSync: () async => callbacks++,
        wipeDatabase: () async => callbacks++,
        wipeAppOwnedFiles: () async => callbacks++,
        clearSecureUserData: () async => callbacks++,
        resetSettings: () async => callbacks++,
        resetInMemoryState: () async => callbacks++,
      ).resumePending();

      expect(result.isSuccess, isTrue);
      expect(callbacks, 0);
    },
  );

  test(
    'corrupt journal fails closed, retains evidence, and runs no step',
    () async {
      final store = makeStore();
      await store.write(
        store.newEntry(PrivacyWipeJournalStage.databasePending),
      );
      final file = File(
        '${support.path}/${FilePrivacyWipeJournalStore.directoryName}/'
        '${FilePrivacyWipeJournalStore.fileName}',
      );
      await file.writeAsString('{"version":999}', flush: true);
      var callbacks = 0;

      final result = await makeUseCase(
        journalStore: store,
        suspendSync: () async => callbacks++,
        wipeDatabase: () async => callbacks++,
        wipeAppOwnedFiles: () async => callbacks++,
        clearSecureUserData: () async => callbacks++,
        resetSettings: () async => callbacks++,
        resetInMemoryState: () async => callbacks++,
      ).resumePending();

      expect(result.isError, isTrue);
      expect(callbacks, 0);
      expect(file.existsSync(), isTrue);
    },
  );
}

class _FaultingPrivacyWipeJournalStore implements PrivacyWipeJournalStore {
  _FaultingPrivacyWipeJournalStore(
    this.delegate, {
    this.failOnWrite,
    this.failDelete = false,
  });

  final PrivacyWipeJournalStore delegate;
  final int? failOnWrite;
  final bool failDelete;
  int _writes = 0;

  @override
  String get coordinationKey => delegate.coordinationKey;

  @override
  Future<void> delete() async {
    if (failDelete) throw StateError('injected journal delete failure');
    await delegate.delete();
  }

  @override
  PrivacyWipeJournalEntry newEntry(PrivacyWipeJournalStage stage) =>
      delegate.newEntry(stage);

  @override
  Future<PrivacyWipeJournalEntry?> read() => delegate.read();

  @override
  Future<void> write(PrivacyWipeJournalEntry entry) async {
    _writes++;
    if (_writes == failOnWrite) {
      throw StateError('injected journal advance failure');
    }
    await delegate.write(entry);
  }
}

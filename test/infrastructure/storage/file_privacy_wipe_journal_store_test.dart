import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/storage/file_privacy_wipe_journal_store.dart';
import 'package:home_pocket/infrastructure/storage/privacy_wipe_journal.dart';

void main() {
  late Directory temp;
  late Directory support;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('wipe-store-');
    support = Directory('${temp.path}/support')..createSync();
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  FilePrivacyWipeJournalStore makeStore() => FilePrivacyWipeJournalStore(
    supportDirectoryResolver: () async => support.path,
    clock: () => DateTime.utc(2026, 8, 2, 12, 34, 56),
  );

  File journalFile() => File(
    '${support.path}/${FilePrivacyWipeJournalStore.directoryName}/'
    '${FilePrivacyWipeJournalStore.fileName}',
  );

  test(
    'durably round-trips only version, stage, timestamp and checksum',
    () async {
      final store = makeStore();
      await store.write(
        store.newEntry(PrivacyWipeJournalStage.secureUserDataPending),
      );

      final decoded = jsonDecode(await journalFile().readAsString()) as Map;
      expect(decoded.keys.toSet(), {
        'version',
        'stage',
        'updatedAtEpochMs',
        'checksum',
      });
      expect(await store.read(), isNotNull);
      expect(
        await journalFile().readAsString(),
        isNot(anyOf(contains('device'), contains('group'), contains('token'))),
      );

      await store.delete();
      expect(await store.read(), isNull);
    },
  );

  test(
    'corrupt checksum, unknown version and unknown stage all fail closed',
    () async {
      final store = makeStore();
      final valid = store.newEntry(PrivacyWipeJournalStage.databasePending);
      await store.write(valid);
      final original = jsonDecode(await journalFile().readAsString()) as Map;

      for (final mutation in <Map<String, Object?>>[
        {
          ...original.cast<String, Object?>(),
          'checksum': List.filled(64, '0').join(),
        },
        {...original.cast<String, Object?>(), 'version': 999},
        {...original.cast<String, Object?>(), 'stage': 'futureStage'},
        {...original.cast<String, Object?>(), 'unexpected': true},
      ]) {
        await journalFile().writeAsString(jsonEncode(mutation), flush: true);
        await expectLater(
          store.read(),
          throwsA(isA<PrivacyWipeJournalCorruptException>()),
        );
      }
    },
  );

  test(
    'rejects a symlinked journal directory and never writes outside',
    () async {
      final external = Directory('${temp.path}/external')..createSync();
      final externalMarker = File('${external.path}/keep')
        ..writeAsStringSync('keep');
      Link(
        '${support.path}/${FilePrivacyWipeJournalStore.directoryName}',
      ).createSync(external.path);

      await expectLater(
        makeStore().write(
          makeStore().newEntry(PrivacyWipeJournalStage.databasePending),
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(externalMarker.readAsStringSync(), 'keep');
      expect(
        File(
          '${external.path}/${FilePrivacyWipeJournalStore.fileName}',
        ).existsSync(),
        isFalse,
      );
    },
  );
}

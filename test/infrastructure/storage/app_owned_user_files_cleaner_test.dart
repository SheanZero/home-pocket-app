import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/storage/app_owned_user_files_cleaner.dart';

void main() {
  test(
    'deletes only app-owned avatar roots and never follows symlinks',
    () async {
      final temp = await Directory.systemTemp.createTemp('home-pocket-files-');
      addTearDown(() => temp.delete(recursive: true));
      final documents = Directory('${temp.path}/documents')..createSync();
      final support = Directory('${temp.path}/support')..createSync();
      final external = File('${temp.path}/picker-source.jpg')
        ..writeAsStringSync('external');
      final unrelated = File('${documents.path}/backup.hpb')
        ..writeAsStringSync('backup');
      final generatedBackup = File(
        '${documents.path}/homepocket_backup_2026-08-02.hpb',
      )..writeAsStringSync('encrypted backup');
      final avatars = Directory('${documents.path}/avatars')..createSync();
      File('${avatars.path}/owned.jpg').writeAsStringSync('owned');
      Link('${avatars.path}/external-link').createSync(external.path);
      final staging = Directory(
        '${support.path}/family_sync/avatar_semantic_staging',
      )..createSync(recursive: true);
      File('${staging.path}/blob.jpg').writeAsStringSync('staged');
      final privacyJournal = File(
        '${support.path}/home_pocket_privacy/wipe_journal_v1.json',
      );
      privacyJournal.parent.createSync();
      privacyJournal.writeAsStringSync('must survive user-file cleanup');

      final cleaner = AppOwnedUserFilesCleaner(
        documentsDirectoryResolver: () async => documents.path,
        supportDirectoryResolver: () async => support.path,
      );
      await cleaner.clear();

      expect(avatars.existsSync(), isFalse);
      expect(staging.existsSync(), isFalse);
      expect(
        external.existsSync(),
        isTrue,
        reason: 'external picker source must survive',
      );
      expect(
        unrelated.existsSync(),
        isTrue,
        reason: 'unrelated documents must survive',
      );
      expect(
        generatedBackup.existsSync(),
        isFalse,
        reason: 'app-generated backups contain local user data',
      );
      expect(
        privacyJournal.existsSync(),
        isTrue,
        reason: 'wipe recovery journal must survive the file-cleaning stage',
      );
      await cleaner.clear();
    },
  );

  test('rejects an untrusted symlink root instead of traversing it', () async {
    final temp = await Directory.systemTemp.createTemp(
      'home-pocket-files-link-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final realDocuments = Directory('${temp.path}/real-docs')..createSync();
    final documentsLink = Link('${temp.path}/docs-link')
      ..createSync(realDocuments.path);
    final support = Directory('${temp.path}/support')..createSync();
    final external = File('${realDocuments.path}/avatars/keep.jpg');
    external.parent.createSync();
    external.writeAsStringSync('keep');

    final cleaner = AppOwnedUserFilesCleaner(
      documentsDirectoryResolver: () async => documentsLink.path,
      supportDirectoryResolver: () async => support.path,
    );

    await expectLater(cleaner.clear(), throwsA(isA<FileSystemException>()));
    expect(external.existsSync(), isTrue);
  });

  test('rejects empty and relative platform storage roots', () async {
    final cleanerWithEmptyRoot = AppOwnedUserFilesCleaner(
      documentsDirectoryResolver: () async => '',
      supportDirectoryResolver: () async => '/absolute/support',
    );
    final cleanerWithRelativeRoot = AppOwnedUserFilesCleaner(
      documentsDirectoryResolver: () async => 'relative/documents',
      supportDirectoryResolver: () async => '/absolute/support',
    );

    await expectLater(
      cleanerWithEmptyRoot.clear(),
      throwsA(isA<FileSystemException>()),
    );
    await expectLater(
      cleanerWithRelativeRoot.clear(),
      throwsA(isA<FileSystemException>()),
    );
  });
}

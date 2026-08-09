import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path_lib;

import 'app_owned_user_files_cleaner.dart' show UserDataDirectoryResolver;
import 'privacy_wipe_journal.dart';

typedef PrivacyWipeClock = DateTime Function();

/// Atomic journal stored outside every user-file cleanup root.
///
/// Location: `<Application Support>/home_pocket_privacy/wipe_journal_v1.json`.
/// It intentionally does not live in SharedPreferences or secure storage,
/// because both are privacy-wipe stages. The record contains no identity,
/// group, token, path, or other user data.
class FilePrivacyWipeJournalStore implements PrivacyWipeJournalStore {
  FilePrivacyWipeJournalStore({
    required this._supportDirectoryResolver,
    PrivacyWipeClock? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  static const int journalVersion = 1;
  static const String directoryName = 'home_pocket_privacy';
  static const String fileName = 'wipe_journal_v1.json';
  static const String _temporaryFileName = 'wipe_journal_v1.json.tmp';
  static const int _maximumJournalBytes = 4096;

  static const Set<String> _expectedKeys = {
    'version',
    'stage',
    'updatedAtEpochMs',
    'checksum',
  };

  final UserDataDirectoryResolver _supportDirectoryResolver;
  final PrivacyWipeClock _clock;

  @override
  String get coordinationKey => 'home-pocket-privacy-wipe-v1';

  @override
  PrivacyWipeJournalEntry newEntry(PrivacyWipeJournalStage stage) {
    final updatedAt = _clock().toUtc().millisecondsSinceEpoch;
    return PrivacyWipeJournalEntry(
      version: journalVersion,
      stage: stage,
      updatedAtEpochMs: updatedAt,
      checksum: _checksum(journalVersion, stage.wireName, updatedAt),
    );
  }

  @override
  Future<PrivacyWipeJournalEntry?> read() async {
    final directory = await _resolveJournalDirectory(create: false);
    if (directory == null) return null;
    final journal = File(path_lib.join(directory.path, fileName));
    final type = await FileSystemEntity.type(journal.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw const PrivacyWipeJournalCorruptException(
        'Journal is not a regular file.',
      );
    }

    try {
      final length = await journal.length();
      if (length <= 0 || length > _maximumJournalBytes) {
        throw const PrivacyWipeJournalCorruptException(
          'Journal size is invalid.',
        );
      }
      final decoded = jsonDecode(await journal.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const PrivacyWipeJournalCorruptException(
          'Journal root is invalid.',
        );
      }
      if (decoded.length != _expectedKeys.length ||
          !_expectedKeys.every(decoded.containsKey)) {
        throw const PrivacyWipeJournalCorruptException(
          'Journal fields are invalid.',
        );
      }

      final version = decoded['version'];
      final stageName = decoded['stage'];
      final updatedAt = decoded['updatedAtEpochMs'];
      final checksum = decoded['checksum'];
      if (version is! int || version != journalVersion) {
        throw const PrivacyWipeJournalCorruptException(
          'Journal version is unsupported.',
        );
      }
      if (stageName is! String ||
          updatedAt is! int ||
          updatedAt <= 0 ||
          checksum is! String ||
          checksum.length != 64) {
        throw const PrivacyWipeJournalCorruptException(
          'Journal values are invalid.',
        );
      }
      final stage = PrivacyWipeJournalStage.fromWireName(stageName);
      if (checksum != _checksum(version, stageName, updatedAt)) {
        throw const PrivacyWipeJournalCorruptException(
          'Journal checksum does not match.',
        );
      }
      return PrivacyWipeJournalEntry(
        version: version,
        stage: stage,
        updatedAtEpochMs: updatedAt,
        checksum: checksum,
      );
    } on PrivacyWipeJournalCorruptException {
      rethrow;
    } on Object {
      throw const PrivacyWipeJournalCorruptException(
        'Journal cannot be decoded.',
      );
    }
  }

  @override
  Future<void> write(PrivacyWipeJournalEntry entry) async {
    _validateEntry(entry);
    final directory = (await _resolveJournalDirectory(create: true))!;
    final journal = File(path_lib.join(directory.path, fileName));
    final temporary = File(path_lib.join(directory.path, _temporaryFileName));
    await _requireRegularOrMissing(journal.path);
    await _requireRegularOrMissing(temporary.path);

    final payload = jsonEncode({
      'version': entry.version,
      'stage': entry.stage.wireName,
      'updatedAtEpochMs': entry.updatedAtEpochMs,
      'checksum': entry.checksum,
    });
    await temporary.writeAsString(payload, flush: true);
    // Same-directory rename is atomic on the supported iOS/Android filesystems.
    // If the process dies before this point, the previous safe boundary remains.
    await temporary.rename(journal.path);
  }

  @override
  Future<void> delete() async {
    final directory = await _resolveJournalDirectory(create: false);
    if (directory == null) return;
    final journal = File(path_lib.join(directory.path, fileName));
    final type = await FileSystemEntity.type(journal.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return;
    if (type != FileSystemEntityType.file) {
      throw const PrivacyWipeJournalCorruptException(
        'Journal is not a regular file.',
      );
    }
    await journal.delete();
  }

  Future<Directory?> _resolveJournalDirectory({required bool create}) async {
    final rawRoot = await _supportDirectoryResolver();
    if (rawRoot.trim().isEmpty || !path_lib.isAbsolute(rawRoot)) {
      throw FileSystemException('Invalid application support root', rawRoot);
    }
    final rootPath = path_lib.normalize(rawRoot);
    var rootType = await FileSystemEntity.type(rootPath, followLinks: false);
    if (rootType == FileSystemEntityType.notFound && create) {
      await Directory(rootPath).create(recursive: true);
      rootType = await FileSystemEntity.type(rootPath, followLinks: false);
    }
    if (rootType == FileSystemEntityType.notFound) return null;
    if (rootType != FileSystemEntityType.directory) {
      throw FileSystemException('Untrusted application support root', rootPath);
    }

    final directoryPath = path_lib.normalize(
      path_lib.join(rootPath, directoryName),
    );
    if (!path_lib.isWithin(rootPath, directoryPath)) {
      throw FileSystemException('Journal escaped application support root');
    }
    var directoryType = await FileSystemEntity.type(
      directoryPath,
      followLinks: false,
    );
    if (directoryType == FileSystemEntityType.notFound && create) {
      await Directory(directoryPath).create();
      directoryType = await FileSystemEntity.type(
        directoryPath,
        followLinks: false,
      );
    }
    if (directoryType == FileSystemEntityType.notFound) return null;
    if (directoryType != FileSystemEntityType.directory) {
      throw FileSystemException('Untrusted privacy journal directory');
    }
    return Directory(directoryPath);
  }

  Future<void> _requireRegularOrMissing(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw FileSystemException('Untrusted privacy journal entity', path);
    }
  }

  void _validateEntry(PrivacyWipeJournalEntry entry) {
    if (entry.version != journalVersion ||
        entry.updatedAtEpochMs <= 0 ||
        entry.checksum !=
            _checksum(
              entry.version,
              entry.stage.wireName,
              entry.updatedAtEpochMs,
            )) {
      throw const PrivacyWipeJournalCorruptException(
        'Refusing to persist an invalid journal entry.',
      );
    }
  }

  static String _checksum(int version, String stage, int updatedAt) =>
      sha256.convert(utf8.encode('$version|$stage|$updatedAt')).toString();
}

import 'dart:io';

import 'package:path/path.dart' as path_lib;

typedef UserDataDirectoryResolver = Future<String> Function();

/// Deletes only directories whose ownership is established by Happy Pocket.
///
/// Current shipped user-image roots:
/// - Documents/avatars: local profile and received member avatars.
/// - Documents/homepocket_backup_YYYY-MM-DD.hpb: backups written to the app's
///   default output directory.
/// - Application Support/family_sync/avatar_semantic_staging: immutable
///   outbound Avatar semantic blobs.
///
/// Receipt-photo storage has not shipped; when it does, its explicit owned
/// root must be added here and to the coverage tests. Picker source paths,
/// backups written to caller-selected directories, and unrelated files are
/// never traversed.
class AppOwnedUserFilesCleaner {
  AppOwnedUserFilesCleaner({
    required UserDataDirectoryResolver documentsDirectoryResolver,
    required UserDataDirectoryResolver supportDirectoryResolver,
  }) : _documentsDirectoryResolver = documentsDirectoryResolver,
       _supportDirectoryResolver = supportDirectoryResolver;

  final UserDataDirectoryResolver _documentsDirectoryResolver;
  final UserDataDirectoryResolver _supportDirectoryResolver;

  static final RegExp _generatedBackupName = RegExp(
    r'^homepocket_backup_\d{4}-\d{2}-\d{2}\.hpb$',
  );

  Future<void> clear() async {
    final documentsRoot = await _validateTrustedRoot(
      await _documentsDirectoryResolver(),
    );
    final supportRoot = await _validateTrustedRoot(
      await _supportDirectoryResolver(),
    );

    if (documentsRoot != null) {
      await _deleteOwnedSubtree(documentsRoot, const ['avatars']);
      await _deleteGeneratedBackups(documentsRoot);
    }
    if (supportRoot != null) {
      await _deleteOwnedSubtree(supportRoot, const [
        'family_sync',
        'avatar_semantic_staging',
      ]);
    }
  }

  Future<String?> _validateTrustedRoot(String rawRoot) async {
    if (rawRoot.trim().isEmpty || !path_lib.isAbsolute(rawRoot)) {
      throw FileSystemException('Invalid app storage root', rawRoot);
    }
    final root = path_lib.normalize(rawRoot);
    final rootType = await FileSystemEntity.type(root, followLinks: false);
    if (rootType == FileSystemEntityType.notFound) return null;
    if (rootType != FileSystemEntityType.directory) {
      throw FileSystemException('Untrusted app storage root', root);
    }
    return root;
  }

  Future<void> _deleteOwnedSubtree(String root, List<String> segments) async {
    var current = root;
    for (var index = 0; index < segments.length; index++) {
      final segment = segments[index];
      if (segment.isEmpty ||
          segment == '.' ||
          segment == '..' ||
          path_lib.basename(segment) != segment) {
        throw FileSystemException('Invalid owned storage segment', segment);
      }
      current = path_lib.normalize(path_lib.join(current, segment));
      if (!path_lib.isWithin(root, current)) {
        throw FileSystemException('Owned storage escaped its root', current);
      }
      if (index == segments.length - 1) break;
      final type = await FileSystemEntity.type(current, followLinks: false);
      if (type == FileSystemEntityType.notFound) return;
      if (type != FileSystemEntityType.directory) {
        throw FileSystemException('Untrusted owned storage ancestor', current);
      }
    }

    await _deleteEntityWithoutFollowingLinks(current);
  }

  Future<void> _deleteGeneratedBackups(String documentsRoot) async {
    await for (final entity in Directory(
      documentsRoot,
    ).list(followLinks: false)) {
      if (!_generatedBackupName.hasMatch(path_lib.basename(entity.path))) {
        continue;
      }
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type == FileSystemEntityType.file) {
        await File(entity.path).delete();
      } else if (type == FileSystemEntityType.link) {
        await Link(entity.path).delete();
      } else {
        throw FileSystemException(
          'Unexpected generated backup entity',
          entity.path,
        );
      }
    }
  }

  Future<void> _deleteEntityWithoutFollowingLinks(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    switch (type) {
      case FileSystemEntityType.notFound:
        return;
      case FileSystemEntityType.file:
        await File(path).delete();
      case FileSystemEntityType.link:
        await Link(path).delete();
      case FileSystemEntityType.directory:
        final directory = Directory(path);
        await for (final child in directory.list(followLinks: false)) {
          await _deleteEntityWithoutFollowingLinks(child.path);
        }
        await directory.delete();
      default:
        throw FileSystemException('Unsupported filesystem entity', path);
    }
  }
}

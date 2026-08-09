import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:path/path.dart' as path_lib;

import 'avatar_mime_type.dart';

typedef AvatarStagingRootDirectoryResolver = Future<String> Function();

class AvatarSemanticStagingException implements Exception {
  const AvatarSemanticStagingException({
    required this.code,
    required this.isPermanent,
  });

  final String code;
  final bool isPermanent;

  @override
  String toString() => 'AvatarSemanticStagingException: $code';
}

class AvatarStagedBlob {
  const AvatarStagedBlob({
    required this.key,
    required this.path,
    required this.contentHash,
    required this.mimeType,
    required this.byteLength,
    required this.wasCreated,
  });

  final String key;
  final String path;
  final String contentHash;
  final String mimeType;
  final int byteLength;
  final bool wasCreated;
}

class AvatarMaterializedBlob {
  const AvatarMaterializedBlob({
    required this.bytes,
    required this.contentHash,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String contentHash;
  final String mimeType;
}

class AvatarStagingGarbageCollectionResult {
  const AvatarStagingGarbageCollectionResult({
    required this.deletedCount,
    required this.remainingFileCount,
    required this.remainingBytes,
  });

  final int deletedCount;
  final int remainingFileCount;
  final int remainingBytes;
}

/// App-owned immutable storage for outbound Avatar semantics.
///
/// SQLCipher outbox rows persist only the relative [AvatarStagedBlob.key].
/// Neither external picker paths nor image bytes are written to the outbox.
class AvatarSemanticStagingStore {
  AvatarSemanticStagingStore({
    required this._rootDirectoryResolver,
    this.orphanRetention = const Duration(days: 7),
    this.maxStoredFiles = 16,
    this.maxStoredBytes = maxBlobBytes * 8,
  }) : assert(maxStoredFiles > 0),
       assert(maxStoredBytes >= maxBlobBytes);

  static const maxBlobBytes = 768 * 1024;
  static final _blobKeyPattern = RegExp(r'^[0-9a-f]{64}\.(jpg|png|webp)$');
  static final _hashPattern = RegExp(r'^[0-9a-f]{64}$');
  static const _extensionByMime = <String, String>{
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  final AvatarStagingRootDirectoryResolver _rootDirectoryResolver;
  final Duration orphanRetention;
  final int maxStoredFiles;
  final int maxStoredBytes;
  Future<void> _referenceBarrier = Future.value();

  /// Serializes a mutation that can create a blob or change its durable
  /// references with garbage collection over the same store instance.
  Future<T> runReferenceCriticalSection<T>(Future<T> Function() action) {
    final previous = _referenceBarrier;
    final released = Completer<void>();
    _referenceBarrier = released.future;
    return () async {
      await previous;
      try {
        return await action();
      } finally {
        released.complete();
      }
    }();
  }

  Future<AvatarStagedBlob> stageSource(String sourcePath) async {
    final source = File(sourcePath);
    final sourceType = await _entityType(source.path);
    if (sourceType == FileSystemEntityType.notFound) {
      throw const AvatarSemanticStagingException(
        code: 'source_missing',
        isPermanent: true,
      );
    }
    if (sourceType != FileSystemEntityType.file) {
      throw const AvatarSemanticStagingException(
        code: 'source_not_regular_file',
        isPermanent: true,
      );
    }

    final bytes = await _readBounded(source, source: true);
    final mimeType = detectAvatarMimeType(bytes);
    if (mimeType == null) {
      throw const AvatarSemanticStagingException(
        code: 'unsupported_type',
        isPermanent: true,
      );
    }
    final contentHash = hash_lib.sha256.convert(bytes).toString();
    final key = '$contentHash.${_extensionByMime[mimeType]}';
    final managedSourceKey = await keyForManagedPath(source.path);
    if (managedSourceKey != null && managedSourceKey != key) {
      throw const AvatarSemanticStagingException(
        code: 'managed_source_integrity_mismatch',
        isPermanent: true,
      );
    }
    final destination = await _resolveBlobFile(key, createRoot: true);

    if (await destination.exists()) {
      await materialize(blobKey: key, expectedHash: contentHash);
      return AvatarStagedBlob(
        key: key,
        path: destination.path,
        contentHash: contentHash,
        mimeType: mimeType,
        byteLength: bytes.length,
        wasCreated: false,
      );
    }

    final root = destination.parent;
    final temporary = File(
      path_lib.join(
        root.path,
        '.$contentHash.${DateTime.now().toUtc().microsecondsSinceEpoch}.tmp',
      ),
    );
    var wasCreated = false;
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      final written = await _readBounded(temporary, source: false);
      if (hash_lib.sha256.convert(written).toString() != contentHash) {
        throw const AvatarSemanticStagingException(
          code: 'staging_write_mismatch',
          isPermanent: false,
        );
      }
      try {
        await temporary.rename(destination.path);
        wasCreated = true;
      } on FileSystemException {
        if (!await destination.exists()) rethrow;
      }
      await materialize(blobKey: key, expectedHash: contentHash);
    } on AvatarSemanticStagingException {
      rethrow;
    } on FileSystemException {
      throw const AvatarSemanticStagingException(
        code: 'staging_io_failure',
        isPermanent: false,
      );
    } finally {
      await _deleteBestEffort(temporary);
    }

    return AvatarStagedBlob(
      key: key,
      path: destination.path,
      contentHash: contentHash,
      mimeType: mimeType,
      byteLength: bytes.length,
      wasCreated: wasCreated,
    );
  }

  Future<AvatarMaterializedBlob> materialize({
    required String blobKey,
    required String expectedHash,
  }) async {
    if (!_hashPattern.hasMatch(expectedHash) ||
        !_blobKeyPattern.hasMatch(blobKey) ||
        !blobKey.startsWith('$expectedHash.')) {
      throw const AvatarSemanticStagingException(
        code: 'hash_mismatch',
        isPermanent: true,
      );
    }
    final file = await _resolveBlobFile(blobKey);
    final type = await _entityType(file.path);
    if (type == FileSystemEntityType.notFound) {
      throw const AvatarSemanticStagingException(
        code: 'blob_missing',
        isPermanent: true,
      );
    }
    if (type != FileSystemEntityType.file) {
      throw const AvatarSemanticStagingException(
        code: 'blob_not_regular_file',
        isPermanent: true,
      );
    }

    final bytes = await _readBounded(file, source: false);
    final mimeType = detectAvatarMimeType(bytes);
    final extension = mimeType == null ? null : _extensionByMime[mimeType];
    final actualHash = hash_lib.sha256.convert(bytes).toString();
    if (extension == null ||
        !blobKey.endsWith('.$extension') ||
        actualHash != expectedHash) {
      throw const AvatarSemanticStagingException(
        code: 'blob_integrity_mismatch',
        isPermanent: true,
      );
    }
    return AvatarMaterializedBlob(
      bytes: bytes,
      contentHash: actualHash,
      mimeType: mimeType!,
    );
  }

  Future<String?> keyForManagedPath(String? candidatePath) async {
    if (candidatePath == null || candidatePath.isEmpty) return null;
    final root = await _normalizedRoot(create: false);
    final candidate = path_lib.normalize(path_lib.absolute(candidatePath));
    if (!path_lib.isWithin(root, candidate)) return null;
    final key = path_lib.basename(candidate);
    return _blobKeyPattern.hasMatch(key) ? key : null;
  }

  /// Removes one newly-created blob only when the caller's current durable
  /// reference snapshot does not retain it. The locator is resolved inside the
  /// app-owned root and links or other non-regular entities are never followed.
  Future<bool> deleteBlobIfUnreferenced({
    required String blobKey,
    required Set<String> retainedBlobKeys,
  }) async {
    if (retainedBlobKeys.contains(blobKey)) return false;
    final file = await _resolveBlobFile(blobKey);
    if (await _entityType(file.path) != FileSystemEntityType.file) return false;
    return _deleteBestEffort(file);
  }

  Future<AvatarStagingGarbageCollectionResult> garbageCollect({
    required Set<String> retainedBlobKeys,
    DateTime? now,
  }) async {
    final rootPath = await _normalizedRoot(create: false);
    final root = Directory(rootPath);
    if (!await root.exists()) {
      return const AvatarStagingGarbageCollectionResult(
        deletedCount: 0,
        remainingFileCount: 0,
        remainingBytes: 0,
      );
    }
    final clock = (now ?? DateTime.now()).toUtc();
    final records = <_StagedFileRecord>[];
    await for (final entity in root.list(followLinks: false)) {
      final type = await _entityType(entity.path);
      if (type != FileSystemEntityType.file) {
        if (type == FileSystemEntityType.link) {
          await _deleteBestEffort(File(entity.path));
        }
        continue;
      }
      try {
        final stat = await entity.stat();
        records.add(
          _StagedFileRecord(
            file: File(entity.path),
            key: path_lib.basename(entity.path),
            bytes: stat.size,
            modifiedAt: stat.modified.toUtc(),
          ),
        );
      } on FileSystemException {
        // A transient stat race is retried by a later maintenance pass.
      }
    }

    var remainingCount = records.length;
    var remainingBytes = records.fold<int>(0, (sum, row) => sum + row.bytes);
    var deletedCount = 0;
    records.sort((a, b) => a.modifiedAt.compareTo(b.modifiedAt));
    for (final record in records) {
      if (retainedBlobKeys.contains(record.key)) continue;
      final expired = clock.difference(record.modifiedAt) >= orphanRetention;
      final overQuota =
          remainingCount > maxStoredFiles || remainingBytes > maxStoredBytes;
      if (!expired && !overQuota) continue;
      if (await _deleteBestEffort(record.file)) {
        deletedCount++;
        remainingCount--;
        remainingBytes -= record.bytes;
      }
    }
    return AvatarStagingGarbageCollectionResult(
      deletedCount: deletedCount,
      remainingFileCount: remainingCount,
      remainingBytes: remainingBytes,
    );
  }

  Future<File> _resolveBlobFile(String key, {bool createRoot = false}) async {
    if (!_blobKeyPattern.hasMatch(key) || path_lib.basename(key) != key) {
      throw const AvatarSemanticStagingException(
        code: 'invalid_blob_locator',
        isPermanent: true,
      );
    }
    final root = await _normalizedRoot(create: createRoot);
    final candidate = path_lib.normalize(
      path_lib.absolute(path_lib.join(root, key)),
    );
    if (!path_lib.isWithin(root, candidate)) {
      throw const AvatarSemanticStagingException(
        code: 'invalid_blob_locator',
        isPermanent: true,
      );
    }
    return File(candidate);
  }

  Future<String> _normalizedRoot({required bool create}) async {
    final raw = await _rootDirectoryResolver();
    final normalized = path_lib.normalize(path_lib.absolute(raw));
    if (create) await Directory(normalized).create(recursive: true);
    return normalized;
  }

  Future<Uint8List> _readBounded(File file, {required bool source}) async {
    try {
      final length = await file.length();
      if (length <= 0 || length > maxBlobBytes) {
        throw const AvatarSemanticStagingException(
          code: 'invalid_size',
          isPermanent: true,
        );
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in file.openRead(0, maxBlobBytes + 1)) {
        builder.add(chunk);
        if (builder.length > maxBlobBytes) {
          throw const AvatarSemanticStagingException(
            code: 'invalid_size',
            isPermanent: true,
          );
        }
      }
      final bytes = builder.takeBytes();
      if (bytes.length != length) {
        throw AvatarSemanticStagingException(
          code: source
              ? 'source_changed_during_read'
              : 'blob_changed_during_read',
          isPermanent: false,
        );
      }
      return bytes;
    } on AvatarSemanticStagingException {
      rethrow;
    } on FileSystemException {
      throw AvatarSemanticStagingException(
        code: source ? 'source_io_failure' : 'blob_io_failure',
        isPermanent: false,
      );
    }
  }

  Future<FileSystemEntityType> _entityType(String path) async {
    try {
      return await FileSystemEntity.type(path, followLinks: false);
    } on FileSystemException {
      throw const AvatarSemanticStagingException(
        code: 'filesystem_io_failure',
        isPermanent: false,
      );
    }
  }

  Future<bool> _deleteBestEffort(File file) async {
    try {
      if (await FileSystemEntity.type(file.path, followLinks: false) ==
          FileSystemEntityType.notFound) {
        return false;
      }
      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _StagedFileRecord {
  const _StagedFileRecord({
    required this.file,
    required this.key,
    required this.bytes,
    required this.modifiedAt,
  });

  final File file;
  final String key;
  final int bytes;
  final DateTime modifiedAt;
}

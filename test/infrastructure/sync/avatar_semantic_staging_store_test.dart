import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/avatar_semantic_staging_store.dart';

const _pngA = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1];
const _pngB = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 2];

void main() {
  late Directory sandbox;
  late Directory stagingRoot;
  late AvatarSemanticStagingStore store;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('avatar-semantic-stage');
    stagingRoot = Directory('${sandbox.path}/support');
    store = AvatarSemanticStagingStore(
      rootDirectoryResolver: () async => stagingRoot.path,
    );
  });

  tearDown(() => sandbox.delete(recursive: true));

  test('stages immutable content and survives a reconstructed store', () async {
    final source = File('${sandbox.path}/picked.png');
    await source.writeAsBytes(_pngA);

    final staged = await store.stageSource(source.path);
    expect(staged.wasCreated, isTrue);
    expect(staged.key, matches(RegExp(r'^[0-9a-f]{64}\.png$')));
    expect(staged.path, isNot(source.path));
    expect(await store.keyForManagedPath(staged.path), staged.key);

    await source.writeAsBytes(_pngB);
    final restarted = AvatarSemanticStagingStore(
      rootDirectoryResolver: () async => stagingRoot.path,
    );
    final duplicateSource = File('${sandbox.path}/picked-again.png');
    await duplicateSource.writeAsBytes(_pngA);
    expect(
      (await restarted.stageSource(duplicateSource.path)).wasCreated,
      false,
    );
    final materialized = await restarted.materialize(
      blobKey: staged.key,
      expectedHash: staged.contentHash,
    );
    expect(materialized.bytes, _pngA);
    expect(materialized.mimeType, 'image/png');
  });

  test('missing corrupt and hash-mismatched blobs fail permanently', () async {
    final source = File('${sandbox.path}/picked.png');
    await source.writeAsBytes(_pngA);
    var staged = await store.stageSource(source.path);

    await File(staged.path).delete();
    await expectLater(
      store.materialize(blobKey: staged.key, expectedHash: staged.contentHash),
      throwsA(
        isA<AvatarSemanticStagingException>()
            .having((error) => error.isPermanent, 'permanent', isTrue)
            .having((error) => error.code, 'code', 'blob_missing'),
      ),
    );

    staged = await store.stageSource(source.path);
    await File(staged.path).writeAsBytes(_pngB);
    await expectLater(
      store.materialize(blobKey: staged.key, expectedHash: staged.contentHash),
      throwsA(
        isA<AvatarSemanticStagingException>().having(
          (error) => error.isPermanent,
          'permanent',
          isTrue,
        ),
      ),
    );
    await expectLater(
      store.stageSource(staged.path),
      throwsA(
        isA<AvatarSemanticStagingException>().having(
          (error) => error.code,
          'code',
          'managed_source_integrity_mismatch',
        ),
      ),
    );

    await File(staged.path).delete();
    await source.writeAsBytes(_pngA);
    staged = await store.stageSource(source.path);
    await expectLater(
      store.materialize(blobKey: staged.key, expectedHash: '0' * 64),
      throwsA(
        isA<AvatarSemanticStagingException>().having(
          (error) => error.code,
          'code',
          'hash_mismatch',
        ),
      ),
    );
  });

  test('rejects unsupported and oversized source files', () async {
    final unsupported = File('${sandbox.path}/avatar.txt');
    await unsupported.writeAsBytes(List<int>.filled(32, 1));
    await expectLater(
      store.stageSource(unsupported.path),
      throwsA(
        isA<AvatarSemanticStagingException>().having(
          (error) => error.code,
          'code',
          'unsupported_type',
        ),
      ),
    );

    final oversized = File('${sandbox.path}/oversized.png');
    await oversized.writeAsBytes([
      ..._pngA,
      ...List<int>.filled(AvatarSemanticStagingStore.maxBlobBytes, 0),
    ]);
    await expectLater(
      store.stageSource(oversized.path),
      throwsA(
        isA<AvatarSemanticStagingException>().having(
          (error) => error.code,
          'code',
          'invalid_size',
        ),
      ),
    );
  });

  test(
    'rejects traversal locators and never follows managed symlinks',
    () async {
      final outside = File('${sandbox.path}/outside.png');
      await outside.writeAsBytes(_pngA);
      final key = '${'0' * 64}.png';
      await stagingRoot.create(recursive: true);
      final link = Link('${stagingRoot.path}/$key');
      await link.create(outside.path);

      await expectLater(
        store.materialize(blobKey: '../$key', expectedHash: '0' * 64),
        throwsA(
          isA<AvatarSemanticStagingException>().having(
            (error) => error.code,
            'code',
            'hash_mismatch',
          ),
        ),
      );
      await expectLater(
        store.stageSource(link.path),
        throwsA(
          isA<AvatarSemanticStagingException>().having(
            (error) => error.code,
            'code',
            'source_not_regular_file',
          ),
        ),
      );
      await expectLater(
        store.materialize(blobKey: key, expectedHash: '0' * 64),
        throwsA(
          isA<AvatarSemanticStagingException>().having(
            (error) => error.code,
            'code',
            'blob_not_regular_file',
          ),
        ),
      );

      await store.garbageCollect(retainedBlobKeys: {key});
      expect(await link.exists(), isFalse);
      expect(await outside.exists(), isTrue);
    },
  );

  test(
    'garbage collection retains current content and bounds orphans',
    () async {
      final boundedStore = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => stagingRoot.path,
        orphanRetention: Duration.zero,
        maxStoredFiles: 2,
        maxStoredBytes: AvatarSemanticStagingStore.maxBlobBytes * 2,
      );
      final staged = <AvatarStagedBlob>[];
      for (var index = 1; index <= 3; index++) {
        final source = File('${sandbox.path}/avatar-$index.png');
        await source.writeAsBytes([..._pngA, index]);
        staged.add(await boundedStore.stageSource(source.path));
      }

      final result = await boundedStore.garbageCollect(
        retainedBlobKeys: {staged.last.key},
        now: DateTime.now().toUtc().add(const Duration(seconds: 1)),
      );

      expect(result.deletedCount, 2);
      expect(await File(staged.last.path).exists(), isTrue);
      expect(
        await stagingRoot.list().where((entry) => entry is File).length,
        1,
      );
    },
  );
}

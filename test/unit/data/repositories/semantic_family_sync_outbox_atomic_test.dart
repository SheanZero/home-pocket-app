import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/avatar_semantic_staging_maintenance.dart';
import 'package:home_pocket/application/family_sync/drain_family_sync_outbox_use_case.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/profile_sync_operation_mapper.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/application/profile/save_user_profile_use_case.dart';
import 'package:home_pocket/application/shopping_list/create_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/clear_completed_items_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/family_sync_outbox_dao.dart';
import 'package:home_pocket/data/daos/shopping_item_dao.dart';
import 'package:home_pocket/data/daos/user_profile_dao.dart';
import 'package:home_pocket/data/repositories/family_sync_outbox_repository_impl.dart';
import 'package:home_pocket/data/repositories/shopping_item_repository_impl.dart';
import 'package:home_pocket/data/repositories/user_profile_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/avatar_semantic_staging_store.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _Encryption extends Mock implements FieldEncryptionService {}

class _GroupRepository extends Mock implements GroupRepository {}

class _KeyManager extends Mock implements KeyManager {}

class _PushSync extends Mock implements PushSyncUseCase {}

Future<void> _activate(AppDatabase database) => database.customStatement(
  '''INSERT INTO groups (group_id, status, role, created_at)
     VALUES ('group-a', 'active', 'owner', ?)''',
  [DateTime.now().millisecondsSinceEpoch],
);

void main() {
  late AppDatabase database;
  late _Encryption encryption;

  setUp(() async {
    database = AppDatabase.forTesting();
    encryption = _Encryption();
    when(() => encryption.encryptField(any())).thenAnswer(
      (call) async => 'encrypted:${call.positionalArguments.single}',
    );
    when(
      () => encryption.decryptField(any()),
    ).thenAnswer((call) async => call.positionalArguments.single as String);
    await _activate(database);
  });

  tearDown(() => database.close());

  test('real public shopping create commits row and semantic outbox', () async {
    final repository = ShoppingItemRepositoryImpl(
      dao: ShoppingItemDao(database),
      encryptionService: encryption,
    );
    final result =
        await CreateShoppingItemUseCase(
          shoppingItemRepository: repository,
          deviceIdResolver: () async => 'device-a',
        ).execute(
          const CreateShoppingItemParams(
            deviceId: 'device-a',
            listType: 'public',
            name: 'milk',
          ),
        );

    expect(result.isSuccess, isTrue);
    final saved = result.data!;
    expect(saved.syncRevision, greaterThan(0));
    final pending = await FamilySyncOutboxRepositoryImpl(
      dao: FamilySyncOutboxDao(database),
    ).getPendingForGroup('group-a');
    expect(pending, hasLength(1));
    expect(pending.single.entityId, saved.id);
    expect(pending.single.operation['data']['name'], 'milk');
  });

  test('shopping outbox failure rolls the business row back', () async {
    await database.customStatement('''
      CREATE TRIGGER fail_shopping_outbox
      BEFORE INSERT ON family_sync_outbox
      BEGIN SELECT RAISE(ABORT, 'forced outbox failure'); END
    ''');
    final repository = ShoppingItemRepositoryImpl(
      dao: ShoppingItemDao(database),
      encryptionService: encryption,
    );

    await expectLater(
      CreateShoppingItemUseCase(
        shoppingItemRepository: repository,
        deviceIdResolver: () async => 'device-a',
      ).execute(
        const CreateShoppingItemParams(
          deviceId: 'device-a',
          listType: 'public',
          name: 'rollback me',
        ),
      ),
      throwsA(anything),
    );
    expect(await database.select(database.shoppingItems).get(), isEmpty);
  });

  test(
    'concurrent public updates keep one highest stable semantic version',
    () async {
      final repository = ShoppingItemRepositoryImpl(
        dao: ShoppingItemDao(database),
        encryptionService: encryption,
      );
      final now = DateTime.now();
      final initial = await repository.insertWithFamilySyncOutbox(
        ShoppingItem(
          id: 'concurrent-a',
          deviceId: 'device-a',
          listType: 'public',
          name: 'initial',
          createdAt: now,
        ),
        originDeviceId: 'device-a',
      );

      final updates = await Future.wait([
        repository.updateWithFamilySyncOutbox(
          initial.copyWith(name: 'first', updatedAt: now),
          originDeviceId: 'device-a',
        ),
        repository.updateWithFamilySyncOutbox(
          initial.copyWith(name: 'second', updatedAt: now),
          originDeviceId: 'device-a',
        ),
      ]);
      expect(updates.map((item) => item.syncRevision).toSet(), hasLength(2));
      final finalItem = await repository.findById(initial.id);
      final pending = await FamilySyncOutboxRepositoryImpl(
        dao: FamilySyncOutboxDao(database),
      ).getPendingForGroup('group-a');
      expect(pending, hasLength(1));
      expect(pending.single.revision, finalItem!.syncRevision);
      expect(pending.single.operation['data']['name'], finalItem.name);
    },
  );

  test(
    'real clear-completed commits every tombstone as one atomic batch',
    () async {
      final repository = ShoppingItemRepositoryImpl(
        dao: ShoppingItemDao(database),
        encryptionService: encryption,
      );
      final now = DateTime.now();
      for (final id in ['bulk-a', 'bulk-b']) {
        await repository.insertWithFamilySyncOutbox(
          ShoppingItem(
            id: id,
            deviceId: 'device-a',
            listType: 'public',
            name: id,
            isCompleted: true,
            completedAt: now,
            createdAt: now,
          ),
          originDeviceId: 'device-a',
        );
      }
      final outbox = FamilySyncOutboxRepositoryImpl(
        dao: FamilySyncOutboxDao(database),
      );
      await outbox.clearGroup('group-a');

      final result = await ClearCompletedItemsUseCase(
        shoppingItemRepository: repository,
        deviceIdResolver: () async => 'device-a',
      ).execute('public');
      expect(result.isSuccess, isTrue);
      expect((await repository.findById('bulk-a'))!.isDeleted, isTrue);
      expect((await repository.findById('bulk-b'))!.isDeleted, isTrue);
      final pending = await outbox.getPendingForGroup('group-a');
      expect(pending, hasLength(2));
      expect(pending.every((entry) => entry.isTombstone), isTrue);
    },
  );

  test(
    'real profile save atomically commits profile and two safe semantics',
    () async {
      final repository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );
      final result = await SaveUserProfileUseCase(
        repository,
        deviceIdResolver: () async => 'device-a',
      ).execute(displayName: 'Alice', avatarEmoji: '🐱');

      expect(result.isSuccess, isTrue);
      expect(result.profile!.syncRevision, greaterThan(0));
      final pending = await FamilySyncOutboxRepositoryImpl(
        dao: FamilySyncOutboxDao(database),
      ).getPendingForGroup('group-a');
      expect(
        pending.map((entry) => entry.entityType),
        containsAll(['profile', 'avatar']),
      );
      final avatar = pending.singleWhere(
        (entry) => entry.entityType == 'avatar',
      );
      expect(avatar.operation.toString(), isNot(contains('bytesBase64')));
      expect(avatar.operation.toString(), isNot(contains('avatarImagePath')));
    },
  );

  test('profile outbox failure rolls the Drift profile back', () async {
    await database.customStatement('''
      CREATE TRIGGER fail_profile_outbox
      BEFORE INSERT ON family_sync_outbox
      BEGIN SELECT RAISE(ABORT, 'forced outbox failure'); END
    ''');
    final repository = UserProfileRepositoryImpl(dao: UserProfileDao(database));

    await expectLater(
      SaveUserProfileUseCase(
        repository,
        deviceIdResolver: () async => 'device-a',
      ).execute(displayName: 'Alice', avatarEmoji: '🐱'),
      throwsA(anything),
    );
    expect(await repository.find(), isNull);
  });

  test(
    'failed profile outbox transaction compensates its new staged orphan',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-semantic-rollback-orphan',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/picked.png');
      await source.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        8,
      ]);
      final stagingRoot = Directory('${directory.path}/staging');
      final staging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => stagingRoot.path,
      );
      final repository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );
      await database.customStatement('''
        CREATE TRIGGER fail_avatar_outbox_after_staging
        BEFORE INSERT ON family_sync_outbox
        BEGIN SELECT RAISE(ABORT, 'forced avatar outbox failure'); END
      ''');

      await expectLater(
        SaveUserProfileUseCase(
          repository,
          deviceIdResolver: () async => 'device-a',
          avatarStagingStore: staging,
        ).execute(
          displayName: 'Alice',
          avatarEmoji: '🐱',
          avatarImagePath: source.path,
        ),
        throwsA(anything),
      );

      expect(await repository.find(), isNull);
      expect(await source.exists(), isTrue);
      final restarted = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => stagingRoot.path,
      );
      expect(
        await stagingRoot
            .list(followLinks: false)
            .where((entry) => entry is File)
            .toList(),
        isEmpty,
      );
      expect(
        await restarted.garbageCollect(retainedBlobKeys: const {}),
        isA<AvatarStagingGarbageCollectionResult>(),
      );
    },
  );

  test(
    'failed save never deletes a same-content blob that pre-existed',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-semantic-preexisting-rollback',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/picked.png');
      await source.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        9,
      ]);
      final staging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => '${directory.path}/staging',
      );
      final preexisting = await staging.stageSource(source.path);
      expect(preexisting.wasCreated, isTrue);
      await database.customStatement('''
      CREATE TRIGGER fail_reused_avatar_outbox
      BEFORE INSERT ON family_sync_outbox
      BEGIN SELECT RAISE(ABORT, 'forced reused avatar failure'); END
    ''');
      final repository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );

      await expectLater(
        SaveUserProfileUseCase(
          repository,
          deviceIdResolver: () async => 'device-a',
          avatarStagingStore: staging,
        ).execute(
          displayName: 'Alice',
          avatarEmoji: '🐱',
          avatarImagePath: source.path,
        ),
        throwsA(anything),
      );

      expect(await repository.find(), isNull);
      expect(await File(preexisting.path).exists(), isTrue);
    },
  );

  test(
    'failed compensation is retried by restarted orphan maintenance',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-semantic-compensation-retry',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/picked.png');
      await source.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        12,
      ]);
      final stagingRoot = '${directory.path}/staging';
      final failingStore = _FailOnceDeleteStagingStore(stagingRoot);
      await database.customStatement('''
      CREATE TRIGGER fail_avatar_outbox_for_retry
      BEFORE INSERT ON family_sync_outbox
      BEGIN SELECT RAISE(ABORT, 'forced compensation retry'); END
    ''');
      final repository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );

      await expectLater(
        SaveUserProfileUseCase(
          repository,
          deviceIdResolver: () async => 'device-a',
          avatarStagingStore: failingStore,
        ).execute(
          displayName: 'Alice',
          avatarEmoji: '🐱',
          avatarImagePath: source.path,
        ),
        throwsA(anything),
      );
      expect(failingStore.failedDelete, isTrue);
      final stagedFiles = await Directory(
        stagingRoot,
      ).list(followLinks: false).where((entry) => entry is File).toList();
      expect(stagedFiles, hasLength(1));

      await AvatarSemanticStagingMaintenance(
        stagingStore: AvatarSemanticStagingStore(
          rootDirectoryResolver: () async => stagingRoot,
          orphanRetention: Duration.zero,
        ),
        userProfileRepository: repository,
      ).cleanupCurrentReferences();
      expect(await File(stagedFiles.single.path).exists(), isFalse);
    },
  );

  test(
    'failed save compensation retains a concurrently committed same blob',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-semantic-concurrent-reference',
      );
      addTearDown(() => directory.delete(recursive: true));
      const bytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 10];
      final failingSource = File('${directory.path}/failing-picker.png');
      final successfulSource = File('${directory.path}/successful-picker.png');
      await failingSource.writeAsBytes(bytes);
      await successfulSource.writeAsBytes(bytes);
      final stagingRoot = '${directory.path}/staging';
      final failingStore = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => stagingRoot,
      );
      final successfulStore = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => stagingRoot,
      );
      final delegate = UserProfileRepositoryImpl(dao: UserProfileDao(database));
      final failingRepository = _BlockingDurableProfileRepository(delegate)
        ..blockNextSave = true
        ..failBlockedSave = true;
      final failingSave =
          SaveUserProfileUseCase(
            failingRepository,
            deviceIdResolver: () async => 'device-a',
            avatarStagingStore: failingStore,
          ).execute(
            displayName: 'Failure',
            avatarEmoji: '🐱',
            avatarImagePath: failingSource.path,
          );
      await failingRepository.blockedSaveEntered.future;

      final successful =
          (await SaveUserProfileUseCase(
                delegate,
                deviceIdResolver: () async => 'device-a',
                avatarStagingStore: successfulStore,
              ).execute(
                displayName: 'Winner',
                avatarEmoji: '🐱',
                avatarImagePath: successfulSource.path,
              ))
              .profile!;
      failingRepository.releaseBlockedSave.complete();
      await expectLater(failingSave, throwsStateError);

      expect((await delegate.find())!.id, successful.id);
      expect(await File(successful.avatarImagePath!).exists(), isTrue);
      final avatar =
          (await FamilySyncOutboxRepositoryImpl(
            dao: FamilySyncOutboxDao(database),
          ).getPendingForGroup('group-a')).singleWhere(
            (entry) => entry.entityType == 'avatar',
          );
      expect(
        avatar.operation['avatarBlobKey'],
        await successfulStore.keyForManagedPath(successful.avatarImagePath),
      );
    },
  );

  test('restart maintenance collects a crashed unreferenced blob', () async {
    final directory = await Directory.systemTemp.createTemp(
      'avatar-semantic-crash-restart',
    );
    addTearDown(() => directory.delete(recursive: true));
    final source = File('${directory.path}/picked.png');
    await source.writeAsBytes(const [
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      11,
    ]);
    final stagingRoot = '${directory.path}/staging';
    final crashedStore = AvatarSemanticStagingStore(
      rootDirectoryResolver: () async => stagingRoot,
    );
    final orphan = await crashedStore.stageSource(source.path);
    expect(await File(orphan.path).exists(), isTrue);

    final restartedStore = AvatarSemanticStagingStore(
      rootDirectoryResolver: () async => stagingRoot,
      orphanRetention: Duration.zero,
    );
    await AvatarSemanticStagingMaintenance(
      stagingStore: restartedStore,
      userProfileRepository: UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      ),
    ).cleanupCurrentReferences();

    expect(await File(orphan.path).exists(), isFalse);
  });

  test(
    'photo save persists an immutable safe locator that survives restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-semantic-save',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/picked.png');
      const originalBytes = <int>[
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        7,
      ];
      await source.writeAsBytes(originalBytes);
      final stagingRoot = '${directory.path}/support/avatar-staging';
      final staging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => stagingRoot,
      );
      final repository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );

      final result =
          await SaveUserProfileUseCase(
            repository,
            deviceIdResolver: () async => 'device-a',
            avatarStagingStore: staging,
          ).execute(
            displayName: 'Alice',
            avatarEmoji: '🐱',
            avatarImagePath: source.path,
          );

      expect(result.isSuccess, isTrue);
      expect(result.profile!.avatarImagePath, isNot(source.path));
      expect(
        await staging.keyForManagedPath(result.profile!.avatarImagePath),
        isNotNull,
      );
      final outbox = FamilySyncOutboxRepositoryImpl(
        dao: FamilySyncOutboxDao(database),
      );
      final avatar = (await outbox.getPendingForGroup(
        'group-a',
      )).singleWhere((entry) => entry.entityType == 'avatar');
      expect(avatar.operation['avatarBlobKey'], isNotNull);
      expect(avatar.operation.toString(), isNot(contains(source.path)));
      expect(avatar.operation.toString(), isNot(contains('bytesBase64')));

      await source.writeAsBytes(const [1, 2, 3]);
      final restartedStaging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => stagingRoot,
      );
      final avatarSync = SyncAvatarUseCase(
        pushSync: _PushSync(),
        groupRepository: _GroupRepository(),
        userProfileRepository: repository,
        keyManager: _KeyManager(),
        stagingStore: restartedStaging,
      );
      final materialized = await avatarSync.materializeOutboxOperation(
        avatar.operation,
      );
      expect(materialized['data']['bytesBase64'], isNotNull);
      expect(materialized['data']['byteLength'], originalBytes.length);
    },
  );

  test(
    'same avatar bytes from a new picker path keep the shared managed blob',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-semantic-same-content',
      );
      addTearDown(() => directory.delete(recursive: true));
      const bytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 7];
      final firstSource = File('${directory.path}/picker-a.png');
      final secondSource = File('${directory.path}/picker-b.png');
      await firstSource.writeAsBytes(bytes);
      await secondSource.writeAsBytes(bytes);
      final stagingRoot = '${directory.path}/support/avatar-staging';
      final staging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => stagingRoot,
        orphanRetention: Duration.zero,
      );
      final repository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );
      final save = SaveUserProfileUseCase(
        repository,
        deviceIdResolver: () async => 'device-a',
        avatarStagingStore: staging,
      );
      final first = (await save.execute(
        displayName: 'Alice',
        avatarEmoji: '🐱',
        avatarImagePath: firstSource.path,
      )).profile!;
      final second = (await save.execute(
        id: first.id,
        displayName: 'Alice',
        avatarEmoji: '🐱',
        avatarImagePath: secondSource.path,
        oldAvatarImagePath: first.avatarImagePath,
      )).profile!;

      expect(second.avatarImagePath, first.avatarImagePath);
      expect(await File(second.avatarImagePath!).exists(), isTrue);
      final outbox = FamilySyncOutboxRepositoryImpl(
        dao: FamilySyncOutboxDao(database),
      );
      final pending = await outbox.getPendingForGroup('group-a');
      final avatarEntry = pending.singleWhere(
        (entry) => entry.entityType == 'avatar',
      );
      expect(
        avatarEntry.operation['avatarBlobKey'],
        await staging.keyForManagedPath(second.avatarImagePath),
      );

      final groupRepository = _GroupRepository();
      when(() => groupRepository.getActiveGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-a',
          groupName: 'Family',
          status: GroupStatus.active,
          role: 'owner',
          groupKey: 'key',
          members: const [],
          createdAt: DateTime.utc(2026),
        ),
      );
      final keyManager = _KeyManager();
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-a');
      final push = _PushSync();
      final pushed = <Map<String, dynamic>>[];
      when(
        () => push.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: 'group-a',
          enqueueOnFailure: false,
        ),
      ).thenAnswer((invocation) async {
        pushed.addAll(
          invocation.namedArguments[#operations] as List<Map<String, dynamic>>,
        );
        return PushSyncResult.success(pushed.length);
      });
      final avatarSync = SyncAvatarUseCase(
        pushSync: push,
        groupRepository: groupRepository,
        userProfileRepository: repository,
        keyManager: keyManager,
        stagingStore: AvatarSemanticStagingStore(
          rootDirectoryResolver: () async => stagingRoot,
          orphanRetention: Duration.zero,
        ),
      );
      final drainer = DrainFamilySyncOutboxUseCase(
        outboxRepository: outbox,
        groupRepository: groupRepository,
        pushSync: push,
        operationMaterializer: avatarSync.materializeOutboxOperation,
        onMaterializationFailure: (entry, error) async =>
            await avatarSync.recoverOutboxMaterializationFailure(entry, error)
            ? FamilySyncOutboxFailureDisposition.superseded
            : FamilySyncOutboxFailureDisposition.retry,
        onEntriesSettled: (_) => avatarSync.cleanupStagingAfterSettlement(),
      );

      expect(await drainer.execute(), 2);
      expect(
        pushed.singleWhere(
          (operation) => operation['entityType'] == 'avatar',
        )['data']['removed'],
        isFalse,
      );
      expect(
        (await repository.find())!.avatarImagePath,
        second.avatarImagePath,
      );
    },
  );

  test(
    'different avatar bytes collect the old unreferenced managed blob',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-semantic-replaced-content',
      );
      addTearDown(() => directory.delete(recursive: true));
      final firstSource = File('${directory.path}/picker-a.png');
      final secondSource = File('${directory.path}/picker-b.png');
      await firstSource.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        1,
      ]);
      await secondSource.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        2,
      ]);
      final staging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => '${directory.path}/staging',
        orphanRetention: Duration.zero,
      );
      final repository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );
      final save = SaveUserProfileUseCase(
        repository,
        deviceIdResolver: () async => 'device-a',
        avatarStagingStore: staging,
      );
      final first = (await save.execute(
        displayName: 'Alice',
        avatarEmoji: '🐱',
        avatarImagePath: firstSource.path,
      )).profile!;
      final second = (await save.execute(
        id: first.id,
        displayName: 'Alice',
        avatarEmoji: '🐱',
        avatarImagePath: secondSource.path,
        oldAvatarImagePath: first.avatarImagePath,
      )).profile!;

      expect(second.avatarImagePath, isNot(first.avatarImagePath));
      expect(await File(first.avatarImagePath!).exists(), isFalse);
      expect(await File(second.avatarImagePath!).exists(), isTrue);
      final references = await repository.loadAvatarSemanticReferences();
      expect(references.outboxBlobKeys, {
        await staging.keyForManagedPath(second.avatarImagePath),
      });
    },
  );

  test(
    'cleanup retains every blob referenced only by a pending outbox',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-semantic-outbox-reference',
      );
      addTearDown(() => directory.delete(recursive: true));
      final referencedSource = File('${directory.path}/referenced.png');
      final orphanSource = File('${directory.path}/orphan.png');
      await referencedSource.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        5,
      ]);
      await orphanSource.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        6,
      ]);
      final staging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => '${directory.path}/staging',
        orphanRetention: Duration.zero,
      );
      final referenced = await staging.stageSource(referencedSource.path);
      final orphan = await staging.stageSource(orphanSource.path);
      await FamilySyncOutboxDao(database).upsertOperation(
        groupId: 'group-a',
        operation: {
          'operationId': 'avatar:device-a:1',
          'op': 'update',
          'entityType': 'avatar',
          'entityId': 'device-a',
          'revision': 1,
          'originDeviceId': 'device-a',
          'timestamp': 1,
          'avatarBlobKey': referenced.key,
          'requiresLocalAvatarHydration': true,
          'data': {'avatarContentHash': referenced.contentHash},
        },
      );
      final repository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );

      await AvatarSemanticStagingMaintenance(
        stagingStore: staging,
        userProfileRepository: repository,
      ).cleanupCurrentReferences();

      expect(await File(referenced.path).exists(), isTrue);
      expect(await File(orphan.path).exists(), isFalse);
    },
  );

  test(
    'new save blocks stale cleanup until its durable references commit',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-semantic-concurrent-cleanup',
      );
      addTearDown(() => directory.delete(recursive: true));
      final firstSource = File('${directory.path}/picker-a.png');
      final secondSource = File('${directory.path}/picker-b.png');
      await firstSource.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        3,
      ]);
      await secondSource.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        4,
      ]);
      final staging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => '${directory.path}/staging',
        orphanRetention: Duration.zero,
      );
      final delegate = UserProfileRepositoryImpl(dao: UserProfileDao(database));
      final repository = _BlockingDurableProfileRepository(delegate);
      final save = SaveUserProfileUseCase(
        repository,
        deviceIdResolver: () async => 'device-a',
        avatarStagingStore: staging,
      );
      final first = (await save.execute(
        displayName: 'Alice',
        avatarEmoji: '🐱',
        avatarImagePath: firstSource.path,
      )).profile!;
      repository.blockNextSave = true;

      final newerSave = save.execute(
        id: first.id,
        displayName: 'Alice v2',
        avatarEmoji: '🐱',
        avatarImagePath: secondSource.path,
        oldAvatarImagePath: first.avatarImagePath,
      );
      await repository.blockedSaveEntered.future;
      final staleCleanup = AvatarSemanticStagingMaintenance(
        stagingStore: staging,
        userProfileRepository: repository,
      ).cleanupCurrentReferences();
      await Future<void>.delayed(Duration.zero);
      repository.releaseBlockedSave.complete();

      final second = (await newerSave).profile!;
      await staleCleanup;
      expect(await File(second.avatarImagePath!).exists(), isTrue);
      final outbox = FamilySyncOutboxRepositoryImpl(
        dao: FamilySyncOutboxDao(database),
      );
      final avatar = (await outbox.getPendingForGroup(
        'group-a',
      )).singleWhere((entry) => entry.entityType == 'avatar');
      final avatarSync = SyncAvatarUseCase(
        pushSync: _PushSync(),
        groupRepository: _GroupRepository(),
        userProfileRepository: repository,
        keyManager: _KeyManager(),
        stagingStore: staging,
      );
      expect(
        (await avatarSync.materializeOutboxOperation(
          avatar.operation,
        ))['data']['removed'],
        isFalse,
      );
    },
  );

  test(
    'permanent avatar source failure atomically writes a higher removal',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-semantic-recovery',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/picked.png');
      await source.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        9,
      ]);
      final staging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => '${directory.path}/staging',
      );
      final repository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );
      final saved =
          (await SaveUserProfileUseCase(
                repository,
                deviceIdResolver: () async => 'device-a',
                avatarStagingStore: staging,
              ).execute(
                displayName: 'Alice',
                avatarEmoji: '🐱',
                avatarImagePath: source.path,
              ))
              .profile!;

      final recovered = await repository.supersedeInvalidAvatarWithRemoval(
        expectedRevision: saved.syncRevision,
        expectedOriginDeviceId: saved.syncOriginDeviceId,
        originDeviceId: 'device-a',
        buildOperations: (normalized) =>
            ProfileSyncOperationMapper.buildOperations(
              normalized,
              deviceId: 'device-a',
            ),
      );

      expect(recovered, isNotNull);
      expect(recovered!.avatarImagePath, isNull);
      expect(recovered.syncRevision, greaterThan(saved.syncRevision));
      final pending = await FamilySyncOutboxRepositoryImpl(
        dao: FamilySyncOutboxDao(database),
      ).getPendingForGroup('group-a');
      final avatar = pending.singleWhere(
        (entry) => entry.entityType == 'avatar',
      );
      expect(avatar.revision, recovered.syncRevision);
      expect(avatar.operation['data']['removed'], isTrue);
      expect(avatar.operation['avatarBlobKey'], isNull);

      // A stale failure callback may arrive after a concurrent replacement;
      // it must not bump or remove the newer semantic state again.
      expect(
        await repository.supersedeInvalidAvatarWithRemoval(
          expectedRevision: saved.syncRevision,
          expectedOriginDeviceId: saved.syncOriginDeviceId,
          originDeviceId: 'device-a',
          buildOperations: (normalized) =>
              ProfileSyncOperationMapper.buildOperations(
                normalized,
                deviceId: 'device-a',
              ),
        ),
        isNull,
      );
      expect((await repository.find())!.syncRevision, recovered.syncRevision);
    },
  );

  test(
    'full-sync profile builder recovers a missing blob without blocking',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-full-sync-recovery',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/picked.png');
      await source.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        4,
      ]);
      final staging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => '${directory.path}/staging',
      );
      final repository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );
      final saved =
          (await SaveUserProfileUseCase(
                repository,
                deviceIdResolver: () async => 'device-a',
                avatarStagingStore: staging,
              ).execute(
                displayName: 'Alice',
                avatarEmoji: '🐱',
                avatarImagePath: source.path,
              ))
              .profile!;
      await File(saved.avatarImagePath!).delete();
      final keyManager = _KeyManager();
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-a');
      final push = _PushSync();
      when(
        () => push.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          syncType: 'full',
        ),
      ).thenAnswer((invocation) async {
        final operations =
            invocation.namedArguments[#operations]
                as List<Map<String, dynamic>>;
        return PushSyncResult.success(operations.length);
      });
      final avatarSync = SyncAvatarUseCase(
        pushSync: push,
        groupRepository: _GroupRepository(),
        userProfileRepository: repository,
        keyManager: keyManager,
        stagingStore: AvatarSemanticStagingStore(
          rootDirectoryResolver: () async => '${directory.path}/staging',
        ),
      );

      final fullSync = FullSyncUseCase(
        pushSync: push,
        fetchAllTransactions: () async => [
          {
            'op': 'reconcile',
            'entityType': 'bill',
            'entityId': 'bill-a',
            'revision': 7,
            'originDeviceId': 'device-a',
            'timestamp': 7,
            'data': {'id': 'bill-a', 'syncRevision': 7},
          },
        ],
        fetchAllShoppingOps: () async => [
          {
            'op': 'create',
            'entityType': 'shopping_item',
            'entityId': 'shopping-a',
            'revision': 8,
            'originDeviceId': 'device-a',
            'timestamp': 8,
            'data': {
              'id': 'shopping-a',
              'listType': 'public',
              'syncRevision': 8,
            },
          },
        ],
        fetchAdditionalOperations:
            avatarSync.buildCurrentProfileOperationsForFullSync,
      );

      expect(await fullSync.execute(), 4);
      final operations =
          verify(
                () => push.execute(
                  operations: captureAny(named: 'operations'),
                  vectorClock: any(named: 'vectorClock'),
                  syncType: 'full',
                ),
              ).captured.single
              as List<Map<String, dynamic>>;

      expect(operations.map((operation) => operation['entityType']), [
        'bill',
        'shopping_item',
        'profile',
        'avatar',
      ]);
      final avatar = operations.last;
      expect(avatar['revision'], greaterThan(saved.syncRevision));
      expect(avatar['data']['removed'], isTrue);
      expect(
        avatar.toString(),
        isNot(contains('requiresLocalAvatarHydration')),
      );
      expect((await repository.find())!.avatarImagePath, isNull);
    },
  );

  test(
    'restarted drain isolates corrupt avatar and still sends shopping then removal',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-poison-shopping',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/picked.png');
      await source.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        5,
      ]);
      final stagingRoot = '${directory.path}/staging';
      final staging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => stagingRoot,
      );
      final profileRepository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );
      final saved =
          (await SaveUserProfileUseCase(
                profileRepository,
                deviceIdResolver: () async => 'device-a',
                avatarStagingStore: staging,
              ).execute(
                displayName: 'Alice',
                avatarEmoji: '🐱',
                avatarImagePath: source.path,
              ))
              .profile!;
      await File(
        saved.avatarImagePath!,
      ).writeAsBytes(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 6]);
      final shoppingRepository = ShoppingItemRepositoryImpl(
        dao: ShoppingItemDao(database),
        encryptionService: encryption,
      );
      expect(
        (await CreateShoppingItemUseCase(
              shoppingItemRepository: shoppingRepository,
              deviceIdResolver: () async => 'device-a',
            ).execute(
              const CreateShoppingItemParams(
                deviceId: 'device-a',
                listType: 'public',
                name: 'milk',
              ),
            ))
            .isSuccess,
        isTrue,
      );

      final groupRepository = _GroupRepository();
      when(() => groupRepository.getActiveGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-a',
          groupName: 'Family',
          status: GroupStatus.active,
          role: 'owner',
          groupKey: 'key',
          members: const [],
          createdAt: DateTime.utc(2026),
        ),
      );
      final keyManager = _KeyManager();
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-a');
      final push = _PushSync();
      final batches = <List<String>>[];
      when(
        () => push.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: 'group-a',
          enqueueOnFailure: false,
        ),
      ).thenAnswer((invocation) async {
        final operations =
            invocation.namedArguments[#operations]
                as List<Map<String, dynamic>>;
        batches.add(
          operations
              .map((operation) => operation['entityType'] as String)
              .toList(growable: false),
        );
        return PushSyncResult.success(operations.length);
      });
      final restartedAvatarSync = SyncAvatarUseCase(
        pushSync: push,
        groupRepository: groupRepository,
        userProfileRepository: profileRepository,
        keyManager: keyManager,
        stagingStore: AvatarSemanticStagingStore(
          rootDirectoryResolver: () async => stagingRoot,
        ),
      );
      final outbox = FamilySyncOutboxRepositoryImpl(
        dao: FamilySyncOutboxDao(database),
      );
      final drainer = DrainFamilySyncOutboxUseCase(
        outboxRepository: outbox,
        groupRepository: groupRepository,
        pushSync: push,
        operationMaterializer: restartedAvatarSync.materializeOutboxOperation,
        onMaterializationFailure: (entry, error) async =>
            await restartedAvatarSync.recoverOutboxMaterializationFailure(
              entry,
              error,
            )
            ? FamilySyncOutboxFailureDisposition.superseded
            : FamilySyncOutboxFailureDisposition.retry,
        onEntriesSettled: (_) =>
            restartedAvatarSync.cleanupStagingAfterSettlement(),
      );

      expect(await drainer.execute(), 4);
      expect(batches, hasLength(2));
      expect(batches.first, ['profile', 'shopping_item']);
      expect(batches.last, unorderedEquals(['profile', 'avatar']));
      expect((await profileRepository.find())!.avatarImagePath, isNull);
      expect(await outbox.getPendingForGroup('group-a'), isEmpty);
    },
  );

  test(
    'old avatar ACK cannot settle a concurrently saved newer staged version',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avatar-exact-settlement',
      );
      addTearDown(() => directory.delete(recursive: true));
      final firstSource = File('${directory.path}/first.png');
      final secondSource = File('${directory.path}/second.png');
      await firstSource.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        1,
      ]);
      await secondSource.writeAsBytes(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        2,
      ]);
      final stagingRoot = '${directory.path}/staging';
      final staging = AvatarSemanticStagingStore(
        rootDirectoryResolver: () async => stagingRoot,
      );
      final repository = UserProfileRepositoryImpl(
        dao: UserProfileDao(database),
      );
      final save = SaveUserProfileUseCase(
        repository,
        deviceIdResolver: () async => 'device-a',
        avatarStagingStore: staging,
      );
      final first = (await save.execute(
        displayName: 'Alice',
        avatarEmoji: '🐱',
        avatarImagePath: firstSource.path,
      )).profile!;
      final groupRepository = _GroupRepository();
      when(() => groupRepository.getActiveGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-a',
          groupName: 'Family',
          status: GroupStatus.active,
          role: 'owner',
          groupKey: 'key',
          members: const [],
          createdAt: DateTime.utc(2026),
        ),
      );
      final keyManager = _KeyManager();
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-a');
      final push = _PushSync();
      final firstPushEntered = Completer<void>();
      final releaseFirstPush = Completer<void>();
      final pushedRevisions = <int>[];
      when(
        () => push.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: 'group-a',
          enqueueOnFailure: false,
        ),
      ).thenAnswer((invocation) async {
        final operations =
            invocation.namedArguments[#operations]
                as List<Map<String, dynamic>>;
        pushedRevisions.add((operations.first['revision'] as num).toInt());
        if (!firstPushEntered.isCompleted) {
          firstPushEntered.complete();
          await releaseFirstPush.future;
        }
        return PushSyncResult.success(operations.length);
      });
      final avatarSync = SyncAvatarUseCase(
        pushSync: push,
        groupRepository: groupRepository,
        userProfileRepository: repository,
        keyManager: keyManager,
        stagingStore: staging,
      );
      final drainer = DrainFamilySyncOutboxUseCase(
        outboxRepository: FamilySyncOutboxRepositoryImpl(
          dao: FamilySyncOutboxDao(database),
        ),
        groupRepository: groupRepository,
        pushSync: push,
        operationMaterializer: avatarSync.materializeOutboxOperation,
        onMaterializationFailure: (entry, error) async =>
            await avatarSync.recoverOutboxMaterializationFailure(entry, error)
            ? FamilySyncOutboxFailureDisposition.superseded
            : FamilySyncOutboxFailureDisposition.retry,
        onEntriesSettled: (_) => avatarSync.cleanupStagingAfterSettlement(),
      );

      final oldDrain = drainer.execute();
      await firstPushEntered.future;
      final second = (await save.execute(
        id: first.id,
        displayName: 'Alice v2',
        avatarEmoji: '🐱',
        avatarImagePath: secondSource.path,
      )).profile!;
      releaseFirstPush.complete();
      expect(await oldDrain, 2);

      final outbox = FamilySyncOutboxRepositoryImpl(
        dao: FamilySyncOutboxDao(database),
      );
      final pending = await outbox.getPendingForGroup('group-a');
      expect(pending, hasLength(2));
      expect(
        pending.every((entry) => entry.revision == second.syncRevision),
        isTrue,
      );
      expect(second.syncRevision, greaterThan(first.syncRevision));
      expect(await drainer.execute(), 2);
      expect(await outbox.getPendingForGroup('group-a'), isEmpty);
      expect(pushedRevisions, [first.syncRevision, second.syncRevision]);
    },
  );

  test('avatar hydration fails closed after staged content changes', () async {
    final directory = await Directory.systemTemp.createTemp('avatar-outbox');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/avatar.png');
    await file.writeAsBytes(const [
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      1,
    ]);
    final now = DateTime.now();
    final profile = UserProfile(
      id: 'profile-a',
      displayName: 'Alice',
      avatarEmoji: '🐱',
      avatarImagePath: file.path,
      createdAt: now,
      updatedAt: now,
      syncRevision: 10,
      syncOriginDeviceId: 'device-a',
    );
    final repository = _ProfileMemory(profile);
    final staging = AvatarSemanticStagingStore(
      rootDirectoryResolver: () async => '${directory.path}/staging',
    );
    final staged = await staging.stageSource(file.path);
    final operation = (await ProfileSyncOperationMapper.buildOperations(
      profile,
      deviceId: 'device-a',
      stagedAvatar: staged,
    )).singleWhere((candidate) => candidate['entityType'] == 'avatar');
    await File(
      staged.path,
    ).writeAsBytes(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 2]);
    final avatarSync = SyncAvatarUseCase(
      pushSync: _PushSync(),
      groupRepository: _GroupRepository(),
      userProfileRepository: repository,
      keyManager: _KeyManager(),
      stagingStore: staging,
    );

    await expectLater(
      avatarSync.materializeOutboxOperation(operation),
      throwsA(isA<AvatarSyncValidationException>()),
    );
  });
}

class _ProfileMemory implements UserProfileRepository {
  _ProfileMemory(this.profile);
  UserProfile? profile;

  @override
  Future<void> delete(String id) async => profile = null;
  @override
  Future<UserProfile?> find() async => profile;
  @override
  Future<void> save(UserProfile profile) async => this.profile = profile;
}

class _BlockingDurableProfileRepository
    implements DurableFamilySyncUserProfileRepository {
  _BlockingDurableProfileRepository(this.delegate);

  final DurableFamilySyncUserProfileRepository delegate;
  final blockedSaveEntered = Completer<void>();
  final releaseBlockedSave = Completer<void>();
  bool blockNextSave = false;
  bool failBlockedSave = false;

  @override
  Future<void> delete(String id) => delegate.delete(id);

  @override
  Future<UserProfile?> find() => delegate.find();

  @override
  Future<AvatarSemanticReferencesSnapshot> loadAvatarSemanticReferences() =>
      delegate.loadAvatarSemanticReferences();

  @override
  Future<void> save(UserProfile profile) => delegate.save(profile);

  @override
  Future<UserProfile> saveWithFamilySyncOutbox(
    UserProfile profile, {
    required String originDeviceId,
    required ProfileFamilySyncOperationsFactory buildOperations,
  }) async {
    if (blockNextSave) {
      blockNextSave = false;
      blockedSaveEntered.complete();
      await releaseBlockedSave.future;
      if (failBlockedSave) throw StateError('forced blocked save failure');
    }
    return delegate.saveWithFamilySyncOutbox(
      profile,
      originDeviceId: originDeviceId,
      buildOperations: buildOperations,
    );
  }

  @override
  Future<UserProfile?> supersedeInvalidAvatarWithRemoval({
    required int expectedRevision,
    required String expectedOriginDeviceId,
    required String originDeviceId,
    required ProfileFamilySyncOperationsFactory buildOperations,
  }) => delegate.supersedeInvalidAvatarWithRemoval(
    expectedRevision: expectedRevision,
    expectedOriginDeviceId: expectedOriginDeviceId,
    originDeviceId: originDeviceId,
    buildOperations: buildOperations,
  );
}

class _FailOnceDeleteStagingStore extends AvatarSemanticStagingStore {
  _FailOnceDeleteStagingStore(String root)
    : super(rootDirectoryResolver: () async => root);

  bool failedDelete = false;

  @override
  Future<bool> deleteBlobIfUnreferenced({
    required String blobKey,
    required Set<String> retainedBlobKeys,
  }) {
    if (!failedDelete) {
      failedDelete = true;
      throw FileSystemException('forced compensation delete failure');
    }
    return super.deleteBlobIfUnreferenced(
      blobKey: blobKey,
      retainedBlobKeys: retainedBlobKeys,
    );
  }
}

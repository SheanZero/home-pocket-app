import 'dart:convert';

import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../app_database.dart';
import '../daos/user_profile_dao.dart';
import '../daos/family_sync_outbox_dao.dart';

class UserProfileRepositoryImpl
    implements DurableFamilySyncUserProfileRepository {
  UserProfileRepositoryImpl({required UserProfileDao dao})
    : _dao = dao,
      _outboxDao = FamilySyncOutboxDao(dao.attachedDatabase);

  final UserProfileDao _dao;
  final FamilySyncOutboxDao _outboxDao;

  @override
  Future<UserProfile?> find() async {
    final row = await _dao.find();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<void> save(UserProfile profile) async {
    await _dao.upsert(
      id: profile.id,
      displayName: profile.displayName,
      avatarEmoji: profile.avatarEmoji,
      avatarImagePath: profile.avatarImagePath,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      syncRevision: profile.syncRevision,
      syncOriginDeviceId: profile.syncOriginDeviceId,
    );
  }

  @override
  Future<AvatarSemanticReferencesSnapshot> loadAvatarSemanticReferences() {
    return _dao.attachedDatabase.transaction(() async {
      final profile = await _dao.find();
      final rows = await (_dao.attachedDatabase.select(
        _dao.attachedDatabase.familySyncOutbox,
      )..where((row) => row.entityType.equals('avatar'))).get();
      final keys = <String>{};
      for (final row in rows) {
        try {
          final operation = jsonDecode(row.operationJson);
          if (operation is! Map<String, dynamic>) continue;
          final key = operation['avatarBlobKey'];
          if (key is String && key.isNotEmpty) keys.add(key);
        } on FormatException {
          // A malformed row remains durable for its normal recovery path. It
          // must not make reference discovery or unrelated cleanup fail.
        }
      }
      return AvatarSemanticReferencesSnapshot(
        profileAvatarImagePath: profile?.avatarImagePath,
        outboxBlobKeys: keys,
      );
    });
  }

  @override
  Future<UserProfile> saveWithFamilySyncOutbox(
    UserProfile profile, {
    required String originDeviceId,
    required ProfileFamilySyncOperationsFactory buildOperations,
  }) {
    return _dao.attachedDatabase.transaction(() async {
      final current = await _dao.find();
      final timestampRevision = profile.updatedAt
          .toUtc()
          .microsecondsSinceEpoch;
      final currentRevision = current?.syncRevision ?? profile.syncRevision;
      final revision = timestampRevision > currentRevision
          ? timestampRevision
          : currentRevision + 1;
      final normalized = profile.copyWith(
        syncRevision: revision,
        syncOriginDeviceId: originDeviceId,
      );
      await _writeProfile(normalized);
      await _enqueueActiveGroupOperations(
        normalized,
        originDeviceId: originDeviceId,
        buildOperations: buildOperations,
      );
      return normalized;
    });
  }

  @override
  Future<UserProfile?> supersedeInvalidAvatarWithRemoval({
    required int expectedRevision,
    required String expectedOriginDeviceId,
    required String originDeviceId,
    required ProfileFamilySyncOperationsFactory buildOperations,
  }) {
    return _dao.attachedDatabase.transaction(() async {
      final row = await _dao.find();
      if (row == null) return null;
      final current = _toModel(row);
      final effectiveRevision = current.syncRevision > 0
          ? current.syncRevision
          : current.updatedAt.toUtc().microsecondsSinceEpoch;
      final effectiveOrigin = current.syncOriginDeviceId.isNotEmpty
          ? current.syncOriginDeviceId
          : expectedOriginDeviceId;
      if (effectiveRevision != expectedRevision ||
          effectiveOrigin != expectedOriginDeviceId) {
        return null;
      }

      final now = DateTime.now();
      final timestampRevision = now.toUtc().microsecondsSinceEpoch;
      final revision = timestampRevision > effectiveRevision
          ? timestampRevision
          : effectiveRevision + 1;
      final recovered = current.copyWith(
        avatarImagePath: null,
        updatedAt: now,
        syncRevision: revision,
        syncOriginDeviceId: originDeviceId,
      );
      await _writeProfile(recovered);
      await _enqueueActiveGroupOperations(
        recovered,
        originDeviceId: originDeviceId,
        buildOperations: buildOperations,
      );
      return recovered;
    });
  }

  @override
  Future<void> delete(String id) => _dao.delete(id);

  UserProfile _toModel(UserProfileRow row) => UserProfile(
    id: row.id,
    displayName: row.displayName,
    avatarEmoji: row.avatarEmoji,
    avatarImagePath: row.avatarImagePath,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    syncRevision: row.syncRevision,
    syncOriginDeviceId: row.syncOriginDeviceId,
  );

  Future<void> _writeProfile(UserProfile profile) => _dao.upsert(
    id: profile.id,
    displayName: profile.displayName,
    avatarEmoji: profile.avatarEmoji,
    avatarImagePath: profile.avatarImagePath,
    createdAt: profile.createdAt,
    updatedAt: profile.updatedAt,
    syncRevision: profile.syncRevision,
    syncOriginDeviceId: profile.syncOriginDeviceId,
  );

  Future<void> _enqueueActiveGroupOperations(
    UserProfile profile, {
    required String originDeviceId,
    required ProfileFamilySyncOperationsFactory buildOperations,
  }) async {
    final groups = await (_dao.attachedDatabase.select(
      _dao.attachedDatabase.groups,
    )..where((row) => row.status.equals('active'))).get();
    if (groups.length > 1) {
      throw StateError('Multiple active family groups found');
    }
    if (groups.isEmpty || originDeviceId.isEmpty) return;
    for (final operation in await buildOperations(profile)) {
      await _outboxDao.upsertOperation(
        groupId: groups.single.groupId,
        operation: operation,
      );
    }
  }
}

import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'control_snapshot_digest.dart';
import 'group_operation_error.dart';
import 'membership_rotation_coordinator.dart';

sealed class RefreshGroupSnapshotResult {
  const RefreshGroupSnapshotResult();
}

class RefreshGroupSnapshotApplied extends RefreshGroupSnapshotResult {
  const RefreshGroupSnapshotApplied({required this.groupName});

  final String groupName;

  @override
  bool operator ==(Object other) =>
      other is RefreshGroupSnapshotApplied && other.groupName == groupName;

  @override
  int get hashCode => groupName.hashCode;
}

class RefreshGroupSnapshotIgnored extends RefreshGroupSnapshotResult {
  const RefreshGroupSnapshotIgnored();
}

class RefreshGroupSnapshotFailed extends RefreshGroupSnapshotResult
    implements GroupOperationFailure {
  const RefreshGroupSnapshotFailed(
    this.message, {
    this.statusCode,
    this.kind = GroupOperationErrorKind.general,
  });

  @override
  final String message;
  final int? statusCode;
  @override
  final GroupOperationErrorKind kind;
}

/// An authenticated status response proves this device can no longer use the
/// local family. The caller must route this through authoritative cleanup.
class RefreshGroupSnapshotMembershipInvalid extends RefreshGroupSnapshotResult {
  const RefreshGroupSnapshotMembershipInvalid(
    this.message, {
    this.statusCode = 403,
  });

  final String message;
  final int statusCode;
}

/// Refreshes local control-plane state from the relay's authoritative snapshot.
///
/// Rename notifications are invalidations, not data-plane writes: their
/// payload is deliberately not trusted. A later request generation always wins
/// so duplicated or out-of-order push/WebSocket delivery cannot restore an old
/// name. The event data map remains extensible for a future server revision.
class RefreshGroupSnapshotUseCase {
  RefreshGroupSnapshotUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    required KeyManager keyManager,
    MembershipRotationCoordinator? membershipRotation,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _keyManager = keyManager,
       _membershipRotation = membershipRotation;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final KeyManager _keyManager;
  final MembershipRotationCoordinator? _membershipRotation;
  final _requestGeneration = <String, int>{};

  Future<RefreshGroupSnapshotResult> execute({
    required String groupId,
    Map<String, dynamic>? controlEvent,
    List<Map<String, dynamic>> controlEvents = const [],
  }) async {
    // Allocate at invocation time (before any async boundary), so a later
    // notification always supersedes an earlier one even if local reads are
    // scheduled in a different order.
    final generation = (_requestGeneration[groupId] ?? 0) + 1;
    _requestGeneration[groupId] = generation;

    final preparation = await _prepareRefresh(
      groupId: groupId,
      controlEvent: controlEvent,
      controlEvents: controlEvents,
    );
    if (preparation case _RefreshIgnored()) {
      return const RefreshGroupSnapshotIgnored();
    }
    if (preparation case _RefreshFailed(:final message)) {
      return RefreshGroupSnapshotFailed(message);
    }
    final context = preparation as _RefreshReady;

    try {
      final snapshot = await _fetchSnapshot(groupId);
      if (!_isCurrentRequest(groupId, generation)) {
        return const RefreshGroupSnapshotIgnored();
      }
      final validation = _validateSnapshot(snapshot, context);
      if (validation case _InvalidSnapshot(:final result)) return result;
      if (!await _isCurrentActiveGroup(groupId, generation)) {
        return const RefreshGroupSnapshotIgnored();
      }
      return await _applySnapshot(
        context: context,
        validation: validation as _ValidSnapshot,
        controlEvent: controlEvent,
        controlEvents: controlEvents,
      );
    } on RelayApiException catch (error) {
      if (error.isForbidden || error.isNotFound) {
        return RefreshGroupSnapshotMembershipInvalid(
          error.message,
          statusCode: error.statusCode,
        );
      }
      return RefreshGroupSnapshotFailed(
        error.message,
        statusCode: error.statusCode,
      );
    } on ControlSnapshotConflictException {
      return const RefreshGroupSnapshotFailed(
        'Conflicting authoritative group snapshot revision',
      );
    } catch (error) {
      final failure = groupOperationFailureFrom(
        error,
        fallbackMessage: 'Failed to refresh the group snapshot',
      );
      return RefreshGroupSnapshotFailed(failure.message, kind: failure.kind);
    }
  }

  Future<_RefreshPreparation> _prepareRefresh({
    required String groupId,
    required Map<String, dynamic>? controlEvent,
    required List<Map<String, dynamic>> controlEvents,
  }) async {
    final localGroup = await _groupRepository.getActiveGroup();
    if (localGroup == null || localGroup.groupId != groupId) {
      return const _RefreshIgnored();
    }
    final revisioned = _groupRepository is RevisionedGroupRepository
        ? _groupRepository as RevisionedGroupRepository
        : null;
    final eventId = _nonEmptyString(controlEvent?['eventId']);
    if (controlEvents.isEmpty &&
        eventId != null &&
        revisioned != null &&
        await revisioned.hasProcessedControlEvent(eventId)) {
      return const _RefreshIgnored();
    }
    final deviceId = await _keyManager.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      return const _RefreshFailed('Device identity unavailable');
    }
    return _RefreshReady(
      groupId: groupId,
      deviceId: deviceId,
      eventId: eventId,
      revisionedRepository: revisioned,
    );
  }

  Future<Map<String, dynamic>> _fetchSnapshot(String groupId) async {
    var snapshot = await _apiClient.getGroupStatus(groupId);
    if (await _membershipRotation?.recoverFromSnapshot(snapshot) == true) {
      snapshot = await _apiClient.getGroupStatus(groupId);
    }
    return snapshot;
  }

  bool _isCurrentRequest(String groupId, int generation) =>
      _requestGeneration[groupId] == generation;

  Future<bool> _isCurrentActiveGroup(String groupId, int generation) async {
    // Re-check after the network boundary. The repository update also uses
    // `status = active` in its WHERE clause, closing the remaining race.
    final currentGroup = await _groupRepository.getActiveGroup();
    return _isCurrentRequest(groupId, generation) &&
        currentGroup != null &&
        currentGroup.groupId == groupId;
  }

  _SnapshotValidation _validateSnapshot(
    Map<String, dynamic> snapshot,
    _RefreshReady context,
  ) {
    if (snapshot['groupId'] != context.groupId) {
      return const _InvalidSnapshot(
        RefreshGroupSnapshotFailed(
          'Authoritative group snapshot has a mismatched group id',
        ),
      );
    }
    if (snapshot['status'] != 'active') {
      return const _InvalidSnapshot(
        RefreshGroupSnapshotMembershipInvalid(
          'Group is inactive',
          statusCode: 404,
        ),
      );
    }
    final members = _parseMembers(snapshot['members']);
    final localMember = _memberForDevice(members, context.deviceId);
    if (localMember == null || localMember.status != 'active') {
      return const _InvalidSnapshot(
        RefreshGroupSnapshotMembershipInvalid(
          'Device is no longer an active group member',
        ),
      );
    }
    final keyEpoch = (snapshot['keyEpoch'] as num?)?.toInt();
    if (keyEpoch == null || keyEpoch < 1) {
      return const _InvalidSnapshot(
        RefreshGroupSnapshotFailed(
          'Authoritative group snapshot has an invalid key epoch',
        ),
      );
    }
    final groupName = snapshot['groupName'];
    if (groupName is! String || groupName.trim().isEmpty) {
      return const _InvalidSnapshot(
        RefreshGroupSnapshotFailed(
          'Authoritative group snapshot has an invalid name',
        ),
      );
    }
    return _ValidSnapshot(
      groupName: groupName,
      keyEpoch: keyEpoch,
      members: members,
      localMember: localMember,
      revision: (snapshot['revision'] as num?)?.toInt(),
      updatedAt: DateTime.tryParse(snapshot['updatedAt'] as String? ?? ''),
    );
  }

  Future<RefreshGroupSnapshotResult> _applySnapshot({
    required _RefreshReady context,
    required _ValidSnapshot validation,
    required Map<String, dynamic>? controlEvent,
    required List<Map<String, dynamic>> controlEvents,
  }) async {
    final eventMetadata = _parseControlEvents(controlEvents);
    if (eventMetadata.isNotEmpty && validation.revision == null) {
      return const RefreshGroupSnapshotFailed(
        'Authoritative snapshot does not cover fetched control events',
      );
    }
    if (validation.revision != null &&
        eventMetadata.any((event) => event.revision > validation.revision!)) {
      return const RefreshGroupSnapshotFailed(
        'Authoritative snapshot revision is behind the control feed',
      );
    }
    final updated = await _applyAuthoritativeSnapshot(
      context: context,
      validation: validation,
      controlEvent: controlEvent,
      eventMetadata: eventMetadata,
    );
    return updated
        ? RefreshGroupSnapshotApplied(groupName: validation.groupName)
        : const RefreshGroupSnapshotIgnored();
  }

  Future<bool> _applyAuthoritativeSnapshot({
    required _RefreshReady context,
    required _ValidSnapshot validation,
    required Map<String, dynamic>? controlEvent,
    required List<ControlEventMetadata> eventMetadata,
  }) {
    final revisioned = context.revisionedRepository;
    if (revisioned != null && validation.revision != null) {
      return revisioned.applyRevisionedAuthoritativeSnapshot(
        groupId: context.groupId,
        groupName: validation.groupName,
        role: validation.localMember.role,
        keyEpoch: validation.keyEpoch,
        members: validation.members,
        revision: validation.revision!,
        updatedAt:
            validation.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        snapshotDigest: controlSnapshotDigest(
          groupId: context.groupId,
          groupName: validation.groupName,
          role: validation.localMember.role,
          keyEpoch: validation.keyEpoch,
          members: validation.members,
        ),
        eventId: context.eventId,
        eventRevision: _intValue(controlEvent?['revision']),
        eventType:
            _nonEmptyString(controlEvent?['controlEventType']) ??
            _nonEmptyString(controlEvent?['type']),
        eventOccurredAt: DateTime.tryParse(
          _nonEmptyString(controlEvent?['occurredAt']) ?? '',
        ),
        controlEvents: eventMetadata,
      );
    }
    return _groupRepository.applyAuthoritativeSnapshot(
      groupId: context.groupId,
      groupName: validation.groupName,
      role: validation.localMember.role,
      keyEpoch: validation.keyEpoch,
      members: validation.members,
    );
  }

  String? _nonEmptyString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  int? _intValue(Object? value) => switch (value) {
    int number => number,
    num number => number.toInt(),
    String text => int.tryParse(text),
    _ => null,
  };

  List<ControlEventMetadata> _parseControlEvents(
    List<Map<String, dynamic>> events,
  ) {
    return events
        .map((event) {
          final eventId = _nonEmptyString(event['eventId']);
          final eventGroupId = _nonEmptyString(event['groupId']);
          final revision = _intValue(event['revision']);
          if (eventId == null ||
              eventGroupId == null ||
              revision == null ||
              revision <= 0) {
            throw const FormatException('Invalid control event metadata');
          }
          return ControlEventMetadata(
            eventId: eventId,
            groupId: eventGroupId,
            revision: revision,
            eventType:
                _nonEmptyString(event['eventType']) ?? 'snapshot_invalidated',
            occurredAt:
                DateTime.tryParse(_nonEmptyString(event['occurredAt']) ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          );
        })
        .toList(growable: false);
  }

  List<GroupMember> _parseMembers(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (member) => GroupMember.fromJson(
            member.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  GroupMember? _memberForDevice(List<GroupMember> members, String deviceId) {
    for (final member in members) {
      if (member.deviceId == deviceId) return member;
    }
    return null;
  }
}

sealed class _RefreshPreparation {
  const _RefreshPreparation();
}

class _RefreshIgnored extends _RefreshPreparation {
  const _RefreshIgnored();
}

class _RefreshFailed extends _RefreshPreparation {
  const _RefreshFailed(this.message);

  final String message;
}

class _RefreshReady extends _RefreshPreparation {
  const _RefreshReady({
    required this.groupId,
    required this.deviceId,
    required this.eventId,
    required this.revisionedRepository,
  });

  final String groupId;
  final String deviceId;
  final String? eventId;
  final RevisionedGroupRepository? revisionedRepository;
}

sealed class _SnapshotValidation {
  const _SnapshotValidation();
}

class _InvalidSnapshot extends _SnapshotValidation {
  const _InvalidSnapshot(this.result);

  final RefreshGroupSnapshotResult result;
}

class _ValidSnapshot extends _SnapshotValidation {
  const _ValidSnapshot({
    required this.groupName,
    required this.keyEpoch,
    required this.members,
    required this.localMember,
    required this.revision,
    required this.updatedAt,
  });

  final String groupName;
  final int keyEpoch;
  final List<GroupMember> members;
  final GroupMember localMember;
  final int? revision;
  final DateTime? updatedAt;
}

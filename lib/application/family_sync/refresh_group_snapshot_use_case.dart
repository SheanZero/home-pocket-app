import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'control_snapshot_digest.dart';
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

class RefreshGroupSnapshotFailed extends RefreshGroupSnapshotResult {
  const RefreshGroupSnapshotFailed(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
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

    final localGroup = await _groupRepository.getActiveGroup();
    if (localGroup == null || localGroup.groupId != groupId) {
      return const RefreshGroupSnapshotIgnored();
    }

    final revisionedRepository = _groupRepository is RevisionedGroupRepository
        ? _groupRepository as RevisionedGroupRepository
        : null;
    final eventId = _nonEmptyString(controlEvent?['eventId']);
    if (controlEvents.isEmpty &&
        eventId != null &&
        revisionedRepository != null &&
        await revisionedRepository.hasProcessedControlEvent(eventId)) {
      return const RefreshGroupSnapshotIgnored();
    }

    final deviceId = await _keyManager.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      return const RefreshGroupSnapshotFailed('Device identity unavailable');
    }

    try {
      var snapshot = await _apiClient.getGroupStatus(groupId);
      if (await _membershipRotation?.recoverFromSnapshot(snapshot) == true) {
        snapshot = await _apiClient.getGroupStatus(groupId);
      }
      if (_requestGeneration[groupId] != generation) {
        return const RefreshGroupSnapshotIgnored();
      }

      if (snapshot['groupId'] != groupId) {
        return const RefreshGroupSnapshotFailed(
          'Authoritative group snapshot has a mismatched group id',
        );
      }
      if (snapshot['status'] != 'active') {
        return const RefreshGroupSnapshotMembershipInvalid(
          'Group is inactive',
          statusCode: 404,
        );
      }

      final members = _parseMembers(snapshot['members']);
      final isActiveMember = members.any(
        (member) => member.deviceId == deviceId && member.status == 'active',
      );
      if (!isActiveMember) {
        return const RefreshGroupSnapshotMembershipInvalid(
          'Device is no longer an active group member',
        );
      }

      final localMember = members.firstWhere(
        (member) => member.deviceId == deviceId,
      );
      final keyEpoch = (snapshot['keyEpoch'] as num?)?.toInt();
      if (keyEpoch == null || keyEpoch < 1) {
        return const RefreshGroupSnapshotFailed(
          'Authoritative group snapshot has an invalid key epoch',
        );
      }

      final groupName = snapshot['groupName'];
      if (groupName is! String || groupName.trim().isEmpty) {
        return const RefreshGroupSnapshotFailed(
          'Authoritative group snapshot has an invalid name',
        );
      }

      // Re-check after the network boundary. The repository update also uses
      // `status = active` in its WHERE clause, closing the remaining race.
      final currentGroup = await _groupRepository.getActiveGroup();
      if (_requestGeneration[groupId] != generation ||
          currentGroup == null ||
          currentGroup.groupId != groupId) {
        return const RefreshGroupSnapshotIgnored();
      }

      final revision = (snapshot['revision'] as num?)?.toInt();
      final eventMetadata = _parseControlEvents(controlEvents);
      if (eventMetadata.isNotEmpty && revision == null) {
        return const RefreshGroupSnapshotFailed(
          'Authoritative snapshot does not cover fetched control events',
        );
      }
      if (revision != null &&
          eventMetadata.any((event) => event.revision > revision)) {
        return const RefreshGroupSnapshotFailed(
          'Authoritative snapshot revision is behind the control feed',
        );
      }
      final updatedAt = DateTime.tryParse(
        snapshot['updatedAt'] as String? ?? '',
      );
      final updated = revisionedRepository != null && revision != null
          ? await revisionedRepository.applyRevisionedAuthoritativeSnapshot(
              groupId: groupId,
              groupName: groupName,
              role: localMember.role,
              keyEpoch: keyEpoch,
              members: members,
              revision: revision,
              updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
              snapshotDigest: controlSnapshotDigest(
                groupId: groupId,
                groupName: groupName,
                role: localMember.role,
                keyEpoch: keyEpoch,
                members: members,
              ),
              eventId: eventId,
              eventRevision: _intValue(controlEvent?['revision']),
              eventType:
                  _nonEmptyString(controlEvent?['controlEventType']) ??
                  _nonEmptyString(controlEvent?['type']),
              eventOccurredAt: DateTime.tryParse(
                _nonEmptyString(controlEvent?['occurredAt']) ?? '',
              ),
              controlEvents: eventMetadata,
            )
          : await _groupRepository.applyAuthoritativeSnapshot(
              groupId: groupId,
              groupName: groupName,
              role: localMember.role,
              keyEpoch: keyEpoch,
              members: members,
            );
      if (!updated) {
        return const RefreshGroupSnapshotIgnored();
      }
      return RefreshGroupSnapshotApplied(groupName: groupName);
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
    } catch (_) {
      return const RefreshGroupSnapshotFailed(
        'Failed to refresh the group snapshot',
      );
    }
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
}

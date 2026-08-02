import 'dart:async';

import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'check_group_validity_use_case.dart';
import 'refresh_group_snapshot_use_case.dart';

enum ControlPlaneReconciliationDeferredReason {
  noProgress,
  pageLimitReached,
  invalidResponse,
}

sealed class ControlPlaneReconciliationResult {
  const ControlPlaneReconciliationResult();

  const factory ControlPlaneReconciliationResult.reconciled({
    required int pageCount,
    required int eventCount,
    bool eventsEndpointUnsupported,
  }) = ControlPlaneReconciliationReconciled;

  const factory ControlPlaneReconciliationResult.noGroup() =
      ControlPlaneReconciliationNoGroup;

  const factory ControlPlaneReconciliationResult.unavailable(String message) =
      ControlPlaneReconciliationUnavailable;

  const factory ControlPlaneReconciliationResult.deferred({
    required ControlPlaneReconciliationDeferredReason reason,
    required String message,
    required int pageCount,
  }) = ControlPlaneReconciliationDeferred;
}

class ControlPlaneReconciliationReconciled
    extends ControlPlaneReconciliationResult {
  const ControlPlaneReconciliationReconciled({
    required this.pageCount,
    required this.eventCount,
    this.eventsEndpointUnsupported = false,
  });

  final int pageCount;
  final int eventCount;
  final bool eventsEndpointUnsupported;

  @override
  bool operator ==(Object other) =>
      other is ControlPlaneReconciliationReconciled &&
      other.pageCount == pageCount &&
      other.eventCount == eventCount &&
      other.eventsEndpointUnsupported == eventsEndpointUnsupported;

  @override
  int get hashCode =>
      Object.hash(pageCount, eventCount, eventsEndpointUnsupported);
}

class ControlPlaneReconciliationNoGroup
    extends ControlPlaneReconciliationResult {
  const ControlPlaneReconciliationNoGroup();
}

class ControlPlaneReconciliationUnavailable
    extends ControlPlaneReconciliationResult {
  const ControlPlaneReconciliationUnavailable(this.message);

  final String message;
}

class ControlPlaneReconciliationDeferred
    extends ControlPlaneReconciliationResult {
  const ControlPlaneReconciliationDeferred({
    required this.reason,
    required this.message,
    required this.pageCount,
  });

  final ControlPlaneReconciliationDeferredReason reason;
  final String message;
  final int pageCount;
}

/// Rebuilds the local family control plane before any data-plane work.
///
/// Control events are authenticated invalidations and audit evidence only.
/// They are collected into a bounded page window, then settled atomically by
/// [RefreshGroupSnapshotUseCase] with the authoritative status snapshot.
class ControlPlaneReconciliationUseCase {
  ControlPlaneReconciliationUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    required RefreshGroupSnapshotUseCase refreshSnapshot,
    required CheckGroupValidityUseCase checkValidity,
    int maxPagesPerExecution = 20,
    Duration requestTimeout = const Duration(seconds: 10),
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _refreshSnapshot = refreshSnapshot,
       _checkValidity = checkValidity,
       _maxPagesPerExecution = maxPagesPerExecution,
       _requestTimeout = requestTimeout {
    if (maxPagesPerExecution <= 0) {
      throw ArgumentError.value(
        maxPagesPerExecution,
        'maxPagesPerExecution',
        'must be greater than zero',
      );
    }
    if (requestTimeout <= Duration.zero) {
      throw ArgumentError.value(
        requestTimeout,
        'requestTimeout',
        'must be greater than zero',
      );
    }
  }

  static const int pageSize = 100;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final RefreshGroupSnapshotUseCase _refreshSnapshot;
  final CheckGroupValidityUseCase _checkValidity;
  final int _maxPagesPerExecution;
  final Duration _requestTimeout;

  Future<ControlPlaneReconciliationResult>? _inFlight;

  /// Concurrent cold-start, resume and transport-error triggers share one run.
  Future<ControlPlaneReconciliationResult> execute() {
    final existing = _inFlight;
    if (existing != null) return existing;

    late final Future<ControlPlaneReconciliationResult> tracked;
    tracked = _executeOnce().whenComplete(() {
      if (identical(_inFlight, tracked)) _inFlight = null;
    });
    _inFlight = tracked;
    return tracked;
  }

  /// Reconciles an already-authenticated transport rejection without relying
  /// on a second network request that may itself be unavailable.
  Future<ControlPlaneReconciliationResult>
  executeAfterAuthenticatedMembershipFailure({
    required int statusCode,
    required String reason,
  }) async {
    if (statusCode != 403 && statusCode != 404) {
      throw ArgumentError.value(
        statusCode,
        'statusCode',
        'Only membership failures can use authoritative cleanup',
      );
    }
    final localGroup = await _groupRepository.getActiveGroup();
    if (localGroup == null) {
      return const ControlPlaneReconciliationResult.noGroup();
    }
    return _invalidateMembership(
      groupId: localGroup.groupId,
      statusCode: statusCode,
      reason: reason,
    );
  }

  Future<ControlPlaneReconciliationResult> _executeOnce() async {
    final localGroup = await _groupRepository.getActiveGroup();
    if (localGroup == null) {
      return const ControlPlaneReconciliationResult.noGroup();
    }

    var cursor = localGroup.controlRevision;
    var pageCount = 0;
    var eventsEndpointUnsupported = false;
    final eventsById = <String, Map<String, dynamic>>{};

    while (pageCount < _maxPagesPerExecution) {
      Map<String, dynamic> response;
      try {
        response = await _apiClient
            .getGroupControlEvents(
              groupId: localGroup.groupId,
              afterRevision: cursor,
              limit: pageSize,
            )
            .timeout(_requestTimeout);
      } on RelayApiException catch (error) {
        if (error.isForbidden) {
          return _invalidateMembership(
            groupId: localGroup.groupId,
            statusCode: error.statusCode,
            reason: error.message,
          );
        }
        if (error.isNotFound) {
          // Older relay builds did not expose /events. A 404 from this endpoint
          // alone is not proof that the signed-in device lost membership.
          eventsEndpointUnsupported = true;
          break;
        }
        return ControlPlaneReconciliationResult.unavailable(error.message);
      } catch (error) {
        return ControlPlaneReconciliationResult.unavailable(error.toString());
      }

      pageCount++;
      final parsed = _parsePage(response, expectedGroupId: localGroup.groupId);
      if (parsed == null) {
        return ControlPlaneReconciliationResult.deferred(
          reason: ControlPlaneReconciliationDeferredReason.invalidResponse,
          message: 'Relay returned an invalid control-event page',
          pageCount: pageCount,
        );
      }

      for (final event in parsed.events) {
        final revision = _intValue(event['revision'])!;
        if (revision > localGroup.controlRevision) {
          eventsById.putIfAbsent(event['eventId']! as String, () => event);
        }
      }

      if (!parsed.hasMore) break;
      if (pageCount >= _maxPagesPerExecution) {
        return ControlPlaneReconciliationResult.deferred(
          reason: ControlPlaneReconciliationDeferredReason.pageLimitReached,
          message: 'Control-event reconciliation stopped at the page limit',
          pageCount: pageCount,
        );
      }

      final nextCursor = parsed.nextRevision;
      if (nextCursor == null || nextCursor <= cursor) {
        return ControlPlaneReconciliationResult.deferred(
          reason: ControlPlaneReconciliationDeferredReason.noProgress,
          message: 'Control-event pagination made no progress',
          pageCount: pageCount,
        );
      }
      cursor = nextCursor;
      await Future<void>.delayed(Duration.zero);
    }

    final events = eventsById.values.toList(growable: false)
      ..sort((left, right) {
        final revisionOrder = _intValue(
          left['revision'],
        )!.compareTo(_intValue(right['revision'])!);
        if (revisionOrder != 0) return revisionOrder;
        return (left['eventId']! as String).compareTo(
          right['eventId']! as String,
        );
      });

    RefreshGroupSnapshotResult snapshotResult;
    try {
      snapshotResult = await _refreshSnapshot
          .execute(groupId: localGroup.groupId, controlEvents: events)
          .timeout(_requestTimeout);
    } catch (error) {
      return ControlPlaneReconciliationResult.unavailable(error.toString());
    }
    switch (snapshotResult) {
      case RefreshGroupSnapshotMembershipInvalid(
        :final message,
        :final statusCode,
      ):
        return _invalidateMembership(
          groupId: localGroup.groupId,
          statusCode: statusCode,
          reason: message,
        );
      case RefreshGroupSnapshotFailed(:final message):
        return ControlPlaneReconciliationResult.unavailable(message);
      case RefreshGroupSnapshotApplied() || RefreshGroupSnapshotIgnored():
        final currentGroup = await _groupRepository.getActiveGroup();
        if (currentGroup == null ||
            currentGroup.groupId != localGroup.groupId) {
          return const ControlPlaneReconciliationResult.noGroup();
        }
        return ControlPlaneReconciliationResult.reconciled(
          pageCount: pageCount,
          eventCount: events.length,
          eventsEndpointUnsupported: eventsEndpointUnsupported,
        );
    }
  }

  Future<ControlPlaneReconciliationResult> _invalidateMembership({
    required String groupId,
    required int statusCode,
    required String reason,
  }) async {
    await _checkValidity.invalidateAfterAuthenticatedMembershipFailure(
      groupId: groupId,
      statusCode: statusCode,
      reason: reason,
    );
    return const ControlPlaneReconciliationResult.noGroup();
  }

  _ControlEventPage? _parsePage(
    Map<String, dynamic> response, {
    required String expectedGroupId,
  }) {
    final rawEvents = response['events'];
    if (rawEvents is! List || rawEvents.length > pageSize) return null;
    final rawHasMore = response['hasMore'];
    if (rawHasMore != null && rawHasMore is! bool) return null;

    final events = <Map<String, dynamic>>[];
    var maxRevision = 0;
    for (final rawEvent in rawEvents) {
      if (rawEvent is! Map) return null;
      final event = rawEvent.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final eventId = event['eventId'];
      final groupId = event['groupId'];
      final revision = _intValue(event['revision']);
      if (eventId is! String ||
          eventId.isEmpty ||
          groupId != expectedGroupId ||
          revision == null ||
          revision <= 0) {
        return null;
      }
      maxRevision = revision > maxRevision ? revision : maxRevision;
      events.add(event);
    }

    final hasMore = rawHasMore as bool? ?? false;
    final declaredNext = _intValue(response['nextRevision']);
    if (declaredNext != null && maxRevision > 0 && declaredNext > maxRevision) {
      // Advancing beyond the last authenticated event would skip audit rows.
      return null;
    }
    return _ControlEventPage(
      events: events,
      hasMore: hasMore,
      nextRevision: declaredNext ?? (maxRevision > 0 ? maxRevision : null),
    );
  }

  int? _intValue(Object? value) => switch (value) {
    int number => number,
    num number => number.toInt(),
    String text => int.tryParse(text),
    _ => null,
  };
}

class _ControlEventPage {
  const _ControlEventPage({
    required this.events,
    required this.hasMore,
    required this.nextRevision,
  });

  final List<Map<String, dynamic>> events;
  final bool hasMore;
  final int? nextRevision;
}

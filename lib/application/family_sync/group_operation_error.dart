import '../../infrastructure/network/network_status_checker.dart';
import '../../infrastructure/sync/relay_api_client.dart';

export '../../infrastructure/network/network_status_checker.dart'
    show isNetworkUnavailableError;

enum GroupOperationErrorKind {
  general,
  membershipConflict,
  networkUnavailable,
  notFound,
  rateLimited,
}

const networkUnavailableErrorMessage = 'Network unavailable';

/// Common contract for user-triggered family operations.
///
/// Screens use [kind] for presentation decisions and never inspect [message]
/// for socket/client substrings.
abstract interface class GroupOperationFailure {
  String get message;
  GroupOperationErrorKind get kind;
}

class GroupOperationFailureData implements GroupOperationFailure {
  const GroupOperationFailureData(this.message, {required this.kind});

  @override
  final String message;

  @override
  final GroupOperationErrorKind kind;
}

bool isSingleGroupConflict(RelayApiException error) {
  return error.isConflict &&
      (error.code == 'device_already_grouped' ||
          error.code == 'group_membership_conflict');
}

/// Converts infrastructure/server failures into a presentation-safe result.
GroupOperationFailureData groupOperationFailureFrom(
  Object error, {
  required String fallbackMessage,
}) {
  if (isNetworkUnavailableError(error)) {
    return const GroupOperationFailureData(
      networkUnavailableErrorMessage,
      kind: GroupOperationErrorKind.networkUnavailable,
    );
  }
  if (error is RelayApiException) {
    if (error.isNotFound) {
      return GroupOperationFailureData(
        error.message,
        kind: GroupOperationErrorKind.notFound,
      );
    }
    if (error.statusCode == 429) {
      return const GroupOperationFailureData(
        'Too many requests',
        kind: GroupOperationErrorKind.rateLimited,
      );
    }
    return GroupOperationFailureData(
      error.message,
      kind: GroupOperationErrorKind.general,
    );
  }
  return GroupOperationFailureData(
    fallbackMessage,
    kind: GroupOperationErrorKind.general,
  );
}

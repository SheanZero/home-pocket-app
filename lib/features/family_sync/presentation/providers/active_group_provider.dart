import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/group_info.dart';
import 'repository_providers.dart';

part 'active_group_provider.g.dart';

/// Watches the local database for an active group.
///
/// Emits [GroupInfo] when device is in an active group, null otherwise.
/// Pure local DB stream — zero network calls.
@Riverpod(keepAlive: true)
Stream<GroupInfo?> activeGroup(Ref ref) {
  return ref.watch(groupRepositoryProvider).watchActiveGroup();
}

/// Whether device is currently in an active group.
///
/// Derived from [activeGroupProvider]. Used for conditional UI
/// (banner visibility, mode badge text).
@Riverpod(keepAlive: true)
bool isGroupMode(Ref ref) {
  return ref.watch(activeGroupProvider).valueOrNull != null;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/group_info.dart';
import 'repository_providers.dart';

part 'active_group_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<GroupInfo?> activeGroup(Ref ref) {
  return ref.watch(groupRepositoryProvider).watchActiveGroup();
}

@riverpod
bool isGroupMode(Ref ref) {
  return ref.watch(activeGroupProvider).valueOrNull != null;
}

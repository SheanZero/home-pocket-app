/// Builds a real vector-clock summary from versioned sync operations.
///
/// Each key is the stable mutation origin and each value is the maximum
/// Lamport revision observed for that origin. The summary survives encrypted
/// offline replay unchanged because it is stored alongside the payload.
Map<String, int> buildSyncVectorClock(
  Iterable<Map<String, dynamic>> operations,
) {
  final clock = <String, int>{};
  for (final operation in operations) {
    final data = operation['data'] as Map<String, dynamic>?;
    final origin =
        operation['originDeviceId'] as String? ??
        data?['syncOriginDeviceId'] as String?;
    final revision =
        (operation['revision'] as num?)?.toInt() ??
        (data?['syncRevision'] as num?)?.toInt();
    if (origin == null || origin.isEmpty || revision == null || revision <= 0) {
      continue;
    }
    final previous = clock[origin] ?? 0;
    if (revision > previous) clock[origin] = revision;
  }
  return clock;
}

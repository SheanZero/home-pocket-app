/// Persisted deterministic version for one independently merged member field.
///
/// Ordering is lexicographic: revision, authenticated origin device id, then
/// canonical content digest. Equal versions are duplicates.
class MemberContentVersion implements Comparable<MemberContentVersion> {
  const MemberContentVersion({
    required this.revision,
    required this.originDeviceId,
    required this.contentDigest,
  });

  final int revision;
  final String originDeviceId;
  final String contentDigest;

  @override
  int compareTo(MemberContentVersion other) {
    final revisionOrder = revision.compareTo(other.revision);
    if (revisionOrder != 0) return revisionOrder;
    final originOrder = originDeviceId.compareTo(other.originDeviceId);
    if (originOrder != 0) return originOrder;
    return contentDigest.compareTo(other.contentDigest);
  }

  bool isStrictlyNewerThan(MemberContentVersion other) => compareTo(other) > 0;

  static int nextRevision({required int current, required DateTime now}) {
    final wallClock = now.toUtc().microsecondsSinceEpoch;
    return wallClock > current ? wallClock : current + 1;
  }
}

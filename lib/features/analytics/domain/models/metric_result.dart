/// Sealed envelope for happiness metric results (HAPPY-06 / D-13).
///
/// Two variants:
///   - Empty: window had no qualifying joy-ledger transactions.
///   - Value: a real metric value with the sample size that produced it.
///
/// UI consumers use Dart 3 pattern matching:
///   switch (result) {
///     case Empty(): renderEmptyState();
///     case Value(:final data, :final sampleSize): renderValue(data, sampleSize);
///   }
///
/// Not Freezed - generic plain-sealed avoids Freezed's generic-codegen quirks
/// (no copyWith / no JSON needed; metric instances are immutable transient query
/// results).
sealed class MetricResult<T> {
  const MetricResult();
}

final class Empty<T> extends MetricResult<T> {
  const Empty();
}

final class Value<T> extends MetricResult<T> {
  const Value(this.data, this.sampleSize);

  final T data;
  final int sampleSize;
}

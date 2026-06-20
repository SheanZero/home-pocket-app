import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'state_donut_dimension.g.dart';

/// The donut's split dimension (260620-v2m / D2).
///
/// `category` — the existing L1-category breakdown (default).
/// `member` — split by recording device (`transactions.deviceId`), names/avatars
/// resolved via `activeGroupMembers`.
enum DonutDimension { category, member }

/// Immutable donut-dimension view state: the active [dimension] plus an optional
/// global [memberFilterDeviceId] (`null` = all members).
///
/// The member filter is a GLOBAL narrowing (CONTEXT discretion): it is applied
/// first, then the data is split by whatever the active [dimension] is — and it
/// is intentionally KEPT when switching dimensions (Test 5), not reset.
class DonutDimensionView {
  const DonutDimensionView({
    required this.dimension,
    required this.memberFilterDeviceId,
  });

  const DonutDimensionView.initial()
      : dimension = DonutDimension.category,
        memberFilterDeviceId = null;

  final DonutDimension dimension;

  /// `null` = all members; otherwise the deviceId the view is narrowed to.
  final String? memberFilterDeviceId;

  DonutDimensionView copyWith({
    DonutDimension? dimension,
    bool clearMemberFilter = false,
    String? memberFilterDeviceId,
  }) {
    return DonutDimensionView(
      dimension: dimension ?? this.dimension,
      memberFilterDeviceId: clearMemberFilter
          ? null
          : (memberFilterDeviceId ?? this.memberFilterDeviceId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonutDimensionView &&
          runtimeType == other.runtimeType &&
          dimension == other.dimension &&
          memberFilterDeviceId == other.memberFilterDeviceId;

  @override
  int get hashCode => Object.hash(dimension, memberFilterDeviceId);
}

/// Holds the donut card's in-screen interaction state — split dimension +
/// member filter.
///
/// Plain `@riverpod` (NOT keepAlive) — analytics cards are auto-dispose and this
/// is a per-screen interaction state, consistent with the other analytics
/// providers and the trend card's local `_TrendBody` state.
@riverpod
class DonutDimensionState extends _$DonutDimensionState {
  @override
  DonutDimensionView build() => const DonutDimensionView.initial();

  /// Switches the active split dimension. The member filter is preserved
  /// (global narrowing kept across dimensions — Test 5).
  void setDimension(DonutDimension dimension) {
    state = state.copyWith(dimension: dimension);
  }

  /// Sets (or clears, when [deviceId] is null) the global member filter.
  void setMemberFilter(String? deviceId) {
    state = deviceId == null
        ? state.copyWith(clearMemberFilter: true)
        : state.copyWith(memberFilterDeviceId: deviceId);
  }
}

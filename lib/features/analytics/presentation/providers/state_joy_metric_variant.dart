import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'state_joy_metric_variant.g.dart';

/// D-10 / D-11: Session-scoped AnalyticsScreen joy-metric-variant selection.
///
/// HomeHero is NOT a consumer (D-15), and Settings recommendation UI is NOT a
/// consumer. Cold starts reset to [JoyMetricVariant.all]; this intentionally
/// does not persist to SharedPreferences.
enum JoyMetricVariant { all, manualOnly }

@riverpod
class SelectedJoyMetricVariant extends _$SelectedJoyMetricVariant {
  @override
  JoyMetricVariant build() => JoyMetricVariant.all;

  void setVariant(JoyMetricVariant variant) {
    state = variant;
  }
}

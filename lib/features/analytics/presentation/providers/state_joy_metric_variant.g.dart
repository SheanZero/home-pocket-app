// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_joy_metric_variant.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedJoyMetricVariant)
final selectedJoyMetricVariantProvider = SelectedJoyMetricVariantProvider._();

final class SelectedJoyMetricVariantProvider
    extends $NotifierProvider<SelectedJoyMetricVariant, JoyMetricVariant> {
  SelectedJoyMetricVariantProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedJoyMetricVariantProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedJoyMetricVariantHash();

  @$internal
  @override
  SelectedJoyMetricVariant create() => SelectedJoyMetricVariant();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JoyMetricVariant value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JoyMetricVariant>(value),
    );
  }
}

String _$selectedJoyMetricVariantHash() =>
    r'2f45e522faf4951eb2ec672eef4262b1900b3ba8';

abstract class _$SelectedJoyMetricVariant extends $Notifier<JoyMetricVariant> {
  JoyMetricVariant build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<JoyMetricVariant, JoyMetricVariant>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<JoyMetricVariant, JoyMetricVariant>,
              JoyMetricVariant,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

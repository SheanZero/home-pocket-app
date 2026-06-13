// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversion_preview_panel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keyed rate provider. Resolves the [RateResultWithSignal] for the given
/// (currency, date, amount) via the already-wired P41
/// `appGetExchangeRateUseCaseProvider`. The result carries the D-02 dialog /
/// D-03 toast signals pre-computed by the use case — callers never recompute
/// the >1% threshold (RESEARCH Don't-Hand-Roll).

@ProviderFor(conversionRate)
final conversionRateProvider = ConversionRateFamily._();

/// Keyed rate provider. Resolves the [RateResultWithSignal] for the given
/// (currency, date, amount) via the already-wired P41
/// `appGetExchangeRateUseCaseProvider`. The result carries the D-02 dialog /
/// D-03 toast signals pre-computed by the use case — callers never recompute
/// the >1% threshold (RESEARCH Don't-Hand-Roll).

final class ConversionRateProvider
    extends
        $FunctionalProvider<
          AsyncValue<RateResultWithSignal>,
          RateResultWithSignal,
          FutureOr<RateResultWithSignal>
        >
    with
        $FutureModifier<RateResultWithSignal>,
        $FutureProvider<RateResultWithSignal> {
  /// Keyed rate provider. Resolves the [RateResultWithSignal] for the given
  /// (currency, date, amount) via the already-wired P41
  /// `appGetExchangeRateUseCaseProvider`. The result carries the D-02 dialog /
  /// D-03 toast signals pre-computed by the use case — callers never recompute
  /// the >1% threshold (RESEARCH Don't-Hand-Roll).
  ConversionRateProvider._({
    required ConversionRateFamily super.from,
    required ConversionPreviewArgs super.argument,
  }) : super(
         retry: null,
         name: r'conversionRateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversionRateHash();

  @override
  String toString() {
    return r'conversionRateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RateResultWithSignal> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RateResultWithSignal> create(Ref ref) {
    final argument = this.argument as ConversionPreviewArgs;
    return conversionRate(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversionRateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversionRateHash() => r'aea13bad0dd51cdd1c6ec81b70d1dfac6186889e';

/// Keyed rate provider. Resolves the [RateResultWithSignal] for the given
/// (currency, date, amount) via the already-wired P41
/// `appGetExchangeRateUseCaseProvider`. The result carries the D-02 dialog /
/// D-03 toast signals pre-computed by the use case — callers never recompute
/// the >1% threshold (RESEARCH Don't-Hand-Roll).

final class ConversionRateFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<RateResultWithSignal>,
          ConversionPreviewArgs
        > {
  ConversionRateFamily._()
    : super(
        retry: null,
        name: r'conversionRateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keyed rate provider. Resolves the [RateResultWithSignal] for the given
  /// (currency, date, amount) via the already-wired P41
  /// `appGetExchangeRateUseCaseProvider`. The result carries the D-02 dialog /
  /// D-03 toast signals pre-computed by the use case — callers never recompute
  /// the >1% threshold (RESEARCH Don't-Hand-Roll).

  ConversionRateProvider call(ConversionPreviewArgs args) =>
      ConversionRateProvider._(argument: args, from: this);

  @override
  String toString() => r'conversionRateProvider';
}

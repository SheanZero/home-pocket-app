// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formatter_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application-layer provider for [FormatterService].
///
/// No `app` prefix needed — FormatterService has no infrastructure-side analog
/// provider; this is the single canonical name.

@ProviderFor(formatterService)
final formatterServiceProvider = FormatterServiceProvider._();

/// Application-layer provider for [FormatterService].
///
/// No `app` prefix needed — FormatterService has no infrastructure-side analog
/// provider; this is the single canonical name.

final class FormatterServiceProvider
    extends
        $FunctionalProvider<
          FormatterService,
          FormatterService,
          FormatterService
        >
    with $Provider<FormatterService> {
  /// Application-layer provider for [FormatterService].
  ///
  /// No `app` prefix needed — FormatterService has no infrastructure-side analog
  /// provider; this is the single canonical name.
  FormatterServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'formatterServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$formatterServiceHash();

  @$internal
  @override
  $ProviderElement<FormatterService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FormatterService create(Ref ref) {
    return formatterService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FormatterService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FormatterService>(value),
    );
  }
}

String _$formatterServiceHash() => r'96d786c85768b95c9419e0fb959c710ff3606246';

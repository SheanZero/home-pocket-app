// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_category_reorder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CategoryReorderNotifier)
final categoryReorderProvider = CategoryReorderNotifierProvider._();

final class CategoryReorderNotifierProvider
    extends $NotifierProvider<CategoryReorderNotifier, CategoryReorderState> {
  CategoryReorderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryReorderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryReorderNotifierHash();

  @$internal
  @override
  CategoryReorderNotifier create() => CategoryReorderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryReorderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryReorderState>(value),
    );
  }
}

String _$categoryReorderNotifierHash() =>
    r'4338ccc503b0fd37d13974312078d9ed83a5c0da';

abstract class _$CategoryReorderNotifier
    extends $Notifier<CategoryReorderState> {
  CategoryReorderState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CategoryReorderState, CategoryReorderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CategoryReorderState, CategoryReorderState>,
              CategoryReorderState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
